## ─── Provider ──────────────────────────────────────────────────────────────────
##
## gateway-cluster-ha — INFRA-ONLY / MANUAL REGISTRATION DEFAULT
##
## This example deploys dual-node Trustgrid gateway cluster infrastructure on
## GCP using only the hashicorp/google provider. No Trustgrid API credentials
## are required to run this example. It is designed for platform teams that
## provision GCP infrastructure first and perform Trustgrid node registration
## separately (via the Trustgrid portal or serial console).
##
## Default registration mode is MANUAL. To switch to automatic registration,
## set registration_mode = "auto" and supply tg_license (and optionally
## tg_registration_key). See the README for step-by-step instructions.
##
## This example demonstrates:
##   - Two gateway nodes, each with its own service account and static external IP
##     in separate GCP zones for cross-zone high availability
##   - The trustgrid_cluster_route_role IAM helper granting both service accounts
##     the least-privilege compute.routes.{list,get,create,delete} permissions
##     required for route failover
##   - Management + gateway firewall helpers applied to both nodes
##   - Heartbeat firewall rule (TCP 9000) between data subnet CIDRs for HA
##   - Conditional auto registration wiring (no-op when registration_mode = "manual")
##
## Network resources (VPC, subnets) are consumed from existing infrastructure.
## This example does NOT create subnets or VPCs.

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

## ─── Service accounts ──────────────────────────────────────────────────────────
##
## Each gateway node gets a dedicated service account. Both accounts are
## collected into a list that is passed to the cluster route role module so a
## single binding grants both nodes the route-manager role.

module "node_a_sa" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_node_service_account?ref=v0.10.0"

  account_id   = "${var.cluster_name}-gw-a-sa"
  display_name = "Trustgrid Gateway SA — ${var.cluster_name}-gw-a"
  project      = var.project
}

module "node_b_sa" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_node_service_account?ref=v0.10.0"

  account_id   = "${var.cluster_name}-gw-b-sa"
  display_name = "Trustgrid Gateway SA — ${var.cluster_name}-gw-b"
  project      = var.project
}

## ─── HA route role ─────────────────────────────────────────────────────────────
##
## The cluster route role grants compute.routes.{list,get,create,delete} to both
## gateway service accounts at project scope. GCP routes are project-global, so
## the IAM binding must be project-level.
##
## This module creates:
##   - A custom IAM role "trustgridRouteManager" (configurable via role_id)
##   - A project-level google_project_iam_binding binding both SAs to that role
##
## IMPORTANT: google_project_iam_binding is AUTHORITATIVE for this role. Any
## existing members not listed here will be removed. See the module README for
## guidance on switching to non-authoritative (additive) bindings.

module "cluster_route_role" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_cluster_route_role?ref=v0.10.0"

  project = var.project

  ## Bind both gateway service accounts to the route-manager role
  service_account_emails = [
    module.node_a_sa.email,
    module.node_b_sa.email,
  ]
}

## ─── Firewall rules ────────────────────────────────────────────────────────────
##
## Gateway nodes need two sets of firewall rules, both scoped to the
## `trustgrid-gateway` network tag applied to each instance below:
##
##   1. trustgrid_mgmt_firewall  — egress to control plane, DNS, metadata server
##   2. trustgrid_gateway_firewall — ingress on TCP/UDP 8443 from edge nodes
##   3. heartbeat rule — TCP 9000 between data subnet CIDRs for HA cluster
##      heartbeat traffic
##
## A single firewall module call covers both gateway nodes because the rules
## target the shared network tag.

module "mgmt_firewall" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_mgmt_firewall?ref=v0.10.0"

  name_prefix = var.cluster_name
  network     = var.management_vpc_network
  target_tags = ["trustgrid-gateway"]
}

module "gateway_firewall" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_gateway_firewall?ref=v0.10.0"

  name_prefix = var.cluster_name
  network     = var.management_vpc_network
  target_tags = ["trustgrid-gateway"]

  ## Gateway port — 8443 is the Trustgrid default; change only if the cluster
  ## is explicitly configured to listen on a different port
  gateway_port = 8443
}

## ─── Heartbeat firewall ─────────────────────────────────────────────────────────
##
## HA cluster nodes exchange heartbeat traffic on TCP 9000 over the data network.
## This rule allows traffic between the two data subnet CIDRs so that both nodes
## can maintain mutual health-monitoring sessions.
##
## Source/destination: node_a_data_subnet_cidr ↔ node_b_data_subnet_cidr
## Protocol/port:      TCP 9000

resource "google_compute_firewall" "heartbeat" {
  name    = "${var.cluster_name}-heartbeat"
  network = var.data_vpc_network

  description = "Allow Trustgrid HA cluster heartbeat traffic (TCP 9000) between gateway node data interfaces."

  direction = "INGRESS"

  source_ranges = [
    var.node_a_data_subnet_cidr,
    var.node_b_data_subnet_cidr,
  ]

  target_tags = ["trustgrid-gateway"]

  allow {
    protocol = "tcp"
    ports    = ["9000"]
  }
}

## ─── Gateway node A ────────────────────────────────────────────────────────────
##
## Node A is in zone_a. In direct_static_ip mode the module creates a separate
## static external IP for this node. Both nodes have stable, independent public
## IPs so edge nodes can reach either gateway.
##
## Registration is controlled by var.registration_mode (default: "manual").
## In manual mode license and registration_key are not passed to the module.
## In auto mode both are injected into instance metadata.

module "gateway_node_a" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.10.0"

  ## Identity
  name = "${var.cluster_name}-gw-a"
  zone = var.zone_a

  ## Registration — mode-driven; defaults to manual (no credentials required)
  registration_mode = var.registration_mode
  license           = var.registration_mode == "auto" ? var.tg_license : null
  registration_key  = var.registration_mode == "auto" ? var.tg_registration_key : null

  ## Network — consume existing subnets
  management_subnetwork = var.management_subnetwork
  data_subnetwork       = var.data_subnetwork

  ## Apply the gateway tag so all firewall rules above target this node
  network_tags = ["trustgrid-gateway"]

  ## Public exposure — default: module-managed static external IP per node
  public_exposure_mode = "direct_static_ip"

  ## IAM — use the node-specific service account
  service_account_email = module.node_a_sa.email
}

## ─── Gateway node B ────────────────────────────────────────────────────────────
##
## Node B is in zone_b for cross-zone HA. It has its own static external IP.
## Edge nodes can be configured to connect to either gateway IP.

module "gateway_node_b" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.10.0"

  ## Identity
  name = "${var.cluster_name}-gw-b"
  zone = var.zone_b

  ## Registration — mode-driven; defaults to manual (no credentials required)
  registration_mode = var.registration_mode
  license           = var.registration_mode == "auto" ? var.tg_license : null
  registration_key  = var.registration_mode == "auto" ? var.tg_registration_key : null

  ## Network — consume existing subnets
  management_subnetwork = var.management_subnetwork
  data_subnetwork       = var.data_subnetwork

  ## Apply the gateway tag so all firewall rules above target this node
  network_tags = ["trustgrid-gateway"]

  ## Public exposure — default: module-managed static external IP per node
  public_exposure_mode = "direct_static_ip"

  ## IAM — use the node-specific service account
  service_account_email = module.node_b_sa.email
}
