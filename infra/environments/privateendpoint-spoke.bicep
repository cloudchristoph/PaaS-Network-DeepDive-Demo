@secure()
param parAdminUsername string
@secure()
param parAdminPassword string

param parResourceBaseName string
param parLocation string
param parTags object
param parVnetId string
param parPrivateDnsZoneResourceGroup string

var varServicesSubnetId = '${parVnetId}/subnets/services'

module modVm '../modules/vm_windows.bicep' = {
  name: 'modVm'
  params: {
    parBaseName: parResourceBaseName
    parLocation: parLocation
    parAdminUsername: parAdminUsername
    parAdminPassword: parAdminPassword
    parVnetId: parVnetId
    parSubnetName: 'default'
    parTags: parTags
  }
}

module modSql '../modules/sql_database.bicep' = {
  name: 'modSql'
  params: {
    parBaseName: parResourceBaseName
    parLocation: parLocation
    parTags: parTags
    parAdministratorLogin: parAdminUsername
    parAdministratorLoginPassword: parAdminPassword
    parPublicNetworkAccess: 'Disabled'
    parUsePrivateEndpoint: true
    parPrivateEndpointSubnetId: varServicesSubnetId
    parPrivateDnsZoneResourceGroup: parPrivateDnsZoneResourceGroup
  }
}
