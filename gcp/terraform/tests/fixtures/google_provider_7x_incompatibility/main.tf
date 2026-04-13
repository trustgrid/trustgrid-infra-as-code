## Fixture: Google provider >= 7.0 consumer vs module constraint ~> 6.0 (negative)
## Story: US-001 — Reproduce provider 7.x incompatibility in a failing check
##
## Purpose:
##   This fixture represents a realistic caller that has standardised on Google
##   provider 7.x (version = ">= 7.0").  The module under test declares
##   version = "~> 6.0", which imposes an implicit upper bound of < 7.0.0.
##   Terraform cannot resolve a provider version that satisfies both constraints
##   simultaneously, so `terraform init` fails.
##
## Expected behaviour BEFORE the US-002 fix (module still declares ~> 6.0):
##   $ terraform init -backend=false
##   ╷
##   │ Error: Failed to query available provider packages
##   │
##   │   ...
##   │   no available releases match the given constraints
##   │   hashicorp/google (>= 7.0.0, < 7.0.0)
##   ╵
##   Exit code: 1
##
## Expected behaviour AFTER the US-002 fix (module declares >= 6.0):
##   $ terraform init -backend=false
##   Terraform has been successfully initialized!
##   Exit code: 0
##
## Test command (run from repo root):
##   bash gcp/terraform/tests/run_provider_constraint_tests.sh
##
## IMPORTANT — this fixture must NOT be passed through `terraform validate` or
## `terraform plan` alone.  The conflict is a provider-resolution failure that
## surfaces at `terraform init` time, before any HCL validation takes place.

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0" # Caller is standardised on provider 7.x+
    }
  }
}

provider "google" {
  project = "test-project"
  region  = "us-central1"
}

## Consume one representative affected module (compute/trustgrid_single_node).
## All required variables use plausible placeholder values; the fixture only
## needs to reach provider-resolution — it does not need to plan or apply.
module "trustgrid_node" {
  source = "../../../modules/compute/trustgrid_single_node"

  name                  = "tg-repro-node"
  zone                  = "us-central1-a"
  machine_type          = "e2-standard-4"
  management_subnetwork = "projects/test-project/regions/us-central1/subnetworks/mgmt"
  data_subnetwork       = "projects/test-project/regions/us-central1/subnetworks/data"
  service_account_email = "tg-sa@test-project.iam.gserviceaccount.com"
}
