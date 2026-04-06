## Fixture: trustgrid_cluster_route_role — two valid SA emails (positive)
## Acceptance criterion: an HA configuration providing separate SA emails for
## each cluster node must pass terraform validate with no errors.
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
    "tg-ha-node-a@test-project.iam.gserviceaccount.com",
    "tg-ha-node-b@test-project.iam.gserviceaccount.com",
  ]

  ## Expected: validate succeeds — two well-formed SA emails for an HA pair.
}
