variable "instance_profile_name" {
  type        = string
  description = "IAM Instance Profile the Trustgrid EC2 node will use"
}

variable "license" {
  type        = string
  description = "The Trustgrid license given from the API or Portal"
}


variable "management_subnet_id" {
  type        = string
  description = "Subnet ID for management traffic (needs to be able to reach the internet)"
}

variable "management_security_group_ids" {
  type        = list
  description = "Security group IDs for the management interface"
}

variable "data_subnet_id" {
  type        = string
  description = "Subnet ID for data traffic"
}

variable "data_security_group_ids" {
  type        = list
  description = "Security group IDs for the data interface"
}


variable "name" {
  type        = string
  description = "Instance name"
}

variable "instance_type" {
  type        = string
  description = "Node instance type"
  default     = "t3.small"

  validation {
    condition     = contains(["t3.small", "t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge","t3a.small", "t3a.medium", "t3a.large", "t3a.xlarge", "t3a.2xlarge", "c5n.large", "c5n.xlarge", "c5n.2xlarge", "c5n.4xlarge", "c5n.9xlarge"], var.instance_type)
    error_message = "Instance type must be t3 or t3a (small or bigger) or c5n (large or bigger) family instance."
  }
}

variable key_pair_name {
  type        = string
  description = "AWS Key Pair for ubuntu user in EC2 instance"
}

variable root_block_device_encrypt {
  type = bool
  description = "Should the root device be encrypted in AWS"
  default = true
}

variable root_block_device_size {
  type = number
  description = "Size of the root volume in GB"
  default = 30 
}

variable is_tggateway {
  type = bool
  description = "Determines if security group should allow tcp/udp port 8443 inbound for Trustgrid Tunnels"
  default = false
}

variable is_wggateway {
  type = bool
  description = "Determines if security group should allow port 51820 inbound for Wireguard"
  default = false
}

variable is_appgateway {
  type = bool
  description = "Determines if security group should allow port 443 inbound for Application Gateway"
  default = false
}

variable enroll_endpoint {
  type = string
  description = "Determines which Trustgrid Tenant the node is registered to"
  default = "https://keymaster.trustgrid.io/v2/enroll"
}

variable "tg_fqdn" {
  type = string
  description = "FQDN of the Trustgrid Node associated with the license"
  
}

variable "tg_node_timeout" {
  type = number
  default = 600
  description = "Number of seconds to wait to confirm the node is online via the Trustgrid API before failing"
  
}