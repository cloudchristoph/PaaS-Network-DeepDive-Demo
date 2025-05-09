param parLocation string
param parTags object
param parResourceBaseName string

var varLawName = '${parResourceBaseName}-law'

resource resLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: varLawName
  location: parLocation
  tags: parTags
  properties: {
    retentionInDays: 30
  }
}

output outLawId string = resLogAnalyticsWorkspace.id
