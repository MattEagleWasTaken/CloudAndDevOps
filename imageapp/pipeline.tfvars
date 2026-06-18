# –––– Terraform Variable - Values ––––––––––––––––––––––––––––––––
#
# Naming Convention: 
# {ressourcetype}-{project/app}-{number}-{region}-{ID}
#
#


location                    = "germanywestcentral"

resource_group_name         = "rg-imageapp-01-wger-mfis"

app_service_name            = "app-imageapp-01-wger-mfis"

app_service_plan_name       = "asp-imageapp-01-wger-mfis"

storage_account_name        = "stimageapp01wgermfis"

key_vault_name              = "kv-imageapp-01-wger-mfis"

container_name              = "images"

service_plan_sku_name       = "B1"

key_vault_sku_name          = "standard"

sto_acc_replication_type    = "LRS"

user_assigned_identity_name = "id-imageapp-01-wger-mfis"

kv_readers_group_object_id  = "<wird später eingetragen>"


