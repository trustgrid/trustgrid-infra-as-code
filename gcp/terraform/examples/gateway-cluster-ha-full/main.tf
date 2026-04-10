## ─── Providers ──────────────────────────────────────────────────────────────────
##
## gateway-cluster-ha-full — FULL AUTOMATION (Google + Trustgrid providers)
##
## This example deploys a complete Trustgrid HA gateway cluster on GCP using
## BOTH the hashicorp/google and trustgrid/tg providers. It is designed for
## teams that have Trustgrid API credentials and want a single terraform apply
## to provision all GCP infrastructure AND configure the Trustgrid cluster,
## node network settings, and HA gossip config end-to-end.
##
## This example demonstrates:
##   - Two gateway nodes with automatic Trustgrid registration via tg_license
##   - tg_cluster with two tg_cluster_member resources (both nodes joined)
##   - tg_node online readiness gate via data.tg_node with timeout
##   - tg_node_iface_names to discover OS-level interface names for each node
##   - tg_node_cluster_config wiring heartbeat host/port for both members
##   - Per-node tg_network_config with LAN route glue (cross-subnet heartbeat route)
##   - Cluster-level tg_network_config with cloud_route for cluster CIDR failover
##   - All GCP infra: service accounts, cluster route IAM, management +
##     gateway + heartbeat firewall rules, dual-node compute instances
##
## Prerequisites:
##   - Trustgrid API Key ID and Secret (supply via env vars, see README)
##   - Trustgrid Org ID
##   - Existing GCP VPC networks and subnetworks
##
## Network resources (VPC, subnets) are consumed from existing infrastructure.
## This example does NOT create subnets or VPCs.
##
## Sequencing: tg_license → data.tg_node (waits for online) → tg_cluster.main
## → tg_cluster_member + tg_node_cluster_config + tg_network_config. All
## Trustgrid config resources depend on the node being online, which is gated
## by data.tg_node.timeout.

terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
    tg = {
      source  = "trustgrid/tg"
      version = "~> 2.2"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

provider "tg" {
  api_host = var.tg_api_host
  org_id   = var.tg_org_id
}

## ─── Trustgrid licenses ────────────────────────────────────────────────────────
##
## tg_license creates a node in the Trustgrid control plane and returns a JWT
## license string. The license is then injected into the compute instance as
## instance metadata so the Trustgrid agent can register automatically on first
## boot. Each node needs its own license because each license is tied to a single
## node identity (FQDN / UID).

resource "tg_license" "node_a" {
  name = "${var.cluster_name}-gw-a"
}

resource "tg_license" "node_b" {
  name = "${var.cluster_name}-gw-b"
}

## ─── Service accounts ──────────────────────────────────────────────────────────
##
## Each gateway node gets a dedicated service account. Both accounts are
## collected into a list that is passed to the cluster route role module so a
## single binding grants both nodes the route-manager role.

module "node_a_sa" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_node_service_account?ref=v0.10.0"

  account_id   = "${var.cluster_name}-gw-a-sa"
  display_name = "Trustgrid Gateway SA — ${var.cluster_name}-gw-a"
  project      = var.project
}

module "node_b_sa" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_node_service_account?ref=v0.10.0"

  account_id   = "${var.cluster_name}-gw-b-sa"
  display_name = "Trustgrid Gateway SA — ${var.cluster_name}-gw-b"
  project      = var.project
}

## ─── HA route role ─────────────────────────────────────────────────────────────
##
## The cluster route role grants compute.routes.{list,get,create,delete} to both
## gateway service accounts at project scope. GCP routes are project-global, so
## the IAM binding must be project-level.

module "cluster_route_role" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/iam/trustgrid_cluster_route_role?ref=v0.10.0"

  project = var.project

  ## Bind both gateway service accounts to the route-manager role
  service_account_emails = [
    module.node_a_sa.email,
    module.node_b_sa.email,
  ]
}

## ─── Firewall rules ────────────────────────────────────────────────────────────
##
## Gateway nodes need three sets of firewall rules:
##   1. trustgrid_mgmt_firewall  — egress to control plane, DNS, metadata server
##   2. trustgrid_gateway_firewall — ingress on TCP/UDP 8443 from edge nodes
##   3. heartbeat rule (below) — TCP 9000 between data subnet CIDRs for HA

module "mgmt_firewall" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_mgmt_firewall?ref=v0.10.0"

  name_prefix = var.cluster_name
  network     = var.management_vpc_network
  target_tags = ["trustgrid-gateway"]
}

module "gateway_firewall" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_gateway_firewall?ref=v0.10.0"

  name_prefix = var.cluster_name
  network     = var.management_vpc_network
  target_tags = ["trustgrid-gateway"]

  ## Gateway port — 8443 is the Trustgrid default
  gateway_port = 8443
}

