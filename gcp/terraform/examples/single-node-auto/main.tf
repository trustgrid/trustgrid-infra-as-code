## ─── Provider ──────────────────────────────────────────────────────────────────
##
## This example deploys a single Trustgrid edge node in automatic registration
## mode. On first boot the node writes the supplied license to disk and calls
## the Trustgrid registration script automatically — no portal interaction is
## required to register the node.
##
## Sensitive inputs (license, registration_key) are declared as sensitive
## variables and should be supplied via a secrets manager, CI/CD environment
## variables, or an encrypted tfvars file. Never commit license values to source
## control.
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

## ─── Service account ───────────────────────────────────────────────────────────
##
## A dedicated service account is created for the node. For a single edge node
## that does not participate in HA failover no additional IAM permissions are
## needed beyond the service account itself. If you add this node to a cluster
## that performs route failover, see the gateway-cluster-ha example for how to
## attach the cluster route role.

module "node_sa" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_node_service_account?ref=v0.11.0"

  account_id   = "${var.name}-sa"
  display_name = "Trustgrid Node SA — ${var.name}"
  project      = var.project
}

## ─── Management firewall (egress) ─────────────────────────────────────────────
##
## Edge nodes require egress to the Trustgrid control plane (TCP 443 + 8443),
## DNS, and the GCP metadata server. Rules are scoped to the `trustgrid-mgmt`
## network tag applied to the instance below.

module "mgmt_firewall" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_mgmt_firewall?ref=v0.11.0"

  name_prefix = var.name
  network     = var.management_vpc_network
  target_tags = ["trustgrid-mgmt"]
}

## ─── Compute node (automatic registration) ─────────────────────────────────────
##
## In auto mode the bootstrap script:
##   1. Reads the license from instance metadata (tg-license key).
##   2. Writes the license and optional registration_key to
##      /usr/local/trustgrid/ with locked-down permissions.
##   3. Calls bin/register.sh with automatic retry until the node registers.
##
## registration_key is optional. Supply it when the node should join a specific
## cluster or be placed into a pre-configured group in the Trustgrid portal.
##
## public_exposure_mode = "direct_static_ip" (default) creates a module-managed
## regional static external IP. This IP is preserved across redeployments.

module "node" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.11.0"

  ## Identity
  name = var.name
  zone = var.zone

  ## Registration — auto mode: supply license (required) and optional key
  registration_mode = "auto"
  license           = var.tg_license
  registration_key  = var.tg_registration_key

  ## Network — consume existing subnets
  management_subnetwork = var.management_subnetwork
  data_subnetwork       = var.data_subnetwork

  ## Apply the management tag so the firewall rule above targets this node
  network_tags = ["trustgrid-mgmt"]

  ## Public exposure — default: creates and attaches a static external IP
  public_exposure_mode = "direct_static_ip"

  ## IAM — use the service account created by the helper module above
  service_account_email = module.node_sa.email
}
