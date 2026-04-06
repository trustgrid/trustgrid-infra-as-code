## Fixture: trustgrid_cluster_route_role — single valid SA email (positive)
## Acceptance criterion: a well-formed SA email ending in .iam.gserviceaccount.com
## and a required project must pass terraform validate with no errors.
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

module "tg_route_role" {
  source = "../../../modules/iam/trustgrid_cluster_route_role"

  project = "test-project"
  service_account_emails = [
    "tg-node-edge-01@test-project.iam.gserviceaccount.com",
  ]

  ## Expected: validate succeeds — single SA email is well-formed.
}
