## Fixture: trustgrid_node_service_account — minimal valid inputs (positive)
## Acceptance criterion: a 6-character lowercase account_id with a project must
## pass terraform validate with no errors.
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

module "tg_sa" {
  source = "../../../modules/iam/trustgrid_node_service_account"

  account_id = "tg-sa1"
  project    = "test-project"

  ## Expected: validate succeeds — 6-char account_id, starts with lowercase letter.
}
