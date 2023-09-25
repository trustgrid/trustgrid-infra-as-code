# Trustgrid Route Table Role module
This module creates a role that can be used to grant a Trustgrid node access to a route table necessary for deploying a [highly available cluster](https://docs.trustgrid.io/tutorials/deployments/deploy-azure/#requirements-for-ha-failover). The created role is scoped to the resource group it is deployed in.

## Parameters
- `roleName` - (string) Name of the role to create. Default: 'trustgrid-route-table'
- `roleDescription` -(string) Description of the role. Default: 'Grants Trustgrid nodes ability to manage route table entries for HA failover'

## Output
- `routeTableRoleGUID` - (string) GUID/Name of the created role
- `routeTableRole` - (object) The full role definition object
