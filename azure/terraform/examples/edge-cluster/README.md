## Terraform Edge Cluster Example
This example demonstrates how to deploy a cluster of edge nodes using Terraform.  It also creates several resources that may already exist in your environment, such as the resources group, a virtual network, subnet, and a security group. If these resources already exist, you should modify your Terraform code to reference them and remove the resources that are created by this example.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.15.0 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | ~> 2.3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.15.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_az_node1"></a> [az\_node1](#module\_az\_node1) | github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/compute/trustgrid_single_node_manual_reg | v0.2.0 |
| <a name="module_az_node2"></a> [az\_node2](#module\_az\_node2) | github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/compute/trustgrid_single_node_auto_reg | v0.2.0 |
| <a name="module_trustgrid_cluster_ip_role"></a> [trustgrid\_cluster\_ip\_role](#module\_trustgrid\_cluster\_ip\_role) | github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/authorization/trustgrid_cluster_ip_role | v0.2.0 |
| <a name="module_trustgrid_cluster_route_role"></a> [trustgrid\_cluster\_route\_role](#module\_trustgrid\_cluster\_route\_role) | github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/authorization/trustgrid_cluster_route_role | v0.2.0 |
| <a name="module_trustgrid_outbound_cp_rules"></a> [trustgrid\_outbound\_cp\_rules](#module\_trustgrid\_outbound\_cp\_rules) | github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/network/trustgrid_outbound_control_plane_security_group_rules | v0.2.0 |
| <a name="module_trustgrid_outbound_dp_rules"></a> [trustgrid\_outbound\_dp\_rules](#module\_trustgrid\_outbound\_dp\_rules) | github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/network/trustgrid_outbound_data_plane_security_group_rules | 6-add-tf-autoregistration-scripts-to-azure-examples |

## Resources

| Name | Type |
|------|------|
| [azurerm_network_security_group.private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.public](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_resource_group.trustgrid](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.az_node1_cluster_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.az_node1_cluster_route_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.az_node2_cluster_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.az_node2_cluster_route_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_subnet.private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.public](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_ssh_key_pub"></a> [admin\_ssh\_key\_pub](#input\_admin\_ssh\_key\_pub) | Public Key for SSH access to the virtual machines. External SSH is disabled during registration, but a key is required by Azure to create the VM and may be needed if there are issues registering. | `string` | n/a | yes |
| <a name="input_az_node1_name"></a> [az\_node1\_name](#input\_az\_node1\_name) | Name for the first Edge node VM, environment prefix will be prepended | `string` | n/a | yes |
| <a name="input_az_node1_zone"></a> [az\_node1\_zone](#input\_az\_node1\_zone) | Availability zone for the first Edge node VM | `number` | n/a | yes |
| <a name="input_az_node2_name"></a> [az\_node2\_name](#input\_az\_node2\_name) | Name for the second Edge node VM, environment prefix will be prepended | `string` | n/a | yes |
| <a name="input_az_node2_zone"></a> [az\_node2\_zone](#input\_az\_node2\_zone) | Availability zone for the second Edge node VM | `number` | n/a | yes |
| <a name="input_data_plane_enable_udp"></a> [data\_plane\_enable\_udp](#input\_data\_plane\_enable\_udp) | Enable UDP rules in addition to TCP rules | `bool` | `true` | no |
| <a name="input_data_plane_endpoints"></a> [data\_plane\_endpoints](#input\_data\_plane\_endpoints) | List of destination IP and port combinations to allow outbound access. The IP field accepts both single IPs and CIDR ranges. Example: [{ip = "10.0.0.0/24", port = 8443, suffix = "internal", description = "Internal network access"}, {ip = "192.168.1.1", port = 8443, suffix = "external", description = "External endpoint access"}]. The port field accepts a single port number. | <pre>list(object({<br/>    ip          = string<br/>    port        = number<br/>    suffix      = string<br/>    description = string<br/>  }))</pre> | n/a | yes |
| <a name="input_environment_prefix"></a> [environment\_prefix](#input\_environment\_prefix) | The prefix used for all resources in this environment | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The location/region where the resources will be created | `string` | n/a | yes |
| <a name="input_private_cidr"></a> [private\_cidr](#input\_private\_cidr) | The CIDR block for the private subnet | `string` | n/a | yes |
| <a name="input_public_cidr"></a> [public\_cidr](#input\_public\_cidr) | The CIDR block for the public subnet | `string` | n/a | yes |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | The subscription ID where the resources will be created | `string` | n/a | yes |
| <a name="input_vnet_cidr"></a> [vnet\_cidr](#input\_vnet\_cidr) | The CIDR block for the virtual network | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_az_node1_mac_address"></a> [az\_node1\_mac\_address](#output\_az\_node1\_mac\_address) | az\_node1 mac address |
| <a name="output_az_node1_name"></a> [az\_node1\_name](#output\_az\_node1\_name) | az\_node1 vm name |
| <a name="output_az_node1_public_ip"></a> [az\_node1\_public\_ip](#output\_az\_node1\_public\_ip) | az\_node1 public ip |
| <a name="output_az_node2_mac_address"></a> [az\_node2\_mac\_address](#output\_az\_node2\_mac\_address) | az\_node2 mac address |
| <a name="output_az_node2_name"></a> [az\_node2\_name](#output\_az\_node2\_name) | az\_node2 vm name |
| <a name="output_az_node2_public_ip"></a> [az\_node2\_public\_ip](#output\_az\_node2\_public\_ip) | az\_node2 public ip |
<!-- END_TF_DOCS -->