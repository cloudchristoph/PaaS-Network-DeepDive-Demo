Set-AzSubscriptionDeploymentStack `
    -Name "CloudChristoph-PaaS-Network-DeepDive" `
    -Location "germanywestcentral" `
    -TemplateFile "./BaseInfra/BaseInfra.bicep" `
    -TemplateParameterFile "./BaseInfra/BaseInfra.bicepparam" `
    -DenySettingsMode "None" `
    -ActionOnUnmanage DeleteAll `
    -Verbose