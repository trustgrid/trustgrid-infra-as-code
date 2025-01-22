output "role_definition_id" {
  value = azurerm_role_definition.tg_cluster_ip_role.role_definition_id
  description = "The Azure ID for the Trustgrid Cluster IP role"
}