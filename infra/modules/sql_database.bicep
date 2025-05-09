param parLocation string
param parTags object
param parBaseName string

param parAdministratorLogin string
@secure()
param parAdministratorLoginPassword string

@allowed(['Disabled', 'Enabled'])
param parPublicNetworkAccess string = 'Enabled'

param parUsePrivateEndpoint bool = false
param parPrivateEndpointSubnetId string = ''
param parPrivateDnsZoneResourceGroup string = ''

param parAllowedSubnetIds array = []

var varDatabaseName = 'adventureworks'

var varPrivateDnsZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'
var varPrivateDnsZoneId = (parUsePrivateEndpoint
  ? resourceId(parPrivateDnsZoneResourceGroup, 'Microsoft.Network/privateDnsZones', varPrivateDnsZoneName)
  : '')

var varSqlServerName = 'demo-${parBaseName}'

resource resSqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: varSqlServerName
  location: parLocation
  tags: parTags
  properties: {
    administratorLogin: parAdministratorLogin
    administratorLoginPassword: parAdministratorLoginPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: parPublicNetworkAccess
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

resource resDatabase 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  name: varDatabaseName
  parent: resSqlServer
  location: parLocation
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    sampleName: 'AdventureWorksLT'
    maxSizeBytes: 34359738368
    zoneRedundant: false
    autoPauseDelay: 60
  }
  sku: {
    name: 'GP_S_Gen5_1'
    tier: 'GeneralPurpose'
  }
}

resource resPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-06-01' = if (parUsePrivateEndpoint) {
  name: '${varSqlServerName}-pe'
  location: parLocation
  tags: parTags
  properties: {
    subnet: {
      id: parPrivateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${varSqlServerName}-connection'
        properties: {
          privateLinkServiceId: resSqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
    customNetworkInterfaceName: '${varSqlServerName}-pe-nic'
  }

  resource dnsZoneGroup 'privateDnsZoneGroups' = {
    name: '${varSqlServerName}-pe-dns'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: varPrivateDnsZoneName
          properties: {
            privateDnsZoneId: varPrivateDnsZoneId
          }
        }
      ]
    }
  }
}

resource resAllowedSubnets 'Microsoft.Sql/servers/virtualNetworkRules@2023-05-01-preview' = [
  for (allowedSubnet, index) in parAllowedSubnetIds: {
    name: '${varSqlServerName}-subnet-${index}'
    parent: resSqlServer
    properties: {
      virtualNetworkSubnetId: allowedSubnet
      ignoreMissingVnetServiceEndpoint: true
    }
  }
]

output outSqlServerName string = resSqlServer.name
output outSqlServerId string = resSqlServer.id
