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

variable "tg_license" {
  type        = string
  description = "Trustgrid node license. Required for automatic registration on both gateway nodes. Obtain from the Trustgrid portal or API. Treat as a secret — supply via environment variable (TF_VAR_tg_license) or a secrets manager."
  sensitive   = true
}

variable "tg_registration_key" {
  type        = string
  description = "Trustgrid registration key that associates both nodes with the same gateway cluster. Supply via environment variable (TF_VAR_tg_registration_key). Required for HA cluster formation."
  sensitive   = true
}

## ─── Network (existing resources) ─────────────────────────────────────────────

variable "management_vpc_network" {
  type        = string
  description = "Self-link or name of the existing VPC network used for the management (WAN/nic0) interface. Firewall rules are attached to this network."
}

variable "management_subnetwork" {
  type        = string
  description = "Self-link or name of the existing subnetwork for the management (WAN/nic0) interface on both nodes. Must have internet egress for control-plane connectivity and accept inbound tunnel traffic on port 8443."
}

variable "data_subnetwork" {
  type        = string
  description = "Self-link or name of the existing subnetwork for the data (LAN/nic1) interface on both nodes."
}
