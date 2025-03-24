# MTD-AdminTools

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
