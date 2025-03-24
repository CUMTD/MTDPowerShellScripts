<#
.SYNOPSIS
    Removes document versions older than a specified age from all document libraries in a site.

.DESCRIPTION
    Connects to SharePoint Online using PnP PowerShell and deletes all non-current file versions
    older than X days. Supports -WhatIf and -Confirm so you can preview or confirm each removal.

.PARAMETER SiteUrl
    The full URL to the SharePoint site to scan (e.g., https://tenant.sharepoint.com/sites/MySite).

.PARAMETER DaysToKeep
    Number of days to keep. Older versions will be deleted. Default is 365.

.PARAMETER LaunchStorageExplorer
	Launches the SharePoint Storage Explorer after the script completes. Default is false.

.EXAMPLE
    Remove-OldSharePointVersions -SiteUrl "https://tenant.sharepoint.com/sites/MySite" -DaysToKeep 180 -WhatIf

    Shows which file versions would be removed but doesn't actually remove them.

.EXAMPLE
    Remove-OldSharePointVersions -SiteUrl "https://tenant.sharepoint.com/sites/MySite" -Confirm

    Prompts for confirmation before removing each old version.

.EXAMPLE
    Remove-OldSharePointVersions -SiteUrl "https://tenant.sharepoint.com/sites/MySite" -LaunchStorageExplorer

    Launch the SharePoint Storage Explorer after the script completes.

.NOTES
    Author: Ryan Blackman
    Created: 2025-03-19
#>
function Remove-OldSharePointVersions {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true)]
		[string]$SiteUrl,

		[Parameter(Mandatory = $false)]
		[int]$DaysToKeep = 365,

		[Parameter(Mandatory = $false)]
		[switch]$LaunchStorageExplorer = $false
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
			# Retrieve the Versions collection from the item
			$versions = Get-PnPProperty -ClientObject $item -Property Versions

			# Identify old, non-current versions
			$oldVersions = $versions | Where-Object {
				$_.Created -lt $cutoffDate -and $_.IsCurrentVersion -eq $false
			}

			foreach ($version in $oldVersions) {
				# Use ShouldProcess for -WhatIf / -Confirm
				$versionDate = $version.Created
				$fileName = $item.FieldValues.FileLeafRef

				if ($PSCmdlet.ShouldProcess(
						"$versionDate - File: $fileName",
						"Delete old version (created before $($cutoffDate.ToShortDateString()))"
					)) {
					try {
						Write-Host "🧹 Deleting version from $versionDate for $fileName" -ForegroundColor Gray
						$version.DeleteObject()
					} catch {
						Write-Warning "❌ Failed to delete version: $($_.Exception.Message)"
					}
				}
			}

			# If we queued deletions, commit them now
			if ($oldVersions.Count -gt 0) {
				Invoke-PnPQuery
			}
		}

		Write-Host "✅ Finished cleaning: $($list.Title)"
	}

	if ($LaunchStorageExplorer) {
		Write-Host "🚀 Launching SharePoint Storage Explorer..." -ForegroundColor Cyan
		$launchPath = "$($SiteUrl.TrimEnd('/'))/_layouts/15/storman.aspx"
		Start-Process $launchPath
	}

	Write-Host "`n🎉 Cleanup complete for $SiteUrl" -ForegroundColor Green
}
