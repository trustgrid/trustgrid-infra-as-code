## TrustGrid Gateway Security Group Rules
This module adds security group rules to an existing security group to allow inbound traffic to Trustgrid appliance-based nodes acting as gateways.  

**NOTE: Most Trustgrid nodes do not act as gateways and therefore do not require these rules.**

The security group rules creates an Application Security Group (ASG) to allow inbound traffic to the Trustgrid appliance. You will need to utilize an `azurerm_network_interface_application_security_group_association` resource to associate the ASG with the **public** network interface of the Trustgrid node.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.15.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.15.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_application_security_group.trustgrid_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_security_group) | resource |
| [azurerm_network_security_rule.data_plane_tcp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.data_plane_udp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.wireguard](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.ztna](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for the resources created by this module | `string` | n/a | yes |
| <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id) | Security group ID for the Trustgrid Gateway rules | `string` | n/a | yes |
| <a name="input_security_group_rule_priority_start"></a> [security\_group\_rule\_priority\_start](#input\_security\_group\_rule\_priority\_start) | Start of the priority range for the Trustgrid Gateway rules. Up to 4 rules will be created, starting at this priority. Ensure that this value is set such that the rules are not overridden by lower priority restrictions, and that they do not conflict with existing rules. | `number` | `200` | no |
| <a name="input_trustgrid_data_plane_gateway_tcp"></a> [trustgrid\_data\_plane\_gateway\_tcp](#input\_trustgrid\_data\_plane\_gateway\_tcp) | Enable TCP for the Trustgrid Data Plane Gateway. | `bool` | `true` | no |
| <a name="input_trustgrid_data_plane_gateway_tcp_port"></a> [trustgrid\_data\_plane\_gateway\_tcp\_port](#input\_trustgrid\_data\_plane\_gateway\_tcp\_port) | TCP Port for the Trustgrid Data Plane Gateway | `string` | `"8443"` | no |
| <a name="input_trustgrid_data_plane_gateway_udp"></a> [trustgrid\_data\_plane\_gateway\_udp](#input\_trustgrid\_data\_plane\_gateway\_udp) | Enable UDP for the Trustgrid Data Plane Gateway | `bool` | `true` | no |
| <a name="input_trustgrid_data_plane_gateway_udp_port"></a> [trustgrid\_data\_plane\_gateway\_udp\_port](#input\_trustgrid\_data\_plane\_gateway\_udp\_port) | TCP Port UDP for the Trustgrid Data Plane Gateway | `string` | `"8443"` | no |
| <a name="input_trustgrid_wireguard_gateway"></a> [trustgrid\_wireguard\_gateway](#input\_trustgrid\_wireguard\_gateway) | Enable Wireguard for the Trustgrid Gateway | `bool` | `false` | no |
| <a name="input_trustgrid_wireguard_gateway_port"></a> [trustgrid\_wireguard\_gateway\_port](#input\_trustgrid\_wireguard\_gateway\_port) | UDP Port for the Trustgrid Wireguard Gateway | `string` | `"51820"` | no |
| <a name="input_trustgrid_ztna_gateway"></a> [trustgrid\_ztna\_gateway](#input\_trustgrid\_ztna\_gateway) | Enable ZTNA for the Trustgrid Gateway | `bool` | `false` | no |
| <a name="input_trustgrid_ztna_gateway_port"></a> [trustgrid\_ztna\_gateway\_port](#input\_trustgrid\_ztna\_gateway\_port) | TCP Port for the Trustgrid ZTNA Gateway (not recommended to change) | `string` | `"443"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_security_group_id"></a> [application\_security\_group\_id](#output\_application\_security\_group\_id) | The ID of the Trustgrid Gateway Application Security Group |
| <a name="output_data_plane_tcp_rule_id"></a> [data\_plane\_tcp\_rule\_id](#output\_data\_plane\_tcp\_rule\_id) | The ID of the TCP data plane security rule, if created |
| <a name="output_data_plane_udp_rule_id"></a> [data\_plane\_udp\_rule\_id](#output\_data\_plane\_udp\_rule\_id) | The ID of the UDP data plane security rule, if created |
| <a name="output_wireguard_rule_id"></a> [wireguard\_rule\_id](#output\_wireguard\_rule\_id) | The ID of the Wireguard security rule, if created |
| <a name="output_ztna_rule_id"></a> [ztna\_rule\_id](#output\_ztna\_rule\_id) | The ID of the ZTNA security rule, if created |
<!-- END_TF_DOCS -->