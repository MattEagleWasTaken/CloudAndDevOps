# ––––– Providers –––––––––––––––––––––––––––––––––––––––––––

terraform {
  required_providers {
    azurerm = {
        source  = "hashicorp/azurerm"
        version = "~> 3.0"
    }
  }
}


provider "azurerm" {
  features {}
}

# –––– Resource group Setup –––––––––––––––––––––––––––––––––––

resource "azurerm_resource_group" "bootstrap" {
  name     = var.bootstrap_resource_group_name
  location = var.bootstrap_location
}


# –––– Storage Account Setup –––––––––––––––––––––––––––––––––––

resource "azurerm_storage_account" "bootstrap" {
  name                     = var.bootstrap_storage_account_name
  resource_group_name      = azurerm_resource_group.bootstrap.name
  location                 = azurerm_resource_group.bootstrap.location
  account_tier             = var.bootstrap_storage_acc_tier
  account_replication_type = var.bootstrap_storage_acc_replication_type
}



# –––– Storage Container Setup –––––––––––––––––––––––––––––––––––

resource "azurerm_storage_container" "bootstrap" {
    name                  = var.bootstrap_container_name
    storage_account_name  = azurerm_storage_account.bootstrap.name
    container_access_type = var.bootstrap_container_access_type
}


# –––– Output Management to populate backend.tf via the powershell script –––––––––––––––––––––––––––––––––––



output "bootstrap_storage_account_name" { 
    description = "The bootstrap storage account name to populate the backend"
    value       = azurerm_storage_account.bootstrap.name
}

output "bootstrap_container_name" {
  description = "The bootstrap storage container name to populate the backend"
  value = azurerm_storage_container.bootstrap.name
}

output "bootstrap_resource_group_name" {
  description = "The bootstrap resource group name to populate the backend"
  value = azurerm_resource_group.bootstrap.name
}


