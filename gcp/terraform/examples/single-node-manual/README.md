# single-node-manual

Deploys a single Trustgrid edge node in **manual registration** mode on GCP.

Use this example when you want to deploy the node infrastructure first and register it through the Trustgrid portal afterwards. No license or registration key is required at deploy time.

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
- A Trustgrid account and portal access to complete node registration after deployment.

## Usage

1. Copy this directory to your working directory.
2. Create a `terraform.tfvars` file:

```hcl
project                = "my-gcp-project"
region                 = "us-central1"
name                   = "tg-edge-node-01"
zone                   = "us-central1-a"
management_vpc_network = "projects/my-gcp-project/global/networks/mgmt-vpc"
management_subnetwork  = "projects/my-gcp-project/regions/us-central1/subnetworks/mgmt-subnet"
data_subnetwork        = "projects/my-gcp-project/regions/us-central1/subnetworks/data-subnet"
```

3. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

4. Note the `management_external_ip` output, then open the [Trustgrid portal](https://portal.trustgrid.io) and register the node.

## Variables

| Name | Type | Required | Description |
|---|---|---|---|
| `project` | string | yes | GCP project ID |
| `region` | string | yes | GCP region (e.g. `us-central1`) |
| `name` | string | yes | Base name for all created resources |
| `zone` | string | yes | GCP zone (e.g. `us-central1-a`) |
| `management_vpc_network` | string | yes | Self-link or name of the management VPC network |
| `management_subnetwork` | string | yes | Self-link or name of the management subnetwork |
| `data_subnetwork` | string | yes | Self-link or name of the data subnetwork |

## Outputs

| Name | Description |
|---|---|
| `management_external_ip` | Static external IP — use this to register the node in the Trustgrid portal |
| `management_internal_ip` | Internal IP of nic0 |
| `data_internal_ip` | Internal IP of nic1 |
| `node_name` | Instance name |
| `node_self_link` | Instance self-link |
| `service_account_email` | Service account email attached to the instance |

## Registration flow

After `terraform apply`:

1. Retrieve the `management_external_ip` from the Terraform outputs.
2. Log in to the [Trustgrid portal](https://portal.trustgrid.io).
3. Navigate to **Nodes → Add Node** and enter the external IP.
4. The node will appear as **Pending** and complete registration automatically once the instance boots and establishes a control-plane connection.

## IP stability on redeploy

The module creates a `google_compute_address` resource that is independent of the instance. Destroying and re-creating the instance (e.g. via `terraform taint` or a full `destroy + apply`) preserves the same external IP. This ensures that DNS records and Trustgrid portal configuration remain valid after a node replacement.

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
