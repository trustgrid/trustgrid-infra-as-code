# gateway-cluster-ha

> **Infra-only example — manual registration default.**
> No Trustgrid API credentials are required to use this example.
> This is the recommended starting point for platform teams that provision GCP
> infrastructure independently from Trustgrid node registration.

Deploys dual-node Trustgrid **gateway cluster** infrastructure in high-availability (HA)
mode on GCP using only the `hashicorp/google` provider.

Gateway nodes accept inbound tunnel connections from Trustgrid edge nodes. Each gateway
has an independent static external IP so edge nodes can reach a stable endpoint. When one
gateway becomes unavailable, the cluster updates GCP project routes to redirect traffic to
the active node — this is Trustgrid's **route-failover HA model**.

By default, nodes are deployed with `registration_mode = "manual"`. They boot into an
unregistered state; a Trustgrid operator registers them via the portal or serial console
when ready. No license key or registration key input is needed for the default deployment.

## When to use this example vs. gateway-cluster-ha-full

| Scenario | Use this example | Use gateway-cluster-ha-full |
|---|---|---|
| No Trustgrid API access yet | ✅ | ❌ |
| Separate infra and Trustgrid provisioning teams | ✅ | — |
| Fully automated end-to-end deployment | — | ✅ |
| Trustgrid API credentials available | optional | ✅ |

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
        ├── Data subnetwork  ──► nic1 (both nodes)
        └── Firewall rules
              └── ingress: TCP 9000 (HA heartbeat) between data subnet CIDRs

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
| `google_compute_firewall` heartbeat | Ingress TCP 9000 between data subnet CIDRs (HA heartbeat) |
| `trustgrid_single_node` × 2 | Compute Engine instances in separate zones (dual-NIC, `can_ip_forward=true`) |
| `google_compute_address` × 2 | Module-managed static external IPs per node |

## Prerequisites

- An existing GCP project with billing enabled.
- Two VPC networks with subnetworks: one management (WAN) network with internet egress and
  inbound port 8443; one data (LAN) network.
- `roles/compute.instanceAdmin.v1`, `roles/iam.serviceAccountAdmin`, and
  `roles/resourcemanager.projectIamAdmin` permissions (or equivalent) for the Terraform
  principal.
- No Trustgrid API credentials required (manual registration default).

## Usage — manual registration (default)

1. Copy this directory to your working directory.
2. Create a `terraform.tfvars` file:

```hcl
project                 = "my-gcp-project"
region                  = "us-central1"
cluster_name            = "tg-gw-prod"
zone_a                  = "us-central1-a"
zone_b                  = "us-central1-b"
management_vpc_network  = "projects/my-gcp-project/global/networks/mgmt-vpc"
management_subnetwork   = "projects/my-gcp-project/regions/us-central1/subnetworks/mgmt-subnet"
data_vpc_network        = "projects/my-gcp-project/global/networks/data-vpc"
data_subnetwork         = "projects/my-gcp-project/regions/us-central1/subnetworks/data-subnet"
node_a_data_subnet_cidr = "10.1.0.0/24"
node_b_data_subnet_cidr = "10.2.0.0/24"
```

3. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

4. Note the `node_a_external_ip` and `node_b_external_ip` outputs. Use these addresses
   when registering each gateway node in the Trustgrid portal.

## Switching to automatic registration

When a Trustgrid license and (optionally) a cluster registration key are available, set
`registration_mode = "auto"` and provide the credentials. Both gateway nodes will
self-register on first boot without manual portal steps.

Add to `terraform.tfvars`:

```hcl
registration_mode = "auto"
```

Export sensitive values via environment variables (never commit secrets to source control):

```bash
export TF_VAR_tg_license="<your-trustgrid-license>"
export TF_VAR_tg_registration_key="<your-cluster-registration-key>"  # optional
```

Then re-apply:

```bash
terraform plan
terraform apply
```

## Variables

