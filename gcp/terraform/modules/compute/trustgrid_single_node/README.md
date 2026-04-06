# trustgrid\_single\_node — GCP Compute Module

This module deploys a single Trustgrid node on a GCP Compute Engine instance.  
It supports both **manual** and **automatic** registration with the Trustgrid control plane.

## Key design decisions

| Concern | Approach |
|---|---|
| Firewall rules | **Not managed here.** Attach `network_tags` and manage firewall rules externally (or use the `trustgrid_firewall` helper module). |
| Service account | **Not created here.** Pass an existing service account email via `service_account_email` (or use the `trustgrid_service_account` helper module). |
| IP forwarding | Always enabled (`can_ip_forward = true`) — required for Trustgrid data-plane routing. |
| Lifecycle | `ignore_changes = all` on the instance — prevents Terraform from replacing a running node due to post-boot drift. |
| Bootstrap | A startup script (`templates/bootstrap.sh.tpl`) is rendered and attached as `metadata_startup_script`. In `auto` mode it writes the license/registration key and calls `bin/register.sh`. In `manual` mode it exits immediately. |

---

## Usage

### Manual registration (license omitted)

After first boot the GCP guest agent runs the bootstrap script, which detects
`registration_mode = "manual"` and exits immediately without writing any
credentials. The node surfaces in the Trustgrid portal as **"pending"**. Complete
registration there by following the portal workflow.

```hcl
module "trustgrid_node" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.1.0"

  name                  = "my-tg-node"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/my-project/regions/us-central1/subnetworks/mgmt-subnet"
  data_subnetwork       = "projects/my-project/regions/us-central1/subnetworks/data-subnet"
  service_account_email = module.trustgrid_sa.service_account_email

  # registration_mode defaults to "manual" — license is not required
  network_tags = ["trustgrid-mgmt", "trustgrid-data"]
}
```

### Auto registration (license provided)

On first boot the bootstrap script writes the license (read from instance
metadata) to `/usr/local/trustgrid/license.txt`, then calls `bin/register.sh`
in a retry loop until the node successfully joins the Trustgrid control plane.
Bootstrap progress is logged to `/var/log/tg-bootstrap.log`.

```hcl
module "trustgrid_node" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.1.0"

  name                  = "my-tg-node"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/my-project/regions/us-central1/subnetworks/mgmt-subnet"
  data_subnetwork       = "projects/my-project/regions/us-central1/subnetworks/data-subnet"
  service_account_email = module.trustgrid_sa.service_account_email

  registration_mode = "auto"
  license           = var.tg_license   # sensitive — supply via TF_VAR or secret manager

  network_tags = ["trustgrid-mgmt", "trustgrid-data"]
}
```

### Auto registration with a registration key

Supply `registration_key` to associate the node with a specific cluster or
configuration profile at registration time. The key is written to
`/usr/local/trustgrid/registration-key.txt` with restricted permissions.

```hcl
module "trustgrid_node" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.1.0"

  name                  = "my-tg-node"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/my-project/regions/us-central1/subnetworks/mgmt-subnet"
  data_subnetwork       = "projects/my-project/regions/us-central1/subnetworks/data-subnet"
  service_account_email = module.trustgrid_sa.service_account_email

  registration_mode = "auto"
  license           = var.tg_license
  registration_key  = var.tg_registration_key   # sensitive — supply via TF_VAR or secret manager

  network_tags = ["trustgrid-mgmt", "trustgrid-data"]
}
```

### Explicit image pinning

```hcl
module "trustgrid_node" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.1.0"

  name                  = "my-tg-node"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/my-project/regions/us-central1/subnetworks/mgmt-subnet"
  data_subnetwork       = "projects/my-project/regions/us-central1/subnetworks/data-subnet"
  service_account_email = module.trustgrid_sa.service_account_email

  registration_mode = "auto"
  license           = var.tg_license

  # Pin to an exact image rather than resolving from a family
  image_name = "projects/trustgrid-images/global/images/trustgrid-node-20240101"
}
```

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_instance.node](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_image.node_image](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Name of the Compute Engine instance. | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | GCP zone (e.g. us-central1-a). | `string` | n/a | yes |
| <a name="input_management_subnetwork"></a> [management\_subnetwork](#input\_management\_subnetwork) | Subnetwork self-link for the management (WAN/nic0) interface. | `string` | n/a | yes |
| <a name="input_data_subnetwork"></a> [data\_subnetwork](#input\_data\_subnetwork) | Subnetwork self-link for the data (LAN/nic1) interface. | `string` | n/a | yes |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account\_email) | Email of the GCP service account to attach to the instance. | `string` | n/a | yes |
| <a name="input_registration_mode"></a> [registration\_mode](#input\_registration\_mode) | `manual` or `auto`. In `auto` mode the bootstrap script writes the license and calls `bin/register.sh` on first boot. In `manual` mode the script exits immediately and the operator completes registration via the portal. | `string` | `"manual"` | no |
| <a name="input_license"></a> [license](#input\_license) | Trustgrid license. Required when `registration_mode = "auto"`. Injected into instance metadata as `tg-license` and consumed by the bootstrap script. | `string` | `null` | no |
| <a name="input_registration_key"></a> [registration\_key](#input\_registration\_key) | Optional Trustgrid registration key for cluster/configuration association. Injected into instance metadata as `tg-registration-key` and written to disk by the bootstrap script when supplied. | `string` | `null` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | GCP machine type. | `string` | `"n2-standard-2"` | no |
| <a name="input_boot_disk_size_gb"></a> [boot\_disk\_size\_gb](#input\_boot\_disk\_size\_gb) | Boot disk size in GB (minimum 30). | `number` | `30` | no |
| <a name="input_boot_disk_type"></a> [boot\_disk\_type](#input\_boot\_disk\_type) | Boot disk type: pd-ssd, pd-balanced, or pd-standard. | `string` | `"pd-ssd"` | no |
| <a name="input_enable_secure_boot"></a> [enable\_secure\_boot](#input\_enable\_secure\_boot) | Enable Shielded VM secure boot. | `bool` | `true` | no |
| <a name="input_image_project"></a> [image\_project](#input\_image\_project) | GCP project owning the Trustgrid image. | `string` | `"trustgrid-images"` | no |
| <a name="input_image_family"></a> [image\_family](#input\_image\_family) | Image family for latest Trustgrid node image. | `string` | `"trustgrid-node"` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Explicit image name/self\_link. Overrides image\_project and image\_family. | `string` | `null` | no |
| <a name="input_network_tags"></a> [network\_tags](#input\_network\_tags) | Network tags for targeting VPC firewall rules. | `list(string)` | `[]` | no |
| <a name="input_extra_metadata"></a> [extra\_metadata](#input\_extra\_metadata) | Additional instance metadata key/value pairs. Do not include `tg-license` or `tg-registration-key`; use the `license` and `registration_key` variables instead. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | Server-assigned unique identifier of the Compute Engine instance. |
| <a name="output_instance_name"></a> [instance\_name](#output\_instance\_name) | Name of the created Compute Engine instance. |
| <a name="output_instance_self_link"></a> [instance\_self\_link](#output\_instance\_self\_link) | Self-link URI of the Compute Engine instance. |
| <a name="output_management_nic_internal_ip"></a> [management\_nic\_internal\_ip](#output\_management\_nic\_internal\_ip) | Internal IP address of the management interface (nic0). |
| <a name="output_data_nic_internal_ip"></a> [data\_nic\_internal\_ip](#output\_data\_nic\_internal\_ip) | Internal IP address of the data interface (nic1). |
<!-- END_TF_DOCS -->
