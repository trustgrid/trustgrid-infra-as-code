## ─── Provider ──────────────────────────────────────────────────────────────────
##
## This example deploys a dual-node Trustgrid GATEWAY cluster in high-availability
## (HA) mode on GCP.
##
## Gateway nodes accept inbound tunnel connections from Trustgrid edge nodes.
## Each gateway node has a static external IP so that edge nodes can reach a
## stable endpoint. When one gateway fails, the cluster promotes the other and
## updates GCP routes to redirect traffic — this is the route-failover HA model.
##
## This example demonstrates:
##   - Two gateway nodes, each with its own service account and static external IP
##   - The trustgrid_cluster_route_role IAM helper granting both service accounts
##     the least-privilege compute.routes.{list,get,create,delete} permissions
##     required for route failover
##   - Management + gateway firewall helpers applied to both nodes
##   - Automatic registration (auto mode) for both nodes
##
## Network resources (VPC, subnets) are consumed from existing infrastructure.
## This example does NOT create subnets or VPCs.

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
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
  source = "../../modules/iam/trustgrid_node_service_account"

  account_id   = "${var.cluster_name}-gw-a-sa"
  display_name = "Trustgrid Gateway SA — ${var.cluster_name}-gw-a"
  project      = var.project
}

module "node_b_sa" {
  source = "../../modules/iam/trustgrid_node_service_account"

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
  source = "../../modules/iam/trustgrid_cluster_route_role"

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
##
## A single firewall module call covers both gateway nodes because the rules
## target the shared network tag.

module "mgmt_firewall" {
  source = "../../modules/network/trustgrid_mgmt_firewall"

  name_prefix = var.cluster_name
  network     = var.management_vpc_network
  target_tags = ["trustgrid-gateway"]
}

module "gateway_firewall" {
  source = "../../modules/network/trustgrid_gateway_firewall"

  name_prefix = var.cluster_name
  network     = var.management_vpc_network
  target_tags = ["trustgrid-gateway"]

  ## Gateway port — 8443 is the Trustgrid default; change only if the cluster
  ## is explicitly configured to listen on a different port
  gateway_port = 8443
}

## ─── Gateway node A ────────────────────────────────────────────────────────────
##
## Node A is in zone_a and uses auto registration. In direct_static_ip mode the
## module creates a separate static external IP for this node. Both nodes have
## stable, independent public IPs so edge nodes can reach either gateway.

module "gateway_node_a" {
  source = "../../modules/compute/trustgrid_single_node"

  ## Identity
  name = "${var.cluster_name}-gw-a"
  zone = var.zone_a

  ## Registration — auto mode; supply license and the cluster registration key
  registration_mode = "auto"
  license           = var.tg_license
  registration_key  = var.tg_registration_key

  ## Network — consume existing subnets
  management_subnetwork = var.management_subnetwork
  data_subnetwork       = var.data_subnetwork

  ## Apply the gateway tag so both firewall modules above target this node
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
  source = "../../modules/compute/trustgrid_single_node"

  ## Identity
  name = "${var.cluster_name}-gw-b"
  zone = var.zone_b

  ## Registration — auto mode; same license, same registration key
  registration_mode = "auto"
  license           = var.tg_license
  registration_key  = var.tg_registration_key

  ## Network — consume existing subnets
  management_subnetwork = var.management_subnetwork
  data_subnetwork       = var.data_subnetwork

  ## Apply the gateway tag so both firewall modules above target this node
  network_tags = ["trustgrid-gateway"]

  ## Public exposure — default: module-managed static external IP per node
  public_exposure_mode = "direct_static_ip"

  ## IAM — use the node-specific service account
  service_account_email = module.node_b_sa.email
}
