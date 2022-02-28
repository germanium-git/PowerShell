# Azure - Rename or replace OS disk

## Replace-AzOSDisk.ps1

This example will create a copy of the OS Disk not attached to any VM.
Use case - Rename the OS disk restored from the backup.
You need to specify the Resource Group name, existing OSDisk name, new OSDisk name, subscription ID and tenant id.
Then the script will create a copy of the disk in Azure with desired name.

```powershell
.\Rename-AzOSDisk.ps1 `
-resourceGroup *rg-name* `
-osdiskName *existing-disk* `
-newdiskName *new-disk* `
-subscriptionId *subscription-IdD* `
-tenantId *tenant-Id* `
-Verbose
```

## Rename-AzOSDisk.ps1

This example will replace the OS Disk for the specified VM.
Use-case - Swap the OS disk in the VM with a restored disk.
You need to specify the Resource Group name, VM name and the unattached OS disk name restored from the backup.

```powershell
.\Replace-AzOSDisk.ps1 `
-resourceGroup *rg-name* `
-VMName *virtual-machine-name* `
-restoreddiskName *new-os-disk* `
-subscriptionId *subscription-Id* `
-tenantId *tenant-Id* `
-Verbose
```

## Exclude-DataDisks.ps1

Use-case - Remove the data disks from the backup.
You need to specify the LUN id of the data disk to get it excluded from the backup.

```powershell
.\Exclude-DataDisks.ps1 `
-resourceGroup *rg-name* `
-vmName *virtual-machine-name* `
-vaultName *rsv-name* `
-subscriptionId *subscription-Id* `
-tenantId *tenant-Id* `
-Verbose
```

```powershell
.\Exclude-DataDisks_v2.ps1 `
-resourceGroup *rg-name* `
-vmName *virtual-machine-name* `
-listOfLun *0,1,2,3,4,5,6,7,8*
-vaultName *rsv-name* `
-subscriptionId *subscription-Id* `
-tenantId *tenant-Id* `
-Verbose
```

## Swap-AzOsDisk.ps1

Change the name of the restored OS disk when is being attached to virtual machine.

```powershell
.\Swap-AzOSDisk.ps1 `
-resourceGroup *rg-name* `
-VMName *vm-name* `
-restoreddiskName *restored-disk* `
-subscriptionId *subscription-Id* `
-tenantId *tenant-Id* `
-Verbose
```
