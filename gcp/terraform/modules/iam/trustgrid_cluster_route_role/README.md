# trustgrid\_cluster\_route\_role — GCP IAM HA Route Management Module

This helper module creates the **minimum IAM permissions** for Trustgrid HA cluster
nodes to perform route failover in GCP. When the active node detects its peer is
unreachable it must delete the failing node's routes and create replacement routes
via its own NIC — requiring `compute.routes.*` and `compute.networks.updatePolicy`
permissions at the project level.

The module creates:
1. A **custom IAM role** with least-privilege route-management permissions.
2. A **project-level IAM binding** attaching the role to the supplied service
   account email(s).

> **Note:** Routes are a project-global resource in GCP. There is no per-VPC
> route IAM scope, so the binding must be at project level. The custom role grants
> only the five permissions actually needed — far fewer than the predefined
> `roles/compute.networkAdmin`.

---

## What this module creates

| Resource | Description |
|---|---|
| `google_project_iam_custom_role` | Custom role with `compute.routes.{list,get,create,delete}` + `compute.networks.updatePolicy` |
| `google_project_iam_binding` | Binds the custom role to `service_account_emails` at project scope |

### Permissions granted

| Permission | Why it is needed |
|---|---|
| `compute.routes.list` | Enumerate existing routes to identify which belong to the failed peer |
| `compute.routes.get` | Inspect individual route attributes before deletion/recreation |
| `compute.routes.create` | Create replacement routes via the surviving node's NIC |
| `compute.routes.delete` | Remove stale routes from the failed peer |
| `compute.networks.updatePolicy` | Required by the GCP routes API at route-create time — GCP enforces this permission on the associated VPC network resource even though routes are a separate resource type. Without it, route creation returns 403. |

---

## IAM binding strategy

This module uses `google_project_iam_binding`, which is **authoritative** for
the custom role: it will remove any members of this role not listed in
`service_account_emails`. This is intentional — it prevents privilege creep in
the HA role.

If you need non-authoritative management (e.g. because another system independently
adds members to this role), replace the binding with individual
`google_project_iam_member` resources in your root module.

---

## Usage

### Single node — minimal setup

```hcl
module "tg_sa" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_node_service_account?ref=v0.4.0"

  account_id = "tg-node-edge-01"
  project    = "my-gcp-project"
}

module "tg_route_role" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_cluster_route_role?ref=v0.4.0"

  project                = "my-gcp-project"
  service_account_emails = [module.tg_sa.email]
}
```

### HA cluster — shared service account

```hcl
module "tg_sa" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_node_service_account?ref=v0.4.0"

  account_id   = "tg-cluster-ha"
  display_name = "Trustgrid HA Cluster SA"
  project      = "my-gcp-project"
}

module "tg_route_role" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_cluster_route_role?ref=v0.4.0"

  project                = "my-gcp-project"
  service_account_emails = [module.tg_sa.email]
}

module "tg_node_a" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.4.0"

  name                  = "tg-ha-node-a"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/my-project/regions/us-central1/subnetworks/mgmt-subnet"
  data_subnetwork       = "projects/my-project/regions/us-central1/subnetworks/data-subnet"
  service_account_email = module.tg_sa.email
}

module "tg_node_b" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.4.0"

  name                  = "tg-ha-node-b"
  zone                  = "us-central1-b"
  management_subnetwork = "projects/my-project/regions/us-central1/subnetworks/mgmt-subnet"
  data_subnetwork       = "projects/my-project/regions/us-central1/subnetworks/data-subnet"
  service_account_email = module.tg_sa.email
}
```

### HA cluster — separate service accounts per node

```hcl
module "tg_sa_a" {
  source     = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_node_service_account?ref=v0.4.0"
  account_id = "tg-ha-node-a"
  project    = "my-gcp-project"
}

module "tg_sa_b" {
  source     = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_node_service_account?ref=v0.4.0"
  account_id = "tg-ha-node-b"
  project    = "my-gcp-project"
}

module "tg_route_role" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_cluster_route_role?ref=v0.4.0"

  project = "my-gcp-project"
  service_account_emails = [
    module.tg_sa_a.email,
    module.tg_sa_b.email,
  ]
}
```

### Custom role ID (avoid conflicts in shared projects)

```hcl
module "tg_route_role" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_cluster_route_role?ref=v0.4.0"

  project                = "my-gcp-project"
  role_id                = "trustgridHaRouteManager_prod"
  role_title             = "Trustgrid HA Route Manager (prod)"
  service_account_emails = [module.tg_sa.email]
}
```

---

## Least-privilege note

The five permissions (`compute.routes.{list,get,create,delete}` plus
`compute.networks.updatePolicy`) are the minimum required for route failover.
`compute.networks.updatePolicy` is a cross-resource requirement enforced by the
GCP routes API on the associated VPC network at route-create time — it is not
surfaced in the routes IAM documentation but is confirmed by the 403 error the
Trustgrid agent returns without it.

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_project_iam_binding.route_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_binding) | resource |
| [google_project_iam_custom_role.route_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | GCP project ID in which to create the custom IAM role and project-level IAM binding. | `string` | n/a | yes |
| <a name="input_service_account_emails"></a> [service\_account\_emails](#input\_service\_account\_emails) | List of service account email addresses to bind to the route-manager custom role. | `list(string)` | n/a | yes |
| <a name="input_role_id"></a> [role\_id](#input\_role\_id) | Unique ID for the custom IAM role within the project. 1–64 chars, letters/digits/underscores/dots. | `string` | `"trustgridRouteManager"` | no |
| <a name="input_role_title"></a> [role\_title](#input\_role\_title) | Human-readable title for the custom IAM role shown in the GCP console. | `string` | `"Trustgrid HA Route Manager"` | no |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | Description of the custom IAM role. | `string` | `"Least-privilege role granting Trustgrid HA cluster nodes the compute.routes permissions required to perform route failover: list, get, create, and delete project routes."` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_custom_role_id"></a> [custom\_role\_id](#output\_custom\_role\_id) | The role ID: `projects/<project>/roles/<role_id>`. |
| <a name="output_custom_role_name"></a> [custom\_role\_name](#output\_custom\_role\_name) | The resource name: `projects/<project>/roles/trustgridRouteManager`. |
| <a name="output_iam_binding_etag"></a> [iam\_binding\_etag](#output\_iam\_binding\_etag) | ETag of the project IAM binding. Detect out-of-band changes by comparing this value. |
| <a name="output_bound_members"></a> [bound\_members](#output\_bound\_members) | List of `serviceAccount:<email>` members bound to the custom role. |
<!-- END_TF_DOCS -->
