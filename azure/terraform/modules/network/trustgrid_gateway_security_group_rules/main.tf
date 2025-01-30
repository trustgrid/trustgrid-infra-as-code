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
}

data "azurerm_resource_group" "rg" {
  name = split("/", var.security_group_id)[4]
}

resource "azurerm_application_security_group" "trustgrid_gateway" {
  name                = "${var.name_prefix}-trustgrid-gateway-asg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "data_plane_tcp" {
  count                       = var.trustgrid_data_plane_gateway_tcp ? 1 : 0
  name                        = "${var.name_prefix}-trustgrid-data-plane-tcp"
  priority                    = var.security_group_rule_priority_start
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = var.trustgrid_data_plane_gateway_tcp_port
  source_address_prefix      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.trustgrid_gateway.id]
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = local.security_group_name
}

resource "azurerm_network_security_rule" "data_plane_udp" {
  count                       = var.trustgrid_data_plane_gateway_udp ? 1 : 0
  name                        = "${var.name_prefix}-trustgrid-data-plane-udp"
  priority                    = var.security_group_rule_priority_start + 1
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range          = "*"
  destination_port_range     = var.trustgrid_data_plane_gateway_udp_port
  source_address_prefix      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.trustgrid_gateway.id]
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = local.security_group_name
}

resource "azurerm_network_security_rule" "ztna" {
  count                       = var.trustgrid_ztna_gateway ? 1 : 0
  name                        = "${var.name_prefix}-trustgrid-ztna"
  priority                    = var.security_group_rule_priority_start + 2
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = var.trustgrid_ztna_gateway_port
  source_address_prefix      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.trustgrid_gateway.id]
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = local.security_group_name
}

resource "azurerm_network_security_rule" "wireguard" {
  count                       = var.trustgrid_wireguard_gateway ? 1 : 0
  name                        = "${var.name_prefix}-trustgrid-wireguard"
  priority                    = var.security_group_rule_priority_start + 3
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range          = "*"
  destination_port_range     = var.trustgrid_wireguard_gateway_port
  source_address_prefix      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.trustgrid_gateway.id]
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = local.security_group_name
}
