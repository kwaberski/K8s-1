## Command to build
terraform init
terraform validate

## SECRETS
# now since provider creds need to be delivered as variables
# i have a few choices
# 1. supplying terraform variables' value on command line when running plan
# 2. using TF_VAR_<var_name> OS env vars and setting them tu rin with plan
# 3. enter them manually when terraform plan asks for it
# 4. use a password manager like 1Password, Lastpass or opens source pass
terraform plan -out k8s_infra.tfplan -var "esxi_hname=<value>" -var "esxi_uname=<value>" -var "esxi_pwd=<value>"
# or terraform plan -out k8s_infra.tfplan

# and enter the values
# or use OS env variables with the TF_VAR_ prefix
TF_VAR_esxi_hname=<value> TF_VAR_esxi_uname=<value> TF_VAR_esxi_pwd=<value> terraform plan -out k8s_infra.tfplan

for m in c1m1 c1m2 c1m3 c1w1 c1w2 c1w3; do scp os-prep.sh kube*.yaml ${m}:. ; done
# on each node
sh ./os-prep.sh

## IMPORTANT: if HISTCONTROL env var is set to 'ignorespace' or 'ignoreboth'
## if you enter a secret on command line make sure you place a space first
## that way it wont be save in bash history

## IMPORTANT2: either way the tfplan file will include variable values no matter how I provide them
## that is why i must not upload the plan to git or encrypt it before uploading

## PAY ATTENTIONS
## - provider related secrets show in PLAN and not in STATE
## = how about secrets defined in resources ??
## - encrypt plan/state files (for me only I could use PGP for that and possible the SOPS tool)

# now that the VMs are provisoned you need to copy and run the os-prep.sh script on masters and then on workers


# install kubectl on your laptop
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubectl=1.20.0-00

echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc
