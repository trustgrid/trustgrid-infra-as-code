## ─── Firewall rule outputs ─────────────────────────────────────────────────────

output "gateway_ingress_rule_name" {
  description = "Name of the gateway ingress firewall rule (TCP/UDP 8443 ingress to gateway nodes)."
  value       = google_compute_firewall.gateway_ingress.name
}

output "gateway_ingress_rule_self_link" {
  description = "Self-link of the gateway ingress firewall rule."
  value       = google_compute_firewall.gateway_ingress.self_link
}
