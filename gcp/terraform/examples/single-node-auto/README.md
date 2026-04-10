# single-node-auto

Deploys a single Trustgrid edge node in **automatic registration** mode on GCP.

The license key is passed as instance metadata (`tg-license-key`). On first boot, the Trustgrid image's built-in agent detects this key, registers the node with the control plane, and reboots automatically. No portal interaction is required.

## Architecture

```
Existing VPC / Subnets
  ├── management VPC (WAN)
  │     ├── Management subnetwork  ──► nic0 (static external IP)
  │     └── Firewall rules (egress to control plane, DNS, metadata)
  └── data VPC (LAN)
        └── Data subnetwork  ──► nic1
```

Resources created by this example:

| Resource | Description |
|---|---|
| `trustgrid_node_service_account` | Dedicated GCP service account for the node |
| `trustgrid_mgmt_firewall` | Egress rules: control plane TCP 443/8443, DNS UDP/TCP 53, GCP metadata TCP 80 |
| `trustgrid_single_node` | Compute Engine instance (dual-NIC, `can_ip_forward=true`) |
| `google_compute_address` | Module-managed static external IP (owned by the compute module) |

## Prerequisites

- An existing GCP project with billing enabled.
- Two VPC subnetworks: one for management (WAN) with internet egress, one for data (LAN).
- `roles/compute.instanceAdmin.v1` and `roles/iam.serviceAccountAdmin` permissions (or equivalent) for the Terraform principal.
- A valid Trustgrid license obtained from the Trustgrid portal or API.

## Sensitive variables

`tg_license` and `tg_registration_key` are marked `sensitive = true`. **Never commit these values to source control.** Supply them at apply time using one of:

- Environment variables: `export TF_VAR_tg_license="<license>"`
- A `terraform.tfvars` file that is excluded from version control via `.gitignore`
- A secrets manager integration (e.g. GCP Secret Manager with the Terraform `google_secret_manager_secret_version` data source)

## Usage

1. Copy this directory to your working directory.
2. Set the required sensitive variables via environment variables or a gitignored tfvars file:

```bash
export TF_VAR_tg_license="<your-trustgrid-license>"
# Optional — only needed if the node should join a specific cluster:
export TF_VAR_tg_registration_key="<your-registration-key>"
```

3. Create a `terraform.tfvars` for the non-sensitive variables:

```hcl
project                = "my-gcp-project"
region                 = "us-central1"
name                   = "tg-edge-node-01"
zone                   = "us-central1-a"
management_vpc_network = "projects/my-gcp-project/global/networks/mgmt-vpc"
management_subnetwork  = "projects/my-gcp-project/regions/us-central1/subnetworks/mgmt-subnet"
data_subnetwork        = "projects/my-gcp-project/regions/us-central1/subnetworks/data-subnet"
```

4. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

The node will appear in the Trustgrid portal as **Online** once the built-in registration agent completes and the node reboots (typically within 2–3 minutes of first boot).

## Variables

| Name | Type | Required | Sensitive | Description |
|---|---|---|---|---|
| `project` | string | yes | no | GCP project ID |
| `region` | string | yes | no | GCP region (e.g. `us-central1`) |
| `name` | string | yes | no | Base name for all created resources |
| `zone` | string | yes | no | GCP zone (e.g. `us-central1-a`) |
| `tg_license` | string | yes | **yes** | Trustgrid node license |
| `tg_registration_key` | string | no | **yes** | Registration key to join a cluster (optional) |
| `management_vpc_network` | string | yes | no | Self-link or name of the management VPC network |
| `management_subnetwork` | string | yes | no | Self-link or name of the management subnetwork |
| `data_subnetwork` | string | yes | no | Self-link or name of the data subnetwork |

## Outputs

| Name | Description |
|---|---|
| `management_external_ip` | Static external IP of nic0 |
| `management_internal_ip` | Internal IP of nic0 |
| `data_internal_ip` | Internal IP of nic1 |
| `node_name` | Instance name |
| `node_self_link` | Instance self-link |
| `service_account_email` | Service account email attached to the instance |

## Auto-registration sequence

1. Module sets `tg-license-key` (and optionally `tg-registration-key`) in instance metadata.
2. On first boot, the Trustgrid image's built-in agent detects `tg-license-key` in the instance metadata API.
3. The agent registers the node with the Trustgrid control plane.
4. The agent reboots the VM to activate the new identity.
5. Node appears as **Online** in the Trustgrid portal.

## IP stability on redeploy

The module creates a `google_compute_address` resource that is independent of the instance. Replacing the instance (e.g. via `terraform taint` or a full `destroy + apply`) preserves the same external IP. The license key and registration key are passed to the new instance via metadata, so the node re-registers automatically.

## Module source references

The `source` paths in `main.tf` use pinned GitHub source references:

```hcl
source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.11.0"
```

All modules in this example are pinned to `v0.11.0`. To upgrade, replace the tag with the
desired version from the
[trustgrid-infra-as-code releases](https://github.com/trustgrid/trustgrid-infra-as-code/releases)
page. Always pin to a semver tag — never use a branch name or `?ref=main` in
production deployments.
