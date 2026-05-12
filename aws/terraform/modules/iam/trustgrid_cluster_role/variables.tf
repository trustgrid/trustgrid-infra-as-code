variable "name_prefix" {
  type        = string
  description = "Name prefix for the IAM role, policies, and instance profile."
  default     = "trustgrid-cluster"
}

variable "enable_route_failover" {
  type        = bool
  description = "Grant permissions for route table manipulation (route-based cluster failover). Requires route_table_ids."
  default     = false
}

variable "route_table_ids" {
  type        = list(string)
  description = "Route table IDs the role may manage. Required when enable_route_failover is true."
  default     = []
}

variable "enable_cluster_ip_failover" {
  type        = bool
  description = "Grant permissions for secondary private IP assignment/unassignment (cluster IP failover)."
  default     = false
}
