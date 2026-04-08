terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

## ─── Control-plane egress ──────────────────────────────────────────────────────
##
## Trustgrid nodes must reach the Trustgrid control plane over TCP 443 and
## TCP 8443 to register and maintain their management tunnel.
## Source: https://docs.trustgrid.io/help-center/kb/site-requirements/
##
## The default destination CIDRs are the published Trustgrid control plane
## address blocks. Override via `control_plane_cidr_ranges` if your
## environment routes control-plane traffic through a proxy or NVA.

resource "google_compute_firewall" "control_plane_egress" {
  name    = "${var.name_prefix}-cp-egress"
  network = var.network

  description = "Allow Trustgrid management interface egress to the Trustgrid control plane (TCP 443 and TCP 8443). Required on ALL nodes for registration and ongoing management connectivity."
  direction   = "EGRESS"
  priority    = var.priority

  destination_ranges = var.control_plane_cidr_ranges

  allow {
    protocol = "tcp"
    ports    = ["443", "8443"]
  }

  ## Scope to nodes carrying the supplied tag(s). An empty list means the rule
  ## applies to all instances in the VPC — avoid empty lists in production.
  target_tags = var.target_tags

  log_config {
    metadata = var.enable_logging ? "INCLUDE_ALL_METADATA" : "EXCLUDE_ALL_METADATA"
  }
}

## ─── DNS egress ────────────────────────────────────────────────────────────────
##
## Nodes resolve *.trustgrid.io endpoints via DNS. The rule permits TCP/UDP 53
## to the DNS servers supplied by the caller. Default is Google Public DNS
## (8.8.8.8/32 and 8.8.4.4/32); override with your VPC or on-premises resolvers.

resource "google_compute_firewall" "dns_egress" {
  count = var.enable_dns_egress ? 1 : 0

  name    = "${var.name_prefix}-dns-egress"
  network = var.network

  description = "Allow Trustgrid management interface egress to DNS resolvers (TCP/UDP 53). Nodes must resolve trustgrid.io endpoints."
  direction   = "EGRESS"
  priority    = var.priority

  destination_ranges = var.dns_server_cidr_ranges

  allow {
    protocol = "tcp"
    ports    = ["53"]
  }

  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  target_tags = var.target_tags

  log_config {
    metadata = var.enable_logging ? "INCLUDE_ALL_METADATA" : "EXCLUDE_ALL_METADATA"
  }
}

## ─── GCP metadata server egress ────────────────────────────────────────────────
##
## The Trustgrid bootstrap script and the node agent read instance metadata
## (license key, registration key, zone, etc.) from the link-local metadata
## server at 169.254.169.254. This egress rule is required for both auto and
## manual registration modes.

resource "google_compute_firewall" "metadata_egress" {
  count = var.enable_metadata_server_egress ? 1 : 0

  name    = "${var.name_prefix}-metadata-egress"
  network = var.network

  description = "Allow Trustgrid management interface egress to the GCP instance metadata server (169.254.169.254:80). Required to retrieve instance metadata on first boot and during normal operation."
  direction   = "EGRESS"
  priority    = var.priority

  destination_ranges = ["169.254.169.254/32"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = var.target_tags

  log_config {
    metadata = var.enable_logging ? "INCLUDE_ALL_METADATA" : "EXCLUDE_ALL_METADATA"
  }
}
