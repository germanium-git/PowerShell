<#
.SYNOPSIS Rename Azure OS Disk.

.DESCRIPTION Create a copy of an OS Disk restored from backup.

.LINK
For more information please visit: https://github.com/germanium-git/PowerShell/tree/main/azure_rename_disk

.EXAMPLE
.\Rename-AzOSDisk.ps1 -resourceGroup [ResourceGroupName] `
    -osdiskName [OSDiskName] `
    -newdiskName [NewdiskName] `
    -subscriptionId [SubscriptionId] `
    -tenantId [TenantId] `
    -Verbose
This example will create a copy of the OS Disk restored from the backup, not attached to any VM.
You need to specify the Resource Group name, existing OSDisk name, new OSDisk name, subscription ID and tenant id.
Then the script will create a copy of the disk in Azure with desired name.
#>

[CmdletBinding()]
Param (
    [Parameter(Position = 0, Mandatory = $True, HelpMessage = 'Enter the Resource Group of the VM')]
    [Alias('VM')]
    [String]$resourceGroup,

    [Parameter(Position = 1, Mandatory = $true, HelpMessage = 'Enter the existing OS Disk name')]
    [Alias('DiskName')]
    [String]$osdiskName,

    [Parameter(Position = 2, Mandatory = $true, HelpMessage = 'Enter the new OS Disk name')]
    [Alias('NewDisk')]
    [String]$newdiskName,

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

#! Get source OS Disk information
Write-Verbose "Get the source OS Disk information: $osdiskName"
$sourceOSDisk = Get-AzDisk -ResourceGroupName $resourceGroup -DiskName $osdiskName

#! Create the managed disk configuration
Write-Verbose "Create the managed disk configuration..."
$diskConfig = New-AzDiskConfig -SkuName $sourceOSDisk.Sku.Name `
    -Location $sourceOSDisk.Location `
    -DiskSizeGB ($sourceOSDisk | select -ExpandProperty DiskSizeGB) `
    -Zone (($sourceOSDisk | select -ExpandProperty Zones)) `
    -SourceResourceId $sourceOSDisk.Id -CreateOption Copy

#! Create the new disk
Write-Verbose "Creating the new OS disk: $newdiskName"
New-AzDisk -Disk $diskConfig -DiskName $newdiskName -ResourceGroupName $resourceGroup


#! Delete the old OS Disk
$delete = Read-Host "Do you want to delete the original OS Disk [y/n]"
If ($delete -eq "y" -or $delete -eq "Y") {
    Write-Warning "Deleting the old OS Disk: $($sourceOSDisk.Name)"
    Remove-AzDisk -ResourceGroupName $resourceGroup -DiskName $sourceOSDisk.Name -Force -Confirm:$false
}
