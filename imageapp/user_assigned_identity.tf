resource "azurerm_user_assigned_identity" "imageapp" {
  location = azurerm_resource_group.imageapp.location
  name = var.user_assigned_identity_name
  resource_group_name = azurerm_resource_group.imageapp.name
}