<#
.SYNOPSIS
  Removes document versions older than a specified age from all document libraries in a site.

.DESCRIPTION
  Connects to SharePoint Online using PnP PowerShell and deletes all non-current file versions older than X days.

.PARAMETER SiteUrl
  The full URL to the SharePoint site to scan (e.g. https://ridemtd.sharepoint.com/sites/YOURSITE).

.PARAMETER DaysToKeep
  Number of days to keep. Older versions will be deleted. Default is 365.

.EXAMPLE
  Cleanup-OldSharePointVersions -SiteUrl "https://ridemtd.sharepoint.com/sites/YOURSITE" -DaysToKeep 180

.NOTES
  Author: Ryan Blackman
  Created: 2025-03-19
#>
function Remove-OldSharePointVersions {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$SiteUrl,

		[Parameter(Mandatory = $false)]
		[int]$DaysToKeep = 365
	)

	Write-Host "🔗 Connecting to $SiteUrl..." -ForegroundColor Cyan
	Connect-PnPOnline -Url $SiteUrl -UseWebLogin

	$cutoffDate = (Get-Date).AddDays(-$DaysToKeep)
	Write-Host "🗓️  Removing versions older than $DaysToKeep days (before $($cutoffDate.ToShortDateString()))" -ForegroundColor Yellow

	$lists = Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 -and $_.Hidden -eq $false }

	foreach ($list in $lists) {
		Write-Host "`n📁 Processing library: $($list.Title)" -ForegroundColor Cyan
		$items = Get-PnPListItem -List $list -PageSize 1000

		foreach ($item in $items) {
			$versions = Get-PnPProperty -ClientObject $item -Property Versions
			$oldVersions = @(
				$versions | Where-Object {
					$_.Created -lt $cutoffDate -and $_.IsCurrentVersion -eq $false
				}
			)

			foreach ($version in $oldVersions) {
				try {
					Write-Host "🧹 Deleting version from $($version.Created) for $($item.FieldValues.FileLeafRef)" -ForegroundColor Gray
					$version.DeleteObject()
				}
				catch {
					Write-Warning "❌ Failed to delete version: $($_.Exception.Message)"
				}
			}

			if ($oldVersions.Count -gt 0) {
				Invoke-PnPQuery
			}
		}

		Write-Host "✅ Finished cleaning: $($list.Title)"
	}

	Write-Host "`n🎉 Cleanup complete for $SiteUrl" -ForegroundColor Green
}
