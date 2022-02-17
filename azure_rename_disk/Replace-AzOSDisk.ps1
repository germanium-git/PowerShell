<#
.SYNOPSIS Replace Azure OS Disk.

.DESCRIPTION Replace Azure VM OS Disk for Linux and Windows.

.LINK
For more information please visit: https://github.com/germanium-git/PowerShell/tree/main/azure_rename_disk

.EXAMPLE
.\Replace-AzOSDisk.ps1 -resourceGroup [ResourceGroupName] `
    -VMName [VMName] `
    -newdiskName [restoreddiskName] `
    -subscriptionId [SubscriptionId] `
    -tenantId [TenantId] `
    -Verbose
This example will replace the OS Disk for the specified VM, you need to specify the Resource Group name, VM name and the unattached OS disk name restored from the backup.
#>

[CmdletBinding()]
Param (
    [Parameter(Position = 0, Mandatory = $true, HelpMessage = 'Enter the Resource Group of the VM')]
    [Alias('rg')]
    [String]$resourceGroup,

    [Parameter(Position = 1, Mandatory = $True, HelpMessage = 'Enter Azure VM name')]
    [Alias('VM')]
    [String]$VMName,

    [Parameter(Position = 2, Mandatory = $true, HelpMessage = 'Enter the restored OS Disk name')]
    [Alias('DiskName')]
    [String]$restoreddiskName,

    [Parameter(Position = 3, Mandatory = $true, HelpMessage = 'Enter the subscription ID')]
    [Alias('SubId')]
    [String]$subscriptionId,

    [Parameter(Position = 4, Mandatory = $true, HelpMessage = 'Enter the tenant ID')]
    [Alias('TenId')]
    [String]$tenantId


)

#! Check Azure Connection
Try {
    Write-Verbose "Connecting to Azure Cloud..."
    Connect-AzAccount -TenantId $tenantId -SubscriptionId $subscriptionId -ErrorAction Stop | Out-Null
}
Catch {
    Write-Warning "Cannot connect to Azure Cloud. Please check your credentials. Exiting!"
    Break
}

#! Get the details of the VM
Write-Verbose "Get the VM information details: $VMName"
$VM = Get-AzVM -Name $VMName -ResourceGroupName $resourceGroup

#! Get source OS Disk information
Write-Verbose "Get the source OS Disk information: $($VM.StorageProfile.OsDisk.Name)"
$sourceOSDisk = Get-AzDisk -ResourceGroupName $resourceGroup -DiskName $VM.StorageProfile.OsDisk.Name


#! Get restored OS Disk information
Write-Verbose "Get the source OS Disk information: $restoreddiskName"
$restoredOSDisk = Get-AzDisk -ResourceGroupName $resourceGroup -DiskName $restoreddiskName


#! Swap the OS Disk
Write-Verbose "Swap the OS disk to: $restoreddiskName"
Set-AzVMOSDisk -VM $VM -ManagedDiskId $restoredOSDisk.Id -Name $osdiskName | Out-Null
Write-Verbose "The VM is rebooting..."
Update-AzVM -ResourceGroupName $resourceGroup -VM $VM

#! Delete the old OS Disk
$delete = Read-Host "Do you want to delete the original OS Disk [y/n]"
If ($delete -eq "y" -or $delete -eq "Y") {
    Write-Warning "Deleting the old OS Disk: $($sourceOSDisk.Name)"
    Remove-AzDisk -ResourceGroupName $resourceGroup -DiskName $sourceOSDisk.Name -Force -Confirm:$false
}

