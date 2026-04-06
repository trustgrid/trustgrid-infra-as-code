## Fixture: trustgrid_single_node — SA-agnostic boundary check (positive)
## Acceptance criterion: the compute module accepts a pre-created service account
## email and must NOT create google_service_account resources itself.
##
## This fixture verifies that:
##   1. The module validates successfully when a well-formed SA email is supplied.
##   2. No google_service_account resource is declared in the compute module —
##      identity management is the responsibility of the IAM helper modules.
##
## Boundary check (grep assertion, run separately):
##   grep -r "resource.*google_service_account" \
##     gcp/terraform/modules/compute/trustgrid_single_node/ \
##     && exit 1 || exit 0
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

module "trustgrid_node" {
  source = "../../../modules/compute/trustgrid_single_node"

  name                  = "tg-node-sa-boundary"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"

  ## SA email is passed in — created externally via trustgrid_node_service_account.
  ## The compute module must consume it, not create it.
  service_account_email = "tg-node-edge-01@test-project.iam.gserviceaccount.com"

  registration_mode = "manual"

  ## Expected: validate succeeds, and no google_service_account resource is managed
  ## by this compute module.
}
