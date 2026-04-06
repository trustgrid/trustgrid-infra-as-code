## Fixture: trustgrid_cluster_route_role — malformed SA email (negative / must fail)
## Acceptance criterion: an email not ending in .iam.gserviceaccount.com must be rejected.
##
## This fixture is intentionally invalid. The expected validation error is:
##   "Each entry in service_account_emails must be a valid GCP service account
##    email ending in .iam.gserviceaccount.com."
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
  ## "user@example.com" is not a GCP service account email — fails the regex check.
  service_account_emails = ["user@example.com"]
}
