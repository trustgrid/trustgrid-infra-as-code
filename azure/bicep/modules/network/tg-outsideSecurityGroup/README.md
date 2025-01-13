# Trustgrid Security Group Module
This module deploys a security group to Azure that can be attached to the **outside** interface of a Trustgrid virtual appliance with the required connectivity to function. It creates a security group and attaches the inbound/outbound rules based on the parameters passed. 

There are two important parameters that determine the security group rules:
`tgGateway` is only required if the Trustgrid node will act as a gateway, meaning it receives connections from other Trustgrid appliances. If you are deploying a device to grant your vendor access this should be kept as **false**. This will prevent unnecessary inbound rules from being created.

`tgDataPlaneClient` is required for all Trustgrid nodes to create outbound rules to allow the attached Trustgrid nodes to communicate with the specified Data Plane gateways. If your default security group rules allows all outbound Internet traffic these rules are extraneous, but it's advisable to keep them. This should only be set to **false** for a gateway that will never need to connect to another Trustgrid gateway.


## Parameters

- `tgGateway` - Boolean - Determines if inbound rules are required to allow Trustgrid appliances attached to the security group to act as a gateway. Default is **false**.
- `tgTCPGatewayPort` - Integer - TCP port for Trustgrid gateway functionality if tgGateway is true. Default is 8443.
- `tgUDPGatewayPort` - Integer - UDP port for Trustgrid gateway functionality if tgGateway is true. Default is 8443.
- `tgControlPlaneNetworkCIDRs` - Array - List of CIDR blocks that the attached appliance should allowed to make outbound connections to for control plane functionality. Defaults to Trustgrid's two production /28 networks. There should be no need to override this normally.
- `tgControlPlaneTCPPorts` - Array - List of TCP ports that the attached appliance should be allowed to make outbound connections on for control plane functionality. Defaults to 443 and 8443. There should be no need to override this normally.
- `tgDataPlaneClient` - Boolean - Determines if outbound rules are required for the attached appliance(s) to connect to Trustgrid gateways. Default is **true**. It is rare that a Trustgrid appliance requires both this setting and `tgGateway` to be true, unless you are building a mesh topology.
- `tgDataPlaneNetworkCIDRs` - Array - List of CIDR blocks that the attached appliance should allowed to make outbound connections to for data plane functionality. No default is provided, this must be specified based on the gateways configured in the target Trustgrid network. 
    - If you do not want to limit to specific CIDRs, pass an array of `['0.0.0.0/0']`
    - If your default rules include AllowInternetOutbound allow any traffic to any internet address these rules are redundant.
- `tgDataPlaneTCPPorts` - Array - List of TCP ports that the attached appliance should be allowed to make outbound connections on for data plane functionality. Defaults to 8443. If gateways in the target Trustgrid network listen on additional ports, they should be specified here.
- `tgDataPlaneUDPPorts` - Array - List of UDP ports that the attached appliance should be allowed to make outbound connections on for data plane functionality. Defaults to 8443. If gateways in the target Trustgrid network listen on additional ports, they should be specified here.

## Outputs
- `securityGroup` - (object) - The security group object created by the module.
- `securityGroupName` - (string) - The name of the security group created by the module.