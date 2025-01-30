### TrustGrid Single Node Manual Registration
This module creates a single node TrustGrid node that can be registered with the TrustGrid control plane manually via [Remote Console Registration](https://docs.trustgrid.io/tutorials/local-console-utility/remote-registration/) process.  
This module is commonly used when the Trustgrid nodes are being created by someone that is not a direct Trustgrid customer. E.g. a customer whose vendor utilizes Trustgrid. The customer can use Terraform to deploy the Trustgrid nodes and then pass the Activation codes to their vendor who can then register the nodes.

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
| [azurerm_linux_virtual_machine.node](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.public](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_interface_security_group_association.public](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_public_ip.public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_ssh_key_pub"></a> [admin\_ssh\_key\_pub](#input\_admin\_ssh\_key\_pub) | SSH Public key for admin user | `string` | n/a | yes |
| <a name="input_admin_ssh_username"></a> [admin\_ssh\_username](#input\_admin\_ssh\_username) | admin username | `string` | `"ubuntu"` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | Availability Zone for the VM | `string` | `"1"` | no |
| <a name="input_location"></a> [location](#input\_location) | Location for creating resources | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Instance name | `string` | n/a | yes |
| <a name="input_os_disk_size"></a> [os\_disk\_size](#input\_os\_disk\_size) | Size of the OS disk volume in GB. 30GB is the recommended minimum. | `number` | `30` | no |
| <a name="input_private_security_group_id"></a> [private\_security\_group\_id](#input\_private\_security\_group\_id) | Security group ID for the private interface | `string` | n/a | yes |
| <a name="input_private_subnet_id"></a> [private\_subnet\_id](#input\_private\_subnet\_id) | Subnet ID for private traffic | `string` | n/a | yes |
| <a name="input_public_security_group_id"></a> [public\_security\_group\_id](#input\_public\_security\_group\_id) | Security group ID for the public interface | `string` | n/a | yes |
| <a name="input_public_subnet_id"></a> [public\_subnet\_id](#input\_public\_subnet\_id) | Subnet ID for public traffic (needs to be able to reach the internet) | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource Group Name for deploying the VM | `string` | n/a | yes |
| <a name="input_tg_image_gallery"></a> [tg\_image\_gallery](#input\_tg\_image\_gallery) | Trustgrid Image Gallery (DO NOT CHANGE) | `string` | `"trustgrid-45680719-9aa7-43b9-a376-dc03bcfdb0ac"` | no |
| <a name="input_tg_tenant"></a> [tg\_tenant](#input\_tg\_tenant) | Trustgrid Tenant ID (DO NOT CHANGE) | `string` | `"prod"` | no |
| <a name="input_tg_version"></a> [tg\_version](#input\_tg\_version) | Trustgrid Node Appliance Version (DO NOT CHANGE) | `string` | `"latest"` | no |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | Node instance type | `string` | `"Standard_B2s"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_principal_id"></a> [principal\_id](#output\_principal\_id) | Principal ID of the system assigned identity |
| <a name="output_private_ip_address"></a> [private\_ip\_address](#output\_private\_ip\_address) | Private IP address of the primary interface |
| <a name="output_private_nic_id"></a> [private\_nic\_id](#output\_private\_nic\_id) | ID of the private network interface |
| <a name="output_public_nic_id"></a> [public\_nic\_id](#output\_public\_nic\_id) | ID of the public network interface |
| <a name="output_public_nic_mac_address"></a> [public\_nic\_mac\_address](#output\_public\_nic\_mac\_address) | MAC address of the public interface |
| <a name="output_public_nic_private_ip_address"></a> [public\_nic\_private\_ip\_address](#output\_public\_nic\_private\_ip\_address) | Private IP address of the public interface |
| <a name="output_public_nic_public_ip_address"></a> [public\_nic\_public\_ip\_address](#output\_public\_nic\_public\_ip\_address) | Public IP address assigned to the VM |
| <a name="output_vm_id"></a> [vm\_id](#output\_vm\_id) | ID of the created virtual machine |
| <a name="output_vm_name"></a> [vm\_name](#output\_vm\_name) | Name of the created virtual machine |
<!-- END_TF_DOCS -->