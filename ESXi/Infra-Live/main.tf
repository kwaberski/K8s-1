##################################################################################
# PROVIDERS
##################################################################################
terraform {
  required_version = ">= 0.13"
  required_providers {
    esxi = {
      source = "registry.terraform.io/josenk/esxi"
      #
      # For more information, see the provider source documentation:
      #
      # https://github.com/josenk/terraform-provider-esxi
      # https://registry.terraform.io/providers/josenk/esxi
      #
    }
  }

}

provider "esxi" {
  esxi_hostname      = var.esxi_hname
  esxi_hostport      = "22"
  esxi_hostssl       = "443"
  esxi_username      = var.esxi_uname
  esxi_password      = var.esxi_pwd
}

##################################################################################
# RESOURCES
##################################################################################
resource "esxi_guest" "masters" {
  count = var.cluster_info["masters"]
  guest_name         = "${var.cluster_info["name"]}m${count.index +1}"
  disk_store         = "internal_hdd"
  ovf_source = "U18MiniT-no-ci-net.ova"
  resource_pool_name = "/"
  power = "on" # if power off then no IP in the output
  memsize  = "2048"
  numvcpus = "2"
  virthwver = "13" # ESXi 6.5 and later https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.vsphere.vm_admin.doc/GUID-789C3913-1053-4850-A0F0-E29C3D32B6DA.html
  guest_startup_timeout = "45"
  guest_shutdown_timeout = "30"
  network_interfaces {
    virtual_network = "CORP"
    nic_type        = "vmxnet3" # this is the interface type use by ESXi 6.5
#    mac_address     = "00:50:56:a1:a1:0${count.index}"
  }

### TODO; there is a diferent function that allows to template file with variables that I shoudl use on the below
### userdata to properly set hostnames
  guestinfo = {
  "metadata.encoding" = "gzip+base64"
  "metadata"          = base64gzip( templatefile("g-metadata.cfg", { h_name = "${var.cluster_info["name"]}m${count.index +1}" } ) )
  "userdata.encoding" = "gzip+base64"
  "userdata"          = base64gzip( templatefile("g-userdata.cfg", { h_name = "${var.cluster_info["name"]}m${count.index +1}" } ) )
  }
}

resource "esxi_guest" "workers" {
  count = var.cluster_info["workers"]
  guest_name         = "${var.cluster_info["name"]}w${count.index +1}"
  disk_store         = "internal_hdd"
  ovf_source = "U18MiniT-no-ci-net.ova"
  resource_pool_name = "/"
  power = "on" # if power off then no IP in the output
  memsize  = "4096"
  numvcpus = "2"
  virthwver = "13" # ESXi 6.5 and later https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.vsphere.vm_admin.doc/GUID-789C3913-1053-4850-A0F0-E29C3D32B6DA.html
  guest_startup_timeout = "45"
  guest_shutdown_timeout = "30"
  network_interfaces {
    virtual_network = "CORP"
    nic_type        = "vmxnet3" # this is the interface type use by ESXi 6.5
#    mac_address     = "00:50:56:a1:a1:1${count.index}"
  }

### TODO; there is a diferent function that allows to template file with variables that I shoudl use on the below
### userdata to properly set hostnames
  guestinfo = {
  "metadata.encoding" = "gzip+base64"
  "metadata"          = base64gzip( templatefile("g-metadata.cfg", { h_name = "${var.cluster_info["name"]}w${count.index +1}" } ) )
  "userdata.encoding" = "gzip+base64"
  "userdata"          = base64gzip( templatefile("g-userdata.cfg", { h_name = "${var.cluster_info["name"]}w${count.index +1}" } ) )
  }
}
