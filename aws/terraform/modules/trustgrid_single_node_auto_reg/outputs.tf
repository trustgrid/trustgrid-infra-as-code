output "node-instance-id" {
  description = "ID of the Trustgrid node EC2 instance."
  value       = aws_instance.node.id
}

output "node-instance-ami-id" {
  description = "AMI ID the instance was launched from: either trustgrid_ami_id or the gen2/gen3 image resolved from instance_type."
  value       = aws_instance.node.ami
}

output "node-mgmt-public-ip" {
  description = "Elastic IP attached to the management (outside) interface."
  value       = aws_eip.mgmt_ip.public_ip
}

output "node-mgmt-private-ip" {
  description = "Private IP of the management (outside) interface."
  value       = one(aws_network_interface.management_eni.private_ips)
}

output "node-data-private-ip" {
  description = "Private IP of the data (inside) interface."
  value       = one(aws_network_interface.data_eni.private_ips)
}

output "node-security-group-id" {
  description = "ID of the security group created for the management interface."
  value       = aws_security_group.node_mgmt_sg.id
}
