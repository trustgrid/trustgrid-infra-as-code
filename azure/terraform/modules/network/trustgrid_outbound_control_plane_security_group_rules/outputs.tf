
output "rule_ids" {
  description = "The IDs of the created security rules"
  value = [
    azurerm_network_security_rule.trustgrid_control_plane_1.id,
    azurerm_network_security_rule.trustgrid_control_plane_2.id
  ]
}
