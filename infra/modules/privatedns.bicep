param parVnetName string
param parVnetResourceGroupName string
param parTags object

var varPrivateDnsZones = [
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.file.${environment().suffixes.storage}'
  'privatelink.table.${environment().suffixes.storage}'
  'privatelink.queue.${environment().suffixes.storage}'
  'privatelink${environment().suffixes.sqlServerHostname}'
]

resource resPrivateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for (privateDnsZone, index) in varPrivateDnsZones : {
  name: privateDnsZone
  location: 'global'
  tags: parTags
  properties: {}
}]

resource resPrivateDnsVirtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (privateDnsZone, index) in varPrivateDnsZones : {
  name: 'vnetlink-${parVnetName}'
  location: 'global'
  parent: resPrivateDnsZones[index]
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(parVnetResourceGroupName, 'Microsoft.Network/virtualNetworks', parVnetName)
    }
  }
}]
