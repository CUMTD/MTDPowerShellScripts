# MTD-AdminTools

![GitHub Release](https://img.shields.io/github/v/release/CUMTD/MTDPowerShellScripts?sort=date&display_name=release&style=for-the-badge&cacheSeconds=120&link=https%3A%2F%2Fgithub.com%2FCUMTD%2FMTDPowerShellScripts%2Freleases)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/CUMTD/MTDPowerShellScripts/build.yml?style=for-the-badge&label=Release%20Build&cacheSeconds=120&link=https%3A%2F%2Fgithub.com%2FCUMTD%2FMTDPowerShellScripts%2Factions%2Fworkflows%2Fbuild.yml)

> PowerShell tools for managing SharePoint Online environments at MTD.

## 📦 About

**MTD-AdminTools** is a PowerShell module developed by MTD to streamline and automate common administrative tasks.

---

## 📂 Included Cmdlets

### `Find-LargeSharePointFiles`

#### Parameters

| Name                 | Type   | Required | Description                                                                                                         |
| -------------------- | ------ | -------- | ------------------------------------------------------------------------------------------------------------------- |
| `SharePointAdminUrl` | string | Yes      | The URL of the SharePoint Admin Center (e.g., `https://<tenant>-admin.sharepoint.com`). Required to scan all sites. |
| `SiteUrl`            | string | No       | The URL of a specific site to scan (e.g., `https://<tenant>.sharepoint.com/sites/YOURSITE`).                        |
| `SizeThresholdMB`    | int    | No       | File size threshold in megabytes (default: 500).                                                                    |

#### Example

```powershell
Import-Module MTD-AdminTools
Find-LargeSharePointFiles -SiteUrl "https://<tenant>-admin.sharepoint.com" -SizeThresholdMB 1024
Find-LargeSharePointFiles -SiteUrl "https://<tenant>.sharepoint.com/sites/YOURSITE" -SizeThresholdMB 1024
```

### `Find-StaleIntuneDevices`

#### Parameters

| Name           | Type | Required | Description                                       |
| -------------- | ---- | -------- | ------------------------------------------------- |
| `DaysInactive` | int  | No       | Number of days since last check-in (default: 90). |

#### Example

```powershell
Import-Module MTD-AdminTools
Find-StaleIntuneDevices -DaysInactive 120
```

### `Offboard-User`

#### Parameters

| Name                | Type   | Required | Description                                                  |
| ------------------- | ------ | -------- | ------------------------------------------------------------ |
| `RunAsUser`         | string | Yes      | UPN of the admin running the script.                         |
| `UserPrincipalName` | string | Yes      | UPN of the user being offboarded.                            |
| `ManagerEmail`      | string | Yes      | Email address of the user's manager.                         |
| `DeleteAccount`     | switch | No       | If set, deletes the user instead of disabling.               |
| `HybridUser`        | switch | No       | If set, processes the user as a synced on-premises identity. |
| `WhatIf`            | switch | No       | Performs a dry run without making changes.                   |

#### Example

```powershell
Import-Module MTD-AdminTools
Offboard-User -RunAsUser me@mtd.org -UserPrincipalName departed@mtd.org -ManagerEmail manager@mtd.org -HybridUser -WhatIf
Offboard-User -RunAsUser me@mtd.org -UserPrincipalName departed@mtd.org -ManagerEmail manager@mtd.org -DeleteAccount -WhatIf
```

### `Remove-OldSharePointVersions`

Deletes non-current file versions older than a specified number of days from all document libraries in a SharePoint site.

#### Parameters

| Name         | Type   | Required | Description                                                         |
| ------------ | ------ | -------- | ------------------------------------------------------------------- |
| `SiteUrl`    | string | Yes      | Full URL of the site to scan.                                       |
| `DaysToKeep` | int    | No       | Versions older than this number of days are deleted (default: 365). |

#### Example

```powershell
Import-Module MTD-AdminTools
Remove-OldSharePointVersions -SiteUrl "https://<tenant>.sharepoint.com/sites/YOURSITE" -DaysToKeep 180
```

### `Remove-StaleIntuneDevices`

#### Example

```powershell
Import-Module MTD-AdminTools
Find-StaleIntuneDevices -DaysInactive 120 | Remove-StaleIntuneDevices
```

### `Set-SharePointRetention`

Configures version-history retention on SharePoint Online sites by enabling automatic trimming or applying custom version/age limits.

#### Parameters

| Name                               | Type   | Required    | Description                                                                                                   |
| ---------------------------------- | ------ | ----------- | ------------------------------------------------------------------------------------------------------------- |
| `SharePointAdminUrl`               | string | Yes         | URL of the SharePoint Admin Center (e.g., `https://contoso-admin.sharepoint.com`).                            |
| `SiteUrl`                          | string | No          | Site URL to target (e.g., `https://contoso.sharepoint.com/sites/YOURSITE`). Defaults to all sites if omitted. |
| `EnableAutoExpirationVersionTrim`  | switch | Auto mode   | Enables automatic version trimming. Mutually exclusive with custom mode.                                      |
| `ExpireVersionsAfterDays`          | int    | Custom mode | Deletes versions older than the specified number of days.                                                     |
| `MajorVersionLimit`                | int    | Custom mode | Keeps only the specified number of major versions.                                                            |
| `MajorWithMinorVersionsLimit`      | int    | Custom mode | Also retains minor versions for the last N major versions (in addition to `MajorVersionLimit`).               |
| `ApplyToExistingDocumentLibraries` | switch | No          | Targets existing libraries (default if no apply flag is used).                                                |
| `ApplyToNewDocumentLibraries`      | switch | No          | Also applies settings to libraries created after this change.                                                 |

> **Note:** In Custom mode, at least one of `-ExpireVersionsAfterDays`, `-MajorVersionLimit`, or `-MajorWithMinorVersionsLimit` is required.

#### Example

```powershell
Import-Module MTD-AdminTools

# Automatic version trimming across all sites, including new libraries
Set-SharePointRetention `
  -SharePointAdminUrl "https://contoso-admin.sharepoint.com" `
  -EnableAutoExpirationVersionTrim `
  -ApplyToNewDocumentLibraries

# Custom limits on a specific site: keep max 50 majors & delete versions older than 90 days
Set-SharePointRetention `
  -SharePointAdminUrl "https://contoso-admin.sharepoint.com" `
  -SiteUrl "https://contoso.sharepoint.com/sites/YOURSITE" `
  -MajorVersionLimit 50 `
  -ExpireVersionsAfterDays 90 `
  -ApplyToExistingDocumentLibraries
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
.\scripts\Install-MTDAdminTools.ps1 [-TargetPath "C:\Modules\MTD-AdminTools"]
Import-Module MTD-AdminTools
```

### 🧪 Verify Installation

```powershell
Get-Command -Module MTD-AdminTools
```

You should see commands like:

```
CommandType     Name                          ModuleName
-----------     ----                          ----------
Function        Find-LargeSharePointFiles     MTD-AdminTools
Function        Set-SharePointRetention       MTD-AdminTools
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
