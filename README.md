# Deep Dive into Azure Service Endpoints and Private Link

## Introduction

This repository contains the Demo Environemnt code of the Deep Dive into Azure Service Endpoints and Private Link session for the Festive Tech Calendar 2023.

![Demo Environment](./DemoEnvironment.png)

## Deploy to your Azure Environment

### Prerequisites

1. Active Azure Subscription
2. Azure CLI or Azure PowerShell / Azure Cloud Shell

### Deploy

> [!WARNING]
> This will deploy quite a few resources into your Azure Subscription that incur costs (Azure Firewall Standard, Virtual Network Gateway, 3 VMs, 3 SQL Severs). Make sure to delete the resources after you are done with the demo!

1. Clone or download this repository
2. Create a parameters file based on the example file under `/BaseInfra/BaseInfra.example.bicepparams`
3. _Choose:_
   1. Deploy as Deployment Stack (Azure PowerShell):

        ```powershell
        New-AzSubscriptionDeploymentStack `
            -Name "CloudFamily-Demo" `
            -Location "westeurope" `
            -TemplateFile "./BaseInfra/BaseInfra.bicep" `
            -TemplateParameterFile "./BaseInfra/BaseInfra.bicepparam" `
            -DenySettingsMode "None" `
            -Verbose
        ```

   2. Deploy as normal Bicep templates (Azure PowerShell)):

        ```powershell
            New-AzDeployment `
                -Location 'westeurope' `
                -TemplateFile './BaseInfra/BaseInfra.bicep' `
                -TemplateParameterFile './BaseInfra/BaseInfra.bicepparam'`
                -Verbose
        ```

4. Play around with the demo environment
5. Destroy:
   1. If you have deployed this as Deployment Stack:

        ```powershell
        Remove-AzSubscriptionDeploymentStack `
            -Name "CloudFamily-Demo" `
            -DeleteAll `
            -Verbose
        ```

   2. If you have deployed as normal Bicep templates, than delete the resource groups created by the deployment manually.

## Questions

If you have any questions, feel free to contact me on Twitter/X [@CloudChristoph](https://twitter.com/CloudChristoph) or open an issue in this repository.
