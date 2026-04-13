## ─── Identity ─────────────────────────────────────────────────────────────────

variable "account_id" {
  type        = string
  description = "The account ID (short name) for the service account. Must be 6–30 characters, start with a lowercase letter, and contain only lowercase letters, digits, and hyphens. Becomes the local part of the service account email: <account_id>@<project>.iam.gserviceaccount.com."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{5,29}$", var.account_id))
    error_message = "account_id must be 6–30 characters, start with a lowercase letter, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "display_name" {
  type        = string
  description = "Human-readable display name for the service account shown in the GCP console. Maximum 100 characters."
  default     = "Trustgrid Node Service Account"
}

variable "description" {
  type        = string
  description = "Optional free-text description of the service account's purpose. Displayed in the GCP console."
  default     = "Service account for a Trustgrid node. Grants only the permissions required for HA route failover and normal node operation."
}

## ─── Project ───────────────────────────────────────────────────────────────────

variable "project" {
  type        = string
  description = "GCP project ID in which to create the service account. If null, the project configured on the provider is used."
  default     = null
}
