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
  description = "GCP machine type for the Trustgrid node (e.g. n2-standard-2). Supported machine families: e2, n2, n2d, t2d."
  default     = "n2-standard-2"

  validation {
    condition     = contains(["e2", "n2", "n2d", "t2d"], split("-", var.machine_type)[0])
    error_message = "machine_type family must be one of: e2, n2, n2d, t2d. Unsupported families (e.g. n4, c4) are not supported by this module."
  }
}

variable "boot_disk_size_gb" {
  type        = number
  description = "Boot disk size in GB. 30 GB is the recommended minimum."
  default     = 30
}

variable "disk_type_mode" {
  type        = string
  description = "Controls how the boot disk type is selected. 'auto' (default) selects pd-balanced for all supported machine families. 'manual' uses the value of boot_disk_type directly and requires it to be set explicitly."
  default     = "auto"

  validation {
    condition     = contains(["auto", "manual"], var.disk_type_mode)
    error_message = "disk_type_mode must be either 'auto' or 'manual'."
  }
}

variable "boot_disk_type" {
  type        = string
  description = "Boot disk type override. Used only when disk_type_mode is 'manual'. Must be one of: pd-ssd, pd-balanced, pd-standard. Ignored when disk_type_mode is 'auto'."
  default     = null

  validation {
    condition = var.boot_disk_type == null || contains(
      ["pd-ssd", "pd-balanced", "pd-standard"],
      var.boot_disk_type
    )
    error_message = "boot_disk_type must be one of: pd-ssd, pd-balanced, pd-standard."
  }

  ## Cross-variable: manual mode requires a non-null value.
  validation {
    condition     = !(var.disk_type_mode == "manual" && var.boot_disk_type == null)
    error_message = "boot_disk_type must be set when disk_type_mode is 'manual'."
  }
}

variable "enable_secure_boot" {
  type        = bool
  description = "Enable Shielded VM secure boot. Disable only if using a custom image that is not signed."
  default     = true
}

## ─── Image ─────────────────────────────────────────────────────────────────────
##
## Image selection follows a two-tier priority:
##   1. Explicit pin  — set image_name to a full self_link or bare image name.
##                      image_project and image_family are ignored entirely.
##   2. Family lookup — leave image_name null (default). Terraform resolves the
##                      latest image in image_family from image_project at plan time.
##
## Production recommendation: pin image_name to a known-good release for
## stability.  Use family lookup (image_project + image_family) for test
## environments where "latest" is acceptable.

variable "image_project" {
  type        = string
  description = "GCP project that owns the Trustgrid node image. Used only when resolving an image by family (image_name is null). Defaults to the Trustgrid production image project. Override for test variants hosted in a separate project."
  default     = "trustgrid-images"

  validation {
    condition     = length(trimspace(var.image_project)) > 0
    error_message = "image_project must not be empty."
  }
}

variable "image_family" {
  type        = string
  description = "Image family to resolve the latest Trustgrid node image from. Used only when image_name is null. Defaults to the Trustgrid production family. Override for test variants (e.g. 'trustgrid-node-staging')."
  default     = "trustgrid-node"

  validation {
    condition     = length(trimspace(var.image_family)) > 0
    error_message = "image_family must not be empty."
  }
}

variable "image_name" {
  type        = string
  description = "Explicit image name or self_link to pin the instance to a specific Trustgrid image version (e.g. 'projects/trustgrid-images/global/images/trustgrid-node-20240101' or 'trustgrid-node-20240101'). When set, image_project and image_family are ignored. Recommended for production to avoid unintended image upgrades on re-apply."
  default     = null

  validation {
    condition     = var.image_name == null || try(length(trimspace(var.image_name)) > 0, false)
    error_message = "image_name must not be an empty string. Set to null to use family-based image resolution instead."
  }
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

## ─── Public Exposure ───────────────────────────────────────────────────────────

variable "public_exposure_mode" {
  type        = string
  description = "Controls how the management interface is exposed to the internet. 'direct_static_ip' (default) creates a module-owned static regional external IP and attaches it to nic0, preserving the same IP across redeployments. 'byo_public_ip' attaches a caller-provided reserved external IP (supply management_external_ip_address). 'private_only' attaches no external IP to nic0."
  default     = "direct_static_ip"

  validation {
    condition     = contains(["direct_static_ip", "byo_public_ip", "private_only"], var.public_exposure_mode)
    error_message = "public_exposure_mode must be one of: direct_static_ip, byo_public_ip, private_only."
  }
}

variable "management_external_ip_address" {
  type        = string
  description = "The reserved external IP address (not self_link) to attach to the management interface (nic0). Required when public_exposure_mode is 'byo_public_ip'. Must be a regional static external IP address in the same region as the instance. Ignored for all other modes."
  default     = null

  validation {
    condition     = !(var.public_exposure_mode == "byo_public_ip" && var.management_external_ip_address == null)
    error_message = "management_external_ip_address is required when public_exposure_mode is 'byo_public_ip'."
  }
}

## ─── IAM ───────────────────────────────────────────────────────────────────────

variable "service_account_email" {
  type        = string
  description = "Email of the GCP service account to attach to the instance. Create the service account outside this module (e.g. via the trustgrid_service_account helper module) and pass the email here."
}

## ─── Miscellaneous ─────────────────────────────────────────────────────────────

variable "serial_port_enable" {
  type        = bool
  description = "Enable the interactive serial console on the instance. Defaults to true and should remain enabled in almost all cases. The serial console is required to complete manual registration via the Trustgrid portal workflow and is the primary access path for critical troubleshooting when network connectivity is unavailable. Disabling it is not recommended — doing so will prevent manual registration and may make an unresponsive node unrecoverable without redeploying. When true, the GCP metadata key 'serial-port-enable' is set to '1', enabling access via the GCP Cloud Console or gcloud CLI. The module always controls this key; it cannot be overridden via extra_metadata."
  default     = true
}

variable "extra_metadata" {
  type        = map(string)
  description = "Additional instance metadata key/value pairs to merge with the module-managed metadata. Do not include tg-license, tg-registration-key, or serial-port-enable here; use the dedicated module variables instead."
  default     = {}
}

## ─── Scheduling ────────────────────────────────────────────────────────────────
##
## Spot (preemptible) VM support — for non-production / cost-sensitive workloads
## only. Spot VMs can be preempted by GCP at any time with a short notice window.
## Production deployments MUST use the default (enable_spot = false).

variable "enable_spot" {
  type        = bool
  description = "Enable Spot (preemptible) VM provisioning. When true the instance is created with provisioning_model = SPOT, preemptible = true, and automatic_restart = false, reducing cost at the expense of availability — GCP may terminate the instance at any time with short notice. **Intended for dev/test and cost-sensitive workloads only. Do not use in production.** Production deployments must use the default (false)."
  default     = false
}

variable "spot_instance_termination_action" {
  type        = string
  description = "Action GCP takes when a Spot VM is preempted. Used only when enable_spot = true. Accepted values: STOP (default — instance transitions to TERMINATED state, preserving disk and allowing manual restart) or DELETE (instance and disk are deleted immediately on preemption). STOP is the safer default for most workloads."
  default     = "STOP"

  validation {
    condition     = contains(["STOP", "DELETE"], var.spot_instance_termination_action)
    error_message = "spot_instance_termination_action must be one of: STOP, DELETE."
  }
}
