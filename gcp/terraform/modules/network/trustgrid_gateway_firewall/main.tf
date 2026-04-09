terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

## ─── Gateway ingress — TCP/UDP 8443 ───────────────────────────────────────────
##
## Trustgrid gateway nodes accept inbound tunnel traffic from edge nodes on
## TCP/UDP 8443. This rule should be applied to the management (WAN) VPC
## network only.
##
## Source: https://docs.trustgrid.io/tutorials/deployments/deploy-gcp/
## "Inbound TCP/UDP 8443 on the Management network is only required if the node
##  will act as a gateway. Edge nodes do not require any inbound Management
##  firewall rules."
##
## By default, ingress is allowed from any IPv4 source (0.0.0.0/0). For
## deployments where the set of peer edge node IPs is known and static, restrict
## source_ranges to those CIDRs to achieve a tighter least-privilege posture.

resource "google_compute_firewall" "gateway_ingress" {
  name    = "${var.name_prefix}-gw-ingress"
  network = var.network

  description = "Allow inbound TCP/UDP 8443 to Trustgrid gateway nodes from edge node source ranges. Required on gateway nodes only; edge nodes do not need inbound rules on the management interface."
  direction   = "INGRESS"
  priority    = var.priority

  source_ranges = var.source_ranges

  ## TCP is always permitted.
  allow {
    protocol = "tcp"
    ports    = ["${var.gateway_port}"]
  }

  ## UDP is optional (recommended). Improves tunnel performance but can be
  ## disabled if network policy restricts inbound UDP.
  dynamic "allow" {
    for_each = var.enable_udp_ingress ? [1] : []
    content {
      protocol = "udp"
      ports    = ["${var.gateway_port}"]
    }
  }

  ## Scope to instances carrying the supplied tag(s). An empty list means the
  ## rule applies to all instances in the VPC — always set target_tags in
  ## production to limit blast radius.
  target_tags = var.target_tags

  log_config {
    metadata = var.enable_logging ? "INCLUDE_ALL_METADATA" : "EXCLUDE_ALL_METADATA"
  }
}
