terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 4.15.0"
    }
  }
}

locals {
  security_group_name = split("/", var.security_group_id)[8]
  resource_group_name = split("/", var.security_group_id)[4]
}

resource "azurerm_network_security_rule" "trustgrid_control_plane_1" {
  name                        = "${var.name_prefix}-tcp-8443-1"
  priority                    = var.security_group_rule_priority_start
  direction                  = "Outbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "8443"
  source_address_prefix      = "*"
  destination_address_prefix = "35.171.100.16/28"
  resource_group_name        = local.resource_group_name
  network_security_group_name = local.security_group_name
}

resource "azurerm_network_security_rule" "trustgrid_control_plane_2" {
  name                        = "${var.name_prefix}-tcp-8443-2"
  priority                    = var.security_group_rule_priority_start + 1
  direction                  = "Outbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "8443"
  source_address_prefix      = "*"
  destination_address_prefix = "34.223.12.192/28"
  resource_group_name        = local.resource_group_name
  network_security_group_name = local.security_group_name
}
