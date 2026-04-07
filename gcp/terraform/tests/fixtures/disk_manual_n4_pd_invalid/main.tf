## Fixture: machine_type with unsupported family — n4 (negative / must fail)
## Acceptance criterion: any machine_type whose family is not one of e2, n2, n2d, t2d
##   must be rejected by the single-variable machine_type validation block.
##
## This fixture is intentionally invalid.  The expected validation error is:
##   "machine_type family must be one of: e2, n2, n2d, t2d"
##
## IMPORTANT — Terraform CLI behavior:
##   terraform validate  → exits 1 (FAILS).  This is a single-variable constraint
##                         evaluated at validate-time.
##   No need for terraform plan for this particular negative test.
##
## NOTE: This fixture previously tested "n4 + pd-balanced in manual mode" which
## relied on the now-removed n4/c4 cross-variable hyperdisk constraint. n4 is now
## entirely rejected at the machine_type variable validation stage.

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

  name                  = "n4-tg-node-invalid-family"
  zone                  = "us-central1-a"
  machine_type          = "n4-standard-8"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"
  service_account_email = "tg-sa@test-project.iam.gserviceaccount.com"

  ## Intentionally invalid: n4 is not a supported machine family.
  ## Expected: validate emits "machine_type family must be one of: e2, n2, n2d, t2d"
}
