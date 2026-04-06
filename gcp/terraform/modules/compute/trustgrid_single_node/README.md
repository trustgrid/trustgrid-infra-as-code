# trustgrid\_single\_node — GCP Compute Module

This module deploys a single Trustgrid node on a GCP Compute Engine instance.  
It supports both **manual** and **automatic** registration with the Trustgrid control plane,
and three public-exposure modes for the management NIC.

## Key design decisions

| Concern | Approach |
|---|---|
| Firewall rules | **Not managed here.** Attach `network_tags` and manage firewall rules externally (or use the `trustgrid_firewall` helper module). |
| Service account | **Not created here.** Pass an existing service account email via `service_account_email` (or use the `trustgrid_service_account` helper module). |
| IP forwarding | Always enabled (`can_ip_forward = true`) — required for Trustgrid data-plane routing. |
| Lifecycle | `ignore_changes = all` on the instance — prevents Terraform from replacing a running node due to post-boot drift. |
| Bootstrap | A startup script (`templates/bootstrap.sh.tpl`) is rendered and attached as `metadata_startup_script`. In `auto` mode it writes the license/registration key and calls `bin/register.sh`. In `manual` mode it exits immediately. |
| Public IP stability | In `direct_static_ip` mode the module creates a separate `google_compute_address` resource. Because this resource is independent of the instance, the external IP is **preserved** across `terraform taint`/replace or destroy+apply cycles — the node always re-attaches the same IP. |

---

## Public exposure modes

| Mode | Behaviour | Use case |
|---|---|---|
| `direct_static_ip` *(default)* | Module creates and owns a regional static external IP and attaches it to nic0 | Production — predictable IP, stable across redeployments |
| `byo_public_ip` | Caller supplies a pre-existing reserved external IP address; module attaches it | Shared/cross-stack IPs, DNS cutover scenarios |
| `private_only` | No external IP on nic0 | Air-gapped / hub-and-spoke architectures where the node reaches the control plane via Cloud NAT or internal routing |

---

## Usage

### Mode 1: direct\_static\_ip (default) — public IP with redeployment stability

The module allocates a regional static external IP named `<name>-mgmt-ext`. Because
this `google_compute_address` resource is separate from the instance, `terraform taint
module.trustgrid_node.google_compute_instance.node` (or a full destroy+apply) will
**reattach the same IP** without requiring a DNS or portal update.

```hcl
module "trustgrid_node" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.2.0"

  name                  = "my-tg-node"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/my-project/regions/us-central1/subnetworks/mgmt-subnet"
  data_subnetwork       = "projects/my-project/regions/us-central1/subnetworks/data-subnet"
  service_account_email = module.trustgrid_sa.service_account_email

  # public_exposure_mode defaults to "direct_static_ip"
  network_tags = ["trustgrid-mgmt", "trustgrid-data"]
}

output "node_external_ip" {
  value = module.trustgrid_node.management_external_ip
}
```

### Mode 2: byo\_public\_ip — attach a caller-managed reserved IP

Use this when you need to control the IP lifecycle outside this module (e.g., for DNS
cutover, cross-stack sharing, or when the same IP must survive the module being removed
and re-added).

```hcl
resource "google_compute_address" "node_ip" {
  name         = "my-tg-node-ip"
  region       = "us-central1"
  address_type = "EXTERNAL"
}

module "trustgrid_node" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.2.0"

  name                  = "my-tg-node"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/my-project/regions/us-central1/subnetworks/mgmt-subnet"
  data_subnetwork       = "projects/my-project/regions/us-central1/subnetworks/data-subnet"
  service_account_email = module.trustgrid_sa.service_account_email

  public_exposure_mode           = "byo_public_ip"
  management_external_ip_address = google_compute_address.node_ip.address

  network_tags = ["trustgrid-mgmt", "trustgrid-data"]
}
```

### Mode 3: private\_only — no external IP on nic0

Use when the node reaches the Trustgrid control plane via **Cloud NAT**, an internal
gateway, or a hub-and-spoke VPN. No external IP is attached to the management interface.

