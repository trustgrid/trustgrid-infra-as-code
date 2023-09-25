# Trustgrid Single Node Module
This module creates a single VM using the Trustgrid image published in our shared image gallery. After deployment is complete, the VM will be ready to be registered with a Trustgrid account. 

The created VM has the following attributes:
- Two network interfaces
    - Outside interface with a Public IP and security group attached. Use the `tg-outsideSecurityGroup` module to define the security group with the required rules. This interface will be used to connect to the Trustgrid Control Plane and either provide Data Plane gateway services or connect to existing Data Plane gateways.
    - Inside interface - This interface will be used as the point of ingress and egress between your Azure resources and the Trustgrid overlay network created across the data plane.

Due to the large number of parameters there is an `exampleparams.json` file in this directory that can be used as a template for providing the most common parameters that do not have defaults defined. These parameters include `vmName`,`virtualNetworkName`, `outsideSubnetName`, `insideSubnetName`. 

`sshPublicKey` is not included for security reasons but does need to be provided for a successful deployment. 

## Parameters

### VM Settings
- `vmName` - (string) - Name of the VM to be created. Highly recommend this is changed to something more specific.  Default: tgnode 
- `vmSize` - (string) - The VM instances size to be deployed. This can be changed later but is disruptive to do so. 
    - Default: 'Standard_B2s'
    - Allowed values: ['Standard_B2s', 'Standard_B2ms', 'Standard_B4ms', 'Standard_B8ms', 'Standard_B12ms' , 'Standard_B16ms', 'Standard_B20ms', 'Standard_A2_v2', 'Standard_A4_v2', 'Standard_A8_v2', 'Standard_A2m_v2', 'Standard_A4m_v2', 'Standard_A8m_v2']
- `defaultAdmin` - (string) - Admin user created by Azure during deployment Default: `ubuntu` **Do Not Change**
- `sshPublicKey` - (string) - Azure requires providing a valid public RSA SSH key. SSH will be disabled after registration, but a key still must be provided.

### OS Disk Settings
- `osDiskType` - (string) - Azure managed disk type. 
    - Default: 'Standard_LRS'
    - Allowed: ['Standard_LRS', 'Premium_LRS']
- `osDiskSizeGB` - (integer) - Size of the OS managed disk in gigabytes (GB). Default: 30 

### Image Settings
- `imageTenant` - (string) - **Do Not Change unless advised by Trustgrid support** 
- `imageOS` - (string) - Base OS used for the deployed Trustgrid node. Default: '2204'
- `imageVersion` - (string) - **Do Not Change unless advised by Trustgrid support** Default: `latest`

### Network Settings
- `publicIPSKUName` - (string) - determines the Public IP type provisioned for the VM.  See Azure documentation for the details. 
    - Default: 'Basic'
    - Allowed: ['Basic','Standard']
- `virtualNetworkName` - (string) - Name of virtual network that the Trustgrid Appliance VM will be attached to.
- `outsideSubnetName` - (string) - Name of outside subnet the Trustgrid Appliance VM outside facing interface will connect to.
- `outsideSecurityGroupName` - (string) - The ID of the network security group to associate with the outside network interface. Use the `securityGroupName` of the `tg-outsideSecurityGroup` module.
- `insideSubnetName` - (string) - Name of inside subnet the Trustgrid Appliance VM inside facing interface will connect to.

## Outputs

- `publicIPAddress` - (string) - The public IP address provisioned for the VM. 
- `vmPrincipalId` - (string) -  The Managed System Identity principal ID of the created VM.
- `vmName` - (string) - Created VM name. Should duplicate vmName input parameter. 
- `outsideNIC` - (object) - The full outside NIC definition
- `insideNIC` - (object) - The full inside NIC definition
- `tgnodevm` - (object) - The full VM definition