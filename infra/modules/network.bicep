type typeSubnetConfiguration = {
  name: string
  addressPrefix: string
}

param parVnetBaseName string
param parLocation string = resourceGroup().location
param parTags object
param parVnetAddressPrefix string
param parSubnetConfigurations typeSubnetConfiguration[] = []
param parAzureFirewallIp string = ''

param parIsHubNetwork bool = false
param parDeployVirtualNetworkGateway bool = false

param parLocalVpnGatewayIp string = ''
param parLocalVpnAddressPrefix string = ''
param parLawId string = ''

param parSpokeNetworks array = []

param parEnableServiceEndpoints bool = false

var varVnetName = '${parVnetBaseName}-vnet'
var varRouteTableName = '${varVnetName}-rt'
var varNetworkSecurityGroupName = '${varVnetName}-nsg'

var varSubnetConfigurations = (!empty(parSubnetConfigurations))
  ? parSubnetConfigurations
  : (parIsHubNetwork)
      ? [
          {
            name: 'AzureFirewallSubnet'
            addressPrefix: cidrSubnet(parVnetAddressPrefix, 26, 0)
          }
          {
            name: 'GatewaySubnet'
            addressPrefix: cidrSubnet(parVnetAddressPrefix, 26, 3)
          }
          {
            name: 'AzureBastionSubnet'
            addressPrefix: cidrSubnet(parVnetAddressPrefix, 26, 1)
          }
        ]
      : [
          {
            name: 'default'
            addressPrefix: cidrSubnet(parVnetAddressPrefix, 26, 0)
          }
          {
            name: 'services'
            addressPrefix: cidrSubnet(parVnetAddressPrefix, 26, 1)
          }
        ]

resource resVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: varVnetName
  location: parLocation
  tags: parTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        parVnetAddressPrefix
      ]
    }
    subnets: [
      for subnet in varSubnetConfigurations: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix

          routeTable: !parIsHubNetwork
            ? {
                id: resRouteTable.id
                /*} : (subnet.name == 'GatewaySubnet') ? {
          id: resRouteTableVpnGateway.id
        */
              }
            : null

          /*
        networkSecurityGroup: subnet.name != 'AzureFirewallSubnet' ? {
          id: resNetworkSecurityGroup.id
        } : {}
        */

          serviceEndpoints: (parEnableServiceEndpoints
            ? [
                {
                  service: 'Microsoft.Sql'
                  locations: [
                    parLocation
                  ]
                }
              ]
            : [])
        }
      }
    ]

    dhcpOptions: parAzureFirewallIp != ''
      ? {
          dnsServers: [
            parAzureFirewallIp
          ]
        }
      : {}
  }
}

resource resRouteTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: varRouteTableName
  location: parLocation
  tags: parTags
  properties: {
    routes: (parAzureFirewallIp != '' && !parIsHubNetwork)
      ? [
          {
            name: 'to-firewall'
            properties: {
              addressPrefix: '0.0.0.0/0'
              nextHopType: 'VirtualAppliance'
              nextHopIpAddress: parAzureFirewallIp
            }
          }
        ]
      : []
    disableBgpRoutePropagation: (parAzureFirewallIp != '' && !parIsHubNetwork) ? true : false
  }
}

resource resRouteTableVpnGateway 'Microsoft.Network/routeTables@2023-05-01' = if (parIsHubNetwork) {
  name: '${varRouteTableName}-vpn-gateway'
  location: parLocation
  tags: parTags
  properties: {
    routes: [
      for (spokeNetwork, index) in parSpokeNetworks: {
        name: 'to-spoke-${index}'
        properties: {
          addressPrefix: spokeNetwork
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: modAzureFirewall.outputs.outAzureFirewallPrivateIp
        }
      }
    ]
  }
}

// Re-defining this resource to attach the route table to the GatewaySubnet, which is not possible in the above resource (circle reference)
resource resGatewaySubnetRouteTableAttachment 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = if (parIsHubNetwork) {
  name: 'GatewaySubnet'
  parent: resVnet
  properties: {
    addressPrefix: cidrSubnet(parVnetAddressPrefix, 26, 3)
    routeTable: {
      id: resRouteTableVpnGateway.id
    }
  }
}

resource resNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: varNetworkSecurityGroupName
  location: parLocation
  tags: parTags
  properties: {
    securityRules: []
  }
}

module modVpnGateway 'vpn_gateway.bicep' = if (parIsHubNetwork && parDeployVirtualNetworkGateway) {
  name: 'modVpnGateway'
  params: {
    parBaseName: parVnetBaseName
    parLocation: parLocation
    parTags: parTags
    parVnetName: resVnet.name
    parLocalVpnAddressPrefix: parLocalVpnAddressPrefix
    parLocalVpnGatewayIp: parLocalVpnGatewayIp
  }
}

module modAzureFirewall 'azure_firewall.bicep' = if (parIsHubNetwork) {
  name: 'modAzureFirewall'
  params: {
    parBaseName: parVnetBaseName
    parLocation: parLocation
    parTags: parTags
    parVnetName: resVnet.name
    parLawId: parLawId
  }
}

module modAzureBastion 'azure_bastion.bicep' = if (parIsHubNetwork) {
  name: 'modAzureBastion'
  params: {
    parName: '${parVnetBaseName}-bastion'
    parLocation: parLocation
    parVnetResourceId: resVnet.id
    parTags: parTags
  }
}

output outVnetId string = resVnet.id
output outVnetName string = resVnet.name
output outAzureFirewallPrivateIp string = parIsHubNetwork ? modAzureFirewall.outputs.outAzureFirewallPrivateIp : ''
