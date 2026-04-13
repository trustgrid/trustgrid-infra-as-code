# gateway-cluster-ha-full

> **Full automation example — Trustgrid API credentials required.**
> This example deploys GCP infrastructure AND configures Trustgrid cluster,
> node network, and HA gossip settings end-to-end in a single `terraform apply`.
> If you do not have Trustgrid API credentials, use the
> [gateway-cluster-ha](../gateway-cluster-ha) infra-only example instead.

Deploys a complete Trustgrid **HA gateway cluster** on GCP using both the
`hashicorp/google` and `trustgrid/tg` providers. A single apply creates and
configures everything: GCP infrastructure, Trustgrid node registration,
cluster membership, heartbeat gossip config, and LAN route glue — no manual
portal steps required.

## When to use this example vs. gateway-cluster-ha

| Scenario | Use gateway-cluster-ha | Use this example |
|---|---|---|
| No Trustgrid API access yet | ✅ | ❌ |
| Separate infra and Trustgrid provisioning teams | ✅ | — |
| Fully automated end-to-end deployment | — | ✅ |
| Trustgrid API credentials available | optional | ✅ (required) |
| Single `terraform apply` for everything | — | ✅ |

## Architecture

```
Existing VPC / Subnets
  ├── management VPC (WAN)
  │     ├── Node A nic0 — zone_a, static ext IP (direct_static_ip)
  │     ├── Node B nic0 — zone_b, static ext IP (direct_static_ip)
  │     └── Firewall rules
  │           ├── egress: control plane TCP 443/8443, DNS, metadata
  │           └── ingress: TCP/UDP 8443 from edge nodes (0.0.0.0/0)
  └── data VPC (LAN)
        ├── Node A nic1 — zone_a data subnet (node_a_data_subnet_cidr)
        ├── Node B nic1 — zone_b data subnet (node_b_data_subnet_cidr)
        └── Firewall rules
              └── ingress: TCP heartbeat_port (default 9000) between data subnet CIDRs

Trustgrid Control Plane
  ├── tg_license per node  → JWT injected as compute metadata → auto-registration
  ├── tg_cluster           → cluster object (fqdn used for membership + cloud route)
  ├── tg_cluster_member × 2 → both nodes joined to cluster
  ├── tg_node_cluster_config × 2 → gossip host/port for each node
  ├── tg_network_config × 2 (per node) → LAN route to opposite subnet
  └── tg_network_config × 1 (cluster) → cloud_route for cluster CIDR failover

IAM (project scope)
  └── Custom role "trustgridRouteManager"
        └── compute.routes.{list,get,create,delete}
              └── Bound to: node-a-sa + node-b-sa
```

## What gets created

### GCP resources

| Resource | Description |
|---|---|
| `tg_license` × 2 | Trustgrid node licenses (node A + B) — also creates node objects in control plane |
| `trustgrid_node_service_account` × 2 | Dedicated GCP service account per gateway node |
| `trustgrid_cluster_route_role` | Custom IAM role + project binding for HA route failover |
| `trustgrid_mgmt_firewall` | Egress rules: control plane TCP 443/8443, DNS, GCP metadata |
| `trustgrid_gateway_firewall` | Ingress rule: TCP/UDP 8443 from edge nodes |
| `google_compute_firewall` heartbeat | Ingress TCP `heartbeat_port` between data subnet CIDRs |
| `trustgrid_single_node` × 2 | Compute Engine instances in separate zones (dual-NIC, auto-register) |
| `google_compute_address` × 2 | Module-managed static external IPs per node |

### Trustgrid resources

| Resource | Description |
|---|---|
| `tg_cluster` | Trustgrid cluster object |
| `tg_cluster_member` × 2 | Both nodes joined to the cluster |
| `tg_node_cluster_config` × 2 | Gossip host (data IP) and port per node |
| `tg_network_config` × 2 (node) | Per-node LAN interface config + cross-subnet heartbeat route |
| `tg_network_config` × 1 (cluster) | Cluster data interface config + cloud_route for CIDR failover |

## Prerequisites

### Trustgrid API access

You need a Trustgrid API Key with sufficient permissions to create nodes, clusters, and
configure network settings. Obtain the key from the Trustgrid portal under
**Organization → API Keys**.

The API key must have at minimum:
- `node:create` — to create node objects via `tg_license`
- `cluster:create`, `cluster:write` — to create `tg_cluster` and add members
- `node:write` — to apply `tg_node_cluster_config` and `tg_network_config`

Supply credentials via environment variables (**never commit them to source control**):

```bash
export TG_API_KEY_ID="<your-api-key-id>"
export TG_API_KEY_SECRET="<your-api-key-secret>"
```