| Name | Type | Required | Default | Sensitive | Description |
|---|---|---|---|---|---|
| `project` | string | yes | — | no | GCP project ID |
| `region` | string | yes | — | no | GCP region (e.g. `us-central1`) |
| `cluster_name` | string | yes | — | no | Base name for cluster resources |
| `zone_a` | string | yes | — | no | Zone for node A (e.g. `us-central1-a`) |
| `zone_b` | string | yes | — | no | Zone for node B (must differ from zone_a) |
| `registration_mode` | string | no | `"manual"` | no | `"manual"` or `"auto"` |
| `tg_license` | string | no | `null` | **yes** | Required when `registration_mode = "auto"` |
| `tg_registration_key` | string | no | `null` | **yes** | Optional cluster registration key for auto mode |
| `management_vpc_network` | string | yes | — | no | Self-link or name of management VPC network |
| `management_subnetwork` | string | yes | — | no | Self-link or name of management subnetwork |
| `data_vpc_network` | string | yes | — | no | Self-link or name of data VPC network |
| `data_subnetwork` | string | yes | — | no | Self-link or name of data subnetwork |
| `node_a_data_subnet_cidr` | string | yes | — | no | CIDR of node A's data subnet (heartbeat source range) |
| `node_b_data_subnet_cidr` | string | yes | — | no | CIDR of node B's data subnet (heartbeat source range) |

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
| `heartbeat_firewall_name` | Name of the TCP 9000 heartbeat firewall rule |

## HA heartbeat firewall (TCP 9000)

Trustgrid HA nodes exchange cluster heartbeat traffic on TCP port 9000 over their data
interfaces. The `google_compute_firewall.heartbeat` rule created by this example allows
traffic between `node_a_data_subnet_cidr` and `node_b_data_subnet_cidr` on TCP 9000,
scoped to instances with the `trustgrid-gateway` network tag.

This is a Google-native resource in this example (not a Trustgrid module), applied
directly to `data_vpc_network`.

## HA route-failover mechanism

Trustgrid HA uses GCP project-level routes for failover:

1. Both gateway nodes monitor each other's health via the Trustgrid control plane.
2. When a failover event occurs, the active node calls the GCP Compute Engine API to
   update project routes so that the advertised data-plane CIDR points to itself.
3. The `trustgrid_cluster_route_role` module grants both service accounts
   `compute.routes.{list,get,create,delete}` at project scope — the minimum permissions
   required.
4. Traffic resumes through the active node within seconds.

### IAM binding authoritativeness

The `google_project_iam_binding` resource used by `trustgrid_cluster_route_role` is
**authoritative** for the `trustgridRouteManager` custom role. This means only the
service accounts listed in this example will have this role — any manually added members
will be removed on the next `terraform apply`. If you need to add members outside
Terraform, switch to `google_project_iam_member` (see the module README for guidance).

## Cross-zone HA

Placing node A in `zone_a` and node B in `zone_b` within the same region provides
protection against single-zone outages. For stronger fault isolation, use zones in
different regions and ensure the subnetworks span multiple regions, or deploy separate
regional gateway clusters.

`zone_a` and `zone_b` **must be different values**. A cross-variable validation block on
`zone_a` enforces this constraint at `terraform plan` time — the plan will fail with a
clear error if both zones are identical. Note that `terraform validate` alone does not
evaluate cross-variable constraints; always run `terraform plan` to catch this error
before applying.

## IP stability on redeploy

Each node's `google_compute_address` resource is owned by the compute module
independently of the instance. Replacing an instance (e.g. via `terraform taint`)
preserves the same external IP. Edge nodes do not need to be reconfigured after a gateway
node replacement.

## Migrating to gateway-cluster-ha-full

When your team is ready for fully automated end-to-end deployment, migrate to
[gateway-cluster-ha-full](../gateway-cluster-ha-full):

| Step | Action |
|---|---|
| 1 | Obtain Trustgrid API Key ID + Secret from **Organization → API Keys** in the portal |
| 2 | Export `TG_API_KEY_ID`, `TG_API_KEY_SECRET`, and `TF_VAR_tg_registration_key` as env vars |
| 3 | Copy `gateway-cluster-ha-full/` to a new working directory |
| 4 | Mirror your existing VPC/subnet values into the new `terraform.tfvars` |
| 5 | Add per-node subnet vars (`management_subnetwork_a/b`, `data_subnetwork_a/b`) and `cluster_route_cidr` |
| 6 | Destroy the infra-only stack (`terraform destroy`) and apply the full stack, or import existing resources |

The full example adds `tg_cluster`, `tg_cluster_member`, `tg_node_cluster_config`,
and `tg_network_config` resources that cannot be imported into the infra-only stack —
a clean re-deploy is the simplest migration path when the cluster is not yet in
production.

## Module source references

The `source` paths in `main.tf` use pinned GitHub source references:

```hcl
source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.10.0"
```

All modules in this example are pinned to `v0.10.0`. To upgrade, replace the tag with the
desired version from the
[trustgrid-infra-as-code releases](https://github.com/trustgrid/trustgrid-infra-as-code/releases)
page. Always pin to a semver tag — never use a branch name or `?ref=main` in production
deployments.
