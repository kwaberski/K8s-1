# Install etcdctl
# On the master
root@masteru:~# RELEASE=$(kubectl exec -it etcd-masteru -n kube-system -- /bin/sh -c 'ETCDCTL_API=3 /usr/local/bin/etcd --version' | head -1 | awk '{print $NF}' | tr -d '\r')
root@masteru:~# echo $RELEASE
3.4.9
root@masteru:~# wget https://github.com/etcd-io/etcd/releases/download/v${RELEASE}/etcd-v${RELEASE}-linux-amd64.tar.gz
root@masteru:~# tar xzf etcd-v3.4.9-linux-amd64.tar.gz
root@masteru:~# cd etcd-v3.4.9-linux-amd64
root@masteru:~/etcd-v3.4.9-linux-amd64# cp etcdctl /usr/local/bin/

### Take a snapshot
# set ENDPOINT var to the endpoint where etcd is running
ENDPOINT=https://127.0.0.1:2379
# provide cert info such as point at the CA bundle of your cluster’s CA, your client’s cert and it is corresponding key
ETCDCTL_API=3 etcdctl --endpoints=$ENDPOINT \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key \
snapshot save /var/tmp/etcdsnapshot
