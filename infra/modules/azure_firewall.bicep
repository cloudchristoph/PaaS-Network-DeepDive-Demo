param parLocation string
param parTags object
param parBaseName string
param parVnetName string
param parLawId string

var varAzureFirewallName = '${parBaseName}-azfw'
var varAzureFirewallPublicIpName = '${varAzureFirewallName}-pip'
var varAzureFirewallPolicyName = '${varAzureFirewallName}-policy'

resource resAzureFirewall 'Microsoft.Network/azureFirewalls@2024-05-01' = {
  name: varAzureFirewallName
  location: parLocation
  tags: parTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: resAzureFirewallPublicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', parVnetName, 'AzureFirewallSubnet')
          }
        }
      }
    ]
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    firewallPolicy: {
      id: resAzureFirewallPolicy.id
    }
  }
}

resource resAzureFirewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: varAzureFirewallPublicIpName
  location: parLocation
  tags: parTags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource resAzureFirewallPolicy 'Microsoft.Network/firewallPolicies@2024-05-01' = {
  name: varAzureFirewallPolicyName
  location: parLocation
  tags: parTags
  properties: {
    dnsSettings: {
      enableProxy: true
    }
    sku: {
      tier: 'Standard'
    }
  }

  resource applicationRuleCollectionGroup 'ruleCollectionGroups' = {
    name: 'ApplicationRuleCollectionGroup'
    properties: {
      priority: 100
      ruleCollections: [
        {
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          action: {
            type: 'Allow'
          }
          name: 'AllowAll'
          priority: 100
          rules: [
            {
              ruleType: 'ApplicationRule'
              name: 'AllowAll'
              description: 'Allow all traffic'
              sourceAddresses: [
                '*'
              ]
              protocols: [
                {
                  port: 443
                  protocolType: 'Https'
                }
                {
                  port: 80
                  protocolType: 'Http'
                }
                {
                  port: 1433
                  protocolType: 'Mssql'
                }
              ]
              targetFqdns: [
                '*'
              ]
            }
          ]
        }
      ]
    }
  }

  resource networkRuleCollectionGroup 'ruleCollectionGroups' = {
    name: 'NetworkRuleCollectionGroup'
    properties: {
      priority: 200
      ruleCollections: [
        {
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          action: {
            type: 'Allow'
          }
          priority: 100
          name: 'AllowRules'
          rules: [
            {
              ruleType: 'NetworkRule'
              name: 'AllowManagement'
              sourceAddresses: [
                '10.1.0.0/23'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '*'
              ]
              ipProtocols: [
                'Any'
              ]
            }
            {
              ruleType: 'NetworkRule'
              name: 'AllowBasicNetworkServices'
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '123' // NTP
                '53' // DNS
              ]
              ipProtocols: [
                'Any'
              ]
            }
            {
              ruleType: 'NetworkRule'
              name: 'AllowAzureSQL'
              sourceAddresses: [
                '10.2.0.0/16'
              ]
              destinationAddresses: [
                'Sql'
              ]
              destinationPorts: [
                '11000-11999'
              ]
              ipProtocols: [
                'TCP'
              ]
            }
          ]
        }
      ]
    }
    dependsOn: [
      resAzureFirewallPolicy::applicationRuleCollectionGroup
    ]
  }
}

resource resAzureFirewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${varAzureFirewallName}-diagnostics'
  scope: resAzureFirewall
  properties: {
    workspaceId: parLawId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'AZFWNetworkRule'
        enabled: true
      }
      {
        category: 'AZFWApplicationRule'
        enabled: true
      }
      {
        category: 'AZFWNatRule'
        enabled: true
      }
      {
        category: 'AZFWDnsQuery'
        enabled: true
      }
      {
        category: 'AZFWFqdnResolveFailure'
        enabled: true
      }
    ]
  }
}

output outAzureFirewallPrivateIp string = resAzureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
