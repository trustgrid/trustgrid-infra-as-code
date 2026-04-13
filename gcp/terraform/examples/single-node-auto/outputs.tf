## ─── Node outputs ──────────────────────────────────────────────────────────────

output "node_name" {
  description = "Name of the created Compute Engine instance."
  value       = module.node.instance_name
}

output "node_self_link" {
  description = "Self-link URI of the Compute Engine instance."
  value       = module.node.instance_self_link
}

output "management_external_ip" {
  description = "Static external IP address attached to the management interface (nic0). The node registers itself automatically — this IP can be used to verify connectivity or configure DNS."
  value       = module.node.management_external_ip
}

output "management_internal_ip" {
  description = "Internal IP address of the management interface (nic0)."
  value       = module.node.management_nic_internal_ip
}

output "data_internal_ip" {
  description = "Internal IP address of the data interface (nic1)."
  value       = module.node.data_nic_internal_ip
}

## ─── IAM outputs ───────────────────────────────────────────────────────────────

output "service_account_email" {
  description = "Email of the service account attached to the Trustgrid node."
  value       = module.node_sa.email
}
