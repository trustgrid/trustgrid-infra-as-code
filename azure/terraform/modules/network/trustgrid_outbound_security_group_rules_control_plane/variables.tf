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
    default     = 300
}