using './BaseInfra.bicep'

param parLocation = 'westeurope'
param parTags = {
  Owner: 'CloudChristoph'
  Project: 'PaaS-Network-DeepDive'
}
param parResourceBaseName = 'globalazure'

param parVnetAddressPrefix = '10.2.0.0/16'
param parDeployVirtualNetworkGateway = false // Set to true if you want to deploy a VPN Gateway in the VNet
param parLocalVpnAddressPrefix = '<your-on-prem-ip-cidr>' // ignore this if you don't deploy a VPN Gateway
param parLocalVpnGatewayIp = '<your-on-prem-ip>' // ignore this if you don't deploy a VPN Gateway

param parAdminUsername = readEnvironmentVariable('ADMIN_USERNAME', '<your-default-admin-username>')
param parAdminPassword = readEnvironmentVariable('ADMIN_PASSWORD', '<your-default-admin-password>')
