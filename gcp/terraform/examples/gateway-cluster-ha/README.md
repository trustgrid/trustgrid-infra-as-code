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
data_vpc_cidr           = "10.47.0.0/16"
data_subnetwork         = "projects/my-gcp-project/regions/us-central1/subnetworks/data-subnet"
node_a_data_subnet_cidr = "10.1.0.0/24"
node_b_data_subnet_cidr = "10.2.0.0/24"
# virtual_network_cidr  = "10.200.0.0/16" # set when remote network CIDRs traverse these gateways directly (not NATed to local VPC IPs)
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

Variable and output reference is auto-generated in the `terraform-docs` section below.

## HA and east-west firewall rules

Trustgrid HA nodes exchange cluster heartbeat traffic on TCP port 9000 over their data
interfaces. The `google_compute_firewall.heartbeat` rule created by this example allows
traffic between `node_a_data_subnet_cidr` and `node_b_data_subnet_cidr` on TCP 9000,
scoped to instances with the `trustgrid-gateway` network tag.

This example also adds two additional data-network ingress rules required for functional
TCP/UDP traffic in GCP custom VPCs:

- `google_compute_firewall.allow_internal_tcp_udp` (always on)
  - Allows TCP/UDP from `data_vpc_cidr` to gateway-tagged nodes
  - Required because custom VPCs do not have default internal allow rules for TCP/UDP
