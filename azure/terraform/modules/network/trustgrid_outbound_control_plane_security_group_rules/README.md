## Trustgrid Outbound Control Plane Security Group Rules
This module adds security group rules to an existing security group to allow outbound traffic to the Trustgrid Control Plane.  This rule is only required if your security group restricts outbound traffic to the internet. 


### security_group_rule_priority_start
Make sure the security_group_rule_priority_start is set to a lower value than any rule restricting outbound traffic to the internet. 

Also, confirm that the security group rule priority start is not in conflict with any other rules in the security group. The module creates two rules one with the value of the security_group_rule_priority_start and the other with the value of the security_group_rule_priority_start + 1. 

For example, if the security_group_rule_priority_start is set to 300, the first rule will have a priority of 300 and the second rule will have a priority of 301.


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
| [azurerm_network_security_rule.trustgrid_control_plane_1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.trustgrid_control_plane_2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for the resources created by this module | `string` | n/a | yes |
| <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id) | Security group ID for the Trustgrid Control Plane rules to be added to | `string` | n/a | yes |
| <a name="input_security_group_rule_priority_start"></a> [security\_group\_rule\_priority\_start](#input\_security\_group\_rule\_priority\_start) | Start of the priority range for the Trustgrid Gateway rules | `number` | `300` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_rule_ids"></a> [rule\_ids](#output\_rule\_ids) | The IDs of the created security rules |
<!-- END_TF_DOCS -->