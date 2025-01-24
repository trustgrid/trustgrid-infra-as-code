### Terraform Azure Gateway Cluster Example
This example demonstrates how to deploy a gateway cluster using Terraform.  It also creates several resources that may already exist in your environment, such as the resources group, a virtual network, subnet, and a security group. If these resources already exist, you should modify your Terraform code to reference them and remove the resources that are created by this example.

The example use both the manual and automated registration modules to show how they work. In a real world scenario, you would use only one method to register.  

***NOTE:*** Typically only direct Trustgrid customers deploy their nodes as [Gateways](https://docs.trustgrid.io/docs/nodes/#gateway-nodes).  Most Trustgrid deployments act only as [Edge](https://docs.trustgrid.io/docs/nodes/#edge-nodes) nodes that do not need inbound security group rules. 

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.15.0 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | ~> 2.3.5 |
| <a name="requirement_tg"></a> [tg](#requirement\_tg) | ~> 1.10.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.15.0 |
| <a name="provider_tg"></a> [tg](#provider\_tg) | ~> 1.10.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_az_gw1"></a> [az\_gw1](#module\_az\_gw1) | github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/compute/trustgrid_single_node_manual_reg | v0.1.0 |
| <a name="module_az_gw2"></a> [az\_gw2](#module\_az\_gw2) | github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/compute/trustgrid_single_node_auto_reg | v0.1.0 |
| <a name="module_trustgrid_cluster_ip_role"></a> [trustgrid\_cluster\_ip\_role](#module\_trustgrid\_cluster\_ip\_role) | github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/authorization/trustgrid_cluster_ip_role | v0.1.0 |
| <a name="module_trustgrid_cluster_route_role"></a> [trustgrid\_cluster\_route\_role](#module\_trustgrid\_cluster\_route\_role) | github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/authorization/trustgrid_cluster_route_role | v0.1.0 |
| <a name="module_trustgrid_gateway_security_group_rules"></a> [trustgrid\_gateway\_security\_group\_rules](#module\_trustgrid\_gateway\_security\_group\_rules) | github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/network/trustgrid_gateway_security_group_rules | v0.1.0 |
| <a name="module_trustgrid_outbound_cp_rules"></a> [trustgrid\_outbound\_cp\_rules](#module\_trustgrid\_outbound\_cp\_rules) | github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/network/trustgrid_outbound_control_plane_security_group_rules | v0.1.0 |
| <a name="module_trustgrid_outbound_dp_rules"></a> [trustgrid\_outbound\_dp\_rules](#module\_trustgrid\_outbound\_dp\_rules) | github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/network/trustgrid_outbound_data_plane_security_group_rules | v0.1.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_network_interface_application_security_group_association.az_gw1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_application_security_group_association) | resource |
| [azurerm_network_interface_application_security_group_association.az_gw2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_application_security_group_association) | resource |
| [azurerm_network_security_group.private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.public](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_resource_group.trustgrid](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.az_gw1_cluster_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.az_gw1_cluster_route_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.az_gw2_cluster_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.az_gw2_cluster_route_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_subnet.private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.public](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [tg_license.az_gw2](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/license) | resource |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |
| [tg_node.az_gw2](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/data-sources/node) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_ssh_key_pub"></a> [admin\_ssh\_key\_pub](#input\_admin\_ssh\_key\_pub) | Public Key for SSH access to the virtual machines. External SSH is disabled during registration, but a key is required by Azure to create the VM and may be needed if there are issues registering. | `string` | n/a | yes |
| <a name="input_az_gw1_name"></a> [az\_gw1\_name](#input\_az\_gw1\_name) | Name for the first gateway VM, environment prefix will be prepended | `string` | n/a | yes |
| <a name="input_az_gw1_zone"></a> [az\_gw1\_zone](#input\_az\_gw1\_zone) | Availability zone for the first gateway VM | `number` | n/a | yes |
| <a name="input_az_gw2_name"></a> [az\_gw2\_name](#input\_az\_gw2\_name) | Name for the second gateway VM, environment prefix will be prepended | `string` | n/a | yes |
| <a name="input_az_gw2_zone"></a> [az\_gw2\_zone](#input\_az\_gw2\_zone) | Availability zone for the second gateway VM | `number` | n/a | yes |
| <a name="input_az_gw_host_name"></a> [az\_gw\_host\_name](#input\_az\_gw\_host\_name) | Name for the gateway host VM, environment prefix will be prepended | `string` | n/a | yes |
| <a name="input_az_gw_host_zone"></a> [az\_gw\_host\_zone](#input\_az\_gw\_host\_zone) | Availability zone for the gateway host VM | `number` | n/a | yes |
| <a name="input_environment_prefix"></a> [environment\_prefix](#input\_environment\_prefix) | The prefix used for all resources in this environment | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The location/region where the resources will be created | `string` | n/a | yes |
| <a name="input_private_cidr"></a> [private\_cidr](#input\_private\_cidr) | The CIDR block for the private subnet | `string` | n/a | yes |
| <a name="input_public_cidr"></a> [public\_cidr](#input\_public\_cidr) | The CIDR block for the public subnet | `string` | n/a | yes |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | The subscription ID where the resources will be created | `string` | n/a | yes |
| <a name="input_tg_api_host"></a> [tg\_api\_host](#input\_tg\_api\_host) | The TrustGrid API host. Defaults to api.trustgrid.io and should not need to be changed. | `string` | `"api.trustgrid.io"` | no |
| <a name="input_vnet_cidr"></a> [vnet\_cidr](#input\_vnet\_cidr) | The CIDR block for the virtual network | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_az_gw1_mac_address"></a> [az\_gw1\_mac\_address](#output\_az\_gw1\_mac\_address) | az\_gw1 mac address |
| <a name="output_az_gw1_name"></a> [az\_gw1\_name](#output\_az\_gw1\_name) | az\_gw1 vm name |
| <a name="output_az_gw1_public_ip"></a> [az\_gw1\_public\_ip](#output\_az\_gw1\_public\_ip) | az\_gw1 public ip |
| <a name="output_az_gw2_mac_address"></a> [az\_gw2\_mac\_address](#output\_az\_gw2\_mac\_address) | az\_gw2 mac address |
| <a name="output_az_gw2_name"></a> [az\_gw2\_name](#output\_az\_gw2\_name) | az\_gw2 vm name |
| <a name="output_az_gw2_public_ip"></a> [az\_gw2\_public\_ip](#output\_az\_gw2\_public\_ip) | az\_gw2 public ip |
<!-- END_TF_DOCS -->