# –––– App Service (Web App) Setup –––––––––––––––––––––––––––––––––––



resource "azurerm_linux_web_app" "imageapp" { 
  name                = var.app_service_name
  resource_group_name = azurerm_resource_group.imageapp.name
  location            = azurerm_resource_group.imageapp.location
  service_plan_id     = azurerm_service_plan.imageapp.id

  identity {
    type = "UserAssigned"
    identity_ids = [ azurerm_user_assigned_identity.imageapp.id ]
  }

  site_config {
    application_stack {
      python_version = local.python_version  
    }
  }

    app_settings = { # Will get passed into the python environment as global variables.
      "STORAGE_ACCOUNT_NAME"           = azurerm_storage_account.imageapp.name
      "STORAGE_CONTAINER_NAME"         = azurerm_storage_container.imageapp.name
      "STORAGE_CONNECTION_STRING"      = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage_connection.id})" # For referencing the Key vault without hardcoding the connection string
      "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    }


}

