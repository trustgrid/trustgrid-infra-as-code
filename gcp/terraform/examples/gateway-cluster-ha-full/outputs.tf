## ─── GCP node A outputs ────────────────────────────────────────────────────────

output "gateway_a_external_ip" {
  description = "Static external IP address of gateway node A management interface (nic0). Configure edge nodes to connect to this IP."
  value       = module.gateway_node_a.management_external_ip
}

output "gateway_a_internal_ip" {
  description = "Internal IP address of gateway node A management interface (nic0)."
  value       = module.gateway_node_a.management_nic_internal_ip
}

output "gateway_a_data_ip" {
  description = "Internal IP address of gateway node A data interface (nic1). Used as the heartbeat host in tg_node_cluster_config."
  value       = module.gateway_node_a.data_nic_internal_ip
}

output "gateway_a_name" {
  description = "Name of gateway node A Compute Engine instance."
  value       = module.gateway_node_a.instance_name
}

## ─── GCP node B outputs ────────────────────────────────────────────────────────

output "gateway_b_external_ip" {
  description = "Static external IP address of gateway node B management interface (nic0). Configure edge nodes to connect to this IP."
  value       = module.gateway_node_b.management_external_ip
}

output "gateway_b_internal_ip" {
  description = "Internal IP address of gateway node B management interface (nic0)."
  value       = module.gateway_node_b.management_nic_internal_ip
}

output "gateway_b_data_ip" {
  description = "Internal IP address of gateway node B data interface (nic1). Used as the heartbeat host in tg_node_cluster_config."
  value       = module.gateway_node_b.data_nic_internal_ip
}

output "gateway_b_name" {
  description = "Name of gateway node B Compute Engine instance."
  value       = module.gateway_node_b.instance_name
}

## ─── Trustgrid outputs ─────────────────────────────────────────────────────────

output "cluster_fqdn" {
  description = "Trustgrid cluster FQDN. Reference this when configuring edge nodes to connect to the gateway cluster."
  value       = tg_cluster.main.fqdn
}

output "node_a_fqdn" {
  description = "Trustgrid FQDN of gateway node A as registered in the control plane."
  value       = tg_license.node_a.fqdn
}

output "node_b_fqdn" {
  description = "Trustgrid FQDN of gateway node B as registered in the control plane."
  value       = tg_license.node_b.fqdn
}

output "node_a_uid" {
  description = "Trustgrid UID of gateway node A."
  value       = tg_license.node_a.uid
}

output "node_b_uid" {
  description = "Trustgrid UID of gateway node B."
  value       = tg_license.node_b.uid
}

## ─── IAM outputs ───────────────────────────────────────────────────────────────

output "node_a_service_account_email" {
  description = "Email of the GCP service account attached to gateway node A."
  value       = module.node_a_sa.email
}

output "node_b_service_account_email" {
  description = "Email of the GCP service account attached to gateway node B."
  value       = module.node_b_sa.email
}

output "cluster_route_role_id" {
  description = "Resource ID of the custom IAM route-manager role bound to both gateway service accounts."
  value       = module.cluster_route_role.custom_role_id
}

## ─── Firewall outputs ──────────────────────────────────────────────────────────

output "heartbeat_firewall_name" {
  description = "Name of the Google Compute firewall rule that permits HA cluster heartbeat traffic between gateway node data interfaces."
  value       = google_compute_firewall.heartbeat.name
}
