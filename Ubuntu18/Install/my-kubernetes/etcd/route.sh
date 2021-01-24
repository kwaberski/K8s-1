#!/bin/bash
sudo sed -i 's/192.168.2.20/192.168.2.1/g' /etc/netplan/50-cloud-init.yaml
cat <<EOF > add_routes
           routes:
           - to:  192.168.0.0/24
             via: 192.168.2.20
EOF
sudo sed -i '/addresses: \[8.8.8.8,8.8.4.4\]/r add_routes' /etc/netplan/50-cloud-init.yaml
sudo netplan apply
sudo route del default gw 192.168.2.20
