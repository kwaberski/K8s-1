# Download the Microsoft repository GPG keys
wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb

# Register the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb

# Update the list of products
sudo apt-get update

# Install PowerShell
sudo apt-get install -y powershell

# Start PowerShell
pwsh

# install VM module for PowerShell (once inm powershell)
if(-not (Get-Module -Name VMware.PowerCLI -ListAvailable)){
    Install-Module -Name VMware.PowerCLI -AllowClobber -Force -Confirm:$false
}

# now enable module, disable cert verification and Connect
PS /home/krzys/Github/K8s/vSphere> Get-Module -ListAvailable PowerCLI* | Import-Module
PS /home/krzys/Github/K8s/vSphere> Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false
PS /home/krzys/Github/K8s/vSphere> Connect-VIServer -Server 192.168.254.10

Specify Credential
Please specify server credential
User: root
Password for user root: ********

Name                           Port  User
----                           ----  ----
192.168.254.10                 443   root

PS /home/krzys/Github/K8s/vSphere> Get-Datacenter

Name
----
ha-datacenter
