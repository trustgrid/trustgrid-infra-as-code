output "az_node1_name" {
    value = module.az_node1.vm_name
    description = "az_node1 vm name"  
}

output "az_node1_public_ip" {
    value = module.az_node1.public_nic_public_ip_address
    description = "az_node1 public ip"  
}

output "az_node1_mac_address" {
    value = module.az_node1.public_nic_mac_address
    description = "az_node1 mac address"
}

output "az_node2_name" {
    value = module.az_node2.vm_name
    description = "az_node2 vm name"  
}

output "az_node2_public_ip" {
    value = module.az_node2.public_nic_public_ip_address
    description = "az_node2 public ip"  
}

output "az_node2_mac_address" {
    value = module.az_node2.public_nic_mac_address
    description = "az_node2 mac address"
}
