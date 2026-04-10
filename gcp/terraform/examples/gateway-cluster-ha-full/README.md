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
management_subnetwork_a = "projects/my-gcp-project/regions/us-central1/subnetworks/mgmt-subnet-a"
management_subnetwork_b = "projects/my-gcp-project/regions/us-central1/subnetworks/mgmt-subnet-b"
data_subnetwork_a       = "projects/my-gcp-project/regions/us-central1/subnetworks/data-subnet-a"
data_subnetwork_b       = "projects/my-gcp-project/regions/us-central1/subnetworks/data-subnet-b"

## CIDRs
node_a_data_subnet_cidr = "10.1.0.0/24"
node_b_data_subnet_cidr = "10.2.0.0/24"
cluster_route_cidr      = "10.0.0.0/8"
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

## Variables

| Name | Type | Required | Default | Sensitive | Description |
|---|---|---|---|---|---|
| `project` | string | yes | — | no | GCP project ID |
| `region` | string | yes | — | no | GCP region (e.g. `us-central1`) |
| `cluster_name` | string | yes | — | no | Base name for cluster resources |
| `zone_a` | string | yes | — | no | Zone for node A (e.g. `us-central1-a`) |
| `zone_b` | string | yes | — | no | Zone for node B (must differ from zone_a) |
| `tg_api_host` | string | no | `https://api.trustgrid.io` | no | Trustgrid API endpoint |
| `tg_org_id` | string | yes | — | no | Trustgrid Organization ID |
| `tg_registration_key` | string | no | `null` | **yes** | Optional cluster registration key |
| `tg_node_timeout` | number | no | `300` | no | Seconds to wait for node online |
| `management_vpc_network` | string | yes | — | no | Self-link or name of management VPC |
| `data_vpc_network` | string | yes | — | no | Self-link or name of data VPC |
| `management_subnetwork_a` | string | yes | — | no | Management subnetwork for node A |
| `management_subnetwork_b` | string | yes | — | no | Management subnetwork for node B |
| `data_subnetwork_a` | string | yes | — | no | Data subnetwork for node A |
| `data_subnetwork_b` | string | yes | — | no | Data subnetwork for node B |
| `node_a_data_subnet_cidr` | string | yes | — | no | CIDR of node A's data subnet |
| `node_b_data_subnet_cidr` | string | yes | — | no | CIDR of node B's data subnet |
| `cluster_route_cidr` | string | yes | — | no | CIDR advertised by active cluster member as GCP cloud route |
| `heartbeat_port` | number | no | `9000` | no | TCP port for HA gossip (1–65535) |

## Outputs

| Name | Description |
|---|---|
| `gateway_a_external_ip` | Static external IP of node A — configure edge nodes to connect here |
| `gateway_b_external_ip` | Static external IP of node B — configure edge nodes to connect here |
| `gateway_a_internal_ip` | Internal IP of node A nic0 |
| `gateway_b_internal_ip` | Internal IP of node B nic0 |
| `gateway_a_data_ip` | Internal IP of node A nic1 (used for heartbeat) |
| `gateway_b_data_ip` | Internal IP of node B nic1 (used for heartbeat) |
| `gateway_a_name` | Instance name of node A |
| `gateway_b_name` | Instance name of node B |
| `cluster_fqdn` | Trustgrid cluster FQDN — use for edge node configuration |
| `node_a_fqdn` | Trustgrid FQDN of node A |
| `node_b_fqdn` | Trustgrid FQDN of node B |
| `node_a_uid` | Trustgrid UID of node A |
| `node_b_uid` | Trustgrid UID of node B |
| `node_a_service_account_email` | GCP service account email for node A |
| `node_b_service_account_email` | GCP service account email for node B |
| `cluster_route_role_id` | ID of the custom IAM route-manager role |
| `heartbeat_firewall_name` | Name of the TCP heartbeat firewall rule |

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
|---|---|
| terraform | >= 1.3 |
| google | >= 6.0 |
| tg | ~> 2.2 |

## Providers

| Name | Version |
|---|---|
| google | >= 6.0 |
| tg | ~> 2.2 |

## Modules

| Name | Source | Version |
|---|---|---|
| node\_a\_sa | trustgrid\_node\_service\_account | v0.10.0 |
| node\_b\_sa | trustgrid\_node\_service\_account | v0.10.0 |
| cluster\_route\_role | trustgrid\_cluster\_route\_role | v0.10.0 |
| mgmt\_firewall | trustgrid\_mgmt\_firewall | v0.10.0 |
| gateway\_firewall | trustgrid\_gateway\_firewall | v0.10.0 |
| gateway\_node\_a | trustgrid\_single\_node | v0.10.0 |
| gateway\_node\_b | trustgrid\_single\_node | v0.10.0 |

## Resources

| Name | Type |
|---|---|
| google\_compute\_firewall.heartbeat | resource |
| tg\_license.node\_a | resource |
| tg\_license.node\_b | resource |
| tg\_cluster.main | resource |
| tg\_cluster\_member.node\_a | resource |
| tg\_cluster\_member.node\_b | resource |
| tg\_node\_cluster\_config.node\_a | resource |
| tg\_node\_cluster\_config.node\_b | resource |
| tg\_network\_config.node\_a | resource |
| tg\_network\_config.node\_b | resource |
| tg\_network\_config.cluster | resource |
| data.tg\_node.node\_a | data source |
| data.tg\_node.node\_b | data source |
| data.tg\_node\_iface\_names.node\_a | data source |
| data.tg\_node\_iface\_names.node\_b | data source |
<!-- END_TF_DOCS -->
