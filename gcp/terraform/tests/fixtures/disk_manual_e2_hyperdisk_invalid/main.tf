## Fixture: boot_disk_type = "hyperdisk-balanced" (negative / must fail)
## Acceptance criterion: hyperdisk-* types are not permitted; the boot_disk_type
##   single-variable validation must reject them at validate-time.
##
## This fixture is intentionally invalid.  The expected validation error is:
##   "boot_disk_type must be one of: pd-ssd, pd-balanced, pd-standard."
##
## IMPORTANT — Terraform CLI behavior:
##   terraform validate  → exits 1 (FAILS).  This is a single-variable constraint
##                         on boot_disk_type (allowed values list) and is evaluated
##                         at validate-time, not deferred to plan-time.
##
## NOTE: Previously this fixture relied on a cross-variable constraint (e2 + hyperdisk
## rejection). Hyperdisk support has been removed entirely; hyperdisk-* disk types are
## now rejected by the boot_disk_type single-variable validation for ALL machine types.

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

  name                  = "n2-tg-node-hyperdisk"
  zone                  = "us-central1-a"
  machine_type          = "n2-standard-4"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"
  service_account_email = "tg-sa@test-project.iam.gserviceaccount.com"

  ## Intentionally invalid: hyperdisk-* types are not supported.
  ## Expected: validate emits "boot_disk_type must be one of: pd-ssd, pd-balanced, pd-standard."
  disk_type_mode = "manual"
  boot_disk_type = "hyperdisk-balanced"
}
