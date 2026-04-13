## Fixture: image selection — family lookup (positive)
## Story 5 — image selection behavior.
##
## image_name is omitted (defaults to null).  Module uses image_project + image_family
## to resolve the latest image via google_compute_image data source.
##
## Acceptance criteria verified:
##   - image_project non-empty (uses default "trustgrid-images")
##   - image_family  non-empty (uses default "trustgrid-node")
##   - image_name    null → data source count = 1
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

  name                  = "tg-node-family-lookup"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"
  service_account_email = "tg-sa@test-project.iam.gserviceaccount.com"

  ## image_name intentionally omitted — defaults to null.
  ## image_project and image_family take their non-empty defaults.
  ## Expected: validate succeeds.
}
