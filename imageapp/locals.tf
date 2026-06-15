locals {
    # app service / service plan
    os_type = "Linux"
    python_version = "3.12"
    identity_type = "SystemAssigned"
    # key vault 
    key_vault_admin_role = "Key Vault Administrator"
    key_vault_user_role = "Key Vault Secrets User"
    key_vault_secret_name = "storage-connection-string"
    # storage account / storage container
    sto_acc_acc_tier = "Standard"
    sto_cont_acc_type = "private"
    cors_allowed_headers = [ "*" ]
    cors_allowed_methods = [ "GET", "POST", "PUT" ]
    cors_exposed_headers = [ "*" ]
    cors_max_age = 3600
}