# you need to source this file first
# source govcvars.sh
export GOVC_INSECURE=1 # Don't verify SSL certs on vCenter
export GOVC_URL=192.168.254.10 # vCenter IP/FQDN
export GOVC_USERNAME=root # vCenter username
export GOVC_PASSWORD=VMty6ry5 # vCenter password
export GOVC_DATASTORE=internal_hdd # Default datastore to deploy to
export GOVC_NETWORK="CORP" # Default network to deploy to

# GOVC uses vSphere API which is not supported in the Free License for vSphere Hypervisor (ESXi)
