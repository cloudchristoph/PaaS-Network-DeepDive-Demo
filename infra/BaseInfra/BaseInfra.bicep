targetScope = 'subscription'

param parLocation string
param parTags object
param parVnetAddressPrefix string
param parResourceBaseName string
param parResourceGroupPrefix string = 'rg-${parResourceBaseName}'

param parDeployVirtualNetworkGateway bool
param parDeployBastionHost bool
param parLocalVpnGatewayIp string
param parLocalVpnAddressPrefix string

@secure()
param parAdminUsername string
@secure()
param parAdminPassword string

var varRoutedSpokes = [for index in range(1, 3): cidrSubnet(parVnetAddressPrefix, 24, index)]

// Resource Groups

resource resRgHub 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${parResourceGroupPrefix}-hub'
  location: parLocation
  tags: parTags
}

resource resRgBase 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${parResourceGroupPrefix}-base'
  location: parLocation
  tags: parTags
}

resource resRgDemoPublic 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${parResourceGroupPrefix}-demo-public'
  location: parLocation
  tags: parTags
}

resource resRgDemoServiceEndpoints 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${parResourceGroupPrefix}-demo-serviceendpoints'
  location: parLocation
  tags: parTags
}

resource resRgDemoPrivateEndpoints 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${parResourceGroupPrefix}-demo-privateendpoints'
  location: parLocation
  tags: parTags
}

// Networks

module modNetworkHub '../modules/network.bicep' = {
  scope: resRgHub
  name: 'modNetworkHub'
  params: {
    parLocation: parLocation
    parTags: parTags
    parVnetBaseName: 'hub'
    parVnetAddressPrefix: cidrSubnet(parVnetAddressPrefix, 24, 0)
    parIsHubNetwork: true
    parDeployVirtualNetworkGateway: parDeployVirtualNetworkGateway
    parDeployBastionHost: parDeployBastionHost
    parLocalVpnAddressPrefix: parLocalVpnAddressPrefix
    parLocalVpnGatewayIp: parLocalVpnGatewayIp
    parLawId: modBaseComponentes.outputs.outLawId
    parSpokeNetworks: varRoutedSpokes
  }
}

module modNetworkSpokePublic '../modules/network.bicep' = {
  scope: resRgDemoPublic
  name: 'modNetworkSpokePublic'
  params: {
    parLocation: parLocation
    parTags: parTags
    parVnetBaseName: 'public'
    parVnetAddressPrefix: cidrSubnet(parVnetAddressPrefix, 24, 1)
    parAzureFirewallIp: modNetworkHub.outputs.outAzureFirewallPrivateIp
  }
}

module modNetworkSpokeServiceEndpoints '../modules/network.bicep' = {
  scope: resRgDemoServiceEndpoints
  name: 'modNetworkSpokeServiceEndpoints'
  params: {
    parLocation: parLocation
    parTags: parTags
    parVnetBaseName: 'serviceendpoint'
    parVnetAddressPrefix: cidrSubnet(parVnetAddressPrefix, 24, 2)
    parAzureFirewallIp: modNetworkHub.outputs.outAzureFirewallPrivateIp
    parEnableServiceEndpoints: true
  }
}

module modNetworkSpokePrivateEndpoints '../modules/network.bicep' = {
  scope: resRgDemoPrivateEndpoints
  name: 'modNetworkSpokePrivateEndpoints'
  params: {
    parLocation: parLocation
    parTags: parTags
    parVnetBaseName: 'privatelink'
    parVnetAddressPrefix: cidrSubnet(parVnetAddressPrefix, 24, 3)
    parAzureFirewallIp: modNetworkHub.outputs.outAzureFirewallPrivateIp
  }
}

// Peerings

module modPeeringHubToSpokePublic '../modules/network_peering.bicep' = {
  name: 'modPeeringHubToSpokePublic'
  params: {
    parHubVnetName: modNetworkHub.outputs.outVnetName
    parHubVnetResourceGroupName: resRgHub.name
    parSpokeVnetName: modNetworkSpokePublic.outputs.outVnetName
    parSpokeVnetResourceGroupName: resRgDemoPublic.name
    parIsGatewayDeployed: parDeployVirtualNetworkGateway
  }
}

module modPeeringHubToSpokeServiceEndpoints '../modules/network_peering.bicep' = {
  name: 'modPeeringHubToSpokeServiceEndpoints'
  params: {
    parHubVnetName: modNetworkHub.outputs.outVnetName
    parHubVnetResourceGroupName: resRgHub.name
    parSpokeVnetName: modNetworkSpokeServiceEndpoints.outputs.outVnetName
    parSpokeVnetResourceGroupName: resRgDemoServiceEndpoints.name
    parIsGatewayDeployed: parDeployVirtualNetworkGateway
  }
}

module modPeeringHubToSpokePrivateEndpoints '../modules/network_peering.bicep' = {
  name: 'modPeeringHubToSpokePrivateEndpoints'
  params: {
    parHubVnetName: modNetworkHub.outputs.outVnetName
    parHubVnetResourceGroupName: resRgHub.name
    parSpokeVnetName: modNetworkSpokePrivateEndpoints.outputs.outVnetName
    parSpokeVnetResourceGroupName: resRgDemoPrivateEndpoints.name
    parIsGatewayDeployed: parDeployVirtualNetworkGateway
  }
}

// Base Components

module modBaseComponentes '../modules/base_components.bicep' = {
  scope: resRgBase
  name: 'modBaseComponentes'
  params: {
    parLocation: parLocation
    parTags: parTags
    parResourceBaseName: parResourceBaseName
  }
}

// Private DNS

module modPrivateDns '../modules/privatedns.bicep' = {
  scope: resRgBase
  name: 'modPrivateDns'
  params: {
    parTags: parTags
    parVnetName: modNetworkHub.outputs.outVnetName
    parVnetResourceGroupName: resRgHub.name
  }
}

// Environments
// Environment: Public

module modEnvironmentPublic '../environments/public-spoke.bicep' = {
  scope: resRgDemoPublic
  name: 'modEnvironmentPublic'
  params: {
    parResourceBaseName: 'public'
    parLocation: parLocation
    parAdminUsername: parAdminUsername
    parAdminPassword: parAdminPassword

    parTags: parTags
    parVnetId: modNetworkSpokePublic.outputs.outVnetId
  }
}

// Environment: Service Endpoints

module modEnvironmentServiceEndpoints '../environments/serviceendpoint-spoke.bicep' = {
  scope: resRgDemoServiceEndpoints
  name: 'modEnvironmentServiceEndpoints'
  params: {
    parResourceBaseName: 'serviceendpoints'
    parLocation: parLocation
    parAdminUsername: parAdminUsername
    parAdminPassword: parAdminPassword

    parTags: parTags
    parVnetId: modNetworkSpokeServiceEndpoints.outputs.outVnetId
  }
}

// Environment: Private Endpoints

module modEnvironmentPrivateEndpoints '../environments/privateendpoint-spoke.bicep' = {
  scope: resRgDemoPrivateEndpoints
  name: 'modEnvironmentPrivateEndpoints'
  params: {
    parResourceBaseName: 'privatelink'
    parLocation: parLocation
    parAdminUsername: parAdminUsername
    parAdminPassword: parAdminPassword

    parTags: parTags
    parVnetId: modNetworkSpokePrivateEndpoints.outputs.outVnetId
    parPrivateDnsZoneResourceGroup: resRgBase.name
  }
}