Find your Org ID in the Trustgrid portal under **Organization → Settings**.

> **Why environment variables?** The `tg` provider reads `TG_API_KEY_ID` and
> `TG_API_KEY_SECRET` automatically. This keeps credentials out of
> `terraform.tfvars`, state files, and version control.

### GCP permissions

The Terraform principal (service account or user) needs:
- `roles/compute.instanceAdmin.v1`
- `roles/iam.serviceAccountAdmin`
- `roles/resourcemanager.projectIamAdmin`

### Existing GCP networking

This example consumes existing VPC networks and subnetworks — it does **not** create
them. You need:

- A management VPC network with internet egress and inbound port 8443
- A data VPC network (may be the same VPC or a dedicated LAN VPC)
- Subnetworks for each node in each VPC (management_subnetwork_a/b, data_subnetwork_a/b)

## One-pass apply sequencing

The apply uses Terraform dependency edges to sequence safely without manual
intervention:

1. `tg_license.node_a` + `tg_license.node_b` — creates node objects in Trustgrid
2. GCP compute modules start provisioning (instances boot in parallel)
3. `data.tg_node.node_a` + `data.tg_node.node_b` — **blocks** until nodes are online
   (up to `tg_node_timeout` seconds, default 5 minutes). This is the readiness gate
   that prevents cluster and network config from racing ahead of node boot.
4. `tg_cluster.main` — creates the Trustgrid cluster
5. `tg_cluster_member` × 2 — joins both nodes to cluster
6. `tg_node_cluster_config` × 2 — sets gossip host/port per node
7. `tg_node_iface_names` × 2 — discovers OS-level NIC names
8. `tg_network_config` × 2 (per node) — sets LAN routes
9. `tg_network_config` × 1 (cluster) — sets cluster cloud route

If a node takes longer than `tg_node_timeout` to boot and register, the apply will
fail at step 3 with a timeout error. Increase `tg_node_timeout` (e.g. to `600`) and
re-run `terraform apply` — idempotent resources already created will be skipped.

## Usage

### 1. Copy this directory

```bash
cp -r gateway-cluster-ha-full/ my-gw-cluster/
cd my-gw-cluster/
```

### 2. Set environment variables

```bash
# Trustgrid API credentials
export TG_API_KEY_ID="<your-api-key-id>"
export TG_API_KEY_SECRET="<your-api-key-secret>"

# Optional: Trustgrid registration key (associates nodes with a pre-created group)
export TF_VAR_tg_registration_key="<your-registration-key>"
```

### 3. Create terraform.tfvars

```hcl
## GCP
project = "my-gcp-project"
region  = "us-central1"

## Cluster identity
cluster_name = "tg-gw-prod"
zone_a       = "us-central1-a"
zone_b       = "us-central1-b"

## Trustgrid provider
tg_org_id = "my-trustgrid-org-id"

## Network (substitute your real VPC/subnet names or self-links)
management_vpc_network  = "projects/my-gcp-project/global/networks/mgmt-vpc"
data_vpc_network        = "projects/my-gcp-project/global/networks/data-vpc"
data_vpc_cidr           = "10.47.0.0/16"
management_subnetwork_a = "projects/my-gcp-project/regions/us-central1/subnetworks/mgmt-subnet-a"
management_subnetwork_b = "projects/my-gcp-project/regions/us-central1/subnetworks/mgmt-subnet-b"
data_subnetwork_a       = "projects/my-gcp-project/regions/us-central1/subnetworks/data-subnet-a"
data_subnetwork_b       = "projects/my-gcp-project/regions/us-central1/subnetworks/data-subnet-b"

## CIDRs
node_a_data_subnet_cidr = "10.1.0.0/24"
node_b_data_subnet_cidr = "10.2.0.0/24"
cluster_route_cidr      = "10.0.0.0/8"
# virtual_network_cidr  = "10.200.0.0/16" # set when remote network CIDRs traverse these gateways directly (not NATed to local VPC IPs)
```

### 4. Apply

```bash
terraform init
terraform plan
terraform apply
```

### 5. Post-apply verification

After a successful apply, verify in the Trustgrid portal:

- Both nodes appear online under **Nodes**
- Both nodes are listed as cluster members under **Clusters → cluster_name**
- Each node shows heartbeat config under **Node → Cluster Config**
- Each node shows the cross-subnet LAN route under **Node → Network → Interfaces**
- The cluster shows the cloud_route under **Cluster → Network → Interfaces**

Use the outputs to configure edge nodes:

