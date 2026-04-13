# trustgrid\_node\_service\_account — GCP IAM Service Account Module

This helper module creates a **dedicated GCP service account** for a Trustgrid node
or cluster. Decoupling identity from compute keeps service account lifecycle
independent of instance replacement and makes least-privilege IAM bindings easier
to manage.

After creating the service account, pass its `email` output to the
`service_account_email` variable on the `trustgrid_single_node` compute module.
To grant HA route-management permissions, use the companion
`trustgrid_cluster_route_role` IAM helper module.

---

## What this module creates

| Resource | Description |
|---|---|
| `google_service_account` | Service account scoped to `var.project` with the given `account_id` |

---

## Usage

### Minimal — service account with defaults

```hcl
module "tg_sa" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_node_service_account?ref=v0.4.0"

  account_id = "tg-node-edge-01"
  project    = "my-gcp-project"
}

module "tg_node" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.4.0"

  name                  = "tg-edge-01"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/my-project/regions/us-central1/subnetworks/mgmt-subnet"
  data_subnetwork       = "projects/my-project/regions/us-central1/subnetworks/data-subnet"
  service_account_email = module.tg_sa.email
}
```

### HA cluster — two nodes sharing one service account

```hcl
module "tg_sa" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_node_service_account?ref=v0.4.0"

  account_id   = "tg-cluster-ha"
  display_name = "Trustgrid HA Cluster Service Account"
  description  = "Shared SA for Trustgrid HA pair in us-central1"
  project      = "my-gcp-project"
}

module "tg_route_role" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_cluster_route_role?ref=v0.4.0"

  name_prefix            = "tg-cluster-ha"
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

---

## Account ID naming guidance

The `account_id` becomes the local part of the service account email:
`<account_id>@<project>.iam.gserviceaccount.com`

| Deployment pattern | Suggested account_id |
|---|---|
| Single edge node | `tg-node-<name>` (e.g. `tg-node-edge-01`) |
| HA cluster pair | `tg-cluster-<name>` (e.g. `tg-cluster-us-central`) |
| Multi-region gateway | `tg-gw-<region>` (e.g. `tg-gw-us-east1`) |

Rules: 6–30 characters, start with a lowercase letter, lowercase letters/digits/hyphens only.

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
| [google_service_account.node_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The account ID (short name) for the service account. Must be 6–30 characters, start with a lowercase letter, and contain only lowercase letters, digits, and hyphens. | `string` | n/a | yes |
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | Human-readable display name for the service account shown in the GCP console. | `string` | `"Trustgrid Node Service Account"` | no |
| <a name="input_description"></a> [description](#input\_description) | Optional free-text description of the service account's purpose. | `string` | `"Service account for a Trustgrid node. Grants only the permissions required for HA route failover and normal node operation."` | no |
| <a name="input_project"></a> [project](#input\_project) | GCP project ID in which to create the service account. If null, the project configured on the provider is used. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_email"></a> [email](#output\_email) | Email address of the created service account. Pass this to `service_account_email` on the `trustgrid_single_node` compute module. |
| <a name="output_unique_id"></a> [unique\_id](#output\_unique\_id) | Unique, stable numeric identifier for the service account. |
| <a name="output_name"></a> [name](#output\_name) | Fully-qualified resource name: `projects/<project>/serviceAccounts/<email>`. |
| <a name="output_member"></a> [member](#output\_member) | IAM member string `serviceAccount:<email>`. Ready to use in `google_project_iam_binding` or `google_project_iam_member`. |
<!-- END_TF_DOCS -->
