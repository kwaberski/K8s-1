#!/bin/bash
#############################################################
### Script to prepare new VMs for kubernetes install
###
### TODO
# 1. set clustername in ClusterConfiguration file used by kubeadm.
#     use the cluster name configure for the deployment
# 2. bootstrap token for masters and workers
#     that way I can bring the whole cluster up with kubadm in paralel
#     this will not use a pub cert hash for authN
# 3. use local terraform local provisioner or ansible to setup local hubeconfig file

function display_usage() { 
	echo "This script provisions a k8s on master and worker nodes."
	echo "It optionally takes three INPUTS that can be provided as parameters or in environment variables"
	echo -e "\nUsage:"
	echo -e "CRI=<value> CNI=<value> K8S_VERSION=,value> $0 \n"
  echo "CRI          - CRI to install. Allowed: containerd (default), crio, docker"
  echo "CNI          - CNI to install. Allowed: calico (default)"
  echo "K8S_VERSION  - Kubernetes version to use, must include the minor release, ex. 1.20.0"
  echo "CLUSTER_NAME - by default derived from host name"
  echo "CLUSTER_IP   - this is the API endpoint (typically IP pointing at a LB)"
  echo "SVC_SUBNET   - subnet to use for the virtual service network"
  echo "POD_CIDR     - POD_CIDR"
	} 

function remove_cloudinit() {
  sudo cloud-init clean --logs
  sudo rm -rf /etc/netplan/50-cloud-init.yaml
  sudo apt purge -y cloud-init
  sudo apt autoremove -y
  sudo rm -rf /etc/cloud/; sudo rm -rf /var/lib/cloud/
}

function prep_cri_fw() {
  # Let iptables see bridged traffic
  # Add overlay module for CRI runtime
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
  sudo modprobe overlay
  sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

  sudo sysctl --system
}

function setup_firewall() {
  # Setup local firewall with diferent rules on masters and workers

  if [[ $NODE == "m" ]]
  then
    # open ports for a master
    echo "I'M MASTER"
cat <<EOF | sudo tee /etc/ufw/applications.d/k8s-master
[k8s-master]
title=K8s Control-plane
description=Ports for the K8s Control-plane nodes
ports=6443,2379:2380,8001,10250:10252/tcp
EOF
      sudo ufw app update k8s-master
      sudo ufw allow k8s-master

  elif [[ $NODE == "w" ]]
  then
    # open ports for a worker
    echo "I'M WORKER"
cat <<EOF | sudo tee /etc/ufw/applications.d/k8s-worker
[k8s-worker]
title=K8s Data-plane
description=Ports for the K8s worker nodes
ports=10250,30000:32767/tcp
EOF
    sudo ufw app update k8s-worker
    sudo ufw allow k8s-worker
  fi 


  if [[ $CNI == "calico" ]]
  then
    # open ports for calico
cat <<EOF | sudo tee /etc/ufw/applications.d/calico
[Calico]
title=Calico CNI
description=Ports for the CalicoCNI
ports=179,5473/tcp|4789/udp
EOF
    sudo ufw app update calico
    sudo ufw allow calico
  fi
  
  # allow SSH and apply settings
  sudo ufw allow OpenSSH
  sudo ufw enable
}

