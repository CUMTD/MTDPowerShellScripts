# MTD-AdminTools

![GitHub Release](https://img.shields.io/github/v/release/CUMTD/MTDPowerShellScripts?sort=date&display_name=release&style=for-the-badge&cacheSeconds=120&link=https%3A%2F%2Fgithub.com%2FCUMTD%2FMTDPowerShellScripts%2Freleases)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/CUMTD/MTDPowerShellScripts/build.yml?style=for-the-badge&label=Release%20Build&cacheSeconds=120&link=https%3A%2F%2Fgithub.com%2FCUMTD%2FMTDPowerShellScripts%2Factions%2Fworkflows%2Fbuild.yml)

> PowerShell tools for managing SharePoint Online environments at MTD.

## 📦 About

**MTD-AdminTools** is a PowerShell module developed by MTD to streamline and automate common administrative tasks.

---

## 📂 Included Cmdlets

### `Cleanup-OldSharePointVersions`

Deletes non-current file versions from all document libraries in a specified SharePoint Online site that are older than a given number of days.

#### Parameters

| Name         | Type   | Required | Description                                         |
| ------------ | ------ | -------- | --------------------------------------------------- |
| `SiteUrl`    | string | ✅       | Full URL of the site to scan                        |
| `DaysToKeep` | int    | ❌       | Versions older than this are deleted (default: 365) |

#### Example

```powershell
Import-Module MTD-AdminTools
Cleanup-OldSharePointVersions -SiteUrl "https://ridemtd.sharepoint.com/sites/your-site" -DaysToKeep 180
```

---

## 📥 Installation

### 🔧 Requirements

Before using the module, ensure the following are installed:

- ✅ PowerShell 5.1+ or [PowerShell 7+][ps]
- ✅ [.NET Framework 4.7.2+ (for Windows PowerShell)][dotnet]
- ✅ [PnP.PowerShell][pnp]

#### 📦 Option 1: Install via GitHub Release

1. Go to the [Releases][release] page.
2. Download the latest `MTD-AdminTools.zip` file.
3. Extract the contents somewhere like C:\Modules\MTD-AdminTools.
4. Then, import the module:

```powershell
Import-Module 'C:\Modules\MTD-AdminTools\MTD-AdminTools.psd1'
```

#### 💻 Option 2: Clone the Repo (for Contributors)

```powershell
git clone git@github.com:CUMTD/MTDPowerShellScripts.git
cd MTDPowerShellScripts

# Optional: Add module path to session
$env:PSModulePath += ";$PWD"

# Load the module
Import-Module "$PWD/MTD-AdminTools.psd1"
```

#### ⚙️ Option 3: Use the Installer Script

Run the provided installer script to install the module to a default module path:

```powershell
.\scripts\Install-MTDAdminTools.ps1
```

You can also specify a custom location:

```powershell
.\scripts\Install-MTDAdminTools.ps1 -TargetPath "C:\Modules\MTD-AdminTools"
```

Once installed:

```powershell
Import-Module MTD-AdminTools
```

#### 🧪 Confirm It’s Loaded

```powershell
Get-Command -Module MTD-AdminTools
```

You should see functions like:

```pgsql
CommandType     Name                                  ModuleName
-----------     ----                                  ----------
Function        MTD-CleanupOldSharePointVersions      MTD-AdminTools
```

## 🧰 Development

### Repo Structure

```bash
MTD-SharePointTools/
├── Public/                  # Publicly exported cmdlets
├── Private/                 # Internal helper functions (optional)
├── MTD-AdminTools.psm1      # Module loader
├── MTD-AdminTools.psd1      # Module manifest
├── scripts/                 # Build and utility scripts
├── .editorconfig
├── .gitignore
├── .gitattributes
├── .vscode/settings.json
```

## 📜 License

Licensed under the Apache License 2.0.

[ps]: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5#installing-the-msi-package
[dotnet]: https://dotnet.microsoft.com/en-us/download/dotnet-framework/net472
[pnp]: https://pnp.github.io/powershell/
[release]: https://github.com/CUMTD/MTDPowerShellScripts/releases
