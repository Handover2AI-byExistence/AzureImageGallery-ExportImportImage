# Copy Azure Shared Image Gallery Image Version Across Tenants

![PSScriptAnalyzer](https://github.com/Handover2AI/AzureImageGallery-ExportImportImage/actions/workflows/ci-workflow-psscriptanalyzer.yml/badge.svg)

This script copies an existing image version from an Azure Shared Image Gallery in one tenant/subscription to another gallery in a different tenant/subscription. It uses a temporary managed disk and AzCopy to move the underlying VHD and then creates a new image version in the target gallery with comprehensive support for Hyper-V Gen 2 and Trusted Launch security profiles

## 🚀 Core Features
- **Cross-Tenant Compatibility**: Handles independent authentication flow transitions securely.
- **Trusted Launch Replication**: Automatically carries over Gen 2 Hyper-V configurations and TrustedLaunch security provisions.
- **AzCopy Engine Support**: Interoperates with local installations of `azcopy.exe` to maximize data streaming velocities via Shared Access Signatures (SAS).
- **Automated Validation**: Configures mandatory properties such as Accelerated Networking before injecting the virtual asset into the target gallery workspace.

## 📦 Prerequisites
1. **Az PowerShell Module**: Ensure the `Az` module suite is active. Run `Install-Module -Name Az` if required.
2. **AzCopy CLI Utility**: Download the executable and ensure its destination directory is accessible or configured natively within your parameter fields.
3. **IAM Permissions**: 
   - **Source Subscription**: Reader/Contributor privileges inside your compute framework to invoke SAS leases.
   - **Target Subscription**: Contributor privileges inside target Resource Groups to construct target disks and update Compute Galleries.

## 🛠️ Parameters Reference
| Parameter Name | Description | Default Profile Example |
| :--- | :--- | :--- |
| `SourceSubscriptionId` | ID of the origin subscription framework | `<subscriptionID>` |
| `SourceResourceGroup` | Source resource group holding your image infrastructure | `rg-avd-images` |
| `SourceGalleryName` | Target source gallery designation | `AVDCITTest` |
| `SourceImageDefinition` | Image definition title | `AVD_VZ_Windows_11_CIS_TPM_Base_v2` |
| `SourceVersionName` | Explicit gallery version tag to replicate | `1.0.0` |
| `LocalVhdPath` | Hard drive location mapping temporary `.vhd` cache files | `C:\Users\...\Downloads\....vhd` |
| `AzCopyPath` | Exact mapping route pointer pointing to `azcopy.exe` | `C:\...\azcopy.exe` |
| `TargetSubscriptionId` | Destination framework workspace subscription ID | `<subscriptionID>` |

## 🏗️Deployment Execution Context
Execute the script straight from a standard administrative PowerShell session terminal window:

```powershell
.\Copy-AzGalleryImageVersionAcrossTenants.ps1 `
  -SourceSubscriptionId "YOUR_SOURCE_SUB_ID" `
  -TargetSubscriptionId "YOUR_TARGET_SUB_ID" `
  -LocalVhdPath "D:\Cache\ImageMigration.vhd" `
  -AzCopyPath "C:\Tools\azcopy.exe"
```

## 📝 Notes

- The script downloads the VHD to a local path (default: `C:\temp\tempexportdisk.vhd`). Ensure you have enough disk space.
- If the transfer takes longer than the SAS duration, you may need to re-run with a higher `SasDurationInSeconds`.
- Clean up temporary disks and local VHDs if you no longer need them.
- Do not commit any secrets or tenant-specific IDs you consider sensitive into the repository.

## 🏛️ Project Governance

- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Contributing Guidelines](CONTRIBUTING.md)

## ✍️ Author

Created and maintained by Handover2AI-byExistence.  
If you find this useful, feel free to star ⭐ the repo or open issues for improvements.
