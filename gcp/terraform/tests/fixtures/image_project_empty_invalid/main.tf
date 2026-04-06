## Fixture: image_project empty string (negative / must fail)
## Story 5 — image selection behavior.
##
## image_project = "" is explicitly set.  The validation block rejects any
## value that is empty or whitespace-only after trimspace().
##
## Expected validate error:
##   "image_project must not be empty."
##
## SINGLE-variable constraint → evaluated by `terraform validate`.
## The test runner asserts that validate exits non-zero for this fixture.

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

  name                  = "tg-node-empty-project"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"
  service_account_email = "tg-sa@test-project.iam.gserviceaccount.com"

  ## Explicitly empty image_project — must be rejected.
  image_project = ""
}
