## ─── Provider ──────────────────────────────────────────────────────────────────

variable "project" {
  type        = string
  description = "GCP project ID in which to deploy all resources."
}

variable "region" {
  type        = string
  description = "GCP region for provider configuration and static IP address allocation (e.g. us-central1)."
}

## ─── Node identity ─────────────────────────────────────────────────────────────

variable "name" {
  type        = string
  description = "Base name for the Trustgrid node and derived resources (service account, firewall rules). Must be unique within the project."
}

variable "zone" {
  type        = string
  description = "GCP zone in which to create the Compute Engine instance (e.g. us-central1-a). Must be in the same region as the static external IP."
}

## ─── Network (existing resources) ─────────────────────────────────────────────

variable "management_vpc_network" {
  type        = string
  description = "Self-link or name of the existing VPC network used for the management (WAN/nic0) interface. Firewall rules are attached to this network."
}

variable "management_subnetwork" {
  type        = string
  description = "Self-link or name of the existing subnetwork for the management (WAN/nic0) interface. Must have internet egress for control-plane connectivity."
}

variable "data_subnetwork" {
  type        = string
  description = "Self-link or name of the existing subnetwork for the data (LAN/nic1) interface."
}
