## Fixture: auto registration — license supplied (valid)
## Acceptance criterion: auto mode with a license must succeed validation.

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

## Dummy license value — validation only, no real credentials used.
variable "tg_license" {
  type      = string
  sensitive = true
  default   = "DUMMY-LICENSE-VALUE-FOR-VALIDATE"
}

module "trustgrid_node" {
  source = "../../../modules/compute/trustgrid_single_node"

  name                  = "tg-node-auto"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"
  service_account_email = "tg-sa@test-project.iam.gserviceaccount.com"

  registration_mode = "auto"
  license           = var.tg_license

  ## Expected: validate succeeds.
}
