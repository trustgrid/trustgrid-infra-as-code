## ─── Identity ─────────────────────────────────────────────────────────────────

variable "name_prefix" {
  type        = string
  description = "Prefix applied to the firewall rule name. Use a value that identifies the deployment, e.g. the gateway node or cluster name."
}

variable "network" {
  type        = string
  description = "Self-link or name of the VPC network to which this firewall rule applies. Must be the management (WAN) VPC network — the same network used for the management interface (nic0) on Trustgrid gateway nodes."
}

## ─── Ingress configuration ─────────────────────────────────────────────────────

variable "source_ranges" {
  type        = list(string)
  description = "Source IPv4 CIDR ranges allowed to reach the gateway on the gateway_port. Defaults to unrestricted (0.0.0.0/0) because edge node public IPs are typically dynamic. Restrict to known edge node CIDRs when possible for a tighter least-privilege posture."
  default     = ["0.0.0.0/0"]
}

variable "gateway_port" {
  type        = number
  description = "TCP/UDP port on which gateway nodes accept inbound tunnel traffic. The Trustgrid default is 8443. Change only if the gateway has been explicitly configured to listen on a different port."
  default     = 8443

  validation {
    condition     = var.gateway_port >= 1 && var.gateway_port <= 65535
    error_message = "gateway_port must be a valid TCP/UDP port number (1–65535)."
  }
}

## ─── Targeting ─────────────────────────────────────────────────────────────────

variable "target_tags" {
  type        = list(string)
  description = "Network tags that scope this ingress rule to specific instances. Strongly recommended in production — use the same tags applied to Trustgrid gateway node instances (e.g. [\"trustgrid-mgmt\"]). An empty list applies the rule to all instances in the VPC."
  default     = []
}

## ─── Behavior ──────────────────────────────────────────────────────────────────

variable "priority" {
  type        = number
  description = "GCP firewall rule priority. Lower values take precedence. The default (1000) is the GCP standard priority."
  default     = 1000
}

variable "enable_logging" {
  type        = bool
  description = "When true, enables GCP Firewall Rules Logging on the gateway ingress rule. Logging generates additional cost — enable in environments where audit trails or troubleshooting visibility are required."
  default     = false
}