```bash
terraform output cluster_fqdn         # connect edge nodes to this
terraform output gateway_a_external_ip # or to this individual node IP
terraform output gateway_b_external_ip # or to this individual node IP
```

Variable and output reference is auto-generated in the `terraform-docs` section below.

## Additional firewall behavior

Beyond management/gateway ingress and heartbeat, this example adds:

- `google_compute_firewall.allow_internal_tcp_udp` (always on)
  - Allows east-west TCP/UDP from `data_vpc_cidr`
  - Required in GCP custom VPCs where internal TCP/UDP is otherwise denied
- `google_compute_firewall.allow_virtual_network_tcp_udp` (optional)
  - Created only when `virtual_network_cidr` is set
  - Required for NONAT / pass-through virtual network routing
  - Usually not needed when traffic is NATed into local VPC ranges

## Security notes

- **Never commit Trustgrid API credentials or license values to source control.**
  The `tg_license.*.license` JWT is stored in Terraform state (marked sensitive).
  Protect your state backend accordingly (e.g. GCS bucket with encryption and
  access controls).
- Supply `TG_API_KEY_ID` and `TG_API_KEY_SECRET` via environment variables or a
  secrets manager — never in `terraform.tfvars`.
- The `tg_registration_key` variable is `sensitive = true`. Supply it via
  `TF_VAR_tg_registration_key` environment variable.

## HA route-failover mechanism

Trustgrid HA uses GCP project-level routes for failover:

1. Both gateway nodes monitor each other via the Trustgrid control plane gossip channel
   (TCP `heartbeat_port`, default 9000) on their data interfaces.
2. When a failover event occurs, the active node calls the GCP Compute Engine API to
   update project routes for `cluster_route_cidr` to point to itself.
3. The `trustgrid_cluster_route_role` module grants both service accounts
   `compute.routes.{list,get,create,delete}` at project scope — the minimum
   permissions required.
4. Traffic resumes through the active node within seconds.

The `tg_network_config.cluster` resource sets the `cloud_route` on the data interface
at cluster scope so the active member always owns the advertised route.

## Module source references

The `source` paths in `main.tf` use pinned GitHub source references:

```hcl
source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.10.0"
```

