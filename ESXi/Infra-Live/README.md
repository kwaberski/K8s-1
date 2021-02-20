# Kubernetes on Free ESXI
## Branch : ci-machine-id

### DHCP Related comment
DHCP servers assign IP addresses based on DHCP unique ID (DUID)
NETPLAN has two renderers: networkd or networkmanager. systemd-networkd uses the contents of /etc/machine-id
to create the OUID. As a result when you clone off an OVA image the clones will get the IP from DHCP
because they present the same OUID. You can either change the machine-id of the cloned instance or change the
netplan config. Beacuse the ESCi does not want to process metadata I change the netplan configuration in my OVA image
`enp3s0:
  dhcp4: yes
  dhcp-identifier: mac`

### Installation
1. Configure cluster details in variables.tf

2. Run
`terraform init
terraform validate
TF_VAR_esxi_hname=<value> TF_VAR_esxi_uname=<value> TF_VAR_esxi_pwd=<value> terraform plan -out k8s_infra.tfplan
terraform apply "k8s_infra.tfplan"``

3. Once VMs are deployed, copy the follwing files to all nodes
`for m in c1m1 c1m2 c1m3 c1w1 c1w2 c1w3; do scp os-prep.sh kube*.yaml ${m}:. ; done`

4. Now and run the provisioning script
`sh ./os-prep.sh`