function install_cri() {
  if [[ $CRI == "containerd" ]]
  then
    # Setup official docker repo
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    ## add docker's official GPG key
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    ## add stable repo
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # install containerd
    sudo apt-get update
    sudo apt-get install -y containerd.io

    # configure containerd
    sudo mkdir -p /etc/containerd
    containerd config default | sudo tee /etc/containerd/config.toml
    # use systemd cgroup driver
    sudo sed -i '/runtimes\.runc\.options]/a\            SystemdCgroup = true' /etc/containerd/config.toml
    # restart containerd
    sudo systemctl restart containerd

    # set CRI_SOCKET used the by clusterinstall_k8s_cluster function
    CRI_SOCKET=/var/run/containerd/containerd.sock
  
  elif [[ $CRI == "crio" ]]
  then 
    # setup repos and their GPG keys
    local OS="xUbuntu_"$(cat /etc/os-release | grep VERSION_ID | cut -f2 -d'=' | cut -f2 -d'"')
    local VERSION=${K8S_VERSION%.*}

    cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF
    cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF
    curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
    curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers-cri-o.gpg add -

    # Install CRI-O
    sudo apt-get update
    sudo apt-get install cri-o cri-o-runc

    # You must remove metacopy=on from mountopt in /etc/containers/storage.conf
    sudo sed -i 's/,metacopy=on//' /etc/containers/storage.conf

    # Launch
    sudo systemctl daemon-reload
    sudo systemctl enable crio --now

    # set CRI_SOCKET used the by clusterinstall_k8s_cluster function
    CRI_SOCKET=/var/run/crio/crio.sock
  
  elif [[ $CRI == "docker" ]]
  then
    # first uninstall older version if they exist
    sudo apt-get remove docker docker-engine docker.io containerd runc

    # configure docker repo, key and install
    sudo apt update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    # since we set up our repo under /etc/apt.source.list.d/docker.list we need to
    # comment out the default docker repo from /etc/apt.source.list
    sudo sed -i 's/deb [arch=amd64] https:\/\/download.docker.com/#deb [arch=amd64] https:\/\/download.docker.com/' /etc/apt/sources.list
    sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io

    # configure docker daemon to use Systemd as CGROUP manager
  sudo mkdir /etc/docker
  cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
    # restart docker
    sudo systemctl enable docker && sudo systemctl daemon-reload && sudo systemctl restart docker

    # set CRI_SOCKET used the by clusterinstall_k8s_cluster function
    CRI_SOCKET=/var/run/docker.sock

  fi

}

function install_kubeadm_toolset() {
  # install dependencies
  sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl
  # downloaf Google cloud GPG signing key
  sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
  # set the repo
  echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
  
  # set version to install
  local VERSION=${K8S_VERSION}-00
  sudo apt-get update
  sudo apt-get install -y kubelet=$VERSION kubeadm=$VERSION kubectl=$VERSION
  sudo apt-mark hold kubelet kubeadm kubectl

}

function install_cni() {
  # pod disruption budgets are policy/v1 as of 1.21+
  local VER=1.21.0
  # install CNI
  if [[ $CNI == "calico" ]]
  then
    # if k8s version is greater or equal $VER then we need to edit the calico yaml
    if [[ $(echo -e "$VER\n$K8S_VERSION" | sort -V | head -n1) == $VER ]]
    then
      curl -fsSL https://docs.projectcalico.org/manifests/calico.yaml | sed 's/apiVersion: policy\/v1beta1/apiVersion: policy\/v1/' | kubectl apply -f -
    else
      kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
    fi 
  fi
}

