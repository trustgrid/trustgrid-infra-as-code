## ─── Firewall rule outputs ─────────────────────────────────────────────────────

output "control_plane_egress_rule_name" {
  description = "Name of the control-plane egress firewall rule (TCP 443/8443 → Trustgrid control plane CIDRs)."
  value       = google_compute_firewall.control_plane_egress.name
}

output "control_plane_egress_rule_self_link" {
  description = "Self-link of the control-plane egress firewall rule."
  value       = google_compute_firewall.control_plane_egress.self_link
}

output "dns_egress_rule_name" {
  description = "Name of the DNS egress firewall rule (TCP/UDP 53 → DNS server CIDRs). Null when enable_dns_egress is false."
  value       = var.enable_dns_egress ? google_compute_firewall.dns_egress[0].name : null
}

output "metadata_egress_rule_name" {
  description = "Name of the GCP metadata server egress firewall rule (TCP 80 → 169.254.169.254/32). Null when enable_metadata_server_egress is false."
  value       = var.enable_metadata_server_egress ? google_compute_firewall.metadata_egress[0].name : null
}
