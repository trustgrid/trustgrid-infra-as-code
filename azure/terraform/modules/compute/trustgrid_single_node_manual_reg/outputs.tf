
output "vm_id" {
  description = "ID of the created virtual machine"
  value       = azurerm_linux_virtual_machine.node.id
}

output "vm_name" {
  description = "Name of the created virtual machine"
  value       = azurerm_linux_virtual_machine.node.name
}

output "public_ip_address" {
  description = "Public IP address assigned to the VM"
  value       = azurerm_public_ip.public_ip.ip_address
}

output "private_ip_address" {
  description = "Private IP address of the primary interface"
  value       = azurerm_network_interface.private.private_ip_address
}

output "public_nic_id" {
  description = "ID of the public network interface"
  value       = azurerm_network_interface.public.id
}

output "private_nic_id" {
  description = "ID of the private network interface"
  value       = azurerm_network_interface.private.id
}

output "principal_id" {
  description = "Principal ID of the system assigned identity"
  value       = azurerm_linux_virtual_machine.node.identity[0].principal_id
}
