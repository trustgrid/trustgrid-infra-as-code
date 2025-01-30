@description('Name of virtual machine to assign the role')
param vmName string

@description('GUID of the role that will be assigned to the VM')
param roleGUID string

var roleDefID = subscriptionResourceId('Microsoft.Authorization/roleDefinitions/',roleGUID)
var roleAssignmentId = guid(subscription().id, resourceGroup().id, vmName)

resource targetVM 'Microsoft.Compute/virtualMachines@2023-03-01' existing = {
  name: vmName
}

resource tgRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentId
  properties: {
    principalId: targetVM.identity.principalId
    roleDefinitionId: roleDefID
  }
}
