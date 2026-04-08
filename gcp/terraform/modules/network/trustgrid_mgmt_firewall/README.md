# trustgrid\_mgmt\_firewall — GCP Management Egress Firewall Module

This helper module creates the **minimum egress firewall rules** required for a
Trustgrid node's management interface (nic0) to connect to the Trustgrid control
plane and function correctly in GCP.

It does **not** create any compute resources and is intentionally decoupled from
the `trustgrid_single_node` compute module — firewall rules are managed
independently so they can be shared across multiple nodes or clusters, and so
they survive instance replacement.

---

## What this module creates

| Rule name | Direction | Protocol | Ports | Default destination | Purpose |
|---|---|---|---|---|---|
| `<prefix>-cp-egress` | EGRESS | TCP | 443, 8443 | `35.171.100.16/28`, `34.223.12.192/28` | Trustgrid control plane |
| `<prefix>-dns-egress` | EGRESS | TCP+UDP | 53 | `8.8.8.8/32`, `8.8.4.4/32` | DNS resolution for `*.trustgrid.io` |
| `<prefix>-metadata-egress` | EGRESS | TCP | 80 | `169.254.169.254/32` | GCP instance metadata server |

DNS and metadata rules are created by default but can be suppressed with
`enable_dns_egress = false` and `enable_metadata_server_egress = false` when
your VPC already has permissive defaults for those destinations.

---

## Least-privilege guidance

| Setting | Recommendation |
|---|---|
| `target_tags` | **Always set in production.** Apply the same network tag(s) used on Trustgrid node instances (e.g. `["trustgrid-mgmt"]`). An empty list applies rules to all instances in the VPC. |
| `control_plane_cidr_ranges` | Do not widen beyond the documented control-plane blocks unless you are routing through a proxy or NVA. Keep the default. |
| `dns_server_cidr_ranges` | Replace the Google Public DNS defaults with your VPC resolver address(es) where possible. |
| `enable_logging` | Enable in regulated/audit environments; leave off in cost-sensitive deployments. |

---

## Usage

### Minimal — control plane + DNS + metadata (all defaults)

```hcl
module "tg_mgmt_fw" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_mgmt_firewall?ref=v0.3.0"

  name_prefix = "my-tg-node"
  network     = "projects/my-project/global/networks/mgmt-vpc"
  target_tags = ["trustgrid-mgmt"]
}
```

### Custom DNS resolvers (VPC internal)

```hcl
module "tg_mgmt_fw" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_mgmt_firewall?ref=v0.3.0"

  name_prefix            = "my-tg-node"
  network                = "projects/my-project/global/networks/mgmt-vpc"
  target_tags            = ["trustgrid-mgmt"]
  dns_server_cidr_ranges = ["10.0.0.2/32"]  # VPC internal resolver
}
```

### Suppress DNS/metadata rules (permissive VPC defaults)

```hcl
module "tg_mgmt_fw" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_mgmt_firewall?ref=v0.3.0"

  name_prefix                   = "my-tg-node"
  network                       = "projects/my-project/global/networks/mgmt-vpc"
  target_tags                   = ["trustgrid-mgmt"]
  enable_dns_egress             = false
  enable_metadata_server_egress = false
}
```

### With firewall logging enabled

```hcl
module "tg_mgmt_fw" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_mgmt_firewall?ref=v0.3.0"

  name_prefix    = "my-tg-node"
  network        = "projects/my-project/global/networks/mgmt-vpc"
  target_tags    = ["trustgrid-mgmt"]
  enable_logging = true
}
```

---

## Control-plane IP ranges

The published Trustgrid control-plane CIDRs used as defaults are:

| CIDR | Description |
|---|---|
| `35.171.100.16/28` | Trustgrid control plane (primary) |
| `34.223.12.192/28` | Trustgrid control plane (secondary) |

Source: [Trustgrid site requirements](https://docs.trustgrid.io/help-center/kb/site-requirements/)

These ranges may evolve. Subscribe to Trustgrid release notes or check the docs
page above when upgrading your deployment.

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.control_plane_egress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.dns_egress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.metadata_egress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix applied to all firewall rule names created by this module. | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | Self-link or name of the management (WAN) VPC network. | `string` | n/a | yes |
| <a name="input_control_plane_cidr_ranges"></a> [control\_plane\_cidr\_ranges](#input\_control\_plane\_cidr\_ranges) | Destination CIDR ranges for the Trustgrid control plane. Override only if traffic is proxied through an NVA. | `list(string)` | `["35.171.100.16/28", "34.223.12.192/28"]` | no |
| <a name="input_enable_dns_egress"></a> [enable\_dns\_egress](#input\_enable\_dns\_egress) | Create a TCP/UDP 53 egress rule to `dns_server_cidr_ranges`. | `bool` | `true` | no |
| <a name="input_dns_server_cidr_ranges"></a> [dns\_server\_cidr\_ranges](#input\_dns\_server\_cidr\_ranges) | DNS resolver CIDR ranges. Defaults to Google Public DNS. | `list(string)` | `["8.8.8.8/32", "8.8.4.4/32"]` | no |
| <a name="input_enable_metadata_server_egress"></a> [enable\_metadata\_server\_egress](#input\_enable\_metadata\_server\_egress) | Create a TCP 80 egress rule to the GCP metadata server (169.254.169.254/32). | `bool` | `true` | no |
| <a name="input_target_tags"></a> [target\_tags](#input\_target\_tags) | Network tags scoping rules to specific instances. Recommended in production. | `list(string)` | `[]` | no |
| <a name="input_priority"></a> [priority](#input\_priority) | GCP firewall rule priority (lower wins). | `number` | `1000` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Enable GCP Firewall Rules Logging on all rules. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_control_plane_egress_rule_name"></a> [control\_plane\_egress\_rule\_name](#output\_control\_plane\_egress\_rule\_name) | Name of the control-plane egress firewall rule. |
| <a name="output_dns_egress_rule_name"></a> [dns\_egress\_rule\_name](#output\_dns\_egress\_rule\_name) | Name of the DNS egress rule. Null when enable\_dns\_egress is false. |
| <a name="output_metadata_egress_rule_name"></a> [metadata\_egress\_rule\_name](#output\_metadata\_egress\_rule\_name) | Name of the metadata server egress rule. Null when enable\_metadata\_server\_egress is false. |
<!-- END_TF_DOCS -->
