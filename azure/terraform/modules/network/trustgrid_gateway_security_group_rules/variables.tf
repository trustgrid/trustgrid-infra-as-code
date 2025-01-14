variable "name_prefix" {
    type        = string
    description = "Prefix for the resources created by this module"
  
}
variable "security_group_id" {
    type        = string
    description = "Security group ID for the Trustgrid Gateway rules"  
}

variable "security_group_rule_priority_start" {
    type        = number
    description = "Start of the priority range for the Trustgrid Gateway rules"
    default     = 200
}

variable "trustgrid_data_plane_gateway_tcp" {
    type = bool
    default = true
    description = "Enable TCP for the Trustgrid Data Plane Gateway"
}

variable "trustgrid_data_plane_gateway_tcp_port" {
    type = string
    default = "8443"
    description = "TCP Port for the Trustgrid Data Plane Gateway"
}

variable "trustgrid_data_plane_gateway_udp" {
    type = bool
    default = true
    description = "Enable UDP for the Trustgrid Data Plane Gateway"
}

variable "trustgrid_data_plane_gateway_udp_port" {
    type = string
    default = "8443"
    description = "TCP Port UDP for the Trustgrid Data Plane Gateway"
}

variable "trustgrid_ztna_gateway" {
    type = bool
    default = false
    description = "Enable ZTNA for the Trustgrid Gateway"
}

variable "trustgrid_ztna_gateway_port" {
    type = string
    default = "443"
    description = "TCP Port for the Trustgrid ZTNA Gateway (not recommended to change)"
}

variable "trustgrid_wireguard_gateway" {
    type = bool
    default = false
    description = "Enable Wireguard for the Trustgrid Gateway"
}

variable "trustgrid_wireguard_gateway_port" {
    type = string
    default = "51820"
    description = "UDP Port for the Trustgrid Wireguard Gateway"
}
