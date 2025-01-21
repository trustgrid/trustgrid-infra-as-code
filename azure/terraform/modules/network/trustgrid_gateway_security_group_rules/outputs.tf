output "application_security_group_id" {
  value       = azurerm_application_security_group.trustgrid_gateway.id
  description = "The ID of the Trustgrid Gateway Application Security Group"
}

output "data_plane_tcp_rule_id" {
  value       = try(azurerm_network_security_rule.data_plane_tcp[0].id, "")
  description = "The ID of the TCP data plane security rule, if created"
}

output "data_plane_udp_rule_id" {
  value       = try(azurerm_network_security_rule.data_plane_udp[0].id, "")
  description = "The ID of the UDP data plane security rule, if created"
}

output "ztna_rule_id" {
  value       = try(azurerm_network_security_rule.ztna[0].id, "")
  description = "The ID of the ZTNA security rule, if created"
}

output "wireguard_rule_id" {
  value       = try(azurerm_network_security_rule.wireguard[0].id, "")
  description = "The ID of the Wireguard security rule, if created"
}
