<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.44.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.trustgrid_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.trustgrid_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cluster_ip_failover](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.route_failover](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cluster_ip_failover](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.route_failover](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_cluster_ip_failover"></a> [enable\_cluster\_ip\_failover](#input\_enable\_cluster\_ip\_failover) | Grant permissions for secondary private IP assignment/unassignment (cluster IP failover). | `bool` | `false` | no |
| <a name="input_enable_route_failover"></a> [enable\_route\_failover](#input\_enable\_route\_failover) | Grant permissions for route table manipulation (route-based cluster failover). Requires route\_table\_ids. | `bool` | `false` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Name prefix for the IAM role, policies, and instance profile. | `string` | `"trustgrid-cluster"` | no |
| <a name="input_route_table_ids"></a> [route\_table\_ids](#input\_route\_table\_ids) | Route table IDs the role may manage. Required when enable\_route\_failover is true. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_profile_name"></a> [profile\_name](#output\_profile\_name) | Name of the IAM instance profile — pass this to the node module's instance\_profile\_name input. |
| <a name="output_role"></a> [role](#output\_role) | The IAM role resource. |
<!-- END_TF_DOCS -->