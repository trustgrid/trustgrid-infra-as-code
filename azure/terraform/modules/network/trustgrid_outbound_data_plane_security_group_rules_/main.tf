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

resource "azurerm_network_security_rule" "tcp_rules" {
  for_each                    = { for idx, endpoint in var.data_plane_endpoints : idx => endpoint }
  name                        = "${var.name_prefix}-tcp-${each.key}"
  resource_group_name         = local.resource_group_name
  network_security_group_name = local.security_group_name
  priority                    = var.security_group_rule_priority_start + (each.key * 2)
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = each.value.port
  source_address_prefix      = "*"
  destination_address_prefix = each.value.ip
}

resource "azurerm_network_security_rule" "udp_rules" {
  for_each                    = var.enable_udp ? { for idx, endpoint in var.data_plane_endpoints : idx => endpoint } : {}
  name                        = "${var.name_prefix}-udp-${each.key}"
  resource_group_name         = local.resource_group_name
  network_security_group_name = local.security_group_name
  priority                    = var.security_group_rule_priority_start + (each.key * 2) + 1
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range          = "*"
  destination_port_range     = each.value.port
  source_address_prefix      = "*"
  destination_address_prefix = each.value.ip
}