```hcl
module "trustgrid_node" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.2.0"

  name                  = "my-tg-node"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/my-project/regions/us-central1/subnetworks/mgmt-subnet"
  data_subnetwork       = "projects/my-project/regions/us-central1/subnetworks/data-subnet"
  service_account_email = module.trustgrid_sa.service_account_email

  public_exposure_mode = "private_only"

  network_tags = ["trustgrid-mgmt", "trustgrid-data"]
}
```

---

## Registration modes

### Manual registration (license omitted)

After first boot the GCP guest agent runs the bootstrap script, which detects
`registration_mode = "manual"` and exits immediately without writing any
credentials. The node surfaces in the Trustgrid portal as **"pending"**. Complete
registration there by following the portal workflow.

```hcl
module "trustgrid_node" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.2.0"

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
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.2.0"

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
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.2.0"

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

---

## Image selection

### How image resolution works

| Priority | Condition | Resolved image |
|---|---|---|
| **1 — explicit pin** | `image_name` is set | `image_name` value used directly; `image_project` and `image_family` are ignored |
| **2 — family lookup** | `image_name = null` (default) | Terraform resolves the latest image in `image_family` from `image_project` at plan time |

### Production: explicit pinning (recommended)

Pin `image_name` to a known-good release so that re-applying a configuration
**never silently upgrades** the Trustgrid image on an existing deployment.

```hcl
module "trustgrid_node" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.2.0"

  name                  = "prod-tg-node"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/my-project/regions/us-central1/subnetworks/mgmt-subnet"
  data_subnetwork       = "projects/my-project/regions/us-central1/subnetworks/data-subnet"
  service_account_email = module.trustgrid_sa.service_account_email

  registration_mode = "auto"
  license           = var.tg_license

  # Pin to a specific release — recommended for production.
  # Use the full self_link or a bare image name from the trustgrid-images project.
  image_name = "projects/trustgrid-images/global/images/trustgrid-node-20240101"
}
```

> **Stability note:** because the instance resource uses `lifecycle { ignore_changes = all }`,
> changing `image_name` after initial deployment will not automatically replace the VM.
> Use `terraform taint` or destroy + re-apply to roll out a new image to an existing node.

### Production: family-based lookup (default)

Omit `image_name` (or set it explicitly to `null`) to always resolve the latest
image in the production family.  This is the default behaviour and is safe for
initial deployments or automation pipelines where controlled upgrades are managed
externally (e.g. via image promotion workflows).

```hcl
module "trustgrid_node" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.2.0"

  name                  = "prod-tg-node"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/my-project/regions/us-central1/subnetworks/mgmt-subnet"
  data_subnetwork       = "projects/my-project/regions/us-central1/subnetworks/data-subnet"
  service_account_email = module.trustgrid_sa.service_account_email

  # image_name defaults to null → resolves latest from image_project/image_family
  # image_project defaults to "trustgrid-images"
  # image_family  defaults to "trustgrid-node"
}
```

### Test / staging variants: project and family overrides

Override `image_project` and/or `image_family` to resolve images from a test or
staging image project without changing any other module behaviour.

```hcl
module "trustgrid_node_staging" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/compute/trustgrid_single_node?ref=v0.2.0"

  name                  = "staging-tg-node"
  zone                  = "us-central1-a"
  management_subnetwork = "projects/my-project/regions/us-central1/subnetworks/mgmt-subnet"
  data_subnetwork       = "projects/my-project/regions/us-central1/subnetworks/data-subnet"
  service_account_email = module.trustgrid_sa.service_account_email

  # Override both project and family to target a staging image track.
  image_project = "my-test-image-project"
  image_family  = "trustgrid-node-staging"
}
```

To pin a test variant to a specific image from a non-production project:

```hcl
  image_name = "projects/my-test-image-project/global/images/trustgrid-node-rc-20240201"
