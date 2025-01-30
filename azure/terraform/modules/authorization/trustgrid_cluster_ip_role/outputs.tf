output "id" {
  value = azurerm_role_definition.tg_cluster_ip_role.role_definition_id
  description = "The Azure ID for the Trustgrid Cluster IP role"
}

output "name" {
  value = azurerm_role_definition.tg_cluster_ip_role.name
  description = "The name of the Trustgrid Cluster IP role"
  
}