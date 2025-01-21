output "tcp_rule_ids" {
  description = "The IDs of the created TCP security rules"
  value = [for rule in azurerm_network_security_rule.tcp_rules : rule.id]
}

output "udp_rule_ids" {
  description = "The IDs of the created UDP security rules"
  value = try([for rule in azurerm_network_security_rule.udp_rules : rule.id], [])
}
