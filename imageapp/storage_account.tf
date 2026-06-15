# –––– Storage Account and BLOB Setup –––––––––––––––––––––––––––––––––––

resource "azurerm_storage_account" "imageapp" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.imageapp.name
  location                 = azurerm_resource_group.imageapp.location
  account_tier             = local.sto_acc_acc_tier
  account_replication_type = var.sto_acc_replication_type

# –––– Container Setup (where the images will be saved) –––––––––––––––––––––––––––––––––––

  blob_properties { #TODO: 
    cors_rule { # Rules for account sharing (Web App can access the storage via the browser)
      allowed_headers    =  local.cors_allowed_headers # FIXME: Every Header allowed in inquiry (maybe changed later)
      allowed_methods    =  local.cors_allowed_methods # The web app can view what's in the container (Page 1 / Get) and upload new content (Page 2 / Post/Put)
      allowed_origins    = ["https://${var.app_service_name}.azurewebsites.net"] # only the web app can access the BLOB Container
      exposed_headers    =  local.cors_exposed_headers# FIXME: which headers is the browser allowed to read in the response (maybe changed later)
      max_age_in_seconds =  local.cors_max_age# max 1h caching 
    }
  }
}

resource "azurerm_storage_container" "imageapp" {
    name                  = var.container_name
    storage_account_name  = azurerm_storage_account.imageapp.name
    container_access_type = local.sto_cont_acc_type # Access only via the app
  }

