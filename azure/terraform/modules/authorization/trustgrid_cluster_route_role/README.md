## Terraform Module: Authorization - TrustGrid Cluster Route Role
This role creates an Azure role definition with the permissions required for clustered Trustgrid nodes to manage routes. 

After creating the role, you will need to use the `azurerm_role_assignment` resource to assign the role to each cluster member for every resources groups that contains either:
- The Trustgrid nodes Virtual Machines
- The Virtual network the Trustgrid nodes are connected to
- Any route table the Trustgrid nodes needs to modify
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
| [azurerm_role_definition.tg_cluster_route_role](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assignable_scopes"></a> [assignable\_scopes](#input\_assignable\_scopes) | Defines the resources, resource groups, or subscriptions where the custom role can be used for assignments. | `list(string)` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for the resources created by this module | `string` | n/a | yes |
| <a name="input_scope"></a> [scope](#input\_scope) | Specifies the Azure Resource Manager (ARM) scope where the custom role definition itself is created or defined. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The Azure ID for the Trustgrid Cluster route role |
| <a name="output_name"></a> [name](#output\_name) | The name of the Trustgrid Cluster route role |
<!-- END_TF_DOCS -->