# MTD-AdminTools

![GitHub Release](https://img.shields.io/github/v/release/CUMTD/MTDPowerShellScripts?sort=date&display_name=release&style=for-the-badge&cacheSeconds=120&link=https%3A%2F%2Fgithub.com%2FCUMTD%2FMTDPowerShellScripts%2Freleases)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/CUMTD/MTDPowerShellScripts/build.yml?style=for-the-badge&label=Release%20Build&cacheSeconds=120&link=https%3A%2F%2Fgithub.com%2FCUMTD%2FMTDPowerShellScripts%2Factions%2Fworkflows%2Fbuild.yml)

> PowerShell tools for managing SharePoint Online environments at MTD.

## 📦 About

**MTD-AdminTools** is a PowerShell module developed by MTD to streamline and automate common administrative tasks.

---

## 📂 Included Cmdlets

### `Disable-MtdUser`

Offboards a user by disabling or deleting the account, converting the mailbox to shared, forwarding mail to the manager, and granting the manager OneDrive access.

| Parameter | Required | Description |
| --- | --- | --- |
| `RunAsUser` | Yes | UPN of the admin running the script (used to activate PIM roles and connect to Graph/Exchange). |
| `UserPrincipalName` | Yes | UPN of the user being offboarded. |
| `ManagerEmail` | Yes | Manager UPN who receives mailbox permissions and forwarding. |
| `DeleteAccount` | No | Deletes the account instead of disabling it. |
| `HybridUser` | No | Also handles on‑prem AD for hybrid users. |

```powershell
Import-Module MTD-AdminTools
Disable-MtdUser -RunAsUser me@mtd.org -UserPrincipalName departed@mtd.org -ManagerEmail manager@mtd.org -HybridUser -WhatIf
Disable-MtdUser -RunAsUser me@mtd.org -UserPrincipalName departed@mtd.org -ManagerEmail manager@mtd.org -DeleteAccount -WhatIf
```

### `Get-LargeSharePointFile`

Scans one site or all tenant sites for documents larger than a threshold.

| Parameter | Required | Description |
| --- | --- | --- |
| `SiteUrl` | Yes (single-site mode) | URL of the site to scan. |
| `SharePointAdminUrl` | Yes (tenant mode) | Admin center URL; when provided all sites are scanned. |
| `ClientId` | Yes | Entra app registration Client ID for PnP interactive auth. |
| `SizeThresholdMB` | No | Minimum size in MB to report (default: 500). |

```powershell
# Single site
Get-LargeSharePointFile -SiteUrl "https://tenant.sharepoint.com/sites/YOURSITE" -ClientId $AppId -SizeThresholdMB 1024

# All sites in the tenant
Get-LargeSharePointFile -SharePointAdminUrl "https://tenant-admin.sharepoint.com" -ClientId $AppId -SizeThresholdMB 1024
```

### `Get-StaleIntuneDevice`

Lists managed devices that have not checked in recently.

| Parameter | Required | Description |
| --- | --- | --- |
| `DaysInactive` | No | Devices with last sync older than this many days are returned (default: 90). |

```powershell
Get-StaleIntuneDevice -DaysInactive 120
```

### `Remove-StaleIntuneDevice`

Removes Intune devices piped from `Get-StaleIntuneDevice`; supports `-WhatIf`/`-Confirm`.

```powershell
Get-StaleIntuneDevice -DaysInactive 120 | Remove-StaleIntuneDevice -WhatIf
```

### `Remove-OldSharePointVersion`

Deletes non-current file versions older than a given age across document libraries in a site.

| Parameter | Required | Description |
| --- | --- | --- |
| `SiteUrl` | Yes | Site to scan (e.g., `https://tenant.sharepoint.com/sites/YOURSITE`). |
| `DaysToKeep` | No | Delete versions older than this many days (default: 365). |
| `LaunchStorageExplorer` | No | Launch the SharePoint Storage Explorer after cleanup. |

```powershell
Remove-OldSharePointVersion -SiteUrl "https://tenant.sharepoint.com/sites/YOURSITE" -DaysToKeep 180 -WhatIf
```

### `Set-SharePointRetention`

Configures version-history retention by enabling automatic trimming or applying custom version/age limits.

| Parameter | Required | Description |
| --- | --- | --- |
| `SharePointAdminUrl` | Yes | Admin center URL (e.g., `https://contoso-admin.sharepoint.com`). |
| `EnableAutoExpirationVersionTrim` | Auto mode | Turn on Microsoft automatic trimming. |
| `ExpireVersionsAfterDays` | Custom mode | Remove versions older than this age. |
| `MajorVersions` | Custom mode | Keep only this many major versions. |
| `MajorWithMinorVersions` | Custom mode | Keep minor versions for the last N majors. |
| `ApplyToExistingDocumentLibraries` | No | Apply to current libraries. |
| `ApplyToNewDocumentLibraries` | No | Apply to libraries created after the change. |
| `SiteUrl` | No | Limit to a single site; omit to target all sites. |

```powershell
# Automatic version trimming across all sites, including new libraries
Set-SharePointRetention `
  -SharePointAdminUrl "https://contoso-admin.sharepoint.com" `
  -EnableAutoExpirationVersionTrim `
  -ApplyToNewDocumentLibraries

# Custom limits on a specific site: keep max 50 majors & delete versions older than 90 days
Set-SharePointRetention `
  -SharePointAdminUrl "https://contoso-admin.sharepoint.com" `
  -SiteUrl "https://contoso.sharepoint.com/sites/YOURSITE" `
  -MajorVersions 50 `
  -ExpireVersionsAfterDays 90 `
  -ApplyToExistingDocumentLibraries
```

### `New-DispositionReport`

Enriches a Purview Disposition export with SharePoint file sizes and created years, producing detailed and summary CSVs grouped by label and year.

| Parameter | Required | Description |
| --- | --- | --- |
| `DispositionCsvPath` | Yes | Path to the Purview export CSV. |
| `PowerShellAppId` | Yes | Application ID used for PnP interactive auth. |
| `DetailOutputCsvPath` | No | Output path for the detailed CSV (default: `./DispositionWithSizes_Detail.csv`). |
| `SummaryOutputCsvPath` | No | Output path for the summary CSV (default: `./DispositionWithSizes_Summary.csv`). |
| `UrlColumnName` | No | CSV column containing the item URL (default: `Location`). |
| `LabelColumnName` | No | CSV column containing the retention label (default: `TagName`). |

```powershell
New-DispositionReport `
  -DispositionCsvPath .\PurviewDisposition.csv `
  -PowerShellAppId $AppId `
  -DetailOutputCsvPath .\DispositionWithSizes_Detail.csv `
  -SummaryOutputCsvPath .\DispositionWithSizes_Summary.csv
```

## 📥 Installation

### 🔧 Requirements

Before using the module, ensure the following are installed:

- PowerShell 5.1+ or [PowerShell 7+][ps]
- .NET Framework 4.7.2+ (for Windows PowerShell)[dotnet]
- [PnP.PowerShell][pnp]

### 📦 Option 1: Install via GitHub Release

1. Go to the [Releases][release] page.
2. Download the latest `MTD-AdminTools.zip`.
3. Extract to a folder, e.g. `C:\Modules\MTD-AdminTools`.
4. Import:

```powershell
Import-Module 'C:\Modules\MTD-AdminTools\MTD-AdminTools.psd1'
```

### 💻 Option 2: Clone the Repo (for Contributors)

```powershell
git clone git@github.com:CUMTD/MTDPowerShellScripts.git
cd MTDPowerShellScripts
\$env:PSModulePath += ";\$PWD"
Import-Module "\$PWD/MTD-AdminTools.psd1"
```

### ⚙️ Option 3: Use the Installer Script

```powershell
.\Scripts\Install-MTDAdminTools.ps1 [-TargetPath "C:\Modules\MTD-AdminTools"]
Import-Module MTD-AdminTools
```

> **Note:** Run the installer from the root of the extracted release or cloned repo so it can locate the module files that sit alongside the `Scripts` directory.

### 🧪 Verify Installation

```powershell
Get-Command -Module MTD-AdminTools
```

You should see commands like:

```
CommandType     Name                       ModuleName
-----------     ----                       ----------
Function        Get-LargeSharePointFile    MTD-AdminTools
Function        Remove-OldSharePointVersion MTD-AdminTools
```

## 🧰 Development

### Repo Structure

```bash
MTDPowerShellScripts/
├── Public/
├── Private/
├── MTD-AdminTools.psm1
├── MTD-AdminTools.psd1
├── scripts/
├── .editorconfig
├── .gitignore
├── .gitattributes
└── .vscode/
```

## 📜 License

Licensed under the Apache License 2.0.

[ps]: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5#installing-the-msi-package
[dotnet]: https://dotnet.microsoft.com/en-us/download/dotnet-framework/net472
[pnp]: https://pnp.github.io/powershell/
[release]: https://github.com/CUMTD/MTDPowerShellScripts/releases
