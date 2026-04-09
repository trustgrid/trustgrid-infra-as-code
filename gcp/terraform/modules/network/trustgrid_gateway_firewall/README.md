# trustgrid\_gateway\_firewall — GCP Gateway Ingress Firewall Module

This helper module creates the **gateway ingress firewall rule** required to
allow edge nodes to establish data-plane tunnels with a Trustgrid gateway node
on GCP.

> **Edge nodes only — do not apply this module to edge-only nodes.**
> Edge nodes require only *egress* rules (use `trustgrid_mgmt_firewall`).
> Gateway nodes require both egress (control-plane) and ingress (tunnel).

The rule permits inbound **TCP on port 8443** (configurable) on the management
VPC network. **UDP ingress is also enabled by default** and is recommended for
improved tunnel performance, but can be disabled by setting
`enable_udp_ingress = false`. The rule is scoped to instances carrying the
specified network tags.

---

## What this module creates

| Rule name | Direction | Protocol | Default port | Default source | Purpose |
|---|---|---|---|---|---|
| `<prefix>-gw-ingress` | INGRESS | TCP + UDP (optional, default: on) | 8443 | `0.0.0.0/0` | Accept tunnel connections from edge nodes |

---

## Least-privilege guidance

| Setting | Recommendation |
|---|---|
| `target_tags` | **Always set in production.** Apply the same network tag(s) used on Trustgrid gateway node instances (e.g. `["trustgrid-mgmt"]`). |
| `source_ranges` | Default is `["0.0.0.0/0"]` because edge node public IPs are typically dynamic. If all edge nodes have known static IPs, restrict `source_ranges` to those CIDRs for a tighter posture. |
| `gateway_port` | Keep at `8443` (the Trustgrid default) unless your gateway is explicitly configured to listen on a different port. |
| `enable_udp_ingress` | Defaults to `true` (recommended). Set to `false` only if your network policy prohibits inbound UDP or your deployment uses TCP-only tunnels. |
| `enable_logging` | Enable in regulated/audit environments; leave off in cost-sensitive deployments. |

---

## Usage

### Default — allow any source to reach the gateway on 8443

```hcl
module "tg_gw_fw" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_gateway_firewall?ref=v0.3.0"

  name_prefix = "my-tg-gateway"
  network     = "projects/my-project/global/networks/mgmt-vpc"
  target_tags = ["trustgrid-mgmt"]
}
```

### Restricted source ranges (known edge node IPs)

```hcl
module "tg_gw_fw" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_gateway_firewall?ref=v0.3.0"

  name_prefix   = "my-tg-gateway"
  network       = "projects/my-project/global/networks/mgmt-vpc"
  target_tags   = ["trustgrid-mgmt"]
  source_ranges = ["203.0.113.0/24", "198.51.100.0/24"]
}
```

### Non-default gateway port

```hcl
module "tg_gw_fw" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_gateway_firewall?ref=v0.3.0"

  name_prefix  = "my-tg-gateway"
  network      = "projects/my-project/global/networks/mgmt-vpc"
  target_tags  = ["trustgrid-mgmt"]
  gateway_port = 9443
}
```

### TCP-only ingress (UDP disabled)

```hcl
module "tg_gw_fw" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_gateway_firewall?ref=v0.3.0"

  name_prefix        = "my-tg-gateway"
  network            = "projects/my-project/global/networks/mgmt-vpc"
  target_tags        = ["trustgrid-mgmt"]
  enable_udp_ingress = false
}
```

### Combined with management egress module

Gateway nodes require both egress and ingress rules. Use both modules together:

```hcl
module "tg_mgmt_fw" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_mgmt_firewall?ref=v0.3.0"

  name_prefix = "my-tg-gateway"
  network     = "projects/my-project/global/networks/mgmt-vpc"
  target_tags = ["trustgrid-mgmt"]
}

module "tg_gw_fw" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//gcp/terraform/modules/network/trustgrid_gateway_firewall?ref=v0.3.0"

  name_prefix = "my-tg-gateway"
  network     = "projects/my-project/global/networks/mgmt-vpc"
  target_tags = ["trustgrid-mgmt"]
}
```

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
| [google_compute_firewall.gateway_ingress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix applied to the firewall rule name. | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | Self-link or name of the management (WAN) VPC network. | `string` | n/a | yes |
| <a name="input_source_ranges"></a> [source\_ranges](#input\_source\_ranges) | Source IPv4 CIDR ranges allowed to reach the gateway. Default is unrestricted (0.0.0.0/0). | `list(string)` | `["0.0.0.0/0"]` | no |
| <a name="input_gateway_port"></a> [gateway\_port](#input\_gateway\_port) | TCP/UDP port the gateway node listens on for tunnel traffic. Trustgrid default is 8443. | `number` | `8443` | no |
| <a name="input_target_tags"></a> [target\_tags](#input\_target\_tags) | Network tags scoping the rule to specific instances. Recommended in production. | `list(string)` | `[]` | no |
| <a name="input_priority"></a> [priority](#input\_priority) | GCP firewall rule priority (lower wins). | `number` | `1000` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Enable GCP Firewall Rules Logging on the gateway ingress rule. | `bool` | `false` | no |
| <a name="input_enable_udp_ingress"></a> [enable\_udp\_ingress](#input\_enable\_udp\_ingress) | When true, the gateway ingress rule permits UDP in addition to TCP on gateway_port. UDP tunnel traffic improves performance and is recommended for most deployments. Set to false if your network policy restricts inbound UDP or you only need TCP tunnels. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway_ingress_rule_name"></a> [gateway\_ingress\_rule\_name](#output\_gateway\_ingress\_rule\_name) | Name of the gateway ingress firewall rule. |
| <a name="output_gateway_ingress_rule_self_link"></a> [gateway\_ingress\_rule\_self\_link](#output\_gateway\_ingress\_rule\_self\_link) | Self-link of the gateway ingress firewall rule. |
<!-- END_TF_DOCS -->
