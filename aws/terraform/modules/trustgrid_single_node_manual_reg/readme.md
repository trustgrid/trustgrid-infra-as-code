# Trustgrid Single Node Manual Registration Module
This module deploys a single Trustgrid module on an EC2 instance in AWS based on the Trustgrid AMI image but **does not** attempt to register the device with the Trustgrid control plane. After deployment, the node will need to be registered via the [remote console registration](https://docs.trustgrid.io/tutorials/local-console-utility/remote-registration/) process

The module handles the creation of the following AWS resources :
- EIP to be used for the EC2 instance outside/public interface
- Outside/public interface with EIP attached
- Inside/private interface
- Security group attached to the outside interface. Optionally, it will include open ports for Trustgrid gateway services.
- EC2 instance attached to both interfaces, built from the latest Trustgrid AMI for the generation implied by `instance_type` (see [Node image and instance generation](#node-image-and-instance-generation))

## Node image and instance generation

Trustgrid publishes two AMI families for AWS. They differ in how the guest OS names its network interfaces, which is driven by the EC2 instance family the node runs on. See [Instance Type](https://docs.trustgrid.io/tutorials/deployments/deploy-aws/#instance-type) in the Trustgrid docs for the full background.

| Generation | AMI name pattern | Instance families |
|---|---|---|
| gen3 | `trustgrid-node-gen3-2204-*` | c7a, c7i, c8a, c8i, m7a, m7i, m8a, m8i and their variants (for example `m7i-flex`, `m8azn`, `c8ine`) |
| gen2 | `trustgrid-node-2204-*` | t3, t3a, c5, c5n, c5a, c6i, c6in, c6a |

The module picks the generation from `instance_type`. When `trustgrid_ami_id` is not set, it looks up the most recent Trustgrid-owned AMI whose name matches the pattern for that generation. You never specify the generation directly; choosing the instance type is enough.

- **Default:** `instance_type` defaults to `c8i.large`, which deploys a gen3 node. Any instance family in the table above is supported; set `instance_type` to one of them to deploy a different size or a gen2 node.
- **Gen3 requires the June 2026 Trustgrid release or later.** Keep this in mind when passing an older image via `trustgrid_ami_id`.
- **Override with care.** Setting `trustgrid_ami_id` bypasses the generation lookup entirely. The module does not verify that the AMI you pass matches the instance family, so a gen2 AMI on a c8i instance (or a gen3 AMI on a t3) will boot with the wrong interface names and the node will not come online.
- **Burstable types (t3, t3a):** set CPU credits to unlimited on gateway nodes and monitor the credit balance, per the Trustgrid docs linked above.

The resolved AMI is exposed as the `node-instance-ami-id` output.

## Destruction Protection

This module applies two layers of protection against accidental destruction of the EC2 instance and EIP, since either loss would require the node to be re-registered with the Trustgrid control plane and all associated tunnel configuration rebuilt.

| Resource | Protection | Scope |
|---|---|---|
| `aws_instance.node` | `disable_api_termination = true` (AWS API-level) + `prevent_destroy = true` (Terraform-level) | AWS rejects termination API calls regardless of who makes them; Terraform blocks plans that would replace the instance |
| `aws_eip.mgmt_ip` | `prevent_destroy = true` (Terraform-level) | Terraform blocks plans that would replace the EIP; EIP cannot be released while associated |
| `aws_network_interface.management_eni` | Implicit (primary ENI) | AWS does not allow the primary network interface to be detached from a running instance |

### To intentionally decommission a node

Before `terraform destroy` (or removing the module block) will succeed, an operator must first disable EC2 termination protection:

```bash
aws ec2 modify-instance-attribute \
  --instance-id <instance-id> \
  --no-disable-api-termination
```

Then remove the module block from your configuration and run `terraform apply`. If you intend to preserve the infrastructure outside of Terraform management, use `terraform state rm` on each resource instead of destroying them.

### Upgrading from a previous module version (migrating to `aws_network_interface_attachment`)

This module version replaced the deprecated `network_interface` blocks on `aws_instance` with `primary_network_interface` (management ENI) and a separate `aws_network_interface_attachment` resource (data ENI). For existing deployed nodes, Terraform will not know about the attachment resource and will attempt to create it — which fails because the ENI is already attached. Import the existing attachment to resolve this:

```bash
# Get the attachment ID from the AWS console or CLI:
aws ec2 describe-network-interfaces \
  --network-interface-ids <data-eni-id> \
  --query 'NetworkInterfaces[0].Attachment.AttachmentId' \
  --output text

# Import it into state:
terraform import module.<your_module_name>.aws_network_interface_attachment.data_eni_attachment <attachment-id>
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.41.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.41.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.mgmt_ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip_association.mgmt_ip_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association) | resource |
| [aws_instance.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_network_interface.data_eni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.management_eni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface_attachment.data_eni_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface_attachment) | resource |
| [aws_security_group.node_mgmt_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.tcp_appgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.tcp_tggw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.udp_tggw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.udp_wggw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ami.trustgrid-node-ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_instance_profile.instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_instance_profile) | data source |
| [aws_subnet.mgmt_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_appgateway_port"></a> [appgateway\_port](#input\_appgateway\_port) | Port for Application Gateway (TCP) | `number` | `443` | no |
| <a name="input_data_security_group_ids"></a> [data\_security\_group\_ids](#input\_data\_security\_group\_ids) | Security group IDs for the data interface | `list(string)` | n/a | yes |
| <a name="input_data_subnet_id"></a> [data\_subnet\_id](#input\_data\_subnet\_id) | Subnet ID for data traffic | `string` | n/a | yes |
| <a name="input_disable_api_termination"></a> [disable\_api\_termination](#input\_disable\_api\_termination) | If true, the EC2 instance cannot be terminated via the AWS API. Disable only when decommissioning the node. | `bool` | `true` | no |
| <a name="input_instance_profile_name"></a> [instance\_profile\_name](#input\_instance\_profile\_name) | IAM Instance Profile the Trustgrid EC2 node will use for managing AWS resources such as route table entries for clustered nodes. | `string` | `null` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type. The instance family selects the Trustgrid AMI generation: c7a, c7i, c8a, c8i, m7a, m7i, m8a and m8i families (and their variants such as m7i-flex or m8azn) resolve the gen3 image; t3, t3a, c5, c5n, c5a, c6i, c6in and c6a resolve the gen2 image. See the README section 'Node image and instance generation'. | `string` | `"c8i.large"` | no |
| <a name="input_is_appgateway"></a> [is\_appgateway](#input\_is\_appgateway) | Determines if security group should allow port 443 inbound for Application Gateway | `bool` | `false` | no |
| <a name="input_is_tggateway"></a> [is\_tggateway](#input\_is\_tggateway) | Determines if security group should allow tcp/udp port 8443 inbound for Trustgrid Tunnels | `bool` | `false` | no |
| <a name="input_is_wggateway"></a> [is\_wggateway](#input\_is\_wggateway) | Determines if security group should allow port 51820 inbound for Wireguard | `bool` | `false` | no |
| <a name="input_key_pair_name"></a> [key\_pair\_name](#input\_key\_pair\_name) | AWS Key Pair for ubuntu user in EC2 instance | `string` | n/a | yes |
| <a name="input_management_security_group_ids"></a> [management\_security\_group\_ids](#input\_management\_security\_group\_ids) | Security group IDs for the management interface | `list(string)` | n/a | yes |
| <a name="input_management_subnet_id"></a> [management\_subnet\_id](#input\_management\_subnet\_id) | Subnet ID for management traffic (needs to be able to reach the internet) | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Instance name | `string` | n/a | yes |
| <a name="input_root_block_device_encrypt"></a> [root\_block\_device\_encrypt](#input\_root\_block\_device\_encrypt) | Should the root device be encrypted in AWS | `bool` | `true` | no |
| <a name="input_root_block_device_size"></a> [root\_block\_device\_size](#input\_root\_block\_device\_size) | Size of the root volume in GB | `number` | `30` | no |
| <a name="input_tggateway_port"></a> [tggateway\_port](#input\_tggateway\_port) | Port for Trustgrid Gateway (TCP/UDP tunnel) | `number` | `8443` | no |
| <a name="input_trustgrid_ami_id"></a> [trustgrid\_ami\_id](#input\_trustgrid\_ami\_id) | Optional explicit Trustgrid AMI ID. When null, the module looks up the most recent Trustgrid-owned AMI whose name matches the generation implied by instance\_type (trustgrid-node-gen3-2204-* or trustgrid-node-2204-*). When set, the generation check is skipped, so you must ensure the AMI matches the instance family. | `string` | `null` | no |
| <a name="input_wggateway_port"></a> [wggateway\_port](#input\_wggateway\_port) | Port for Wireguard Gateway (UDP) | `number` | `51820` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_node-data-private-ip"></a> [node-data-private-ip](#output\_node-data-private-ip) | Private IP of the data (inside) interface. |
| <a name="output_node-instance-ami-id"></a> [node-instance-ami-id](#output\_node-instance-ami-id) | AMI ID the instance was launched from: either trustgrid\_ami\_id or the gen2/gen3 image resolved from instance\_type. |
| <a name="output_node-instance-id"></a> [node-instance-id](#output\_node-instance-id) | ID of the Trustgrid node EC2 instance. |
| <a name="output_node-mgmt-private-ip"></a> [node-mgmt-private-ip](#output\_node-mgmt-private-ip) | Private IP of the management (outside) interface. |
| <a name="output_node-mgmt-public-ip"></a> [node-mgmt-public-ip](#output\_node-mgmt-public-ip) | Elastic IP attached to the management (outside) interface. |
| <a name="output_node-security-group-id"></a> [node-security-group-id](#output\_node-security-group-id) | ID of the security group created for the management interface. |
<!-- END_TF_DOCS -->