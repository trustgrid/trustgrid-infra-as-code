<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.trustgrid-instance-profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.trustgrid-node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.trustgrid-route-policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_policy_document.private-route-table-modifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Name prefix for the role and related resources | `string` | `"trustgrid-cluster-route"` | no |
| <a name="input_route_table_arns"></a> [route\_table\_arns](#input\_route\_table\_arns) | List of route table ARNs the role will be allowed to manage | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_trustgrid-instance-profile-name"></a> [trustgrid-instance-profile-name](#output\_trustgrid-instance-profile-name) | n/a |
| <a name="output_trustgrid-node-iam-role"></a> [trustgrid-node-iam-role](#output\_trustgrid-node-iam-role) | n/a |
<!-- END_TF_DOCS -->