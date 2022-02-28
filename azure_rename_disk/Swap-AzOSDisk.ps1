<#
.SYNOPSIS Replace Azure OS Disk.

.DESCRIPTION Replace Azure VM OS Disk for Linux and Windows.

.LINK
For more information please visit: https://github.com/germanium-git/PowerShell/tree/main/azure_rename_disk

.EXAMPLE
.\Replace-AzOSDisk.ps1 -resourceGroup [ResourceGroupName] `
    -VMName [VMName] `
    -restoreddiskName [RestoreddiskName] `
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
Write-Verbose "Get the restored OS Disk information: $restoreddiskName"
$restoredOSDisk = Get-AzDisk -ResourceGroupName $resourceGroup -DiskName $restoreddiskName


#! Create the 2nd replica of the restored OS disk
#! The disk remains untouched for the 2nd swap
Write-Verbose "Creating the 2nd replica of the restored OS disk: $($sourceOSDisk.Name)-restored-2nd"
$diskConfigRestored = New-AzDiskConfig -SkuName $restoredOSDisk.Sku.Name `
    -Location $restoredOSDisk.Location `
    -DiskSizeGB ($restoredOSDisk | select -ExpandProperty DiskSizeGB) `
    -Zone (($restoredOSDisk | select -ExpandProperty Zones)) `
    -SourceResourceId $restoredOSDisk.Id -CreateOption Copy

New-AzDisk -Disk $diskConfigRestored -DiskName "$($sourceOSDisk.Name)-restored-2nd" -ResourceGroupName $resourceGroup


#! Check that the 2nd replica has been created
$check2nd = Read-Host "Check the 2nd replica of the restored OS disk: $($sourceOSDisk.Name)-restored-2nd and press Y to continue"
If ($check2nd -eq "y" -or $check2nd -eq "Y") {
    Write-Warning "Continue"
}

#! Get 2nd restored OS Disk information
Write-Verbose "Get the restored OS Disk information: $($sourceOSDisk.Name)-restored-2nd"
$restoredOSDisk2nd = Get-AzDisk -ResourceGroupName $resourceGroup -DiskName "$($sourceOSDisk.Name)-restored-2nd"


#! Swap the OS Disk 1st time with the disk restored from RSV
Write-Verbose "Swap the OS disk to: $restoreddiskName"
Set-AzVMOSDisk -VM $VM -ManagedDiskId $restoredOSDisk.Id -Name $restoredOSDisk.Name | Out-Null
Write-Verbose "The VM is rebooting..."
Update-AzVM -ResourceGroupName $resourceGroup -VM $VM


#! Check that the restored disk is connected to VM 
$checkvmswap1st = Read-Host "Check the $($restoredOSDisk.Name) is attached to the VM $VMName and press Y to continue"
If ($checkvmswap1st -eq "y" -or $checkvmswap1st -eq "Y") {
    Write-Warning "Continue"
}


#! Duplicate the original OS Disk
#! Create the managed disk configuration
Write-Verbose "Create the managed disk configuration..."
$diskConfigOriginal = New-AzDiskConfig -SkuName $sourceOSDisk.Sku.Name `
    -Location $sourceOSDisk.Location `
    -DiskSizeGB ($sourceOSDisk | select -ExpandProperty DiskSizeGB) `
    -Zone (($sourceOSDisk | select -ExpandProperty Zones)) `
    -SourceResourceId $sourceOSDisk.Id -CreateOption Copy


#! Create the backup of the old OS disk
Write-Verbose "Creating the backup of the OS disk: $($VM.StorageProfile.OsDisk.Name)-backup"
New-AzDisk -Disk $diskConfigOriginal -DiskName "$($sourceOSDisk.Name)-backup" -ResourceGroupName $resourceGroup


#! Check that backup of the old disk has been created 
$checkbackup = Read-Host "Check the backup of the original OS disk named $($sourceOSDisk.Name)-backup has been created and press Y to continue"
If ($checkbackup -eq "y" -or $checkbackup -eq "Y") {
    Write-Warning "Continue"
}


#! Delete the old OS Disk to avoid the collision of the same names 
Write-Warning "Deleting the old OS Disk: $($sourceOSDisk.Name)"
Remove-AzDisk -ResourceGroupName $resourceGroup -DiskName $sourceOSDisk.Name -Force -Confirm:$false

$checkolddelete = Read-Host "Check that the original disk $($sourceOSDisk.Name) has been deleted and press Y to continue"
If ($checkolddelete -eq "y" -or $checkolddelete -eq "Y") {
    Write-Warning "Continue"
}

#! Create the 3rd replica of the restored OS disk with the name of the original disk.
#! It's created from the 2nd replica of restored disk that hasn't booted yet.
$diskConfigOriginal = New-AzDiskConfig -SkuName $sourceOSDisk.Sku.Name `
    -Location $sourceOSDisk.Location `
    -DiskSizeGB ($sourceOSDisk | select -ExpandProperty DiskSizeGB) `
    -Zone (($sourceOSDisk | select -ExpandProperty Zones)) `
    -SourceResourceId $restoredOSDisk2nd.Id -CreateOption Copy

Write-Verbose "Creating the 3rd replica of the restored OS disk: $($sourceOSDisk.Name)"
New-AzDisk -Disk $diskConfigRestored -DiskName $sourceOSDisk.Name -ResourceGroupName $resourceGroup


#! Check that the 3rd replica has been created
$check3rd = Read-Host "Check the replica of the restored OS disk: $($sourceOSDisk.Name) has been created and press Y to continue"
If ($check3rd -eq "y" -or $check3rd -eq "Y") {
    Write-Warning "Continue"
}

#! Get the 3rd replica of the restored OS Disk information
Write-Verbose "Get the restored OS Disk information: $($sourceOSDisk.Name)"
$restoredOSDisk3rd = Get-AzDisk -ResourceGroupName $resourceGroup -DiskName $sourceOSDisk.Name


#! Swap the OS Disk 2nd time
Write-Verbose "Swap the OS disk to: $($sourceOSDisk.Name)"
Set-AzVMOSDisk -VM $VM -ManagedDiskId $restoredOSDisk3rd.Id -Name $restoredOSDisk3rd.Name | Out-Null
Write-Verbose "The VM is rebooting..."
Update-AzVM -ResourceGroupName $resourceGroup -VM $VM


#! Delete the unused restored disks 
Write-Warning "Deleting the unused restored Disk: $($sourceOSDisk.Name)-restored-2nd"
Remove-AzDisk -ResourceGroupName $resourceGroup -DiskName "$($sourceOSDisk.Name)-restored-2nd" -Force -Confirm:$false
# Write-Warning "Deleting the unused restored Disk: $restoreddiskName"
# Remove-AzDisk -ResourceGroupName $resourceGroup -DiskName $restoreddiskName -Force -Confirm:$false
