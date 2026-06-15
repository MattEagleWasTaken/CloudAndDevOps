# –––– Resource group Setup –––––––––––––––––––––––––––––––––––

resource "azurerm_resource_group" "imageapp" {
  name     = var.resource_group_name
  location = var.location
}