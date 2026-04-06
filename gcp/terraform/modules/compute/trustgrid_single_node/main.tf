terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

## Resolve the boot disk image.
## Priority: explicit image name > family lookup (project + family).
data "google_compute_image" "node_image" {
  count   = var.image_name == null ? 1 : 0
  project = var.image_project
  family  = var.image_family
}

locals {
  ## Use the explicitly pinned image name when supplied; fall back to the
  ## family-resolved self_link so Terraform never accidentally re-resolves
  ## to a newer image on re-apply (lifecycle ignore_changes = all handles
  ## the instance, but we keep the reference deterministic at plan time).
  boot_image = var.image_name != null ? var.image_name : data.google_compute_image.node_image[0].self_link

  ## Render the startup script for the chosen registration mode.
  ## In manual mode the script exits immediately; in auto mode it writes the
  ## license (and optional registration key) to disk and calls register.sh.
  startup_script = templatefile("${path.module}/templates/bootstrap.sh.tpl", {
    registration_mode = var.registration_mode
    license           = var.license != null ? var.license : ""
    registration_key  = var.registration_key != null ? var.registration_key : ""
  })
}

## Compute instance
resource "google_compute_instance" "node" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone

  ## Trustgrid nodes route traffic between interfaces — IP forwarding required.
  can_ip_forward = true

  tags = var.network_tags

  ## Management / WAN interface (nic0)
  network_interface {
    subnetwork = var.management_subnetwork
  }

  ## Data / LAN interface (nic1)
  network_interface {
    subnetwork = var.data_subnetwork
  }

  boot_disk {
    initialize_params {
      image = local.boot_image
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = merge(
    var.extra_metadata,
    # tg-license is read by the bootstrap script in auto-registration mode; the
    # script retrieves it from the instance metadata API so that the value never
    # lands on disk before the script controls permissions.
    var.registration_mode == "auto" ? { "tg-license" = var.license } : {},
    # tg-registration-key is an optional cluster/configuration key consumed by
    # the bootstrap script when supplied; injected regardless of mode so the
    # script can discover it via the metadata API.
    var.registration_key != null ? { "tg-registration-key" = var.registration_key } : {},
  )

  ## metadata_startup_script is executed by the GCP guest agent on first boot
  ## (and on any subsequent boot where the script content changes). The rendered
  ## script handles both manual and auto registration paths.
  metadata_startup_script = local.startup_script

  shielded_instance_config {
    enable_secure_boot          = var.enable_secure_boot
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  lifecycle {
    ignore_changes = all
  }
}
