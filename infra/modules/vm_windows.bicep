param parLocation string
param parTags object
param parBaseName string
param parVmSize string = 'Standard_B2as_v2'
param parVnetId string
param parSubnetName string
param parPublicIpEnabled bool = false
param parAutoShutdownTime string = '19:00'
@secure()
param parAdminUsername string
@secure()
param parAdminPassword string

var varVmName = '${parBaseName}-vm'
var varNicName = '${varVmName}-nic'
var varOsDiskName = '${varVmName}-osdisk'
var varPublicIpName = '${varVmName}-pip'
var varVmHostName = (length(varVmName) > 15) ? substring(parBaseName, 0, 15) : varVmName

var varSubnetId = '${parVnetId}/subnets/${parSubnetName}'

resource resVm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: varVmName
  location: parLocation
  tags: parTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: parVmSize
    }

    osProfile: {
      computerName: varVmHostName
      windowsConfiguration: {
        provisionVMAgent: true
        timeZone: 'W. Europe Standard Time'
      }
      adminUsername: parAdminUsername
      adminPassword: parAdminPassword
    }

    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        name: varOsDiskName
        osType: 'Windows'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-g2'
        version: 'latest'
      }
    }

    networkProfile: {
      networkInterfaces: [
        {
          id: resNic.id
        }
      ]
    }

    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource resNic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: varNicName
  location: parLocation
  tags: parTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: varSubnetId
          }
          publicIPAddress: parPublicIpEnabled
            ? {
                id: resPublicIp.id
              }
            : null
        }
      }
    ]
  }
}

resource resPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = if (parPublicIpEnabled) {
  name: varPublicIpName
  location: parLocation
  tags: parTags
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}

resource resAutoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = if (parAutoShutdownTime != '') {
  name: 'shutdown-computevm-${varVmName}'
  location: parLocation
  tags: parTags
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: parAutoShutdownTime
    }
    timeZoneId: 'W. Europe Standard Time'
    targetResourceId: resVm.id
  }
}

output outVmId string = resVm.id
output outVmName string = resVm.name
output outVmPrivateIp string = resNic.properties.ipConfigurations[0].properties.privateIPAddress
output outVmPublicIp string = parPublicIpEnabled ? resPublicIp.properties.ipAddress : ''
