## ─── Identity ─────────────────────────────────────────────────────────────────

variable "name_prefix" {
  type        = string
  description = "Prefix applied to all firewall rule names created by this module. Use a value that identifies the deployment, e.g. the node or cluster name."
}

variable "network" {
  type        = string
  description = "Self-link or name of the VPC network to which these firewall rules apply. Must be the management (WAN) VPC network."
}

## ─── Control-plane egress ──────────────────────────────────────────────────────

variable "control_plane_cidr_ranges" {
  type        = list(string)
  description = "Destination CIDR ranges for the Trustgrid control plane. Defaults to the published Trustgrid control plane blocks (35.171.100.16/28 and 34.223.12.192/28). Override only if traffic is proxied through an NVA or firewall. See https://docs.trustgrid.io/help-center/kb/site-requirements/"
  default     = ["35.171.100.16/28", "34.223.12.192/28"]
}

## ─── DNS egress ────────────────────────────────────────────────────────────────

variable "enable_dns_egress" {
  type        = bool
  description = "When true, creates a firewall rule permitting TCP/UDP 53 egress to dns_server_cidr_ranges. Set to false if your VPC has a permissive default egress policy that already covers DNS."
  default     = true
}

variable "dns_server_cidr_ranges" {
  type        = list(string)
  description = "Destination CIDR ranges for the DNS egress rule. Defaults to Google Public DNS (8.8.8.8/32 and 8.8.4.4/32). Replace with your VPC or on-premises resolver addresses."
  default     = ["8.8.8.8/32", "8.8.4.4/32"]
}

## ─── GCP metadata server egress ────────────────────────────────────────────────

variable "enable_metadata_server_egress" {
  type        = bool
  description = "When true, creates a firewall rule permitting TCP 80 egress to the GCP metadata server (169.254.169.254/32). Required unless your VPC already permits link-local egress."
  default     = true
}

## ─── Targeting ─────────────────────────────────────────────────────────────────

variable "target_tags" {
  type        = list(string)
  description = "Network tags that scope these egress rules to specific instances. Strongly recommended in production — use the same tags applied to Trustgrid node instances (e.g. [\"trustgrid-mgmt\"]). An empty list applies the rules to all instances in the VPC."
  default     = []
}

## ─── Behavior ──────────────────────────────────────────────────────────────────

variable "priority" {
  type        = number
  description = "GCP firewall rule priority. Lower values take precedence. The default (1000) is the GCP standard priority. Adjust if you need to override other rules in the same network."
  default     = 1000
}

variable "enable_logging" {
  type        = bool
  description = "When true, enables GCP Firewall Rules Logging on all rules created by this module. Logging generates additional cost — enable in environments where audit trails or troubleshooting visibility are required."
  default     = false
}
