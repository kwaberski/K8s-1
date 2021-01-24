terraform {
  required_version = ">= 0.12"
}

provider "esxi" {
  esxi_hostname      = var.esxi_hname
  esxi_hostport      = "22"
  esxi_hostssl       = "443"
  esxi_username      = var.esxi_uname
  esxi_password      = var.esxi_pwd
}

resource "esxi_guest" "vmtest" {
  guest_name         = "vmtest"
  disk_store         = "internal_hdd"
  power              = "off"
  ovf_source         = "https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.ova"
  network_interfaces {
    virtual_network = "CORP"
  }
}