## ─── Heartbeat firewall ─────────────────────────────────────────────────────────
##
## HA cluster nodes exchange heartbeat (gossip) traffic on TCP var.heartbeat_port
## over the data network. This rule allows traffic between the two data subnet
## CIDRs so that both nodes can maintain mutual health-monitoring sessions.
##
## Source/destination: node_a_data_subnet_cidr ↔ node_b_data_subnet_cidr
## Protocol/port:      TCP var.heartbeat_port (default 9000)

resource "google_compute_firewall" "heartbeat" {
  name    = "${var.cluster_name}-heartbeat"
  network = var.data_vpc_network

  description = "Allow Trustgrid HA cluster heartbeat traffic (TCP ${var.heartbeat_port}) between gateway node data interfaces."

  direction = "INGRESS"

  source_ranges = [
    var.node_a_data_subnet_cidr,
    var.node_b_data_subnet_cidr,
  ]

  target_tags = ["trustgrid-gateway"]

  allow {
    protocol = "tcp"
    ports    = ["${var.heartbeat_port}"]
  }
}

## ─── Gateway node A ────────────────────────────────────────────────────────────
##
## Node A is in zone_a with automatic registration. The license JWT from
## tg_license.node_a is injected as instance metadata — the Trustgrid agent
## detects it on first boot, registers the node, and connects to the control plane.

module "gateway_node_a" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.10.0"

  ## Identity
  name = "${var.cluster_name}-gw-a"
  zone = var.zone_a

  ## Registration — auto mode using license from tg_license resource
  registration_mode = "auto"
  license           = tg_license.node_a.license
  registration_key  = var.tg_registration_key

  ## Network — consume existing subnets; node A uses its own management + data subnets
  management_subnetwork = var.management_subnetwork_a
  data_subnetwork       = var.data_subnetwork_a

  ## Apply the gateway tag so all firewall rules above target this node
  network_tags = ["trustgrid-gateway"]

  ## Public exposure — module-managed static external IP per node
  public_exposure_mode = "direct_static_ip"

  ## IAM — use the node-specific service account
  service_account_email = module.node_a_sa.email
}

## ─── Gateway node B ────────────────────────────────────────────────────────────
##
## Node B is in zone_b for cross-zone HA. It has its own static external IP.
## Edge nodes can be configured to connect to either gateway IP.

module "gateway_node_b" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.10.0"

  ## Identity
  name = "${var.cluster_name}-gw-b"
  zone = var.zone_b

  ## Registration — auto mode using license from tg_license resource
  registration_mode = "auto"
  license           = tg_license.node_b.license
  registration_key  = var.tg_registration_key

  ## Network — consume existing subnets; node B uses its own management + data subnets
  management_subnetwork = var.management_subnetwork_b
  data_subnetwork       = var.data_subnetwork_b

  ## Apply the gateway tag so all firewall rules above target this node
  network_tags = ["trustgrid-gateway"]

  ## Public exposure — module-managed static external IP per node
  public_exposure_mode = "direct_static_ip"

  ## IAM — use the node-specific service account
  service_account_email = module.node_b_sa.email
}

## ─── Trustgrid cluster ─────────────────────────────────────────────────────────
##
## tg_cluster creates the cluster object in Trustgrid. Both nodes will be joined
## to this cluster via tg_cluster_member resources below. The cluster FQDN is
## used in tg_network_config for cluster-level cloud route advertisement.

resource "tg_cluster" "main" {
  name = var.cluster_name
}

## ─── Node online readiness gates ───────────────────────────────────────────────
##
## data.tg_node blocks until the specified node UID appears as online in the
## Trustgrid control plane (up to var.tg_node_timeout seconds). This gate
## prevents tg_cluster_member, tg_node_cluster_config, and tg_network_config
## from being applied before the nodes are ready to receive configuration.
##
## Dependency: tg_license outputs the UID after the node is created in the
## control plane. The compute instance must boot, run the registration agent,
## and connect to the control plane before this data source resolves.

data "tg_node" "node_a" {
  uid     = tg_license.node_a.uid
  timeout = var.tg_node_timeout

  depends_on = [module.gateway_node_a]
}

data "tg_node" "node_b" {
  uid     = tg_license.node_b.uid
  timeout = var.tg_node_timeout

  depends_on = [module.gateway_node_b]
}

## ─── Cluster membership ────────────────────────────────────────────────────────
##
## tg_cluster_member joins each node to the Trustgrid cluster. Both nodes must
## be online (gated by data.tg_node above) before cluster membership is applied.
## cluster_fqdn references the FQDN output from the tg_cluster resource.

resource "tg_cluster_member" "node_a" {
  cluster_fqdn = tg_cluster.main.fqdn
  node_id      = data.tg_node.node_a.id

  depends_on = [
    tg_cluster.main,
    data.tg_node.node_a,
  ]
}

resource "tg_cluster_member" "node_b" {
  cluster_fqdn = tg_cluster.main.fqdn
  node_id      = data.tg_node.node_b.id

  depends_on = [
    tg_cluster.main,
    data.tg_node.node_b,
  ]
}

