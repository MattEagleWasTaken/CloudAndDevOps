# –––– App Service Plan Setup –––––––––––––––––––––––––––––––––––


resource "azurerm_service_plan" "imageapp" {
    name                = var.app_service_plan_name
    resource_group_name = azurerm_resource_group.imageapp.name
    location            = azurerm_resource_group.imageapp.location
    os_type             = local.os_type 
    sku_name            = var.service_plan_sku_name # TODO: later: B1! (F1 has no always on - I'll just use it while developing)
}
