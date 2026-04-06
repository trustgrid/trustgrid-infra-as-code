## Fixture: trustgrid_node_service_account — account_id too short (negative / must fail)
## Acceptance criterion: account_id with fewer than 6 characters must be rejected.
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

  ## "tg" is only 2 characters — fails the ^[a-z][a-z0-9-]{5,29}$ regex.
  account_id = "tg"
  project    = "test-project"
}
