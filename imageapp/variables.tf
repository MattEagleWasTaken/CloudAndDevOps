# –––– Variable Management –––––––––––––––––––––––––––––––––––

variable "location" {
    description = "Azure Region"
    type = string
}

variable "resource_group_name" {
    description = "Name of the Resource Group"
    type = string
}

variable "app_service_name" {
    description = "Name of the App Service"
    type = string
}

variable "storage_account_name" {
    description = "Name of the storage account (only lowercase, no special chars, max 24 chars)"
    type = string

    validation {
    condition = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
    }
}

variable "key_vault_name" {
    description = "Name of the key Vault"
    type = string 
}

variable "container_name" {
    description = "Name of the BLOB Container for the images"
    type = string
  }

variable "app_service_plan_name" {
    description = "Name of the App Service plan for the Web-App"
    type = string
}

variable "service_plan_sku_name" {
  description = "The sku name for the app service plan"
  type = string
}

variable "key_vault_sku_name" {
  description = "The sku name for the key vault"
  type = string
}


variable "sto_acc_replication_type" {
  description = "The Azure replication type for the storage account"
  type = string
}