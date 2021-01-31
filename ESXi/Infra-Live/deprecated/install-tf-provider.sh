#!/usr/bin/env bash

# IF YOU USE TERRAFORM .13 YOU DONT NEED TO INSTALL IT
# THE PROVIDER WILL BE PULLED AUTOMATICALLY
### Steps to install ESXi terraform provider
# https://github.com/josenk/terraform-provider-esxi
sudo apt-get install golang
mkdir $HOME/go
export GOPATH="$HOME/go"
git clone https://github.com/josenk/terraform-provider-esxi.git $GOPATH/src/github.com/terraform-providers/terraform-provider-esxi
go get -u -v golang.org/x/crypto/ssh
go get -u -v github.com/hashicorp/terraform
go get -u -v github.com/josenk/terraform-provider-esxi

cd $GOPATH/src/github.com/josenk/terraform-provider-esxi
GO111MODULE=on CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -ldflags '-w -extldflags "-static"' -o terraform-provider-esxi_`cat version`
sudo cp terraform-provider-esxi_`cat version` /usr/local/bin


# install terraform
# download terraform_0.12.30_linux_amd64.zip from https://www.terraform.io/downloads.html
unzip ~/terraform_0.12.30_linux_amd64.zip
sudo cp terraform /usr/local/bin

# download OVFTOOL from VMWare and install
sudo /bin/sh ./VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle
