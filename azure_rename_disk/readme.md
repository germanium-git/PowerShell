# Azure - Rename or replace OS disk

## Rename-AzOSDisk-wo-swap.ps1

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
-subscriptionId *subscription-IdD* `
-tenantId *tenant-Id* `
-Verbose
```
