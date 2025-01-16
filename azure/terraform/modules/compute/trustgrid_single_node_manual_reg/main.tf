terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.15.0"
    }
  }
}

## Create Network Resources
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.name}-public-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "public" {
  name                = "${var.name}-public-nic"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                            = "external"
    subnet_id                       = var.public_subnet_id
    private_ip_address_allocation   = "Dynamic"
    public_ip_address_id            = azurerm_public_ip.public_ip.id
    primary                         = true
  }
}

resource "azurerm_network_interface_security_group_association" "public" {
  network_interface_id = azurerm_network_interface.public.id
  network_security_group_id = var.public_security_group_id
}

resource "azurerm_network_interface" "private" {
  name                = "${var.name}-private-nic"
  resource_group_name = var.resource_group_name
  location            = var.location
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "private"
    subnet_id                     = var.private_subnet_id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }
}

resource "azurerm_network_interface_security_group_association" "private" {
  network_interface_id = azurerm_network_interface.private.id
  network_security_group_id = var.private_security_group_id
}

## Compute Resources

data "azurerm_shared_image_version" "tg_image" {
   name                = var.tg_version
   image_name  = "trustgrid-node-2204-${var.tg_tenant}"
   gallery_name        = var.tg_image_gallery
}

resource "azurerm_linux_virtual_machine" "node" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = "ubuntu"
  source_image_id     = data.azurerm_shared_image_gallery_image_version.tg_image.id
  zone = var.availability_zone

  network_interface_ids = [
    azurerm_network_interface.public.id,
    azurerm_network_interface.private.id,
  ]

  admin_ssh_key {
    username   = var.admin_ssh_username
    public_key = var.admin_ssh_key_pub
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb = var.os_disk_size
  }

  identity {
    type      = "SystemAssigned"
  }

  boot_diagnostics {}

  lifecycle {
    ignore_changes = all
  }
}