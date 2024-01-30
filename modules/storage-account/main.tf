# used for the storage account name
resource "random_string" "storage_account_suffix" {
  length  = 6
  upper   = false
  special = false
}


resource "azurerm_storage_account" "st" {
  name                     = "st${var.name_key}${var.name_suffix}${random_string.storage_account_suffix.result}"
  resource_group_name      = var.rg_name
  location                 = var.location
  account_kind             = var.account_kind
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  is_hns_enabled           = var.is_hns_enabled

  tags = var.tags
}


resource "azurerm_storage_container" "container" {
  storage_account_name  = azurerm_storage_account.st.name
  name                  = var.container_name
  container_access_type = var.container_access_type
}


resource "azurerm_databricks_access_connector" "external" {
  name                = "ac-${var.name_key}${var.name_suffix}"
  resource_group_name = var.rg_name
  location            = var.location
  identity {
    type = "SystemAssigned"
  }
}

# see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment
#
#resource "azurerm_role_assignment" "contributor" {
#  scope                = azurerm_storage_account.st.id
#  role_definition_name = "Storage Blob Data Contributor"
#  principal_id         = azurerm_databricks_access_connector.external.identity[0].principal_id
#}

