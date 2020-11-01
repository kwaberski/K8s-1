#!/bin/bash
read -p "Enter desired hostname: " host_name
if [ "$host_name" == "" ]; then
  echo "Host name can not be blank! Exiting!"
  exit
fi

ip_addr=$(ifconfig enp0s3 | grep "inet " | awk '{print $2}')

### set hostname
sudo hostnamectl set-hostname $host_name
echo "10.0.0.20 masteru" >> /etc/hosts
echo "10.0.0.21 node1u" >> /etc/hosts
echo "10.0.0.22 node2u" >> /etc/hosts

### instal Docker
sudo apt-get install docker.io -y
docker --version
sudo systemctl enable docker
sudo systemctl start docker

### Make sure that the br_netfilter module is loaded.
lsmod | grep br_netfilter
# if not then
# sudo modprobe br_netfilter

### check if net.bridge.bridge-nf-call-iptables is set to 1
# for IPTABLES to correctly see bridged traffic
# if not
#cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
#net.bridge.bridge-nf-call-ip6tables = 1
#net.bridge.bridge-nf-call-iptables = 1
#EOF
#sudo sysctl --system

### check firewall configuration
# MASTER
cat <<EOF > /etc/ufw/applications.d/k8s-master
[k8s-master]
title=K8s Control-plane
description=Ports for the K8s Control-plane nodes
ports=6443,2379:2380,8001,10250:10252/tcp
EOF
ufw app update k8s-master
ufw allow OpenSSH
ufw allow k8s-master

### Installing kubeadm, kubelet and kubectl
# add signing key for kubernetes packages
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

### ONly on MASTER when you dont use DOCKER
# Configure cgroup driver used by kubelet on control-plane node
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

### initialize the MASTER
kubeadm init --pod-network-cidr=172.16.0.0/16 --upload-certs
# to get the token
# kubeadm token list
# TOKEN=$(kubeadm token list | grep "kubeadm init" | awk '{print $1}')
# to get the hash
# openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
#   openssl dgst -sha256 -hex | sed 's/^.* //'
# kubeadm join masteru:6443 --token j9yflw.bzacurze3hkb5avy \
# --discovery-token-ca-cert-hash sha256:01ef61af897ad2c2f77711a9e69e92c886710295f700a6409664648d397993b9


# setup kubeconfig file
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

### instal pod network calico
cat <<EOF > /etc/ufw/applications.d/calico
[Calico]
title=Calico CNI
description=Ports for the CalicoCNI
ports=179,5473/tcp|4789/udp
EOF
ufw app update calico
ufw allow calico

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
