targetScope = 'resourceGroup'

@description('Name prefix for resources created by this template')
param roleName string = 'trustgrid-route-table'

@description('Detailed description of role definition')
param roleDescription string = 'Grants Trustgrid nodes ability to manage route table entries for HA failover'

var roleDefName = guid(resourceGroup().id, roleName)

resource routeTableRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: roleDefName
  properties: {
    assignableScopes: [
      resourceGroup().id
    ]
    description: roleDescription
    roleName: roleName
    type: 'customRole'
    permissions: [
      {
        actions: [
          'Microsoft.Network/networkWatchers/nextHop/action'
					'Microsoft.Network/networkInterfaces/effectiveRouteTable/action'
					'Microsoft.Network/routeTables/routes/delete'
					'Microsoft.Network/routeTables/routes/write'
					'Microsoft.Network/routeTables/routes/read'
					'Microsoft.Network/routeTables/join/action'
					'Microsoft.Network/routeTables/delete'
					'Microsoft.Network/routeTables/write'
					'Microsoft.Network/routeTables/read'
					'Microsoft.Network/networkInterfaces/read'
					'Microsoft.Network/virtualNetworks/read'
          'Microsoft.Compute/virtualMachines/read'
        ]
        notActions: []
        dataActions: [] 
        notDataActions: []
      }
    ]
  }  
}

output routeTableRoleGUID string = routeTableRole.name
output routeTableRole object = routeTableRole
