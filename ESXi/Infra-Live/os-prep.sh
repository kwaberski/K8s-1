### Script to prepare new VMs for kubernetes install
###

## First lets get rid of Cloud-init as we dont need it anymore
sudo cloud-init clean --logs
sudo touch /etc/cloud/cloud-init.disabled
sudo rm -rf /etc/netplan/50-cloud-init.yaml
echo 'datasource_list: [ None ]' | sudo -s tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg
apt-get purge -y cloud-init
sudo apt autoremove -y
sudo rm -rf /etc/cloud/; sudo rm -rf /var/lib/cloud/

## Letting iptables see bridged traffic
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

## Setup local firewall
## diferent rules on masters and workers
## I rely oin naming convention that is c<digit>m<digit> for masters and c<digit>m<digit> for workers
if [ `hostname | cut -c 3` == "m" ];
then
# I'M MASTER
cat <<EOF | sudo tee /etc/ufw/applications.d/k8s-master
[k8s-master]
title=K8s Control-plane
description=Ports for the K8s Control-plane nodes
ports=6443,2379:2380,8001,10250:10252/tcp
EOF
sudo ufw app update k8s-master
sudo ufw allow OpenSSH
sudo ufw allow k8s-master

else
# I'M WORKER
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
