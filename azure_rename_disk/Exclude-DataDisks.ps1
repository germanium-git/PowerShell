[CmdletBinding()]
Param (
    [Parameter(Position = 0, Mandatory = $True, HelpMessage = 'Enter the Resource Group of the VM')]
    [Alias('rg')]
    [String]$resourceGroup,

    [Parameter(Position = 1, Mandatory = $true, HelpMessage = 'Enter the VM name')]
    [Alias('vm')]
    [String]$vmName,

    [Parameter(Position = 2, Mandatory = $true, HelpMessage = 'Enter the Recovery Services Vault name')]
    [Alias('rsv')]
    [String]$vaultName,

    [Parameter(Position = 3, Mandatory = $true, HelpMessage = 'Enter the subscription ID')]
    [Alias('SubId')]
    [String]$subscriptionId,

    [Parameter(Position = 4, Mandatory = $true, HelpMessage = 'Enter the tenant ID')]
    [Alias('TenId')]
    [String]$tenantId

)


#! Sign in to Azure
Try {
    Write-Verbose "Connecting to Azure Cloud..."
    Connect-AzAccount -TenantId $tenantId -SubscriptionId $subscriptionId -ErrorAction Stop | Out-Null
}
Catch {
    Write-Warning "Cannot connect to Azure Cloud. Please check your credentials. Exiting!"
    Break
}

#! Get information about data disk
Write-Verbose "Get the Data Disk LUN information from the VM: $vmName"
$VM = Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName
$luns = ForEach-Object{$VM.StorageProfile.DataDisks.Lun}
$listOfLun = $($luns -join ',') | Out-String


#! Get information about the Recovery services vault
Write-Verbose "Get information from the RSV: $vaultName"
$targetVault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroup -Name $vaultName


#! Get the recovery services vault context
Set-AzRecoveryServicesVaultContext -Vault $targetVault

#! Get information about the backup item
Write-Verbose "Get Information about the backup item: $vmName"
$backupItem = Get-AzRecoveryServicesBackupItem -BackupManagementType "AzureVM" -WorkloadType "AzureVM" -VaultId $targetVault.ID | Where-Object {$_.Name -like "*$vmName*"}

#$Container = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -Status Registered -FriendlyName $vmName -VaultId $targetVault.ID
#$BackupItem = Get-AzRecoveryServicesBackupItem -Container $Container -WorkloadType AzureVM -VaultId $vault.ID

# Exlude data disks from backup item
Write-Verbose "Getting the data disks with LUN $listOfLun excluded from the backup item $($backupItem.ContainerName.Split(';')[2])"
Enable-AzRecoveryServicesBackupProtection -Item $backupItem -ExclusionDisksList $listOfLun -VaultId $targetVault.ID
