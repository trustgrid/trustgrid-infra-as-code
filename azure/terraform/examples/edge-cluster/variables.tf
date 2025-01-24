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

## Azure Edge node 1 Variables
variable "az_node1_name" {
    description = "Name for the first Edge node VM, environment prefix will be prepended"
    type        = string
}

variable "az_node1_zone" {
    description = "Availability zone for the first Edge node VM"
    type        = number
}

## Azure Edge node 2 Variables
variable "az_node2_name" {
    description = "Name for the second Edge node VM, environment prefix will be prepended"
    type        = string
}

variable "az_node2_zone" {
    description = "Availability zone for the second Edge node VM"
    type        = number
}

## Data Plane Variables 
variable "data_plane_endpoints" {
  type = list(object({
    ip          = string
    port        = number
    suffix      = string
    description = string
  }))
  description = "List of destination IP and port combinations to allow outbound access. The IP field accepts both single IPs and CIDR ranges. Example: [{ip = \"10.0.0.0/24\", port = 8443, suffix = \"internal\", description = \"Internal network access\"}, {ip = \"192.168.1.1\", port = 8443, suffix = \"external\", description = \"External endpoint access\"}]. The port field accepts a single port number."
}

variable "data_plane_enable_udp" {
  type        = bool
  description = "Enable UDP rules in addition to TCP rules"
  default     = true
}