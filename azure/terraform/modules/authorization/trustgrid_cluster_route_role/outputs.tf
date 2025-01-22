output "id" {
  value = azurerm_role_definition.tg_cluster_route_role.role_definition_id
  description = "The Azure ID for the Trustgrid Cluster route role"
}

output "name" {
  value = azurerm_role_definition.tg_cluster_route_role.name
  description = "The name of the Trustgrid Cluster route role"
  
}