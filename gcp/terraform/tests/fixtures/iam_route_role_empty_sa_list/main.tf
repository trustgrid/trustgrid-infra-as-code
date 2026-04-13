## Fixture: trustgrid_cluster_route_role — empty service_account_emails list (negative / must fail)
## Acceptance criterion: supplying an empty list must be rejected by validation.
##
## This fixture is intentionally invalid. The expected validation error is:
##   "At least one service_account_email must be provided."
##
## Expected: terraform validate exits non-zero.

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
  ## Empty list intentionally triggers the length(var.service_account_emails) > 0 check.
  service_account_emails = []
}
