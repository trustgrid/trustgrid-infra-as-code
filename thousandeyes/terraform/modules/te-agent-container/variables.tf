variable "node_id" {
  description = "ID of the single node to deploy the container to. Mutually exclusive with cluster_fqdn."
  type        = string
  default     = null
}

variable "cluster_fqdn" {
  description = "FQDN of the cluster to deploy the container to. Mutually exclusive with node_id."
  type        = string
  default     = null
}

variable "container_name" {
  description = "Name of the ThousandEyes container"
  type        = string
}

variable "image_repository" {
  description = "Docker image repository for ThousandEyes container"
  type        = string
  default     = "hub.docker.com/thousandeyes/enterprise-agent"
}

variable "image_tag" {
  description = "Docker image tag for ThousandEyes container"
  type        = string
  default     = "latest"
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "exec_type" {
  description = "Execution type for the container. Options are 'onDemand' or 'service'."
  type        = string
  default     = "onDemand"
}

variable "cpu_max" {
  description = "CPU Max %"
  type        = number
  default     = 40
}

variable "mem_max" {
  description = "Maximum memory in MB the container can use"
  type        = number
  default     = 1536
}

variable "mem_high" {
  description = "Memory limit in MB the node will try to keep the container under"
  type        = number
  default     = 1024
}

variable "add_caps" {
  description = "Additional Linux capabilities for the container"
  type        = list(string)
  default     = ["NET_ADMIN", "SYS_ADMIN"]
}

variable "encrypt_volumes" {
  description = "Whether to encrypt the container volumes"
  type        = bool
  default     = false
}

variable "te_agent_lib_volume_name" {
  description = "Name for the te-agent lib volume"
  type        = string
  default     = "te-agent-lib"
}

variable "te_agent_logs_volume_name" {
  description = "Name for the te-agent logs volume"
  type        = string
  default     = "te-agent-logs"
}

variable "te_browserbot_lib_volume_name" {
  description = "Name for the te-browserbot lib volume"
  type        = string
  default     = "te-browserbot-lib"
}
