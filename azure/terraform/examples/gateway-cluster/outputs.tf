output "az_gw1_name" {
    value = module.az_gw1.vm_name
    description = "az_gw1 vm name"  
}

output "az_gw1_public_ip" {
    value = module.az_gw1.public_nic_public_ip_address
    description = "az_gw1 public ip"  
}

output "az_gw1_mac_address" {
    value = module.az_gw1.public_nic_mac_address
    description = "az_gw1 mac address"
}

output "az_gw2_name" {
    value = module.az_gw2.vm_name
    description = "az_gw2 vm name"  
}

output "az_gw2_public_ip" {
    value = module.az_gw2.public_nic_public_ip_address
    description = "az_gw2 public ip"  
}

output "az_gw2_mac_address" {
    value = module.az_gw2.public_nic_mac_address
    description = "az_gw2 mac address"
}
