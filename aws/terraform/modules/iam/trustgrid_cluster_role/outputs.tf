output "profile_name" {
  description = "Name of the IAM instance profile — pass this to the node module's instance_profile_name input."
  value       = aws_iam_instance_profile.trustgrid_cluster.name
}

output "role" {
  description = "The IAM role resource."
  value       = aws_iam_role.trustgrid_cluster
}
