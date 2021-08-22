##################################################################################
# DATA SOURCES
##################################################################################

##################################################################################
# VARIABLES
##################################################################################
variable "esxi_hname" {
  type = string
}
variable "esxi_uname" {
  type = string
}
variable "esxi_pwd" {
  type = string
}
variable "cidr" {
  type = string
  default = "192.168.2.0/24"
}
variable "gw" {
  type = string
  default = "192.168.2.1"
}
variable "n_mask" {
  type = number
  default = 24
}
variable "cluster_info" {
  type = map
  default = {
    name = "c2"
    masters = 2
    workers = 2
  }
}

##################################################################################
# LOCALS
##################################################################################

locals {
  m_cidr = cidrsubnet(var.cidr, 6, 6)
}

locals {
  w_cidr = cidrsubnet(var.cidr, 6, 7)
}
