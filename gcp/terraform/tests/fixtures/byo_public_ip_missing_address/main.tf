## Fixture: byo_public_ip mode — management_external_ip_address OMITTED (negative / must fail)
## Acceptance criterion: byo_public_ip mode without management_external_ip_address must be rejected.
##
## This fixture is intentionally invalid.  The expected validation error is:
##   "management_external_ip_address is required when public_exposure_mode is 'byo_public_ip'."
##
## IMPORTANT — Terraform CLI behavior (< 1.6):
##   terraform validate  → exits 0 (PASSES).  Cross-variable validation blocks are NOT
##                         evaluated at validate-time; they are deferred to plan-time.
##   terraform plan      → exits 1 (FAILS) with the validation error above.
##
## The test runner for this fixture must therefore use `terraform plan`, not
## `terraform validate`, and assert that plan exits non-zero.
##
## This is a known Terraform limitation — see AGENTS.md "Cross-variable validation" note
## and the Validation section of the module README for details.

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

  name                  = "tg-node-byo-noip"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"
  service_account_email = "tg-sa@test-project.iam.gserviceaccount.com"

  public_exposure_mode = "byo_public_ip"
  ## management_external_ip_address intentionally omitted — must trigger validation error at plan-time.
}
