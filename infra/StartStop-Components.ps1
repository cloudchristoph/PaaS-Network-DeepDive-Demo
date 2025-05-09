param (
    [ValidateSet("Start", "Stop")]
    [string]
    $Action = "Start",
    [switch]
    $ScaleDownDisks = $false,
    [Parameter(Mandatory = $true)]
    [string]
    $BaseName
)

$resourceGroupNamePrefix = "rg-$BaseName"
$resourceGroupNameHub = "$resourceGroupNamePrefix-hub"

# Virtual Machines

# Wait for it all to complete

write-host "$Action of VMs"
$vms = Get-AzVM

$jobs = @()
foreach ($vm in $vms) {
    if ($vm.ResourceGroupName -notlike "$resourceGroupNamePrefix*") {
        write-host "Skipping VM $($vm.Name) in resource group $($vm.ResourceGroupName)" -ForegroundColor Magenta
        continue
    }
    if ($Action -eq "Start") {
        #$job = Start-Job -ScriptBlock {

        # Get OS Disk and move it to Premium_LRS
        $osDisk = Get-AzDisk -DiskName $vm.StorageProfile.OsDisk.Name -ResourceGroupName $vm.ResourceGroupName
        $osDisk.Sku = [Microsoft.Azure.Management.Compute.Models.DiskSku]::new('Premium_LRS')
        write-host "Updating OS Disk $($osDisk.Name) to $($osDisk.Sku.Name)" -ForegroundColor Magenta
        $osDisk | Update-AzDisk -Verbose -ErrorAction Inquire

        Write-host "Starting VM $($vm.Name)" -ForegroundColor Magenta
        Start-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName
        #}
        #$jobs = $jobs + $job
    }
    else {
        #$job = Start-Job -ScriptBlock {
        Write-host "Stopping VM $($vm.Name)" -ForegroundColor Magenta
        Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Force

        # Get OS Disk and move it to Standard_HDD
        if ($ScaleDownDisks) {
            $osDisk = Get-AzDisk -DiskName $vm.StorageProfile.OsDisk.Name -ResourceGroupName $vm.ResourceGroupName
            $osDisk.Sku = [Microsoft.Azure.Management.Compute.Models.DiskSku]::new('Standard_LRS')
            write-host "Updating OS Disk $($osDisk.Name) to $($osDisk.Sku.Name)" -ForegroundColor Magenta
            $osDisk | Update-AzDisk -Verbose
        }
        else {
            write-host "Not scaling down OS Disk $($osDisk.Name)" -ForegroundColor Magenta
        }
        #}
        #$jobs = $jobs + $job
    }
}

#Wait-Job -Job $jobs

# Azure Firewall

write-host "$Action of Azure Firewall"

$firewall = Get-AzFirewall -Name "hub-azfw" -ResourceGroupName $resourceGroupNameHub

if ($Action -eq "Start") {

    $vnet = Get-AzVirtualNetwork -Name "hub-vnet" -ResourceGroupName $resourceGroupNameHub
    $publicIP = Get-AzPublicIpAddress -Name "hub-azfw-pip" -ResourceGroupName $resourceGroupNameHub

    $firewall.Allocate($vnet, $publicIP)
    Set-AzFirewall -AzureFirewall $firewall -Verbose
}
else {
    $firewall.Deallocate()
    Set-AzFirewall -AzureFirewall $firewall -Verbose
}