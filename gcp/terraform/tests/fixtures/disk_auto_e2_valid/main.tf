## Fixture: disk_type_mode = "auto", e2 machine family (positive)
## Acceptance criterion: auto mode with an e2 machine type must pass validate.
##   The effective_disk_type local will resolve to "pd-balanced" at plan time.
##   No boot_disk_type override is needed or provided.
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

  name                  = "e2-tg-node-auto"
  zone                  = "us-central1-a"
  machine_type          = "e2-standard-4"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"
  service_account_email = "tg-sa@test-project.iam.gserviceaccount.com"

  ## disk_type_mode defaults to "auto" — pd-balanced selected automatically for e2.
  ## boot_disk_type intentionally omitted; auto mode ignores it.
}
