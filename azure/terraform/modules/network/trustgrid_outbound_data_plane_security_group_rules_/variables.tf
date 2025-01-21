variable "name_prefix" {
    type        = string
    description = "Prefix for the resources created by this module"
  
}
variable "security_group_id" {
    type        = string
    description = "Security group ID for the Trustgrid Control Plane rules to be added to"  
}

variable "security_group_rule_priority_start" {
    type        = number
    description = "Start of the priority range for the Trustgrid Gateway rules"
    default     = 350
}

variable "data_plane_endpoints" {
  type = list(object({
    ip   = string
    port = number
  }))
  description = "List of destination IP and port combinations to allow outbound access. The IP field accepts both single IPs and CIDR ranges. Example: [{ip = \"10.0.0.0/24\", port = 8443}, {ip = \"192.168.1.1\", port = 8443}]. The port field accepts a single port number. Remove slashes before double quotes in example."
}

variable "enable_udp" {
  type        = bool
  description = "Enable UDP rules in addition to TCP rules"
  default     = true
}