function install_k8s_cluster() {
<< COMMENT
  this function installs a k8s cluster with kubeadm
  if using the hostname naming scheme to detemrine if it is invoked 
  on a master or a worker node and in the case of master if it is a first master 
  it uses a configuration file for kubeadm with with InitConfiguration 
  ClusterConfiguration and KubeletConfiguration. 
  It also uses envsubst to substitute variables used kubeadmInitConfig-new.yaml
  to customize the installation
  
  TOKEN - bootstrap token (we generate it locally)
  CRI_SOCKET - derive fron CRI (set by the install_cri function)
  KEY_TO_ENCRYPT_CONTROLPLANECERTS - used when kubeadm init uploads control-plane 
  certificates to the cluster. We generate it here 
  
  Below variables can be supplied as ENV variables to the script
  CLUSTER_NAME - derived from host name
  CLUSTER_IP - this is the API endpoint (typically DNS name pointing at a LB)
  SVC_SUBNET - subnet to use for the virtual service network
  POD_CIDR - POD_CIDR
COMMENT
  # locally generated variables
  local TOKEN='1h8obe.p47wlhuew5nsfv1c' 
  local KEY_TO_ENCRYPT_CONTROLPLANECERTS="a5bc630d641ad14c3699124a84368b0f33a5112b258b113fd636c957ba1face8"
  
  # if MASTER
  if [[ $NODE == "m" ]]
  then
    if [[ $MID -eq 1 ]]
    then
      # IMPORTANT
      # When using Docker, kubeadm will automatically detect the cgroup driver for the kubelet 
      # If you are using a different CRI, you must pass your cgroupDriver value to kubeadm configuration file (kind: KubeletConfiguration)

      # FIRST MASTER - Init
      sudo bash -c "kubeadm init --config <(TOKEN=$TOKEN KEY_TO_ENCRYPT_CONTROLPLANECERTS=$KEY_TO_ENCRYPT_CONTROLPLANECERTS \
      CRI_SOCKET=$CRI_SOCKET CLUSTER_NAME=$CLUSTER_NAME CLUSTER_IP=$CLUSTER_IP \
      SVC_SUBNET=$SVC_SUBNET POD_CIDR=$POD_CIDR \
      envsubst < ./kubeadmInitConfig-new.yaml)"
      # Now upload certs to ETCD
      sudo kubeadm init phase upload-certs --upload-certs --certificate-key $KEY_TO_ENCRYPT_CONTROLPLANECERTS
      # Set up kubeconfig
      mkdir -p $HOME/.kube
      sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
      sudo chown $(id -u):$(id -g) $HOME/.kube/config      
      # Install CNI
      install_cni
    elif [[ $MID -gt 1 ]]
    then
      # OTHER MASTER - Join Control Plane
      sudo bash -c "kubeadm join --config <(TOKEN=$TOKEN KEY_TO_ENCRYPT_CONTROLPLANECERTS=$KEY_TO_ENCRYPT_CONTROLPLANECERTS \
      CRI_SOCKET=$CRI_SOCKET CLUSTER_NAME=$CLUSTER_NAME CLUSTER_IP=$CLUSTER_IP \
      SVC_SUBNET=$SVC_SUBNET POD_CIDR=$POD_CIDR \
      envsubst < ./kubeadmJoinControlPlaneConfig-new.yaml)"
      # Set up kubeconfig
      mkdir -p $HOME/.kube
      sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
      sudo chown $(id -u):$(id -g) $HOME/.kube/config
    fi
  elif [[ $NODE == "w" ]]
  then
    # WORKER - Join
    sudo bash -c "kubeadm join --config <(TOKEN=$TOKEN KEY_TO_ENCRYPT_CONTROLPLANECERTS=$KEY_TO_ENCRYPT_CONTROLPLANECERTS \
    CRI_SOCKET=$CRI_SOCKET CLUSTER_NAME=$CLUSTER_NAME CLUSTER_IP=$CLUSTER_IP \
    SVC_SUBNET=$SVC_SUBNET POD_CIDR=$POD_CIDR \
    envsubst < ./kubeadmJoinConfig-new.yaml)"

  fi
}
#############################################################
### Main

# check if necessary arguments have been provided otherwise assign defaults
: ${CRI=containerd} ${CNI=calico} ${K8S_VERSION=1.22.0}

# I rely on naming convention for NODES that is 
# c<digit>m<digit> for masters and c<digit>w<digit> for workers
# for example c1m1, c1m2 are masters and c1w3 is a worker
NODE=$(hostname | cut -c 3)
MID=$(hostname | cut -c 4)

# if not privided in ENV then assign values to below variables
[[ ! $CLUSTER_NAME ]] && CLUSTER_NAME=$(hostname | cut -c1-2)
# we start at 192.168.0.20 for c1 and we increment by 1
[[ ! $CLUSTER_IP ]] && CLUSTER_IP=192.168.0.$(expr 19 + $(hostname | cut -c 2))
# we start at 10.96.0.0/16 for c1 and we increment by 1
[[ ! $CLUSTER_IP ]] && SVC_SUBNET=10.$(expr 95 + $(hostname | cut -c 2)).0.0/16
# we start ar 172.16.0.0/16 for c1
[[ ! $POD_CIDR ]] && POD_CIDR=172.$(expr 15 + $(hostname | cut -c 2)).0.0/16

# check whether user had supplied -h or --help . If yes display usage 
if [[ $1 == "--help" ||  $1 == "-h" ]] 
then 
    display_usage
    exit 0
fi 

# OS Level PREP
# First lets get rid of Cloud-init as we dont need it anymore
remove_cloudinit
# prep for cri and firewall
prep_cri_fw
# configure firewall
setup_firewall
# install cri
install_cri
# install kubeadm, kubectl and kubelet
install_kubeadm_toolset
# Before I can install the cluster I MUST setup the LB to server the cluster endpoint
# This means I need the new DNS entry in AD as well as LB
# install k8s cluster
install_k8s_cluster

