## Fixture: auto registration — license AND registration_key supplied (valid)
## Acceptance criterion: registration_key is accepted and sensitive handling preserved.

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

variable "tg_license" {
  type      = string
  sensitive = true
  default   = "DUMMY-LICENSE-VALUE-FOR-VALIDATE"
}

variable "tg_registration_key" {
  type      = string
  sensitive = true
  default   = "DUMMY-REGKEY-VALUE-FOR-VALIDATE"
}

module "trustgrid_node" {
  source = "../../../modules/compute/trustgrid_single_node"

  name                  = "tg-node-auto-key"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"
  service_account_email = "tg-sa@test-project.iam.gserviceaccount.com"

  registration_mode = "auto"
  license           = var.tg_license
  registration_key  = var.tg_registration_key

  ## Expected: validate succeeds.
}
