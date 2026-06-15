# Force admin login at the start
Write-Host "Please log in as admin..."
az login

# Check if you're logged in as admin
$account = az account show | ConvertFrom-Json
Write-Host "Running as: $($account.user.name) (Type: $($account.user.type))"
Write-Host "Subscription: $($account.name)"

# Get ARM Variable
. ./set-env.ps1    

$roleDefinition = @{
  Name = "Key Vault RBAC Configurator"
  Description = "Allows creating role assignments on Key Vault resources only"
  Actions = @(
    "Microsoft.Authorization/roleAssignments/write"
    "Microsoft.Authorization/roleAssignments/delete"
    "Microsoft.Authorization/roleAssignments/read"
  )
  AssignableScopes = @("/subscriptions/$env:ARM_SUBSCRIPTION_ID")
} | ConvertTo-Json

az role definition create --role-definition $roleDefinition


# 2. Assign custom role to Service Principal
az role assignment create `
  --assignee $env:ARM_CLIENT_ID `
  --role "Key Vault RBAC Configurator" `
  --scope "/subscriptions/$env:ARM_SUBSCRIPTION_ID"


  # 3. Assign Contributor role to Service Principal
az role assignment create `
  --assignee $env:ARM_CLIENT_ID `
  --role "Contributor" `
  --scope "/subscriptions/$env:ARM_SUBSCRIPTION_ID"

  # Logout admin and hand over to Service Principal
Write-Host "Setup complete - logging out admin..."
az logout

Write-Host "Starting init.ps1 as Service Principal..."
. ./init.ps1