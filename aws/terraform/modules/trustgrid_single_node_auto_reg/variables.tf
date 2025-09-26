variable "instance_profile_name" {
  type        = string
  description = "IAM Instance Profile the Trustgrid EC2 node will use for managing AWS resources such as route table entries for clustered nodes."
  default     = null
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
  description = "Security group IDs for the management interface. Recommended to include any desired default security groups."
}

variable "data_subnet_id" {
  type        = string
  description = "Subnet ID for data traffic"
}

variable "data_security_group_ids" {
  type        = list
  description = "Security group IDs for the data interface. Recommended to include any desired default security groups."
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
    condition = (
      can(regex("^(t3|t3a|c5|c5n|c5a|c6i|c6in|c6a)\\..+$", var.instance_type))
    )
    error_message = "Instance type must be a valid t3, t3a, c5, c5n, c5a, c6i, c6in, or c6a family instance type (e.g., t3.small, c6i.4xlarge)."
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

variable "tggateway_port" {
  type        = number
  description = "Port for Trustgrid Gateway (TCP/UDP tunnel)"
  default     = 8443
}

variable "appgateway_port" {
  type        = number
  description = "Port for Application Gateway (TCP)"
  default     = 443
}

variable "wggateway_port" {
  type        = number
  description = "Port for Wireguard Gateway (UDP)"
  default     = 51820
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

variable "trustgrid_ami_id" {
  type        = string
  description = "Optional: Explicit Trustgrid AMI ID to use for the EC2 node. If not set, the latest matching AMI will be used."
  default     = null
}
