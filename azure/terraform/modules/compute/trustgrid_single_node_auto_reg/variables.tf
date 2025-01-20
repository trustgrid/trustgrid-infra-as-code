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
  description = "Size of the OS disk volume in GB. 30GB is the recommended minimum."
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

variable "availability_zone" {
  type = string
  description = "Availability Zone for the VM"
  default = "1"  
  validation {
    condition     = contains(["1", "2", "3"], var.availability_zone)
    error_message = "Availability zone must be one of: 1, 2, or 3"
  }
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

## Trustgrid Variables
variable "tg_license" {
  type = string
  description = "Trustgrid Appliance license. Can be generated from the portal/api or the tg_license resource in the Trustgrid Terraform provider" 
}

variable "tg_fqdn" {
  type = string
  description = "FQDN of the Trustgrid Node associated with the license. Can be derived from the tg_license resource with the .fqdn attribute"
  
}

variable enroll_endpoint {
  type = string
  description = "Determines which Trustgrid tenant where the node will be registered (DO NOT CHANGE)"
  default = "https://keymaster.trustgrid.io/v2/enroll"
}
