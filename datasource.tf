data "azurerm_resource_group" "resourcegroup" {
  name = var.resourcegroup
}

data "azurerm_key_vault_secret" "aksspid" {
  count        = var.use_managed_identity ? 0 : 1
  name         = "aks-sp-clientid"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "aksspsecret" {
  count        = var.use_managed_identity ? 0 : 1
  name         = "aks-sp-secret"
  key_vault_id = var.key_vault_id
}

data "azurerm_client_config" "current" {}
