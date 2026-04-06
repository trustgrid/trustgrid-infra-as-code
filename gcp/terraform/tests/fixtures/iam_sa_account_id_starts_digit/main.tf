## Fixture: trustgrid_node_service_account — account_id starts with a digit (negative / must fail)
## Acceptance criterion: account_id that begins with a digit must be rejected.
##
## This fixture is intentionally invalid. The expected validation error is:
##   "account_id must be 6–30 characters, start with a lowercase letter, and
##    contain only lowercase letters, digits, and hyphens."
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

module "tg_sa" {
  source = "../../../modules/iam/trustgrid_node_service_account"

  ## "1tg-node" starts with a digit — fails the ^[a-z] anchor in the regex.
  account_id = "1tg-node"
  project    = "test-project"
}
