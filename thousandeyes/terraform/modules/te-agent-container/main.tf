terraform {
  required_providers {
    tg = {
      source  = "trustgrid/tg"
      version = ">= 1.33.0"
    }
  }
}

# Local value to determine target type based on provided variables
locals {
  is_single_node = var.node_id != null && var.cluster_fqdn == null
  is_cluster     = var.cluster_fqdn != null && var.node_id == null
  
  # Validation - ensure only one target type is specified
  target_count = (var.node_id != null ? 1 : 0) + (var.cluster_fqdn != null ? 1 : 0)
}

# Validation to ensure exactly one target is specified
resource "null_resource" "target_validation" {
  count = local.target_count == 1 ? 0 : 1
  
  provisioner "local-exec" {
    command = "echo 'Error: Must specify exactly one of node_id or cluster_fqdn' && exit 1"
  }
}

# Container volumes for single node
resource "tg_container_volume" "te_agent_lib_single" {
  count = local.is_single_node ? 1 : 0
  
  name      = var.te_agent_lib_volume_name
  node_id   = var.node_id
  encrypted = var.encrypt_volumes
}

resource "tg_container_volume" "te_agent_logs_single" {
  count = local.is_single_node ? 1 : 0
  
  name      = var.te_agent_logs_volume_name
  node_id   = var.node_id
  encrypted = var.encrypt_volumes
}

resource "tg_container_volume" "te_browserbot_lib_single" {
  count = local.is_single_node ? 1 : 0
  
  name      = var.te_browserbot_lib_volume_name
  node_id   = var.node_id
  encrypted = var.encrypt_volumes
}

# Container volumes for cluster
resource "tg_container_volume" "te_agent_lib_cluster" {
  count = local.is_cluster ? 1 : 0
  
  name         = var.te_agent_lib_volume_name
  cluster_fqdn = var.cluster_fqdn
  encrypted    = var.encrypt_volumes
}

resource "tg_container_volume" "te_agent_logs_cluster" {
  count = local.is_cluster ? 1 : 0
  
  name         = var.te_agent_logs_volume_name
  cluster_fqdn = var.cluster_fqdn
  encrypted    = var.encrypt_volumes
}

resource "tg_container_volume" "te_browserbot_lib_cluster" {
  count = local.is_cluster ? 1 : 0
  
  name         = var.te_browserbot_lib_volume_name
  cluster_fqdn = var.cluster_fqdn
  encrypted    = var.encrypt_volumes
}

# Container for single node deployment
resource "tg_container" "thousand_eyes_single" {
  count = local.is_single_node ? 1 : 0
  
  node_id   = var.node_id
  name      = var.container_name
  exec_type = var.exec_type
  add_caps  = var.add_caps
  
  image {
    repository = var.image_repository
    tag        = var.image_tag
  }
  
  limits {
    cpu_max  = var.cpu_max
    mem_high = var.mem_high
    mem_max  = var.mem_max
  }
  
  variables = var.environment_variables
  
  mount {
    type   = "volume"
    source = tg_container_volume.te_agent_lib_single[0].name
    dest   = "/var/lib/te-agent"
  }
  
  mount {
    type   = "volume"
    source = tg_container_volume.te_agent_logs_single[0].name
    dest   = "/var/log/agent"
  }
  
  mount {
    type   = "volume"
    source = tg_container_volume.te_browserbot_lib_single[0].name
    dest   = "/var/lib/te-browserbot"
  }
}

# Container for cluster deployment
resource "tg_container" "thousand_eyes_cluster" {
  count = local.is_cluster ? 1 : 0
  
  cluster_fqdn = var.cluster_fqdn
  name         = var.container_name
  exec_type    = var.exec_type
  add_caps     = var.add_caps
  
  image {
    repository = var.image_repository
    tag        = var.image_tag
  }
  
  limits {
    cpu_max  = var.cpu_max
    mem_high = var.mem_high
    mem_max  = var.mem_max
  }
  
  variables = var.environment_variables
  
  mount {
    type   = "volume"
    source = tg_container_volume.te_agent_lib_cluster[0].name
    dest   = "/var/lib/te-agent"
  }
  
  mount {
    type   = "volume"
    source = tg_container_volume.te_agent_logs_cluster[0].name
    dest   = "/var/log/agent"
  }
  
  mount {
    type   = "volume"
    source = tg_container_volume.te_browserbot_lib_cluster[0].name
    dest   = "/var/lib/te-browserbot"
  }
}