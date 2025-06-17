## Summary
This module creates and configures a ThousandEyes agent container on a target Trustgrid appliance-based node or cluster consistent with the [Trustgrid ThousandEyes Agent Container deployment guide](https://docs.trustgrid.io/tutorials/containers/thousand-eyes/) documentation.
## Example Usage
The below example shows using the module to create a container on a cluster using an image published to a [private Trustgrid repository](https://docs.trustgrid.io/docs/repositories/). 
```hcl
terraform {
    required_providers {
        tg = {
            source    = "trustgrid/tg"
            version   = "1.36.0"
        }
    }
}

provider "tg" {
  # Configuration options
  api_host = var.tg_api_host
  # Locks this to a specific org id, if credentials are for a different org, this will fail
  org_id = var.tg_org_id
}

## TrustGrid Provider Variables
variable "tg_api_host" {
    description = "The TrustGrid API host"
    type        = string
    default = "api.trustgrid.io"
}

variable "tg_org_id" {
    description = "Target Trustgrid organization ID. This is a required field. Attempts to make changes    outside of the context of an organization will fail."
    type        = string  
}

variable "cluster_fqdn" {
    type = string
    description = "The target cluster's FQDN"
  
}

variable "te_account_token" {
    description = "The ThousandEyes account registration token"
    type        = string
}

module "te_containers" {
    source = "github.com/trustgrid/trustgrid-infra-as-code//thousandeyes/terraform/modules/te-agent-container?ref=v0.6.0"
    container_name = "thousandeyes-agent"
    cluster_fqdn = var.cluster_fqdn
    image_repository = "myorg.trustgrid.io/te-enterprise-agent"
    image_tag = "0.45.0-agent"
    environment_variables = {
        TEAGENT_ACCOUNT_TOKEN = var.te_account_token
        TEAGENT_INET = "4"
    }
    encrypt_volumes = true
    exec_type = "service"  
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_tg"></a> [tg](#requirement\_tg) | >= 1.33.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_tg"></a> [tg](#provider\_tg) | >= 1.33.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [null_resource.target_validation](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [tg_container.thousand_eyes_cluster](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/container) | resource |
| [tg_container.thousand_eyes_single](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/container) | resource |
| [tg_container_volume.te_agent_lib_cluster](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/container_volume) | resource |
| [tg_container_volume.te_agent_lib_single](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/container_volume) | resource |
| [tg_container_volume.te_agent_logs_cluster](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/container_volume) | resource |
| [tg_container_volume.te_agent_logs_single](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/container_volume) | resource |
| [tg_container_volume.te_browserbot_lib_cluster](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/container_volume) | resource |
| [tg_container_volume.te_browserbot_lib_single](https://registry.terraform.io/providers/trustgrid/tg/latest/docs/resources/container_volume) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_caps"></a> [add\_caps](#input\_add\_caps) | Additional Linux capabilities for the container | `list(string)` | <pre>[<br/>  "NET_ADMIN",<br/>  "SYS_ADMIN"<br/>]</pre> | no |
| <a name="input_cluster_fqdn"></a> [cluster\_fqdn](#input\_cluster\_fqdn) | FQDN of the cluster to deploy the container to. Mutually exclusive with node\_id. | `string` | `null` | no |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | Name of the ThousandEyes container | `string` | n/a | yes |
| <a name="input_cpu_max"></a> [cpu\_max](#input\_cpu\_max) | CPU Max % | `number` | `40` | no |
| <a name="input_encrypt_volumes"></a> [encrypt\_volumes](#input\_encrypt\_volumes) | Whether to encrypt the container volumes | `bool` | `false` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Environment variables for the container | `map(string)` | `{}` | no |
| <a name="input_exec_type"></a> [exec\_type](#input\_exec\_type) | Execution type for the container. Options are 'onDemand' or 'service'. | `string` | `"onDemand"` | no |
| <a name="input_image_repository"></a> [image\_repository](#input\_image\_repository) | Docker image repository for ThousandEyes container | `string` | `"hub.docker.com/thousandeyes/enterprise-agent"` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Docker image tag for ThousandEyes container | `string` | `"latest"` | no |
| <a name="input_mem_high"></a> [mem\_high](#input\_mem\_high) | Memory limit in MB the node will try to keep the container under | `number` | `1024` | no |
| <a name="input_mem_max"></a> [mem\_max](#input\_mem\_max) | Maximum memory in MB the container can use | `number` | `1536` | no |
| <a name="input_node_id"></a> [node\_id](#input\_node\_id) | ID of the single node to deploy the container to. Mutually exclusive with cluster\_fqdn. | `string` | `null` | no |
| <a name="input_te_agent_lib_volume_name"></a> [te\_agent\_lib\_volume\_name](#input\_te\_agent\_lib\_volume\_name) | Name for the te-agent lib volume | `string` | `"te-agent-lib"` | no |
| <a name="input_te_agent_logs_volume_name"></a> [te\_agent\_logs\_volume\_name](#input\_te\_agent\_logs\_volume\_name) | Name for the te-agent logs volume | `string` | `"te-agent-logs"` | no |
| <a name="input_te_browserbot_lib_volume_name"></a> [te\_browserbot\_lib\_volume\_name](#input\_te\_browserbot\_lib\_volume\_name) | Name for the te-browserbot lib volume | `string` | `"te-browserbot-lib"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->