## ─── Interface name discovery ──────────────────────────────────────────────────
##
## tg_node_iface_names returns the OS-level interface names for each NIC on
## the node. Trustgrid gateway nodes have at least two NICs:
##   interfaces[0] — management NIC (WAN / nic0)
##   interfaces[1] — data NIC (LAN / nic1)
##
## The OS name is used in tg_network_config and tg_node_cluster_config to
## reference the correct interface by its kernel name (e.g. "ens4", "ens5").
##
## These data sources depend on the node being online via the readiness gate.

data "tg_node_iface_names" "node_a" {
  node_id = data.tg_node.node_a.id

  depends_on = [data.tg_node.node_a]
}

data "tg_node_iface_names" "node_b" {
  node_id = data.tg_node.node_b.id

  depends_on = [data.tg_node.node_b]
}

## ─── Node cluster gossip config ────────────────────────────────────────────────
##
## tg_node_cluster_config sets the HA gossip (heartbeat) host and port for each
## node. The host is the data NIC internal IP of the respective node — gossip
## traffic travels over the data network, never the management network.
##
## port defaults to var.heartbeat_port (9000) to match the GCP heartbeat
## firewall rule created above.

resource "tg_node_cluster_config" "node_a" {
  node_id = data.tg_node.node_a.id
  host    = module.gateway_node_a.data_nic_internal_ip
  port    = var.heartbeat_port
  enabled = true

  depends_on = [tg_cluster_member.node_a]
}

resource "tg_node_cluster_config" "node_b" {
  node_id = data.tg_node.node_b.id
  host    = module.gateway_node_b.data_nic_internal_ip
  port    = var.heartbeat_port
  enabled = true

  depends_on = [tg_cluster_member.node_b]
}

## ─── Per-node network config ───────────────────────────────────────────────────
##
## tg_network_config sets the LAN interface configuration and static routes on
## each node. This is required so each node can reach the OTHER node's data
## subnet for heartbeat traffic — GCP cross-subnet routing requires an explicit
## next-hop route when the subnets are in different subnets.
##
## Route logic:
##   Node A: add route to node_b_data_subnet_cidr via .1 of node B's subnet
##   Node B: add route to node_a_data_subnet_cidr via .1 of node A's subnet
##
## The data NIC interface name is discovered via data.tg_node_iface_names —
## interfaces[1] is the LAN/data NIC (index 0 is management).

resource "tg_network_config" "node_a" {
  node_id = data.tg_node.node_a.id

  interface {
    ## LAN / data NIC — use OS-level name discovered from node iface data source
    nic  = data.tg_node_iface_names.node_a.interfaces[1].os_name
    dhcp = true

    ## Static route to node B's data subnet, next-hop = first usable IP in that subnet
    route {
      route       = var.node_b_data_subnet_cidr
      description = "Route to node B data subnet for HA heartbeat"
      next_hop    = cidrhost(var.node_b_data_subnet_cidr, 1)
    }
  }

  depends_on = [
    data.tg_node_iface_names.node_a,
    tg_node_cluster_config.node_a,
  ]
}

resource "tg_network_config" "node_b" {
  node_id = data.tg_node.node_b.id

  interface {
    ## LAN / data NIC — use OS-level name discovered from node iface data source
    nic  = data.tg_node_iface_names.node_b.interfaces[1].os_name
    dhcp = true

    ## Static route to node A's data subnet, next-hop = first usable IP in that subnet
    route {
      route       = var.node_a_data_subnet_cidr
      description = "Route to node A data subnet for HA heartbeat"
      next_hop    = cidrhost(var.node_a_data_subnet_cidr, 1)
    }
  }

  depends_on = [
    data.tg_node_iface_names.node_b,
    tg_node_cluster_config.node_b,
  ]
}

## ─── Cluster-level network config ──────────────────────────────────────────────
##
## The cluster-level tg_network_config declares a cloud_route on the data NIC
## of the active cluster member. When a failover event occurs, the active node
## uses this route advertisement to update GCP project routes so that
## var.cluster_route_cidr is pointed at the current active node.
##
## cluster_fqdn targets the cluster object (not a single node). The LAN
## interface name is sourced from node A's iface discovery — both nodes use the
## same OS-level NIC name on identical GCP Compute Engine instance types.

resource "tg_network_config" "cluster" {
  cluster_fqdn = tg_cluster.main.fqdn

  interface {
    ## LAN / data NIC — reuse OS name from node A (both nodes have same interface layout)
    nic  = data.tg_node_iface_names.node_a.interfaces[1].os_name
    dhcp = true

    cloud_route {
      route       = var.cluster_route_cidr
      description = "Cluster cloud route — active node advertises this CIDR to GCP"
    }
  }

  depends_on = [
    tg_cluster_member.node_a,
    tg_cluster_member.node_b,
    data.tg_node_iface_names.node_a,
  ]
}
