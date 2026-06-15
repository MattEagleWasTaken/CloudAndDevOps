# Service Principal / env setup
. ./set-env.ps1    

# initialize bootstrap storage account

# run bootstrap
Set-Location bootstrap
terraform init
terraform apply -var-file="bootstrap.tfvars" -auto-approve

# get output values
$resource_group_name  = terraform output -raw bootstrap_resource_group_name
$storage_account_name = terraform output -raw bootstrap_storage_account_name
$container_name       = terraform output -raw bootstrap_container_name
$key_name             = "imageapp.tfstate"

# init in the main terraform folder.
Set-Location ../imageapp
terraform init `
  -backend-config="resource_group_name=$resource_group_name" `
  -backend-config="storage_account_name=$storage_account_name" `
  -backend-config="container_name=$container_name" `
  -backend-config="key=$key_name"