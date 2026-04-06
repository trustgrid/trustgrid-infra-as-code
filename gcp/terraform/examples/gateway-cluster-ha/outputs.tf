## ─── Node A outputs ────────────────────────────────────────────────────────────

output "node_a_name" {
  description = "Name of gateway node A Compute Engine instance."
  value       = module.gateway_node_a.instance_name
}

output "node_a_self_link" {
  description = "Self-link URI of gateway node A."
  value       = module.gateway_node_a.instance_self_link
}

output "node_a_external_ip" {
  description = "Static external IP address of gateway node A management interface (nic0). Configure edge nodes to connect to this IP."
  value       = module.gateway_node_a.management_external_ip
}

output "node_a_internal_ip" {
  description = "Internal IP address of gateway node A management interface (nic0)."
  value       = module.gateway_node_a.management_nic_internal_ip
}

output "node_a_data_ip" {
  description = "Internal IP address of gateway node A data interface (nic1)."
  value       = module.gateway_node_a.data_nic_internal_ip
}

## ─── Node B outputs ────────────────────────────────────────────────────────────

output "node_b_name" {
  description = "Name of gateway node B Compute Engine instance."
  value       = module.gateway_node_b.instance_name
}

output "node_b_self_link" {
  description = "Self-link URI of gateway node B."
  value       = module.gateway_node_b.instance_self_link
}

output "node_b_external_ip" {
  description = "Static external IP address of gateway node B management interface (nic0). Configure edge nodes to connect to this IP."
  value       = module.gateway_node_b.management_external_ip
}

output "node_b_internal_ip" {
  description = "Internal IP address of gateway node B management interface (nic0)."
  value       = module.gateway_node_b.management_nic_internal_ip
}

output "node_b_data_ip" {
  description = "Internal IP address of gateway node B data interface (nic1)."
  value       = module.gateway_node_b.data_nic_internal_ip
}

## ─── IAM outputs ───────────────────────────────────────────────────────────────

output "node_a_service_account_email" {
  description = "Email of the service account attached to gateway node A."
  value       = module.node_a_sa.email
}

output "node_b_service_account_email" {
  description = "Email of the service account attached to gateway node B."
  value       = module.node_b_sa.email
}

output "cluster_route_role_id" {
  description = "Resource ID of the custom IAM route-manager role bound to both gateway service accounts."
  value       = module.cluster_route_role.custom_role_id
}

output "cluster_bound_members" {
  description = "IAM members (serviceAccount:<email>) bound to the cluster route-manager role."
  value       = module.cluster_route_role.bound_members
}
