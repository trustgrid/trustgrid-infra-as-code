## ─── Custom role outputs ───────────────────────────────────────────────────────

output "custom_role_id" {
  description = "The role ID of the custom IAM role, in the form projects/<project>/roles/<role_id>."
  value       = google_project_iam_custom_role.route_manager.id
}

output "custom_role_name" {
  description = "The resource name of the custom IAM role, e.g. projects/<project>/roles/trustgridRouteManager."
  value       = google_project_iam_custom_role.route_manager.name
}

## ─── Binding outputs ───────────────────────────────────────────────────────────

output "iam_binding_etag" {
  description = "ETag of the project IAM binding resource. Can be used to detect out-of-band changes to the binding."
  value       = google_project_iam_binding.route_manager.etag
}

output "bound_members" {
  description = "List of IAM member strings that have been bound to the custom route-manager role (each in serviceAccount:<email> form)."
  value       = google_project_iam_binding.route_manager.members
}
