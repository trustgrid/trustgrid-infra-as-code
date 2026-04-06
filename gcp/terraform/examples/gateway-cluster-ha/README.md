# gateway-cluster-ha

Deploys a dual-node Trustgrid **gateway cluster** in high-availability (HA) mode on GCP.

Gateway nodes accept inbound tunnel connections from Trustgrid edge nodes. Each gateway has an independent static external IP so edge nodes can reach a stable endpoint. When one gateway becomes unavailable, the cluster updates GCP project routes to redirect traffic to the active node — this is Trustgrid's **route-failover HA model**.

## Architecture

```
Existing VPC / Subnets
  ├── management VPC (WAN)
  │     ├── Management subnetwork  ──► nic0 (node A: static ext IP in zone_a)
  │     │                          ──► nic0 (node B: static ext IP in zone_b)
  │     └── Firewall rules
  │           ├── egress: control plane TCP 443/8443, DNS, metadata
  │           └── ingress: TCP/UDP 8443 from edge nodes (0.0.0.0/0)
  └── data VPC (LAN)
        └── Data subnetwork  ──► nic1 (both nodes)

IAM (project scope)
  └── Custom role "trustgridRouteManager"
        └── compute.routes.{list,get,create,delete}
              └── Bound to: node-a-sa + node-b-sa
```

Resources created by this example:

| Resource | Description |
|---|---|
| `trustgrid_node_service_account` × 2 | Dedicated GCP service account per gateway node |
| `trustgrid_cluster_route_role` | Custom IAM role + project binding for HA route failover |
| `trustgrid_mgmt_firewall` | Egress rules: control plane TCP 443/8443, DNS, GCP metadata |
| `trustgrid_gateway_firewall` | Ingress rule: TCP/UDP 8443 from edge nodes |
| `trustgrid_single_node` × 2 | Compute Engine instances in separate zones (dual-NIC, `can_ip_forward=true`) |
| `google_compute_address` × 2 | Module-managed static external IPs per node |

## Prerequisites

- An existing GCP project with billing enabled.
- Two VPC subnetworks: one for management (WAN) with internet egress and inbound port 8443, one for data (LAN).
- `roles/compute.instanceAdmin.v1`, `roles/iam.serviceAccountAdmin`, and `roles/resourcemanager.projectIamAdmin` permissions (or equivalent) for the Terraform principal.
- A valid Trustgrid license and gateway cluster registration key from the Trustgrid portal.

## Sensitive variables

`tg_license` and `tg_registration_key` are marked `sensitive = true`. **Never commit these values to source control.**

```bash
export TF_VAR_tg_license="<your-trustgrid-license>"
export TF_VAR_tg_registration_key="<your-cluster-registration-key>"
```

## Usage

1. Copy this directory to your working directory.
2. Export sensitive variables as shown above.
3. Create a `terraform.tfvars` file for non-sensitive variables:

```hcl
project                = "my-gcp-project"
region                 = "us-central1"
cluster_name           = "tg-gw-prod"
zone_a                 = "us-central1-a"
zone_b                 = "us-central1-b"
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

5. Note the `node_a_external_ip` and `node_b_external_ip` outputs. Configure edge nodes to connect to both gateway IPs.

## Variables

| Name | Type | Required | Sensitive | Description |
|---|---|---|---|---|
| `project` | string | yes | no | GCP project ID |
| `region` | string | yes | no | GCP region (e.g. `us-central1`) |
| `cluster_name` | string | yes | no | Base name for cluster resources |
| `zone_a` | string | yes | no | Zone for node A (e.g. `us-central1-a`) |
| `zone_b` | string | yes | no | Zone for node B (must differ from zone_a) |
| `tg_license` | string | yes | **yes** | Trustgrid node license |
| `tg_registration_key` | string | yes | **yes** | Cluster registration key |
| `management_vpc_network` | string | yes | no | Self-link or name of management VPC network |
| `management_subnetwork` | string | yes | no | Self-link or name of management subnetwork |
| `data_subnetwork` | string | yes | no | Self-link or name of data subnetwork |

## Outputs

| Name | Description |
|---|---|
| `node_a_external_ip` | Static external IP of node A — configure edge nodes to connect here |
| `node_b_external_ip` | Static external IP of node B — configure edge nodes to connect here |
| `node_a_internal_ip` | Internal IP of node A nic0 |
| `node_b_internal_ip` | Internal IP of node B nic0 |
| `node_a_data_ip` | Internal IP of node A nic1 |
| `node_b_data_ip` | Internal IP of node B nic1 |
| `node_a_name` | Instance name of node A |
| `node_b_name` | Instance name of node B |
| `node_a_service_account_email` | Service account email for node A |
| `node_b_service_account_email` | Service account email for node B |
| `cluster_route_role_id` | ID of the custom IAM route-manager role |
| `cluster_bound_members` | IAM members bound to the route-manager role |

## HA route-failover mechanism

Trustgrid HA uses GCP project-level routes for failover:

1. Both gateway nodes monitor each other's health via the Trustgrid control plane.
2. When a failover event occurs, the active node calls the GCP Compute Engine API to update project routes so that the advertised data-plane CIDR points to itself.
3. The `trustgrid_cluster_route_role` module grants both service accounts `compute.routes.{list,get,create,delete}` at project scope — the minimum permissions required.
4. Traffic resumes through the active node within seconds.

### IAM binding authoritativeness

The `google_project_iam_binding` resource used by `trustgrid_cluster_route_role` is **authoritative** for the `trustgridRouteManager` custom role. This means only the service accounts listed in this example will have this role — any manually added members will be removed on the next `terraform apply`. If you need to add members outside Terraform, switch to `google_project_iam_member` (see the module README for guidance).

## Cross-zone HA

Placing node A in `zone_a` and node B in `zone_b` within the same region provides protection against single-zone outages. For stronger fault isolation, use zones in different regions and ensure the subnetworks span multiple regions, or deploy separate regional gateway clusters.

## IP stability on redeploy

Each node's `google_compute_address` resource is owned by the compute module independently of the instance. Replacing an instance (e.g. via `terraform taint`) preserves the same external IP. Edge nodes do not need to be reconfigured after a gateway node replacement.

## Module source references

The `source` references in `main.tf` use relative paths (`../../modules/…`) so that this example works directly from the repository without requiring a tagged release. When deploying from outside this repository, replace the relative paths with pinned GitHub sources, for example:

```hcl
source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=vX.Y.Z"
```

Check the [trustgrid-infra-as-code releases](https://github.com/trustgrid/trustgrid-infra-as-code/releases) for the latest stable tag and pin to it. Never use `?ref=main` in production.
