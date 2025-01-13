## General Variables
variable "resource_group_name" {
    type    = string
    description = "Resource Group Name for deploying the VM"  
}

variable "location" { 
    type    = string
    description = "Location for creating resources"
  
}

## VM Variables
variable "name" {
  type        = string
  description = "Instance name"
}

variable "vm_size" {
  type        = string
  description = "Node instance type"
  default     = "Standard_B2s"
}

variable os_disk_size {
  type = number
  description = "Size of the OS disk volume in GB"
  default = 30 
}

variable "admin_ssh_username" {
  type = string
  description = "admin username"
  default = "ubuntu"
  
}

variable "admin_ssh_key_pub" {
  type = string
  description = "SSH Public key for admin user"
  sensitive = true
}

## Network Variables
variable "public_subnet_id" {
  type        = string
  description = "Subnet ID for public traffic (needs to be able to reach the internet)"
}

variable "public_security_group_id" {
  type        = string
  description = "Security group ID for the public interface"
}

variable "private_subnet_id" {
  type        = string
  description = "Subnet ID for private traffic"
}

variable "private_security_group_id" {
  type        = string
  description = "Security group ID for the private interface"
}

## Trustgrid Variables
variable "tg_image_gallery" {
  type        = string
  description = "Trustgrid Image Gallery (DO NOT CHANGE)"
  default = "trustgrid-45680719-9aa7-43b9-a376-dc03bcfdb0ac"
  
}

variable "tg_tenant" {
  type        = string
  description = "Trustgrid Tenant ID (DO NOT CHANGE)"
  default = "prod"
}

variable "tg_version" {
  type        = string
  description = "Trustgrid Node Appliance Version (DO NOT CHANGE)"
  default = "latest"  
}