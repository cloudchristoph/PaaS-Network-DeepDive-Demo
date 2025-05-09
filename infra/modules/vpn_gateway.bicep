param parLocation string
param parTags object
param parBaseName string
param parVnetName string

param parLocalVpnGatewayIp string
param parLocalVpnAddressPrefix string

var varVpnGatewayName = '${parBaseName}-vpn-gateway'
var varVpnGatewayPublicIpName = '${varVpnGatewayName}-pip'

var varVpnGatewayLocalNetworkGatewayName = '${varVpnGatewayName}-local'

resource resVpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-05-01' = {
  name: varVpnGatewayName
  location: parLocation
  tags: parTags
  properties: {
    vpnType: 'RouteBased'
    sku: {
      name: 'Basic'
      tier: 'Basic'
    }
    activeActive: false
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: resVpnGatewayPublicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', parVnetName, 'GatewaySubnet')
          }
        }
      }
    ]
  }
}

resource resVpnGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: varVpnGatewayPublicIpName
  location: parLocation
  tags: parTags
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource resVpnGatewayLocalNetworkGateway 'Microsoft.Network/localNetworkGateways@2023-05-01' = {
  name: varVpnGatewayLocalNetworkGatewayName
  location: parLocation
  tags: parTags
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        parLocalVpnAddressPrefix
      ]
    }
    gatewayIpAddress: parLocalVpnGatewayIp
  }
}

resource resVpnGatewayConnection 'Microsoft.Network/connections@2023-05-01' = {
  name: '${varVpnGatewayName}-connection'
  location: parLocation
  tags: parTags
  properties: {
    connectionType: 'IPsec'
    virtualNetworkGateway1: {
      id: resVpnGateway.id
      properties: {}
    }
    localNetworkGateway2: {
      id: resVpnGatewayLocalNetworkGateway.id
      properties: {}
    }
  }
}
