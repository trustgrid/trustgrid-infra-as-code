@description('namePrefix for security group and related resources. Min 2, Max 60 characters.')
@minLength(2)
@maxLength(60)
param namePrefix string

param location string = resourceGroup().location

@description('Determines if this security group should allow attached nodes to act as Trustgrid gateways and listen for incoming connections on the gateway port (default 8443).')
param tgGateway bool = false

@minValue(1024)
@maxValue(65535)
@description('TCP port that the gateway will lisetn on for incoming connections if tgGateway is true.')
param tgTCPGatewayPort int = 8443

@minValue(1024)
@maxValue(65535)
@description('UDP port that the gateway will lisetn on for incoming connections if tgGateway is true.')
param tgUDPGatewayPort int = 8443

@description('Required networks for control plane connectivity')
param tgControlPlaneNetworkCIDRs array = [ '35.171.100.16/28','34.223.12.192/28'] 

@description( 'TCP ports required for control plane connectivity')
param tgControlPlaneTCPPorts array = ['443','8443']

@description('Determines if the attached nodes will act as a client for remote Trustgrid data plane gateways')
param tgDataPlaneClient bool = true

@description('Network CIDRs for remote Trustgrid data plane Gateways. E.g. ["35.10.10.0/30", "24.56.78.1/32"] would allow connections to 35.10.10.0-3 and 24.56.78.1')
param tgDataPlaneNetworkCIDRs array = []

@description('TCP ports required for data plane connectivity to remote gateways')
param tgDataPlaneTCPPorts array = ['8443']

@description('UDP ports required for data plane connectivity to remote gateways')
param tgDataPlaneUDPPorts array = ['8443']

resource securityGroup 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${namePrefix}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: '${namePrefix}-tg-control-plane'
        properties: {
          access: 'Allow'
          destinationAddressPrefixes: tgControlPlaneNetworkCIDRs
          destinationPortRanges: tgControlPlaneTCPPorts
          direction: 'Outbound'
          description: 'Allow required control plane traffic'
          priority: 1000
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }

    ]
  }
}

resource tgGatewaySGRuleTCP 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (tgGateway) {
  name: '${namePrefix}-tg-gateway-inbound-tcp'
  parent: securityGroup
  properties: {
    access: 'Allow'
    direction: 'Inbound'
    priority: 1000
    protocol: 'Tcp'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '${tgTCPGatewayPort}'
  }  
}

resource tgGatewaySGRuleUDP 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (tgGateway) {
  name: '${namePrefix}-tg-gateway-inbound-udp'
  parent: securityGroup
  properties: {
    access: 'Allow'
    direction: 'Inbound'
    priority: 1001
    protocol: 'Udp'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '${tgUDPGatewayPort}'
  }  
}

resource tgDataPlaneClientRuleTCP 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (tgDataPlaneClient) {
  name: '${namePrefix}-tg-data-plane-outbound-tcp'
  parent: securityGroup
  properties: {
    access: 'Allow'
    direction: 'Outbound'
    priority: 1002
    protocol: 'Tcp'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefixes: tgDataPlaneNetworkCIDRs
    destinationPortRanges: tgDataPlaneTCPPorts
  }
}

resource tgDataPlaneClientRuleUDP 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (tgDataPlaneClient) {
  name: '${namePrefix}-tg-data-plane-outbound-udp'
  parent: securityGroup
  properties: {
    access: 'Allow'
    direction: 'Outbound'
    priority: 1003
    protocol: 'Udp'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefixes: tgDataPlaneNetworkCIDRs
    destinationPortRanges: tgDataPlaneUDPPorts
  }
}

output securityGroup object = securityGroup

output securityGroupName string = securityGroup.name
