output "profile_name" {
    value = aws_iam_instance_profile.trustgrid-instance-profile.name
}

output "role"  {
    value = aws_iam_role.trustgrid-node
}