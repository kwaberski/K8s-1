output "masters" {
  value = { for vm in esxi_guest.masters: vm.guest_name => vm.ip_address }
}
output "workers" {
  value = { for vm in esxi_guest.workers: vm.guest_name => vm.ip_address }
}
