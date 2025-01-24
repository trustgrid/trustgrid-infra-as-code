## Azure Variables
variable "subscription_id" {
    description = "The subscription ID where the resources will be created"
    type        = string
  
}

## Environment Variables
variable "environment_prefix" {
    description = "The prefix used for all resources in this environment"
    type        = string
}

variable "location" {
    description = "The location/region where the resources will be created"
    type        = string
}

## TrustGrid Variables
variable "tg_api_host" {
    description = "The TrustGrid API host. Defaults to api.trustgrid.io and should not need to be changed."
    type        = string
    default = "api.trustgrid.io"
}


## Network Variables
variable "vnet_cidr" {
    description = "The CIDR block for the virtual network"
    type        = string
}

variable "public_cidr" {
    description = "The CIDR block for the public subnet"
    type        = string
}

variable "private_cidr" {
    description = "The CIDR block for the private subnet"
    type        = string
}


## Virtual Machine Variables
variable "admin_ssh_key_pub" {
    description = "Public Key for SSH access to the virtual machines. External SSH is disabled during registration, but a key is required by Azure to create the VM and may be needed if there are issues registering."
    type        = string
}

## Azure Gateway 1 Variables
variable "az_gw1_name" {
    description = "Name for the first gateway VM, environment prefix will be prepended"
    type        = string
}

variable "az_gw1_zone" {
    description = "Availability zone for the first gateway VM"
    type        = number
}

## Azure Gateway 2 Variables
variable "az_gw2_name" {
    description = "Name for the second gateway VM, environment prefix will be prepended"
    type        = string
}

variable "az_gw2_zone" {
    description = "Availability zone for the second gateway VM"
    type        = number
}

## Azure Gateway Host Variables
variable "az_gw_host_name" {
    description = "Name for the gateway host VM, environment prefix will be prepended"
    type        = string
}

variable "az_gw_host_zone" {
    description = "Availability zone for the gateway host VM"
    type        = number
}
