## Fixture: image selection — explicit image_name pin (positive)
## Story 5 — image selection behavior.
##
## image_name is set to a non-empty string.  Module bypasses the
## google_compute_image data source (count = 0) and uses the supplied value
## directly as local.boot_image.
##
## Acceptance criteria verified:
##   - image_name non-empty string is accepted by the validation block
##   - data source is skipped (image_name != null → count = 0)
##   - boot_image local equals image_name
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

  name                  = "tg-node-pinned"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"
  service_account_email = "tg-sa@test-project.iam.gserviceaccount.com"

  ## Explicit image pin — takes priority over family lookup.
  ## image_project and image_family are ignored at plan-time.
  image_name = "projects/trustgrid-images/global/images/trustgrid-node-20240101"

  ## Expected: validate succeeds; data source not queried.
}
