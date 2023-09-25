@description('Name of Trustgrid Appliance VM. Used as prefix for related resources. Min 4, Max 50.')
@minLength(4)
@maxLength(50)
param vmName string = 'tgnode'

@description('Instance Type of the Trustgrid Appliance VM')
@allowed(['Standard_B2s', 'Standard_B2ms', 'Standard_B4ms', 'Standard_B8ms', 'Standard_B12ms' , 'Standard_B16ms', 'Standard_B20ms', 'Standard_A2_v2', 'Standard_A4_v2', 'Standard_A8_v2', 'Standard_A2m_v2', 'Standard_A4m_v2', 'Standard_A8m_v2'])
param vmSize string = 'Standard_B2s'

@description('Username for the virtual machine. WARNING: changing this username may cause issues.')
param defaultAdmin string = 'ubuntu'

@description('RSA Key 2048 bit public key used to login to the virtual machine. NOTE: SSH access and the defaultAdmin user are disabled after successful registration with Trustgrid. This key is only used during pre-registration.')
param sshPublicKey string

@description('Storage Type Used for OS Disk')
@allowed(['Standard_LRS', 'Premium_LRS'])
param osDiskType string = 'Standard_LRS'

param osDiskSizeGB int = 30

param imageTenant string = 'prod'

@allowed(['2204'])
param imageOS string = '2204'

param imageVersion string = 'latest'

@description('Public IP SKU Name')
@allowed(['Basic','Standard'])
param publicIPSKUName string = 'Basic'

@description('Name of virtual network that the Trustgrid Appliance VM will be attached to')
param virtualNetworkName string

@description('Name of outside subnet the Trustgrid Appliance VM outside facing interface will connect to')
param outsideSubnetName string

@description('The ID of the network security group to associate with the outside network interface')
param outsideSecrityGroupName string

@description('Name of inside subnet the Trustgrid Appliance VM inside facing interface will connect to')
param insideSubnetName string

param location string = resourceGroup().location

var trustgridGallery = 'Trustgrid-45680719-9aa7-43b9-a376-dc03bcfdb0ac'

resource outsideSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  name: '${virtualNetworkName}/${outsideSubnetName}'
}

resource outsideSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-04-01' existing = {
  name: outsideSecrityGroupName
}

resource insideSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  name: '${virtualNetworkName}/${insideSubnetName}'
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${vmName}-publicIP'
  location:  location
  sku: {
    name: publicIPSKUName
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    deleteOption: 'Delete'
    publicIPAllocationMethod: 'Static'
  }
}

resource outsideNIC 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${vmName}-outside-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${vmName}-outside-nic-ipconfig1'
        properties: {
          privateIPAddressVersion: 'IPv4'
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
          subnet: { 
            id: outsideSubnet.id
            }
          }
      }
    ]
    networkSecurityGroup: {
      id: outsideSecurityGroup.id
      }
  }
}

resource insideNIC 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${vmName}-inside-nic'
  location: location
  properties: {
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: '${vmName}-inside-nic-ipconfig1'
        properties: {
          privateIPAddressVersion: 'IPv4'
          privateIPAllocationMethod: 'Dynamic'
          subnet: { 
            id: insideSubnet.id
          }
        }
      }
    ]
  }
}

resource tgnodevm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize

    }
    networkProfile: {
      networkInterfaces: [
        {
          id: outsideNIC.id
          properties: {
            primary: true
            deleteOption: 'Delete'
          }
        }
        {
          id: insideNIC.id
          properties: {
            primary: false
            deleteOption: 'Delete'
          }
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: defaultAdmin
      linuxConfiguration: {
        disablePasswordAuthentication: true
        patchSettings: {
          assessmentMode: 'ImageDefault'
        }
        ssh: {
          publicKeys: [
            {
              keyData: sshPublicKey
              path: '/home/${defaultAdmin}/.ssh/authorized_keys'
            }
          ]
        }
      }
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
        diskSizeGB: osDiskSizeGB
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference:  {
        communityGalleryImageId: '/communityGalleries/${trustgridGallery}/images/trustgrid-node-${imageOS}-${imageTenant}/versions/${imageVersion}'
      }
    }
  }
 }

output publicIPAddress string = publicIP.properties.ipAddress
output vmPrincipalId string = tgnodevm.identity.principalId
output vmName string = tgnodevm.name
output outsideNIC object = outsideNIC
output insideNIC object = insideNIC
output tgnodevm object = tgnodevm
