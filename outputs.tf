output "databricks_workspace_host" {
  value = {
    for k, dbw in azurerm_databricks_workspace.dbw : k => dbw.workspace_url
  }
}
output "databricks_workspace_id" {
  value = {
    for k, dbw in azurerm_databricks_workspace.dbw : k => dbw.workspace_id
  }
}