## Command to build
terraform init
terraform validate

## SECRETS
# now since provider creds need to be delivered as variables
# i have a few choices
terraform plan -out k8s_infra.tfplan -var "esxi_hname=<value>" -var "esxi_uname=<value>" -var "esxi_pwd=<value>"
# or
terraform plan -out k8s_infra.tfplan
# and enter the values
# or use OS env variables with the TF_VAR_ prefix
TF_VAR_esxi_hname=<value> TF_VAR_esxi_uname=<value> TF_VAR_esxi_pwd=<value> terraform plan -out k8s_infra.tfplan

# either way the tfplan file will include variable values no matter how I provide them
# that is why i must not upload the plan to git or encrypt it before uploading
