terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 4.15.0"
    }
  }
}

resource "azurerm_role_definition" "tg_cluster_route_role" {
  name  = "${var.name_prefix}-trustgrid-cluster-route-role"
  scope = var.scope
  description = "Provides permissions required for Trustgrid clusters to manage updating routes in Azure"
  permissions {
    actions = [
      "Microsoft.Network/networkWatchers/nextHop/action",
      "Microsoft.Network/networkInterfaces/effectiveRouteTable/action",
      "Microsoft.Network/routeTables/routes/delete",
      "Microsoft.Network/routeTables/routes/write",
      "Microsoft.Network/routeTables/routes/read",
      "Microsoft.Network/routeTables/join/action",
      "Microsoft.Network/routeTables/delete",
      "Microsoft.Network/routeTables/write",
      "Microsoft.Network/routeTables/read",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Compute/virtualMachines/read"
    ]
    not_actions = []
    data_actions = []
    not_data_actions = []
  }
  assignable_scopes = var.assignable_scopes
}