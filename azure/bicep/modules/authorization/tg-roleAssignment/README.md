# Trustgrid Role Assignment module
Used in combination with the `tg-routeTableRole` module, this module will assign the created role to a Trustgrid node VM created by the `tg-single-node`module. This module will need to be called for each member of the HA cluster.

## Parameters
- `vmName` - (string) The name of the VM to assign the role to. No default. Use the `vmName` output from the `tg-single-node` module.
- `roleGUID`- (string) The GUID of the role to assign to the VM. No default. Use the `routeTableRoleGUID` output from the `tg-routeTableRole` module.

## Outputs
None at this time