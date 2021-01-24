#!/bin/sh
ETCD_VER=v3.4.13
wget -q --show-progress --https-only --timestamping "https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz"
tar -xzf etcd-${ETCD_VER}-linux-amd64.tar.gz
sudo mv etcd-${ETCD_VER}-linux-amd64/etcd* /usr/local/bin/
rm -rf etcd-${ETCD_VER}-linux-amd64
sudo mkdir -p /etc/etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd
sudo cp etcd-ca.key etcd-ca.crt etcd-peer.key etcd-peer.crt etcd-server.key etcd-server.crt kube-apiserver-etcd-client.key kube-apiserver-etcd-client.crt /etc/etcd/
sudo chmod 400 /etc/etcd/*.key
INTERNAL_IP=$(ifconfig ens160 | egrep "inet " | awk '{print $2}')
ETCD_NAME=$(hostname -s)

cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/etcd-server.crt \\
  --key-file=/etc/etcd/etcd-server.key \\
  --peer-cert-file=/etc/etcd/etcd-peer.crt \\
  --peer-key-file=/etc/etcd/etcd-peer.key \\
  --trusted-ca-file=/etc/etcd/etcd-ca.crt \\
  --peer-trusted-ca-file=/etc/etcd/etcd-ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster master1=https://192.168.2.32:2380,master2=https://192.168.2.33:2380,master3=https://192.168.2.34:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd

# verify members
#sudo ETCDCTL_API=3 etcdctl member list \
#  --endpoints=https://127.0.0.1:2379 \
#  --cacert=/etc/etcd/ca.crt \
#  --cert=/etc/etcd/kube-apiserver.crt \
#  --key=/etc/etcd/kube-apiserver.key
