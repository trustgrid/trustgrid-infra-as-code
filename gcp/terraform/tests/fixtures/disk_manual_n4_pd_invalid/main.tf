## Fixture: disk_type_mode = "manual", n4 + pd-balanced (negative / must fail)
## Acceptance criterion: manual mode with an n4 machine and a pd-* type must be
##   rejected by validation.
##
## This fixture is intentionally invalid.  The expected validation error is:
##   "n4 and c4 machine families require a hyperdisk disk type"
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

  name                  = "n4-tg-node-pd"
  zone                  = "us-central1-a"
  machine_type          = "n4-standard-8"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"
  service_account_email = "tg-sa@test-project.iam.gserviceaccount.com"

  ## Intentionally invalid: n4 requires hyperdisk; pd-balanced is incompatible.
  ## Expected: plan emits "n4 and c4 machine families require a hyperdisk disk type"
  disk_type_mode = "manual"
  boot_disk_type = "pd-balanced"
}
