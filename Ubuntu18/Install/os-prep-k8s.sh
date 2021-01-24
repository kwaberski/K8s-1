#!/bin/bash
#read -p "Enter desired hostname: " host_name
#if [ "$host_name" == "" ]; then
#  echo "Host name can not be blank! Exiting!"
#  exit
#fi
#
#ip_addr=$(ifconfig enp0s3 | grep "inet " | awk '{print $2}')

### set hostname
#sudo hostnamectl set-hostname $host_name
echo "192.168.2.32 master1" >> /etc/hosts
echo "192.168.2.33 master2" >> /etc/hosts
echo "192.168.2.34 master3" >> /etc/hosts
echo "192.168.2.40 worker1" >> /etc/hosts
echo "192.168.2.41 worker2" >> /etc/hosts
echo "192.168.2.42 worker3" >> /etc/hosts
echo "192.168.0.20 lbext" >> /etc/hosts
echo "192.168.2.20 lbint" >> /etc/hosts

### instal Docker
#sudo apt-get install docker.io -y
#docker --version
#sudo systemctl enable docker
#sudo systemctl start docker

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
## MASTER
#cat <<EOF > /etc/ufw/applications.d/k8s-master
#[k8s-master]
#title=K8s Control-plane
#description=Ports for the K8s Control-plane nodes
#ports=6443,2379:2380,8001,10250:10252/tcp
#EOF
#ufw app update k8s-master
#ufw allow OpenSSH
#ufw allow k8s-master
## for calico
#cat <<EOF > /etc/ufw/applications.d/calico
#[calico]
#title=Calico CNI
#description=Ports for the CalicoCNI
#ports=179,5473/tcp|4789/udp
#EOF
#ufw app update calico
#ufw allow calico
## for flannel
#cat <<EOF > /etc/ufw/applications.d/flannel
#[flannel]
#title=Flannel CNI
#description=Ports for the FlannelCNI
#ports=8472/udp
#EOF
#ufw app update flannel
#ufw allow flannel
#ufw enable
