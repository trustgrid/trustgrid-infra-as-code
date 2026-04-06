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

## ─── External IP outputs ───────────────────────────────────────────────────────

output "management_external_ip" {
  description = "Effective external IP address attached to the management interface (nic0). Non-null when public_exposure_mode is 'direct_static_ip' or 'byo_public_ip'. Null when public_exposure_mode is 'private_only'."
  value       = local.management_external_ip
}

output "management_external_ip_self_link" {
  description = "Self-link of the module-managed static external IP address resource. Non-null only when public_exposure_mode is 'direct_static_ip'. Use this to reference the address resource in other Terraform configurations."
  value       = var.public_exposure_mode == "direct_static_ip" ? google_compute_address.management_external[0].self_link : null
}
