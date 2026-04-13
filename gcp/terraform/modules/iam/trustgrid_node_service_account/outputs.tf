## ─── Service account outputs ───────────────────────────────────────────────────

output "email" {
  description = "Email address of the created service account (e.g. <account_id>@<project>.iam.gserviceaccount.com). Pass this value to the service_account_email variable on the trustgrid_single_node compute module."
  value       = google_service_account.node_sa.email
}

output "unique_id" {
  description = "Unique, stable numeric identifier for the service account. Used to bind IAM policies by unique ID rather than email in certain GCP APIs."
  value       = google_service_account.node_sa.unique_id
}

output "name" {
  description = "Fully-qualified resource name of the service account in the form projects/<project>/serviceAccounts/<email>. Use as the member value (serviceAccount:<email>) in IAM bindings."
  value       = google_service_account.node_sa.name
}

output "member" {
  description = "IAM member string for this service account, formatted as serviceAccount:<email>. Ready to use in google_project_iam_binding or google_project_iam_member resources."
  value       = "serviceAccount:${google_service_account.node_sa.email}"
}
