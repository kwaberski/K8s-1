### TODO
# 1. set clustername in ClusterConfiguration file used by kubeadm.
#     use the cluster name configure for the deployment
# 2. bootstrap token for masters and workers
#     that way I can bring the whole cluster up with kubadm in paralel
#     this will not use a pub cert hash for authN
# 3. use local terraform local provisioner or ansible to setup local hubeconfig file


#############################################################
### Script to prepare new VMs for kubernetes install
###

## OS Level PREP
##

# First lets get rid of Cloud-init as we dont need it anymore
sudo cloud-init clean --logs
#sudo touch /etc/cloud/cloud-init.disabled
sudo rm -rf /etc/netplan/50-cloud-init.yaml
#echo 'datasource_list: [ None ]' | sudo -s tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg
sudo apt-get purge -y cloud-init
sudo apt autoremove -y
sudo rm -rf /etc/cloud/; sudo rm -rf /var/lib/cloud/

#
# Letting iptables see bridged traffic
# also adding overlay module for CRI-O runtime
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


# Setup local firewall
# diferent rules on masters and workers
# I rely on naming convention that is c<digit>m<digit> for masters and c<digit>m<digit> for workers
NODE=`hostname | cut -c 3`
MID=`hostname | cut -c 4`


if [ "$NODE" = "m" ];
then
echo "I'M MASTER"
cat <<EOF | sudo tee /etc/ufw/applications.d/k8s-master
[k8s-master]
title=K8s Control-plane
description=Ports for the K8s Control-plane nodes
ports=6443,2379:2380,8001,10250:10252/tcp
EOF
cat <<EOF | sudo tee /etc/ufw/applications.d/calico
[Calico]
title=Calico CNI
description=Ports for the CalicoCNI
ports=179,5473/tcp|4789/udp
EOF
sudo ufw app update calico
sudo ufw allow calico
sudo ufw app update k8s-master
sudo ufw allow OpenSSH
sudo ufw allow k8s-master
sudo ufw enable

elif [ "$NODE" = "w" ];
then
echo "I'M WORKER"
cat <<EOF | sudo tee /etc/ufw/applications.d/k8s-worker
[k8s-worker]
title=K8s Data-plane
description=Ports for the K8s worker nodes
ports=10250,30000:32767/tcp
EOF
cat <<EOF | sudo tee /etc/ufw/applications.d/calico
[Calico]
title=Calico CNI
description=Ports for the CalicoCNI
ports=179,5473/tcp|4789/udp
EOF
sudo ufw app update calico
sudo ufw allow calico
sudo ufw app update k8s-worker
sudo ufw allow OpenSSH
sudo ufw allow k8s-worker
sudo ufw enable
fi

##
## End Of OS level prepare

## K8s Prep and Install

# 1st container runtime, I will use CRI-O
# Earlier I took care fo the modles and sysctl setup
# Lets set the version
# L_VERSION=1.20.2-00, M_VERSION=1.20.2, S_VERSION=1.20
#L_VERSION=`apt-cache policy kubectl | grep Candidate | awk '{print $NF}'`
#M_VERSION=`echo $L_VERSION | cut -f 1 -d'-'`
#S_VERSION=`apt-cache policy kubectl | grep Candidate | awk '{print $NF}' | cut -f 1,2 -d'.'`
OS="xUbuntu_18.04"
#VERSION="$S_VERSION"
VERSION="1.20"
L_VERSION="1.20.1-00"
cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF
cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers-cri-o.gpg add -
sudo apt-get update
sudo apt-get install cri-o cri-o-runc -y
# You must remove metacopy=on from mountopt in /etc/containers/storage.conf
sudo sed -i 's/,metacopy=on//' /etc/containers/storage.conf
#cat <<EOF | sudo tee /etc/containers/registries.conf
#[registries.search]
#registries = ['docker.io', 'quay.io']
#EOF
sudo systemctl daemon-reload
sudo systemctl enable crio
sudo systemctl start crio

# Lets install desired versions of kubeadm, kubelet, kubectl
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt-get update
sudo apt-get install -y kubelet=$L_VERSION kubeadm=$L_VERSION kubectl=$L_VERSION
sudo apt-mark hold kubelet kubeadm kubectl


### IMPORTANT
# if running a cluster with a frontend LB make sure you provision that LB as well
# and if you do TLS healthcheck you need to either do verify none on the server line
# not to verify the server's cert
# or deliver the ca.crt file to the LB and point to it

# Install the master
### initialize the MASTER
if [ "$NODE" = "m" ];
then
  if [ $MID -eq 1 ];
  then
    # I'M the 1st MASTER
    # IMPORTANT
    # When using Docker, kubeadm will automatically detect the cgroup driver for the kubelet 
    # and set it in the /var/lib/kubelet/config.yaml file during runtime.
    # If you are using a different CRI, you must pass your cgroupDriver value to kubeadm 
    # init
    # Init the 1st MASTER
    sudo kubeadm init --config kubeadmInitConfig.yaml
    # Deploy a CNI based Pod network add-on so pods can communicate
    # Installing Calico: calico detects pod-cidr if setup with kubeadm
    sudo kubeadm init phase upload-certs --upload-certs --certificate-key a5bc630d641ad14c3699124a84368b0f33a5112b258b113fd636c957ba1face8
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
    #
    # here is a warning I get
    # [endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
  else
    sudo kubeadm join --config kubeadmJoinControlPlaneConfig.yaml
    # copy kubeconfig file
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
  fi
elif [ "$NODE" = "w" ];
then
  # I'M WORKER
  sudo kubeadm join --config kubeadmJoinConfig.yaml
fi
