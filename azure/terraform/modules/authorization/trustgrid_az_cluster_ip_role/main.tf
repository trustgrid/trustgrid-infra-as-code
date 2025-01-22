terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 4.15.0"
    }
  }
}

resource "azurerm_role_definition" "tg_cluster_ip_role" {
  name  = "${var.name_prefix}-trustgrid-cluster-ip-role"
  scope = ""
  description = "Provides permissions required for Trustgrid clusters to manage a floating cluster IP address"
  permissions {
    actions = [
        "Microsoft.Network/networkInterfaces/read",
        "Microsoft.Network/networkInterfaces/write",
        "Microsoft.Network/networkInterfaces/ipconfigurations/read",
        "Microsoft.Network/networkInterfaces/ipconfigurations/join/action",
        "Microsoft.Network/networkSecurityGroups/join/action",
        "Microsoft.Network/virtualNetworks/subnets/read",
        "Microsoft.Compute/virtualMachines/read",
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/applicationSecurityGroups/joinIpConfiguration/action"
    ]
    not_actions = []
    data_actions = []
    not_data_actions = []
  }
  assignable_scopes = var.assignable_scopes
}