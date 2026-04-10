## ─── GCP provider ──────────────────────────────────────────────────────────────

variable "project" {
  type        = string
  description = "GCP project ID in which to deploy all resources. The cluster route role IAM binding is also created at project scope in this project."
}

variable "region" {
  type        = string
  description = "GCP region for provider configuration and static IP address allocation (e.g. us-central1). Both nodes should be in zones within this region."
}

## ─── Cluster identity ──────────────────────────────────────────────────────────

variable "cluster_name" {
  type        = string
  description = "Base name for the gateway cluster. Used to name both nodes (tg_license + compute), service accounts, firewall rules, and the Trustgrid cluster object (e.g. tg-gw-prod → tg-gw-prod-gw-a, tg-gw-prod-gw-b, tg-gw-prod cluster)."
}

variable "zone_a" {
  type        = string
  description = "GCP zone for gateway node A (e.g. us-central1-a). Must be a different zone from zone_b for cross-zone high availability."

  validation {
    condition     = var.zone_a != var.zone_b
    error_message = "zone_a and zone_b must be different zones to achieve cross-zone high availability."
  }
}

variable "zone_b" {
  type        = string
  description = "GCP zone for gateway node B (e.g. us-central1-b). Must differ from zone_a to achieve cross-zone high availability."
}

## ─── Trustgrid provider credentials ───────────────────────────────────────────
##
## The trustgrid/tg provider authenticates with a Trustgrid API Key (ID +
## secret). Supply credentials via environment variables — never commit them:
##   export TG_API_KEY_ID="<your-key-id>"
##   export TG_API_KEY_SECRET="<your-key-secret>"
##
## tg_api_host is optional; leave at default unless targeting a non-production
## Trustgrid control plane.

variable "tg_api_host" {
  type        = string
  description = "Trustgrid Portal API endpoint. Leave at the default unless targeting a non-production Trustgrid control plane. The provider also reads the TG_API_HOST environment variable."
  default     = "https://api.trustgrid.io"
}

variable "tg_org_id" {
  type        = string
  description = "Trustgrid Organization ID. The provider will validate that the supplied API credentials belong to this org and fail early if they do not. Obtain from the Trustgrid portal under Organization Settings."
}

## ─── Trustgrid registration ────────────────────────────────────────────────────

variable "tg_registration_key" {
  type        = string
  description = "Optional Trustgrid registration key. When provided it is passed to both gateway nodes as instance metadata and associates them with a pre-created group or cluster at first-boot registration time. Supply via environment variable (TF_VAR_tg_registration_key) — never commit to source control."
  default     = null
  sensitive   = true
}

variable "tg_node_timeout" {
  type        = number
  description = "Seconds to wait for each Trustgrid node to come online before timing out. The data.tg_node readiness gate polls the Trustgrid control plane for this long before failing. Increase for slow-boot environments (default 300 = 5 minutes)."
  default     = 300

  validation {
    condition     = var.tg_node_timeout >= 60
    error_message = "tg_node_timeout must be at least 60 seconds to allow reasonable boot time."
  }
}

## ─── Network (existing resources) ─────────────────────────────────────────────

variable "management_vpc_network" {
  type        = string
  description = "Self-link or name of the existing VPC network used for the management (WAN/nic0) interface. Management and gateway firewall rules are attached to this network."
}

variable "data_vpc_network" {
  type        = string
  description = "Self-link or name of the existing VPC network used for the data (LAN/nic1) interface. The HA heartbeat firewall rule (TCP var.heartbeat_port) is attached to this network."
}

variable "management_subnetwork_a" {
  type        = string
  description = "Self-link or name of the existing subnetwork for node A's management (WAN/nic0) interface. Must have internet egress for control-plane connectivity and accept inbound tunnel traffic on port 8443."
}

variable "management_subnetwork_b" {
  type        = string
  description = "Self-link or name of the existing subnetwork for node B's management (WAN/nic0) interface. Must have internet egress for control-plane connectivity and accept inbound tunnel traffic on port 8443."
}

variable "data_subnetwork_a" {
  type        = string
  description = "Self-link or name of the existing subnetwork for node A's data (LAN/nic1) interface."
}

variable "data_subnetwork_b" {
  type        = string
  description = "Self-link or name of the existing subnetwork for node B's data (LAN/nic1) interface."
}

variable "node_a_data_subnet_cidr" {
  type        = string
  description = "CIDR block of the data subnet used by gateway node A (e.g. 10.1.0.0/24). Used as a source range in the HA heartbeat firewall rule and as the destination in node B's LAN route for cross-subnet heartbeat routing."
}

variable "node_b_data_subnet_cidr" {
  type        = string
  description = "CIDR block of the data subnet used by gateway node B (e.g. 10.2.0.0/24). Used as a source range in the HA heartbeat firewall rule and as the destination in node A's LAN route for cross-subnet heartbeat routing."
}

variable "cluster_route_cidr" {
  type        = string
  description = "CIDR block advertised by the active cluster member as a GCP cloud route. When a failover occurs the active node updates the GCP project route for this CIDR to point to itself. Typically the downstream network reachable via the gateway cluster (e.g. 10.0.0.0/8)."
}

## ─── Heartbeat ─────────────────────────────────────────────────────────────────

variable "heartbeat_port" {
  type        = number
  description = "TCP port used by Trustgrid HA gossip (heartbeat) traffic between cluster nodes. Must match the port configured in tg_node_cluster_config and the GCP heartbeat firewall rule. Default is 9000."
  default     = 9000

  validation {
    condition     = var.heartbeat_port >= 1 && var.heartbeat_port <= 65535
    error_message = "heartbeat_port must be a valid TCP port number between 1 and 65535."
  }
}
