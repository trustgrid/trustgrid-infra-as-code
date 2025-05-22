output "trustgrid-instance-profile-name" {
    value = aws_iam_instance_profile.trustgrid-instance-profile.name
}

output "trustgrid-node-iam-role"  {
    value = aws_iam_role.trustgrid-node
}