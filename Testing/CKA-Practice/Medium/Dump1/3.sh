### copying the DNS record for webservice
## from A POD
k exec -it web -- sh
/ # nslookup webservice
#nslookup: can't resolve '(null)': Name does not resolve
#Name:      webservice
#Address 1: 10.101.254.251 webservice.dump1.svc.cluster.local

## FROM A NODE
# ks is an alias for k -n kube-system
ks get services
#NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
#kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   4d7h

# so I can query the DNS
root@node1u:/home/krzys# nslookup webservice.dump1.svc.cluster.local 10.96.0.10
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   webservice.dump1.svc.cluster.local
Address: 10.101.254.251

### From a new POD started after the service was brought up
# we can run a quick pod
k -n dump1 run test -it --image=busybox

/ # printenv | grep _SERVICE_HOST
WEBSERVICE_SERVICE_HOST=10.101.254.251
KUBERNETES_SERVICE_HOST=10.96.0.1
