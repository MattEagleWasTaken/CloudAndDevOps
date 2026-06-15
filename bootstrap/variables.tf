# –––– Bootstrap Variable Management –––––––––––––––––––––––––––––––––––

variable "bootstrap_location" {
    description = "Azure Region"
    type = string
}

variable "bootstrap_resource_group_name" {
    description = "Name of the Resource Group"
    type = string
}


variable "bootstrap_storage_account_name" {
    description = "Name of the storage account (only lowercase, no special chars, max 24 chars)"
    type = string

    validation {
    condition = can(regex("^[a-z0-9]{3,24}$", var.bootstrap_storage_account_name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
    }
}

variable "bootstrap_storage_acc_tier" {
    description = "The Storage Account Tier for the remote State Sto Acc."
    type = string
} 

variable "bootstrap_storage_acc_replication_type" {
    description = "The Storage Account Replication Type for the remote State"
    type = string
}




variable "bootstrap_container_name" {
    description = "Name of the BLOB Container for remote state"
    type = string
  }

  variable "bootstrap_container_access_type" {
    description = "Azure Storage Container access type for the remote state"
    type = string
  }