All modules in this example are pinned to `v0.10.0`. To upgrade, replace the tag with
the desired version from the
[trustgrid-infra-as-code releases](https://github.com/trustgrid/trustgrid-infra-as-code/releases)
page. Always pin to a semver tag — never use a branch name or `?ref=main`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |
| <a name="requirement_tg"></a> [tg](#requirement\_tg) | ~> 2.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 7.27.0 |
| <a name="provider_tg"></a> [tg](#provider\_tg) | 2.2.0 |

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
| [tg_cluster.main](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/cluster) | resource |
| [tg_cluster_member.node_a](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/cluster_member) | resource |
| [tg_cluster_member.node_b](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/cluster_member) | resource |
| [tg_license.node_a](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/license) | resource |
| [tg_license.node_b](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/license) | resource |
| [tg_network_config.cluster](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/network_config) | resource |
| [tg_network_config.node_a](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/network_config) | resource |
| [tg_network_config.node_b](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/network_config) | resource |
| [tg_node_cluster_config.node_a](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/node_cluster_config) | resource |
| [tg_node_cluster_config.node_b](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/node_cluster_config) | resource |
| [tg_node.node_a](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/data-sources/node) | data source |
| [tg_node.node_b](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/data-sources/node) | data source |
| [tg_node_iface_names.node_a](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/data-sources/node_iface_names) | data source |
| [tg_node_iface_names.node_b](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/data-sources/node_iface_names) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Base name for the gateway cluster. Used to name both nodes (tg\_license + compute), service accounts, firewall rules, and the Trustgrid cluster object (e.g. tg-gw-prod → tg-gw-prod-gw-a, tg-gw-prod-gw-b, tg-gw-prod cluster). | `string` | n/a | yes |
| <a name="input_cluster_route_cidr"></a> [cluster\_route\_cidr](#input\_cluster\_route\_cidr) | CIDR block advertised by the active cluster member as a GCP cloud route. When a failover occurs the active node updates the GCP project route for this CIDR to point to itself. Typically the downstream network reachable via the gateway cluster (e.g. 10.0.0.0/8). | `string` | n/a | yes |
| <a name="input_data_subnetwork_a"></a> [data\_subnetwork\_a](#input\_data\_subnetwork\_a) | Self-link or name of the existing subnetwork for node A's data (LAN/nic1) interface. | `string` | n/a | yes |
| <a name="input_data_subnetwork_b"></a> [data\_subnetwork\_b](#input\_data\_subnetwork\_b) | Self-link or name of the existing subnetwork for node B's data (LAN/nic1) interface. | `string` | n/a | yes |
| <a name="input_data_vpc_cidr"></a> [data\_vpc\_cidr](#input\_data\_vpc\_cidr) | CIDR block of the data VPC (or the internal source range that should be allowed for east-west TCP/UDP). Used by the always-on internal TCP/UDP firewall rule required in custom VPCs. | `string` | n/a | yes |
| <a name="input_data_vpc_network"></a> [data\_vpc\_network](#input\_data\_vpc\_network) | Self-link or name of the existing VPC network used for the data (LAN/nic1) interface. The HA heartbeat firewall rule (TCP var.heartbeat\_port) is attached to this network. | `string` | n/a | yes |
| <a name="input_heartbeat_port"></a> [heartbeat\_port](#input\_heartbeat\_port) | TCP port used by Trustgrid HA gossip (heartbeat) traffic between cluster nodes. Must match the port configured in tg\_node\_cluster\_config and the GCP heartbeat firewall rule. Default is 9000. | `number` | `9000` | no |
| <a name="input_management_subnetwork_a"></a> [management\_subnetwork\_a](#input\_management\_subnetwork\_a) | Self-link or name of the existing subnetwork for node A's management (WAN/nic0) interface. Must have internet egress for control-plane connectivity and accept inbound tunnel traffic on port 8443. | `string` | n/a | yes |
| <a name="input_management_subnetwork_b"></a> [management\_subnetwork\_b](#input\_management\_subnetwork\_b) | Self-link or name of the existing subnetwork for node B's management (WAN/nic0) interface. Must have internet egress for control-plane connectivity and accept inbound tunnel traffic on port 8443. | `string` | n/a | yes |
| <a name="input_management_vpc_network"></a> [management\_vpc\_network](#input\_management\_vpc\_network) | Self-link or name of the existing VPC network used for the management (WAN/nic0) interface. Management and gateway firewall rules are attached to this network. | `string` | n/a | yes |
| <a name="input_node_a_data_subnet_cidr"></a> [node\_a\_data\_subnet\_cidr](#input\_node\_a\_data\_subnet\_cidr) | CIDR block of the data subnet used by gateway node A (e.g. 10.1.0.0/24). Used as a source range in the HA heartbeat firewall rule and as the destination in node B's LAN route for cross-subnet heartbeat routing. | `string` | n/a | yes |
| <a name="input_node_b_data_subnet_cidr"></a> [node\_b\_data\_subnet\_cidr](#input\_node\_b\_data\_subnet\_cidr) | CIDR block of the data subnet used by gateway node B (e.g. 10.2.0.0/24). Used as a source range in the HA heartbeat firewall rule and as the destination in node A's LAN route for cross-subnet heartbeat routing. | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | GCP project ID in which to deploy all resources. The cluster route role IAM binding is also created at project scope in this project. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region for provider configuration and static IP address allocation (e.g. us-central1). Both nodes should be in zones within this region. | `string` | n/a | yes |
| <a name="input_tg_api_host"></a> [tg\_api\_host](#input\_tg\_api\_host) | Trustgrid Portal API endpoint. Leave at the default unless targeting a non-production Trustgrid control plane. The provider also reads the TG\_API\_HOST environment variable. | `string` | `"https://api.trustgrid.io"` | no |
| <a name="input_tg_node_timeout"></a> [tg\_node\_timeout](#input\_tg\_node\_timeout) | Seconds to wait for each Trustgrid node to come online before timing out. The data.tg\_node readiness gate polls the Trustgrid control plane for this long before failing. Increase for slow-boot environments (default 300 = 5 minutes). | `number` | `300` | no |
| <a name="input_tg_org_id"></a> [tg\_org\_id](#input\_tg\_org\_id) | Trustgrid Organization ID. The provider will validate that the supplied API credentials belong to this org and fail early if they do not. Obtain from the Trustgrid portal under Organization Settings. | `string` | n/a | yes |
| <a name="input_tg_registration_key"></a> [tg\_registration\_key](#input\_tg\_registration\_key) | Optional Trustgrid registration key. When provided it is passed to both gateway nodes as instance metadata and associates them with a pre-created group or cluster at first-boot registration time. Supply via environment variable (TF\_VAR\_tg\_registration\_key) — never commit to source control. | `string` | `null` | no |
| <a name="input_virtual_network_cidr"></a> [virtual\_network\_cidr](#input\_virtual\_network\_cidr) | Optional Trustgrid virtual network CIDR. When set, creates an additional TCP/UDP ingress firewall rule allowing traffic from this range. Required for NONAT/pass-through routing; leave null when traffic is NATed into local data VPC ranges. | `string` | `null` | no |
| <a name="input_zone_a"></a> [zone\_a](#input\_zone\_a) | GCP zone for gateway node A (e.g. us-central1-a). Must be a different zone from zone\_b for cross-zone high availability. | `string` | n/a | yes |
| <a name="input_zone_b"></a> [zone\_b](#input\_zone\_b) | GCP zone for gateway node B (e.g. us-central1-b). Must differ from zone\_a to achieve cross-zone high availability. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_fqdn"></a> [cluster\_fqdn](#output\_cluster\_fqdn) | Trustgrid cluster FQDN. Reference this when configuring edge nodes to connect to the gateway cluster. |
| <a name="output_cluster_route_role_id"></a> [cluster\_route\_role\_id](#output\_cluster\_route\_role\_id) | Resource ID of the custom IAM route-manager role bound to both gateway service accounts. |
| <a name="output_gateway_a_data_ip"></a> [gateway\_a\_data\_ip](#output\_gateway\_a\_data\_ip) | Internal IP address of gateway node A data interface (nic1). Used as the heartbeat host in tg\_node\_cluster\_config. |
| <a name="output_gateway_a_external_ip"></a> [gateway\_a\_external\_ip](#output\_gateway\_a\_external\_ip) | Static external IP address of gateway node A management interface (nic0). Configure edge nodes to connect to this IP. |
| <a name="output_gateway_a_internal_ip"></a> [gateway\_a\_internal\_ip](#output\_gateway\_a\_internal\_ip) | Internal IP address of gateway node A management interface (nic0). |
| <a name="output_gateway_a_name"></a> [gateway\_a\_name](#output\_gateway\_a\_name) | Name of gateway node A Compute Engine instance. |
| <a name="output_gateway_b_data_ip"></a> [gateway\_b\_data\_ip](#output\_gateway\_b\_data\_ip) | Internal IP address of gateway node B data interface (nic1). Used as the heartbeat host in tg\_node\_cluster\_config. |
| <a name="output_gateway_b_external_ip"></a> [gateway\_b\_external\_ip](#output\_gateway\_b\_external\_ip) | Static external IP address of gateway node B management interface (nic0). Configure edge nodes to connect to this IP. |
| <a name="output_gateway_b_internal_ip"></a> [gateway\_b\_internal\_ip](#output\_gateway\_b\_internal\_ip) | Internal IP address of gateway node B management interface (nic0). |
| <a name="output_gateway_b_name"></a> [gateway\_b\_name](#output\_gateway\_b\_name) | Name of gateway node B Compute Engine instance. |
| <a name="output_heartbeat_firewall_name"></a> [heartbeat\_firewall\_name](#output\_heartbeat\_firewall\_name) | Name of the Google Compute firewall rule that permits HA cluster heartbeat traffic between gateway node data interfaces. |
| <a name="output_internal_tcp_udp_firewall_name"></a> [internal\_tcp\_udp\_firewall\_name](#output\_internal\_tcp\_udp\_firewall\_name) | Name of the always-on internal TCP/UDP firewall rule for the data VPC CIDR. |
| <a name="output_node_a_fqdn"></a> [node\_a\_fqdn](#output\_node\_a\_fqdn) | Trustgrid FQDN of gateway node A as registered in the control plane. |
| <a name="output_node_a_service_account_email"></a> [node\_a\_service\_account\_email](#output\_node\_a\_service\_account\_email) | Email of the GCP service account attached to gateway node A. |
| <a name="output_node_a_uid"></a> [node\_a\_uid](#output\_node\_a\_uid) | Trustgrid UID of gateway node A. |
| <a name="output_node_b_fqdn"></a> [node\_b\_fqdn](#output\_node\_b\_fqdn) | Trustgrid FQDN of gateway node B as registered in the control plane. |
| <a name="output_node_b_service_account_email"></a> [node\_b\_service\_account\_email](#output\_node\_b\_service\_account\_email) | Email of the GCP service account attached to gateway node B. |
| <a name="output_node_b_uid"></a> [node\_b\_uid](#output\_node\_b\_uid) | Trustgrid UID of gateway node B. |
| <a name="output_virtual_network_tcp_udp_firewall_name"></a> [virtual\_network\_tcp\_udp\_firewall\_name](#output\_virtual\_network\_tcp\_udp\_firewall\_name) | Name of the optional virtual-network TCP/UDP firewall rule (NONAT/pass-through mode). Null when virtual\_network\_cidr is not set. |
<!-- END_TF_DOCS -->
