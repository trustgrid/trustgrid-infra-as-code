## ─── Identity ─────────────────────────────────────────────────────────────────

variable "project" {
  type        = string
  description = "GCP project ID in which to create the custom IAM role and project-level IAM binding. Routes are a project-global resource in GCP so the binding must be at project scope."
}

## ─── Custom role definition ────────────────────────────────────────────────────

variable "role_id" {
  type        = string
  description = "Unique ID for the custom IAM role within the project. Must contain only letters, digits, underscores, and dots, and be at most 64 characters. Must be unique within the project."
  default     = "trustgridRouteManager"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.]{1,64}$", var.role_id))
    error_message = "role_id must be 1–64 characters and contain only letters, digits, underscores, or dots."
  }
}

variable "role_title" {
  type        = string
  description = "Human-readable title for the custom IAM role shown in the GCP console."
  default     = "Trustgrid HA Route Manager"
}

variable "role_description" {
  type        = string
  description = "Description of the custom IAM role. Explains the purpose and least-privilege scope."
  default     = "Least-privilege role granting Trustgrid HA cluster nodes the compute.routes permissions required to perform route failover: list, get, create, and delete project routes."
}

## ─── Binding ───────────────────────────────────────────────────────────────────

variable "service_account_emails" {
  type        = list(string)
  description = "List of service account email addresses to bind to the route-manager custom role. Typically contains the email(s) from the trustgrid_node_service_account module. Accepts one or more values for HA configurations where multiple nodes share a service account, or each node has its own."

  validation {
    condition     = length(var.service_account_emails) > 0
    error_message = "At least one service_account_email must be provided."
  }

  validation {
    condition     = alltrue([for email in var.service_account_emails : can(regex("^[^@]+@[^@]+\\.iam\\.gserviceaccount\\.com$", email))])
    error_message = "Each entry in service_account_emails must be a valid GCP service account email ending in .iam.gserviceaccount.com."
  }
}