- `google_compute_firewall.allow_virtual_network_tcp_udp` (optional)
  - Created only when `virtual_network_cidr` is set
  - Required for NONAT / pass-through virtual network routing
  - Usually not needed when traffic is NATed into local VPC ranges

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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 7.27.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster_route_role"></a> [cluster\_route\_role](#module\_cluster\_route\_role) | github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_cluster_route_role | v0.10.0 |
| <a name="module_gateway_firewall"></a> [gateway\_firewall](#module\_gateway\_firewall) | github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_gateway_firewall | v0.10.0 |
| <a name="module_gateway_node_a"></a> [gateway\_node\_a](#module\_gateway\_node\_a) | github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node | v0.10.0 |
| <a name="module_gateway_node_b"></a> [gateway\_node\_b](#module\_gateway\_node\_b) | github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node | v0.10.0 |
| <a name="module_mgmt_firewall"></a> [mgmt\_firewall](#module\_mgmt\_firewall) | github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_mgmt_firewall | v0.10.0 |
| <a name="module_node_a_sa"></a> [node\_a\_sa](#module\_node\_a\_sa) | github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_node_service_account | v0.10.0 |
| <a name="module_node_b_sa"></a> [node\_b\_sa](#module\_node\_b\_sa) | github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_node_service_account | v0.10.0 |

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.allow_internal_tcp_udp](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow_virtual_network_tcp_udp](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.heartbeat](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Base name for the gateway cluster. Used to name both nodes, service accounts, and firewall rules (e.g. tg-gw-prod → tg-gw-prod-gw-a, tg-gw-prod-gw-b). | `string` | n/a | yes |
| <a name="input_data_subnetwork"></a> [data\_subnetwork](#input\_data\_subnetwork) | Self-link or name of the existing subnetwork for the data (LAN/nic1) interface on both nodes. | `string` | n/a | yes |
| <a name="input_data_vpc_cidr"></a> [data\_vpc\_cidr](#input\_data\_vpc\_cidr) | CIDR block of the data VPC (or the internal source range that should be allowed for east-west TCP/UDP). Used by the always-on internal TCP/UDP firewall rule required in custom VPCs. | `string` | n/a | yes |
| <a name="input_data_vpc_network"></a> [data\_vpc\_network](#input\_data\_vpc\_network) | Self-link or name of the existing VPC network used for the data (LAN/nic1) interface. The HA heartbeat firewall rule (TCP 9000) is attached to this network. | `string` | n/a | yes |
| <a name="input_management_subnetwork"></a> [management\_subnetwork](#input\_management\_subnetwork) | Self-link or name of the existing subnetwork for the management (WAN/nic0) interface on both nodes. Must have internet egress for control-plane connectivity and accept inbound tunnel traffic on port 8443. | `string` | n/a | yes |
| <a name="input_management_vpc_network"></a> [management\_vpc\_network](#input\_management\_vpc\_network) | Self-link or name of the existing VPC network used for the management (WAN/nic0) interface. Management firewall rules (control-plane egress, gateway ingress) are attached to this network. | `string` | n/a | yes |
| <a name="input_node_a_data_subnet_cidr"></a> [node\_a\_data\_subnet\_cidr](#input\_node\_a\_data\_subnet\_cidr) | CIDR block of the data subnet used by gateway node A (e.g. 10.1.0.0/24). Used as a source range in the HA heartbeat firewall rule (TCP 9000) to allow node-A-originated heartbeat traffic to reach node B. | `string` | n/a | yes |
| <a name="input_node_b_data_subnet_cidr"></a> [node\_b\_data\_subnet\_cidr](#input\_node\_b\_data\_subnet\_cidr) | CIDR block of the data subnet used by gateway node B (e.g. 10.2.0.0/24). Used as a source range in the HA heartbeat firewall rule (TCP 9000) to allow node-B-originated heartbeat traffic to reach node A. | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | GCP project ID in which to deploy all resources. The cluster route role IAM binding is also created at project scope in this project. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region for provider configuration and static IP address allocation (e.g. us-central1). Both nodes should be in zones within this region. | `string` | n/a | yes |
| <a name="input_registration_mode"></a> [registration\_mode](#input\_registration\_mode) | Trustgrid node registration mode for both gateway nodes. 'manual' (default) — deploy infrastructure now; register nodes later via the Trustgrid portal or serial console. No API credentials required. 'auto' — nodes self-register on first boot using tg\_license; supply tg\_license and optionally tg\_registration\_key. | `string` | `"manual"` | no |
| <a name="input_tg_license"></a> [tg\_license](#input\_tg\_license) | Trustgrid node license. Required when registration\_mode is 'auto'. Obtain from the Trustgrid portal or API. Ignored when registration\_mode is 'manual'. Treat as a secret — supply via environment variable (TF\_VAR\_tg\_license) or a secrets manager. | `string` | `null` | no |
| <a name="input_tg_registration_key"></a> [tg\_registration\_key](#input\_tg\_registration\_key) | Trustgrid registration key that associates both nodes with the same gateway cluster. Used only when registration\_mode is 'auto'. Optional even in auto mode — the node will still register using the license alone; supply the key when you want to associate the node with a pre-created cluster. Supply via environment variable (TF\_VAR\_tg\_registration\_key). Ignored when registration\_mode is 'manual'. | `string` | `null` | no |
| <a name="input_virtual_network_cidr"></a> [virtual\_network\_cidr](#input\_virtual\_network\_cidr) | Optional Trustgrid virtual network CIDR. When set, creates an additional TCP/UDP ingress firewall rule allowing traffic from this range. Required for NONAT/pass-through routing; leave null when traffic is NATed into local data VPC ranges. | `string` | `null` | no |
| <a name="input_zone_a"></a> [zone\_a](#input\_zone\_a) | GCP zone for gateway node A (e.g. us-central1-a). Choose a different zone from zone\_b for cross-zone HA. | `string` | n/a | yes |
| <a name="input_zone_b"></a> [zone\_b](#input\_zone\_b) | GCP zone for gateway node B (e.g. us-central1-b). Must differ from zone\_a to achieve cross-zone high availability. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_bound_members"></a> [cluster\_bound\_members](#output\_cluster\_bound\_members) | IAM members (serviceAccount:<email>) bound to the cluster route-manager role. |
| <a name="output_cluster_route_role_id"></a> [cluster\_route\_role\_id](#output\_cluster\_route\_role\_id) | Resource ID of the custom IAM route-manager role bound to both gateway service accounts. |
| <a name="output_heartbeat_firewall_name"></a> [heartbeat\_firewall\_name](#output\_heartbeat\_firewall\_name) | Name of the Google Compute firewall rule that permits HA cluster heartbeat traffic (TCP 9000) between gateway node data interfaces. |
| <a name="output_internal_tcp_udp_firewall_name"></a> [internal\_tcp\_udp\_firewall\_name](#output\_internal\_tcp\_udp\_firewall\_name) | Name of the always-on internal TCP/UDP firewall rule for the data VPC CIDR. |
| <a name="output_node_a_data_ip"></a> [node\_a\_data\_ip](#output\_node\_a\_data\_ip) | Internal IP address of gateway node A data interface (nic1). |
| <a name="output_node_a_external_ip"></a> [node\_a\_external\_ip](#output\_node\_a\_external\_ip) | Static external IP address of gateway node A management interface (nic0). Configure edge nodes to connect to this IP. |
| <a name="output_node_a_internal_ip"></a> [node\_a\_internal\_ip](#output\_node\_a\_internal\_ip) | Internal IP address of gateway node A management interface (nic0). |
| <a name="output_node_a_name"></a> [node\_a\_name](#output\_node\_a\_name) | Name of gateway node A Compute Engine instance. |
| <a name="output_node_a_self_link"></a> [node\_a\_self\_link](#output\_node\_a\_self\_link) | Self-link URI of gateway node A. |
| <a name="output_node_a_service_account_email"></a> [node\_a\_service\_account\_email](#output\_node\_a\_service\_account\_email) | Email of the service account attached to gateway node A. |
| <a name="output_node_b_data_ip"></a> [node\_b\_data\_ip](#output\_node\_b\_data\_ip) | Internal IP address of gateway node B data interface (nic1). |
| <a name="output_node_b_external_ip"></a> [node\_b\_external\_ip](#output\_node\_b\_external\_ip) | Static external IP address of gateway node B management interface (nic0). Configure edge nodes to connect to this IP. |
| <a name="output_node_b_internal_ip"></a> [node\_b\_internal\_ip](#output\_node\_b\_internal\_ip) | Internal IP address of gateway node B management interface (nic0). |
| <a name="output_node_b_name"></a> [node\_b\_name](#output\_node\_b\_name) | Name of gateway node B Compute Engine instance. |
| <a name="output_node_b_self_link"></a> [node\_b\_self\_link](#output\_node\_b\_self\_link) | Self-link URI of gateway node B. |
| <a name="output_node_b_service_account_email"></a> [node\_b\_service\_account\_email](#output\_node\_b\_service\_account\_email) | Email of the service account attached to gateway node B. |
| <a name="output_virtual_network_tcp_udp_firewall_name"></a> [virtual\_network\_tcp\_udp\_firewall\_name](#output\_virtual\_network\_tcp\_udp\_firewall\_name) | Name of the optional virtual-network TCP/UDP firewall rule (NONAT/pass-through mode). Null when virtual\_network\_cidr is not set. |
<!-- END_TF_DOCS -->
