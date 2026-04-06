## Fixture: trustgrid_node_service_account — all optional fields populated (positive)
## Acceptance criterion: supplying display_name and description must not cause any
## validation error.
##
## Expected: terraform validate exits 0.

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = "test-project"
  region  = "us-central1"
}

module "tg_sa" {
  source = "../../../modules/iam/trustgrid_node_service_account"

  account_id   = "tg-cluster-ha"
  display_name = "Trustgrid HA Cluster Service Account"
  description  = "Shared service account for Trustgrid HA pair in us-central1."
  project      = "my-gcp-project"

  ## Expected: validate succeeds — 14-char account_id satisfies [a-z][a-z0-9-]{5,29}.
}
