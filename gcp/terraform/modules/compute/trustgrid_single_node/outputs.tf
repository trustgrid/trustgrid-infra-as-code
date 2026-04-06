## ─── Compute instance outputs ──────────────────────────────────────────────────

output "instance_id" {
  description = "Server-assigned unique identifier of the Compute Engine instance."
  value       = google_compute_instance.node.instance_id
}

output "instance_name" {
  description = "Name of the created Compute Engine instance."
  value       = google_compute_instance.node.name
}

output "instance_self_link" {
  description = "Self-link URI of the Compute Engine instance."
  value       = google_compute_instance.node.self_link
}

## ─── Network interface outputs ─────────────────────────────────────────────────

output "management_nic_internal_ip" {
  description = "Internal (RFC-1918) IP address assigned to the management interface (nic0)."
  value       = google_compute_instance.node.network_interface[0].network_ip
}

output "data_nic_internal_ip" {
  description = "Internal (RFC-1918) IP address assigned to the data interface (nic1)."
  value       = google_compute_instance.node.network_interface[1].network_ip
}
