param parVnetName string
param parPeeredVnetName string
param parPeeredVnetResourceGroupName string

param parVnetIsHub bool = false
param parIsGatewayDeployed bool

var varPeeringName = '${replace(parVnetName, '-vnet', '')}-to-${replace(parPeeredVnetName, '-vnet', '')}'

resource resVnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: parVnetName
}

resource resPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  name: varPeeringName
  parent: resVnet
  properties: {
    remoteVirtualNetwork: {
      id: resourceId(parPeeredVnetResourceGroupName, 'Microsoft.Network/virtualNetworks', parPeeredVnetName)
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: !parVnetIsHub
    allowGatewayTransit: parVnetIsHub
    useRemoteGateways: parIsGatewayDeployed ? !parVnetIsHub : false
  }
}
