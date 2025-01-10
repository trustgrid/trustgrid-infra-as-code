# Trustgrid Single Node Auto Registration Module
This module deploys a single Trustgrid module on an EC2 instance in AWS and automatically registers with the Trustgrid control plane. It handles the creation of the following AWS resources :
- EIP to be used for the EC2 instance outside/public interface
- Outside/public interface with EIP attached
- Inside/private interface
- Security group attached to the outside interface. Optionally, it will include open ports for Trustgrid gateway services.
- EC2 instance attached to both interfaces built off the Trustgrid AMI image running the latest Trustgrid software
- On boot, the Trustgrid license is used to register the node with the Trustgrid control plane
- The module will then use the Trustgrid terraform provider to verify that the node has successfully registered with the Trustgrid control plane. 


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 2.7.0 |
| <a name="requirement_tg"></a> [tg](#requirement\_tg) | >= 1.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 2.7.0 |
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | n/a |
| <a name="provider_tg"></a> [tg](#provider\_tg) | >= 1.4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.mgmt_ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_instance.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_network_interface.data_eni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.management_eni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_security_group.node_mgmt_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.tcp_443](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.tcp_8443](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.udp_51820](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.udp_8443](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ami.trustgrid-node-ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_instance_profile.instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_instance_profile) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet.mgmt_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [cloudinit_config.cloud_init](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [tg_node.node](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/data-sources/node) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_data_security_group_ids"></a> [data\_security\_group\_ids](#input\_data\_security\_group\_ids) | Security group IDs for the data interface | `list` | n/a | yes |
| <a name="input_data_subnet_id"></a> [data\_subnet\_id](#input\_data\_subnet\_id) | Subnet ID for data traffic | `string` | n/a | yes |
| <a name="input_enroll_endpoint"></a> [enroll\_endpoint](#input\_enroll\_endpoint) | Determines which Trustgrid Tenant the node is registered to | `string` | `"https://keymaster.trustgrid.io/v2/enroll"` | no |
| <a name="input_instance_profile_name"></a> [instance\_profile\_name](#input\_instance\_profile\_name) | IAM Instance Profile the Trustgrid EC2 node will use | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Node instance type | `string` | `"t3.small"` | no |
| <a name="input_is_appgateway"></a> [is\_appgateway](#input\_is\_appgateway) | Determines if security group should allow port 443 inbound for Application Gateway | `bool` | `false` | no |
| <a name="input_is_tggateway"></a> [is\_tggateway](#input\_is\_tggateway) | Determines if security group should allow tcp/udp port 8443 inbound for Trustgrid Tunnels | `bool` | `false` | no |
| <a name="input_is_wggateway"></a> [is\_wggateway](#input\_is\_wggateway) | Determines if security group should allow port 51820 inbound for Wireguard | `bool` | `false` | no |
| <a name="input_key_pair_name"></a> [key\_pair\_name](#input\_key\_pair\_name) | AWS Key Pair for ubuntu user in EC2 instance | `string` | n/a | yes |
| <a name="input_license"></a> [license](#input\_license) | The Trustgrid license given from the API or Portal | `string` | n/a | yes |
| <a name="input_management_security_group_ids"></a> [management\_security\_group\_ids](#input\_management\_security\_group\_ids) | Security group IDs for the management interface | `list` | n/a | yes |
| <a name="input_management_subnet_id"></a> [management\_subnet\_id](#input\_management\_subnet\_id) | Subnet ID for management traffic (needs to be able to reach the internet) | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Instance name | `string` | n/a | yes |
| <a name="input_root_block_device_encrypt"></a> [root\_block\_device\_encrypt](#input\_root\_block\_device\_encrypt) | Should the root device be encrypted in AWS | `bool` | `true` | no |
| <a name="input_root_block_device_size"></a> [root\_block\_device\_size](#input\_root\_block\_device\_size) | Size of the root volume in GB | `number` | `30` | no |
| <a name="input_tg_fqdn"></a> [tg\_fqdn](#input\_tg\_fqdn) | FQDN of the Trustgrid Node associated with the license | `string` | n/a | yes |
| <a name="input_tg_node_timeout"></a> [tg\_node\_timeout](#input\_tg\_node\_timeout) | Number of seconds to wait to confirm the node is online via the Trustgrid API before failing | `number` | `600` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_node-data-private-ip"></a> [node-data-private-ip](#output\_node-data-private-ip) | n/a |
| <a name="output_node-instance-ami-id"></a> [node-instance-ami-id](#output\_node-instance-ami-id) | n/a |
| <a name="output_node-instance-id"></a> [node-instance-id](#output\_node-instance-id) | n/a |
| <a name="output_node-mgmt-private-ip"></a> [node-mgmt-private-ip](#output\_node-mgmt-private-ip) | n/a |
| <a name="output_node-mgmt-public-ip"></a> [node-mgmt-public-ip](#output\_node-mgmt-public-ip) | n/a |
| <a name="output_node-security-group-id"></a> [node-security-group-id](#output\_node-security-group-id) | n/a |
| <a name="output_tg_node"></a> [tg\_node](#output\_tg\_node) | n/a |
<!-- END_TF_DOCS -->