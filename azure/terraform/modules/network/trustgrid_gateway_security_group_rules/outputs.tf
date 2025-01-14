output "application_security_group_id" {
  value       = azurerm_application_security_group.trustgrid_gateway.id
  description = "The ID of the Trustgrid Gateway Application Security Group"
}
