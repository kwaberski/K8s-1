#!/usr/bin/env bash

### Commands to Install kubectl - 2 OPTIONS

## OPTION 1
# download kubectl, its checksum and verify
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(<kubectl.sha256) kubectl" | sha256sum --check
# install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

## OPTION 2
# or using the native package mgmt
sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2 curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

## Enable kubectl autocompletion
echo 'source <(kubectl completion bash)' >>~/.bashrc
kubectl completion bash | sudo tee -a /etc/bash_completion.d/kubectl
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc
source ~/.bashrc

### SETUP VIM
echo “autocmd FileType yaml setlocal nu ic expandtab sw=2 ts=2 sts=2” >> ~/.vimrc
