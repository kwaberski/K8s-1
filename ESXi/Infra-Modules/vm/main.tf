##################################################################################
# RESOURCES
##################################################################################

# this creates a VM in ESXi host
resource "esxi_guest" "masters" {
  count = var.cluster_info["masters"]
  guest_name         = "${var.cluster_info["name"]}-m${count.index +1}"
  disk_store         = "internal_hdd"
  ovf_source = "U18MiniT.ova"
  power = "on" # if power off then no IP in the output
  memsize  = "2048"
  numvcpus = "1"
  virthwver = "13" # ESXi 6.5 and later https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.vsphere.vm_admin.doc/GUID-789C3913-1053-4850-A0F0-E29C3D32B6DA.html
  guest_startup_timeout = "60"
  network_interfaces {
    virtual_network = "CORP"
    nic_type = "vmxnet3" # this is the interface type use by ESXi 6.5
  }

### TODO; there is a diferent function that allows to template file with variables that I shoudl use on the below
### userdata to properly set hostnames
  guestinfo = {
  "metadata.encoding" = "gzip+base64"
  "metadata"          = base64gzip(file("g-metadata.cfg"))
  "userdata.encoding" = "gzip+base64"
  "userdata"          = base64gzip( templatefile("g-userdata.cfg", { h_name = "${var.cluster_info["name"]}-m${count.index +1}" } ) )
  }
}
