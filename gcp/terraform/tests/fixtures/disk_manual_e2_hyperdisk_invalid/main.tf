## Fixture: disk_type_mode = "manual", e2 + hyperdisk-balanced (negative / must fail)
## Acceptance criterion: manual mode with an e2 machine and a hyperdisk-* type must be
##   rejected by validation.
##
## This fixture is intentionally invalid.  The expected validation error is:
##   "e2 machine family does not support hyperdisk disk types. Use pd-ssd, pd-balanced, or pd-standard."
##
## IMPORTANT — Terraform CLI behavior (< 1.6):
##   terraform validate  → exits 0 (PASSES).  Cross-variable validation blocks are NOT
##                         evaluated at validate-time; they are deferred to plan-time.
##   terraform plan      → exits 1 (FAILS) with the validation error above.
##
## The test runner for this fixture must therefore use `terraform plan`, not
## `terraform validate`, and assert that plan exits non-zero with the expected message.
##
## This is a known Terraform limitation — see AGENTS.md "Cross-variable validation" note
## and the "Validation and testing notes" section of the module README for details.

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

  name                  = "e2-tg-node-hyperdisk"
  zone                  = "us-central1-a"
  machine_type          = "e2-standard-4"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"
  service_account_email = "tg-sa@test-project.iam.gserviceaccount.com"

  ## Intentionally invalid: e2 does not support hyperdisk.
  ## Expected: plan emits "e2 machine family does not support hyperdisk disk types."
  disk_type_mode = "manual"
  boot_disk_type = "hyperdisk-balanced"
}
