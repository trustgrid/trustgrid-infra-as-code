## Fixture: auto registration — license OMITTED (negative / must fail)
## Acceptance criterion: auto mode without a license must be rejected by validation.
##
## This fixture is intentionally invalid. terraform validate is expected to emit:
##   "license is required when registration_mode is 'auto'."
##
## The test runner checks that validate exits non-zero for this fixture.

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

  name                  = "tg-node-auto-nolicense"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"
  service_account_email = "tg-sa@test-project.iam.gserviceaccount.com"

  registration_mode = "auto"
  ## license intentionally omitted — must trigger validation error.
}
