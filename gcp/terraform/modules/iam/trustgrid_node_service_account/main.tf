terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

## Service account for a Trustgrid node or cluster.
##
## This module creates a dedicated GCP service account that can be attached to
## Trustgrid compute instances via the `service_account_email` variable on the
## `trustgrid_single_node` compute module. Creating the service account as a
## separate resource keeps identity management decoupled from compute lifecycle.
##
## After creation, use the `trustgrid_cluster_route_role` IAM helper module to
## grant this account the route-management permissions required for HA failover.

resource "google_service_account" "node_sa" {
  account_id   = var.account_id
  display_name = var.display_name
  description  = var.description
  project      = var.project
}
