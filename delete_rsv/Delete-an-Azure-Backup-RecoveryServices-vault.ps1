<#
 
.SYNOPSIS
 
A script used to delete an Azure Backup Recovery Services vault and all cloud backup items.
 
.DESCRIPTION
 
A script used to delete an Azure Backup Recovery Services vault. 
First of all the script will check if PowerShell runs as an Administrator (when not running from Cloud Shell), otherwise the script will be exited as this is required.
Next soft delete is disabled for the selected , and all soft-deleted backup items are reversed.
Then all cloud backup items are removed before the Recovery Services vault is removed. 
Afterwards the resource groups holding the Recovery Services vault and the one used for the instant recovery are deleted.
 
.NOTES
 
Filename:       Delete-an-Azure-Backup-RecoveryServices-vault.ps1
Created:        17/11/2020
Last modified:  19/10/2021
Author:         Wim Matthyssen
PowerShell:     Azure PowerShell or Azure Cloud Shell
Version:        Install latest Azure PowerShell modules 
Action:         Change variables where needed to fit your needs
Disclaimer:     This script is provided "As Is" with no warranties.
 
.EXAMPLE
 
.\Delete-an-Azure-Backup-RecoveryServices-vault.ps1
 
.LINK
 
https://wmatthyssen.com/2020/11/17/azure-backup-remove-a-recovery-services-vault-and-all-cloud-backup-items-with-azure-powershell/
#>

[CmdletBinding()]
Param (
    [Parameter(Position = 0, Mandatory = $True, HelpMessage = 'Enter the Resource Group of the RSV')]
    [Alias('rg')]
    [String]$rgBackup,

    [Parameter(Position = 1, Mandatory = $true, HelpMessage = 'Enter the RSV name')]
    [Alias('vm')]
    [String]$vaultName,

    [Parameter(Position = 2, Mandatory = $true, HelpMessage = 'Enter the subscription ID')]
    [Alias('SubId')]
    [String]$subscriptionId,

    [Parameter(Position = 3, Mandatory = $true, HelpMessage = 'Enter the tenant ID')]
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


$vault = Get-AzRecoveryServicesVault -ResourceGroupName $rgBackup -Name $vaultName

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "
 
## Disable soft delete for the Azure Backup Recovery Services vault
 
Set-AzRecoveryServicesVaultProperty -Vault $vault.ID -SoftDeleteFeatureState Disable
 
Write-Host ($writeEmptyLine + " # Soft delete disabled for Recovery Service vault " + $vault.Name + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
 
## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Check if there are backup items in a soft-deleted state and reverse the delete operation
 
$containerSoftDelete = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $vault.ID | Where-Object {$_.DeleteState -eq "ToBeDeleted"}
 
foreach ($item in $containerSoftDelete) {
    Undo-AzRecoveryServicesBackupItemDeletion -Item $item -VaultId $vault.ID -Force -Verbose
}
 
Write-Host ($writeEmptyLine + "# Undeleted all backup items in a soft deleted state in Recovery Services vault " + $vault.Name + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
 
## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Stop protection and delete data for all backup-protected items
 
$containerBackup = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $vault.ID | Where-Object {$_.DeleteState -eq "NotDeleted"}
 
foreach ($item in $containerBackup) {
    Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $vault.ID -RemoveRecoveryPoints -Force -Verbose
}
 
Write-Host ($writeEmptyLine + "# Deleted backup date for all cloud protected items in Recovery Services vault " + $vault.Name + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
 
## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Delete the Recovery Services vault
 
Remove-AzRecoveryServicesVault -Vault $vault -Verbose
 
Write-Host ($writeEmptyLine + "# Recovery Services vault " + $vault.Name + " deleted" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
 
## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Delete the resource groups holding the Recovery Services vault and the one used for the instant recovery and this without confirmation
 
Get-AzResourceGroup -Name $rgBackup | Remove-AzResourceGroup -Force -Verbose
Get-AzResourceGroup -Name $rgBackupInstanRecovery | Remove-AzResourceGroup -Force -Verbose
 
Write-Host ($writeEmptyLine + "# Resource groups " + $vault.ResourceGroupName + " and " + $rgBackupInstanRecovery + " deleted" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
 
## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Write script completed
 
Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine
 
## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
