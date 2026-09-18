# Copy-AzGalleryImageVersionAcrossTenants.ps1
# This script consolidates Export, Download, Upload, and Import actions for Azure Image Gallery versions.

param(
    [Parameter(Mandatory = $false)]
    [string]$SourceSubscriptionId = "<subscriptioID>",

    [Parameter(Mandatory = $false)]
    [string]$SourceResourceGroup = "rg-avd-images",

    [Parameter(Mandatory = $false)]
    [string]$SourceGalleryName = "AVDCITTest",

    [Parameter(Mandatory = $false)]
    [string]$SourceImageDefinition = "AVD_VZ_Windows_11_CIS_TPM_Base_v2",

    [Parameter(Mandatory = $false)]
    [string]$SourceVersionName = "1.0.0",

    [Parameter(Mandatory = $false)]
    [string]$SourceLocation = "westeurope",

    [Parameter(Mandatory = $false)]
    [string]$DiskExportName = "TempExportDisk",

    [Parameter(Mandatory = $false)]
    [string]$TargetSubscriptionId = "<subscriptioID>",

    [Parameter(Mandatory = $false)]
    [string]$TargetResourceGroup = "rg-avd-euw-shared-services",

    [Parameter(Mandatory = $false)]
    [string]$TargetImageGallery = "gal_avd_euw",

    [Parameter(Mandatory = $false)]
    [string]$TargetGalleryImageDefinitionName = "AVD_VZ_Windows_11_CIS_TPM_Base_v2",

    [Parameter(Mandatory = $false)]
    [string]$TargetVersionName = "1.0.0",

    [Parameter(Mandatory = $false)]
    [string]$DiskImportName = "TempImportDisk",

    [Parameter(Mandatory = $false)]
    [string]$TargetLocation = "westeurope",

    [Parameter(Mandatory = $false)]
    [string]$LocalVhdPath = "C:\Users\<username>\Downloads\AVD_VZ_Windows_11_CIS_TPM_Base_v2_1.0.0.vhd",

    [Parameter(Mandatory = $false)]
    [string]$AzCopyPath = "C:\Users\<username>\Downloads\azcopy_windows_amd64_10.32.1\azcopy.exe",

    [Parameter(Mandatory = $false)]
    [int]$SasDurationSeconds = 3600
)

$ErrorActionPreference = "Stop"

Write-Host "=== Step 1: Connecting to Source Azure Account ===" -ForegroundColor Cyan
Connect-AzAccount
Select-AzSubscription -SubscriptionId $SourceSubscriptionId

Write-Host "Retrieving source image version..." -ForegroundColor Cyan
$sourceImgVer = Get-AzGalleryImageVersion `
  -ResourceGroupName $SourceResourceGroup `
  -GalleryName $SourceGalleryName `
  -GalleryImageDefinitionName $SourceImageDefinition `
  -Name $SourceVersionName

Write-Host "Creating temporary managed disk from image version..." -ForegroundColor Cyan
$diskConfig = New-AzDiskConfig `
  -Location $SourceLocation `
  -CreateOption FromImage `
  -GalleryImageReference @{Id = $sourceImgVer.Id} `
  -HyperVGeneration V2

$diskConfig = Set-AzDiskSecurityProfile `
  -Disk $diskConfig `
  -SecurityType "TrustedLaunch"

$tempDisk = New-AzDisk `
  -ResourceGroupName $SourceResourceGroup `
  -DiskName $DiskExportName `
  -Disk $diskConfig

Write-Host "Verifying source disk security settings..." -ForegroundColor Cyan
$disk = Get-AzDisk -ResourceGroupName $SourceResourceGroup -DiskName $DiskExportName
Write-Host "Disk Security Type: $($disk.SecurityProfile.SecurityType)" -ForegroundColor Green

Write-Host "=== Step 2: Downloading Disk VHD locally ===" -ForegroundColor Cyan
$sas = Grant-AzDiskAccess `
  -ResourceGroupName $SourceResourceGroup `
  -DiskName $DiskExportName `
  -DurationInSecond $SasDurationSeconds `
  -Access Read

try {
    Write-Host "Downloading VHD using AzCopy..." -ForegroundColor Yellow
    & $AzCopyPath copy "$($sas.AccessSAS)" $LocalVhdPath
}
finally {
    Write-Host "Revoking read access to source disk..." -ForegroundColor Cyan
    Revoke-AzDiskAccess -ResourceGroupName $SourceResourceGroup -DiskName $DiskExportName
}

Write-Host "=== Step 3: Uploading and Importing to Target Image Gallery ===" -ForegroundColor Cyan
Select-AzSubscription -SubscriptionId $TargetSubscriptionId

$vhdSize = (Get-Item $LocalVhdPath).Length

$targetDiskConfig = New-AzDiskConfig `
    -Location $TargetLocation `
    -CreateOption Upload `
    -UploadSizeInBytes $vhdSize `
    -SkuName Premium_LRS `
    -HyperVGeneration V2

$targetDiskConfig = Set-AzDiskSecurityProfile `
    -Disk $targetDiskConfig `
    -SecurityType "TrustedLaunch"

$targetDisk = New-AzDisk `
    -ResourceGroupName $TargetResourceGroup `
    -DiskName $DiskImportName `
    -Disk $targetDiskConfig

$targetSas = Grant-AzDiskAccess `
    -ResourceGroupName $TargetResourceGroup `
    -DiskName $DiskImportName `
    -DurationInSecond $SasDurationSeconds `
    -Access Write

try {
    Write-Host "Uploading VHD using AzCopy..." -ForegroundColor Yellow
    & $AzCopyPath copy $LocalVhdPath "$($targetSas.AccessSAS)" --blob-type PageBlob
}
finally {
    Write-Host "Revoking write access to target disk..." -ForegroundColor Cyan
    Revoke-AzDiskAccess -ResourceGroupName $TargetResourceGroup -DiskName $DiskImportName
}

Write-Host "Enabling Accelerated Networking on the target managed disk..." -ForegroundColor Cyan
$diskUpdateConfig = New-AzDiskUpdateConfig -AcceleratedNetwork $true
Update-AzDisk -ResourceGroupName $TargetResourceGroup -Name $DiskImportName -DiskUpdate $diskUpdateConfig

Write-Host "Publishing new image version to target Shared Image Gallery..." -ForegroundColor Cyan
$osDisk = @{
    Source = @{
        Id = $targetDisk.Id
    }
}

New-AzGalleryImageVersion `
  -ResourceGroupName $TargetResourceGroup `
  -GalleryName $TargetImageGallery `
  -GalleryImageDefinitionName $TargetGalleryImageDefinitionName `
  -Name $TargetVersionName `
  -Location $TargetLocation `
  -OSDiskImage $osDisk `
  -TargetRegion @{Name = $TargetLocation}

Write-Host "Process completed successfully!" -ForegroundColor Green
