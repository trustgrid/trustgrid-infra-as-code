## Fixture: image_name empty string (negative / must fail)
## Story 5 — image selection behavior.
##
## image_name = "" is explicitly set.  The validation block requires that
## image_name be either null OR a non-empty string after trimming whitespace.
## An empty string must be rejected.
##
## Expected validate error:
##   "image_name must not be an empty string. Set to null to use
##    family-based image resolution instead."
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

  name                  = "tg-node-empty-image"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"
  service_account_email = "tg-sa@test-project.iam.gserviceaccount.com"

  ## Explicitly empty image_name — must be rejected.
  image_name = ""
}
