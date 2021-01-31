instance-id: vmtest
local-hostname: vmtest
network:
  version: 2
  ethernets:
    nics:
      match:
        name: ens*
      dhcp4: yes
