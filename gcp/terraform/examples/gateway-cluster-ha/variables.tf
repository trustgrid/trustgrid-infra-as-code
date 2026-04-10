## ─── Provider ──────────────────────────────────────────────────────────────────

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
  description = "Base name for the gateway cluster. Used to name both nodes, service accounts, and firewall rules (e.g. tg-gw-prod → tg-gw-prod-gw-a, tg-gw-prod-gw-b)."
}

variable "zone_a" {
  type        = string
  description = "GCP zone for gateway node A (e.g. us-central1-a). Choose a different zone from zone_b for cross-zone HA."

  validation {
    condition     = var.zone_a != var.zone_b
    error_message = "zone_a and zone_b must be different zones to achieve cross-zone high availability."
  }
}

variable "zone_b" {
  type        = string
  description = "GCP zone for gateway node B (e.g. us-central1-b). Must differ from zone_a to achieve cross-zone high availability."
}

## ─── Registration ──────────────────────────────────────────────────────────────
##
## Default registration mode is 'manual'. No Trustgrid API credentials are
## needed in this mode — nodes are registered via the Trustgrid portal or serial
## console after first boot.
##
## To switch to automatic registration, set registration_mode = "auto" and
## supply tg_license (and optionally tg_registration_key). See the README for
## step-by-step instructions.

variable "registration_mode" {
  type        = string
  description = "Trustgrid node registration mode for both gateway nodes. 'manual' (default) — deploy infrastructure now; register nodes later via the Trustgrid portal or serial console. No API credentials required. 'auto' — nodes self-register on first boot using tg_license; supply tg_license and optionally tg_registration_key."
  default     = "manual"

  validation {
    condition     = contains(["manual", "auto"], var.registration_mode)
    error_message = "registration_mode must be either 'manual' or 'auto'."
  }
}

variable "tg_license" {
  type        = string
  description = "Trustgrid node license. Required when registration_mode is 'auto'. Obtain from the Trustgrid portal or API. Ignored when registration_mode is 'manual'. Treat as a secret — supply via environment variable (TF_VAR_tg_license) or a secrets manager."
  default     = null
  sensitive   = true
}

variable "tg_registration_key" {
  type        = string
  description = "Trustgrid registration key that associates both nodes with the same gateway cluster. Used only when registration_mode is 'auto'. Optional even in auto mode — the node will still register using the license alone; supply the key when you want to associate the node with a pre-created cluster. Supply via environment variable (TF_VAR_tg_registration_key). Ignored when registration_mode is 'manual'."
  default     = null
  sensitive   = true
}

## ─── Network (existing resources) ─────────────────────────────────────────────

variable "management_vpc_network" {
  type        = string
  description = "Self-link or name of the existing VPC network used for the management (WAN/nic0) interface. Management firewall rules (control-plane egress, gateway ingress) are attached to this network."
}

variable "management_subnetwork" {
  type        = string
  description = "Self-link or name of the existing subnetwork for the management (WAN/nic0) interface on both nodes. Must have internet egress for control-plane connectivity and accept inbound tunnel traffic on port 8443."
}

variable "data_vpc_network" {
  type        = string
  description = "Self-link or name of the existing VPC network used for the data (LAN/nic1) interface. The HA heartbeat firewall rule (TCP 9000) is attached to this network."
}

variable "data_subnetwork" {
  type        = string
  description = "Self-link or name of the existing subnetwork for the data (LAN/nic1) interface on both nodes."
}

variable "node_a_data_subnet_cidr" {
  type        = string
  description = "CIDR block of the data subnet used by gateway node A (e.g. 10.1.0.0/24). Used as a source range in the HA heartbeat firewall rule (TCP 9000) to allow node-A-originated heartbeat traffic to reach node B."
}

variable "node_b_data_subnet_cidr" {
  type        = string
  description = "CIDR block of the data subnet used by gateway node B (e.g. 10.2.0.0/24). Used as a source range in the HA heartbeat firewall rule (TCP 9000) to allow node-B-originated heartbeat traffic to reach node A."
}
