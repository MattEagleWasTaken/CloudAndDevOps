# –––– Key Vault Setup and access policy for admin and the webapp –––––––––––––––––––––––––––––––––––

data "azurerm_client_config" "current" {} # FIXME: Can later access the ID of the Service Principal.

resource "azurerm_key_vault" "imageapp" {
    name = var.key_vault_name
    resource_group_name = azurerm_resource_group.imageapp.name
    location = azurerm_resource_group.imageapp.location
    tenant_id = data.azurerm_client_config.current.tenant_id
    sku_name = var.key_vault_sku_name
    enable_rbac_authorization = true
}

resource "azurerm_role_assignment" "Admin" {
    principal_id = data.azurerm_client_config.current.object_id
    scope = azurerm_key_vault.imageapp.id
    role_definition_name = local.key_vault_admin_role
  
}

resource "azurerm_role_assignment" "User" {
    principal_id = azurerm_linux_web_app.imageapp.identity[0].principal_id
    scope = azurerm_key_vault.imageapp.id
    role_definition_name = local.key_vault_user_role
  
}

resource "azurerm_key_vault_secret" "storage_connection" {
    name = local.key_vault_secret_name
    value = azurerm_storage_account.imageapp.primary_connection_string
    key_vault_id = azurerm_key_vault.imageapp.id
    depends_on = [azurerm_role_assignment.Admin]
  }