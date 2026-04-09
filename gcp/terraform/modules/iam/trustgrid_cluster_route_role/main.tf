terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

## ─── Custom IAM role ───────────────────────────────────────────────────────────
##
## A least-privilege custom role granting only the permissions required for
## Trustgrid HA route failover. When the active node in a cluster detects its
## peer is unreachable it must atomically:
##   1. List existing routes (compute.routes.list / compute.routes.get)
##   2. Delete the failing node's routes  (compute.routes.delete)
##   3. Create replacement routes via its own NIC (compute.routes.create)
##
## compute.networks.updatePolicy is also required: the GCP routes API enforces
## this permission on the associated VPC network resource at route-create time,
## even though routes are a separate resource type. Without it, route creation
## returns 403 "Required 'compute.networks.updatePolicy'".
##
## The role is scoped to the project level (routes are a project-global resource
## in GCP — there is no per-VPC route IAM scope).
##
## Using a custom role (rather than the predefined compute.networkAdmin) follows
## the principle of least privilege: networkAdmin grants ~100 permissions whereas
## route failover only requires these five.

resource "google_project_iam_custom_role" "route_manager" {
  role_id     = var.role_id
  title       = var.role_title
  description = var.role_description
  project     = var.project

  permissions = [
    "compute.routes.list",
    "compute.routes.get",
    "compute.routes.create",
    "compute.routes.delete",
    "compute.networks.updatePolicy",
  ]
}

## ─── Project IAM binding ───────────────────────────────────────────────────────
##
## Binds the custom route-manager role to the supplied service account(s).
## `google_project_iam_binding` is AUTHORITATIVE for the bound role — it will
## remove any members of this role not listed here. Use it only if you are
## certain this Terraform root owns the full membership of the custom role.
##
## If another process also manages this role's membership, switch to
## `google_project_iam_member` (one resource per SA email) to avoid clobbering.

resource "google_project_iam_binding" "route_manager" {
  project = var.project
  role    = google_project_iam_custom_role.route_manager.name

  members = [for email in var.service_account_emails : "serviceAccount:${email}"]
}
