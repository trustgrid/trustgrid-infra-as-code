## ─── Identity ─────────────────────────────────────────────────────────────────

variable "name" {
  type        = string
  description = "Name of the Compute Engine instance. Used as the GCP resource name."
}

variable "zone" {
  type        = string
  description = "GCP zone in which to create the instance (e.g. us-central1-a)."
}

## ─── Registration ──────────────────────────────────────────────────────────────

variable "registration_mode" {
  type        = string
  description = "Trustgrid registration mode. Use 'manual' to register the node via the portal after first boot, or 'auto' to supply a license and register automatically on first boot."
  default     = "manual"

  validation {
    condition     = contains(["manual", "auto"], var.registration_mode)
    error_message = "registration_mode must be either 'manual' or 'auto'."
  }
}

variable "license" {
  type        = string
  description = "Trustgrid node license. Optional when registration_mode is 'manual'. Required when registration_mode is 'auto'. Can be obtained from the Trustgrid portal, API, or the tg_license Terraform resource."
  default     = null
  sensitive   = true

  validation {
    condition     = !(var.registration_mode == "auto" && var.license == null)
    error_message = "license is required when registration_mode is 'auto'."
  }
}

variable "registration_key" {
  type        = string
  description = "Optional Trustgrid registration key used to associate the node with a specific cluster or configuration at first boot."
  default     = null
  sensitive   = true
}

## ─── Compute ───────────────────────────────────────────────────────────────────

variable "machine_type" {
  type        = string
  description = "GCP machine type for the Trustgrid node (e.g. n2-standard-2)."
  default     = "n2-standard-2"
}

variable "boot_disk_size_gb" {
  type        = number
  description = "Boot disk size in GB. 30 GB is the recommended minimum."
  default     = 30
}

variable "boot_disk_type" {
  type        = string
  description = "Boot disk type (pd-ssd, pd-balanced, or pd-standard)."
  default     = "pd-ssd"

  validation {
    condition     = contains(["pd-ssd", "pd-balanced", "pd-standard"], var.boot_disk_type)
    error_message = "boot_disk_type must be one of: pd-ssd, pd-balanced, pd-standard."
  }
}

variable "enable_secure_boot" {
  type        = bool
  description = "Enable Shielded VM secure boot. Disable only if using a custom image that is not signed."
  default     = true
}

## ─── Image ─────────────────────────────────────────────────────────────────────

variable "image_project" {
  type        = string
  description = "GCP project that owns the Trustgrid node image. Used when resolving an image by family. Set to the Trustgrid production image project by default."
  default     = "trustgrid-images"
}

variable "image_family" {
  type        = string
  description = "Image family to resolve the latest Trustgrid node image from. Ignored when image_name is set."
  default     = "trustgrid-node"
}

variable "image_name" {
  type        = string
  description = "Explicit image name or self_link to pin the instance to a specific Trustgrid node image version. When set, image_project and image_family are ignored."
  default     = null
}

## ─── Network ───────────────────────────────────────────────────────────────────

variable "management_subnetwork" {
  type        = string
  description = "Self-link or name of the subnetwork for the management (WAN/nic0) interface. Must have internet egress for control-plane connectivity."
}

variable "data_subnetwork" {
  type        = string
  description = "Self-link or name of the subnetwork for the data (LAN/nic1) interface."
}

variable "network_tags" {
  type        = list(string)
  description = "List of network tags to apply to the instance. Use these to target VPC firewall rules without managing firewall resources inside this module."
  default     = []
}

## ─── IAM ───────────────────────────────────────────────────────────────────────

variable "service_account_email" {
  type        = string
  description = "Email of the GCP service account to attach to the instance. Create the service account outside this module (e.g. via the trustgrid_service_account helper module) and pass the email here."
}

## ─── Miscellaneous ─────────────────────────────────────────────────────────────

variable "extra_metadata" {
  type        = map(string)
  description = "Additional instance metadata key/value pairs to merge with the module-managed metadata. Do not include tg-license or tg-registration-key here; use the license and registration_key variables instead."
  default     = {}
}
