## Fixture: invalid registration_mode (negative / must fail)
## Acceptance criterion: values other than "manual" or "auto" must be rejected.
##
## Expected validate error: "registration_mode must be either 'manual' or 'auto'."

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

  name                  = "tg-node-bad-mode"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"
  service_account_email = "tg-sa@test-project.iam.gserviceaccount.com"

  registration_mode = "invalid-mode"
  license           = "DUMMY"
  ## Expected: validate fails with registration_mode validation error.
}
