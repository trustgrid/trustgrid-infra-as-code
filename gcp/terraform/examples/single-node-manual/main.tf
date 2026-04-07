## ─── Provider ──────────────────────────────────────────────────────────────────
##
## This example deploys a single Trustgrid edge node in manual registration
## mode. After `terraform apply`, navigate to the Trustgrid portal and register
## the node using the management external IP shown in the outputs.
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

## ─── Service account ───────────────────────────────────────────────────────────
##
## Every Trustgrid node needs a dedicated GCP service account so that the GCP
## platform can identify the instance. For a single edge node that does NOT
## participate in HA failover, you do not need to attach the cluster route role.
## The service account is created by the helper module below and its email is
## passed directly to the compute module.

module "node_sa" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_node_service_account?ref=v0.11.0"

  account_id   = "${var.name}-sa"
  display_name = "Trustgrid Node SA — ${var.name}"
  project      = var.project
}

## ─── Management firewall (egress) ─────────────────────────────────────────────
##
## Edge nodes need outbound access to the Trustgrid control plane on TCP 443
## and 8443, plus DNS and the GCP metadata server. The management firewall
## helper creates least-privilege egress rules scoped to the `trustgrid-mgmt`
## network tag that is applied to the node instance below.

module "mgmt_firewall" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_mgmt_firewall?ref=v0.11.0"

  name_prefix = var.name
  network     = var.management_vpc_network
  target_tags = ["trustgrid-mgmt"]
}

## ─── Compute node (manual registration) ────────────────────────────────────────
##
## In manual mode the node boots normally and waits to be registered from the
## Trustgrid portal. No license or registration_key is required at deploy time.
##
## public_exposure_mode = "direct_static_ip" (default) creates a module-managed
## regional static external IP. This IP is preserved across redeployments because
## it is owned independently of the instance resource.

module "node" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.11.0"

  ## Identity
  name = var.name
  zone = var.zone

  ## Registration — manual mode; no license needed at deploy time
  registration_mode = "manual"

  ## Network — consume existing subnets
  management_subnetwork = var.management_subnetwork
  data_subnetwork       = var.data_subnetwork

  ## Apply the management tag so the firewall rule above targets this node
  network_tags = ["trustgrid-mgmt"]

  ## Public exposure — default: creates and attaches a static external IP
  ## that survives instance replacement
  public_exposure_mode = "direct_static_ip"

  ## IAM — use the service account created by the helper module above
  service_account_email = module.node_sa.email
}