```

---

## Redeployment and public IP stability

When using `direct_static_ip` mode the module creates a `google_compute_address`
resource (named `<name>-mgmt-ext`) that is **independent of the instance**. This means:

- **`terraform taint`** on the instance resource replaces only the VM; the static IP
  resource is untouched and re-attached on the next apply.
- **destroy + apply** cycles also preserve the IP as long as the address resource
  is not explicitly targeted (`terraform destroy -target=...`).
- The Trustgrid portal and any DNS records pointing to the management IP remain valid
  after a redeployment.

To inspect the allocated IP without applying, use:

```bash
terraform state show 'module.trustgrid_node.google_compute_address.management_external[0]'
```

---

## Validation and testing notes

### Cross-variable constraints are enforced at plan-time

This module contains two validation rules that reference more than one variable:

| Rule | Variables involved | Error message |
|---|---|---|
| `license` required in `auto` mode | `registration_mode`, `license` | "license is required when registration_mode is 'auto'." |
| `management_external_ip_address` required in `byo_public_ip` mode | `public_exposure_mode`, `management_external_ip_address` | "management_external_ip_address is required when public_exposure_mode is 'byo_public_ip'." |

**In Terraform < 1.6** validation blocks that reference a second variable are deferred to
`terraform plan` time — `terraform validate` alone will not catch violations.

```bash
# Validates single-variable constraints only (enum checks, format checks)
terraform validate

# Validates ALL constraints including cross-variable rules — required for negative tests
terraform plan -no-color
# Note: plan will fail at the provider auth step for cross-account/offline testing,
# but variable validation errors are emitted before provider calls and will still appear.
```

When writing negative test fixtures for cross-variable constraints, document this
difference in the fixture header and configure the test runner to assert on
`terraform plan` exit code, not `terraform validate`.

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
| [google_compute_address.management_external](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
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
| <a name="input_public_exposure_mode"></a> [public\_exposure\_mode](#input\_public\_exposure\_mode) | Controls how nic0 is exposed publicly. `direct_static_ip` (default) creates a module-owned static external IP for redeployment stability. `byo_public_ip` attaches a caller-supplied reserved external IP. `private_only` attaches no external IP. | `string` | `"direct_static_ip"` | no |
| <a name="input_management_external_ip_address"></a> [management\_external\_ip\_address](#input\_management\_external\_ip\_address) | Reserved external IP address to attach to nic0. Required when `public_exposure_mode = "byo_public_ip"`. Must be a regional static external IP in the same region as the instance. | `string` | `null` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | GCP machine type. | `string` | `"n2-standard-2"` | no |
| <a name="input_boot_disk_size_gb"></a> [boot\_disk\_size\_gb](#input\_boot\_disk\_size\_gb) | Boot disk size in GB (minimum 30). | `number` | `30` | no |
| <a name="input_boot_disk_type"></a> [boot\_disk\_type](#input\_boot\_disk\_type) | Boot disk type: pd-ssd, pd-balanced, or pd-standard. | `string` | `"pd-ssd"` | no |
| <a name="input_enable_secure_boot"></a> [enable\_secure\_boot](#input\_enable\_secure\_boot) | Enable Shielded VM secure boot. | `bool` | `true` | no |
| <a name="input_image_project"></a> [image\_project](#input\_image\_project) | GCP project owning the Trustgrid image. Used only when `image_name` is null. Defaults to the Trustgrid production project (`trustgrid-images`). Override for test variants hosted in a separate project. | `string` | `"trustgrid-images"` | no |
| <a name="input_image_family"></a> [image\_family](#input\_image\_family) | Image family for latest Trustgrid node image. Used only when `image_name` is null. Defaults to the Trustgrid production family (`trustgrid-node`). Override for test variants (e.g. `trustgrid-node-staging`). | `string` | `"trustgrid-node"` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Explicit image name or self\_link to pin the instance to a specific image version. When set, `image_project` and `image_family` are ignored. Recommended for production to prevent unintended image upgrades on re-apply. | `string` | `null` | no |
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
| <a name="output_management_external_ip"></a> [management\_external\_ip](#output\_management\_external\_ip) | Effective external IP attached to nic0. Non-null for direct\_static\_ip and byo\_public\_ip modes. Null for private\_only. |
| <a name="output_management_external_ip_self_link"></a> [management\_external\_ip\_self\_link](#output\_management\_external\_ip\_self\_link) | Self-link of the module-managed static external IP. Non-null only for direct\_static\_ip mode. |
<!-- END_TF_DOCS -->
