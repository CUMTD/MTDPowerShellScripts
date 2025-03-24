<#
.SYNOPSIS
    Scans all SharePoint Online sites and reports files larger than a specified size.
	This can take a long time to run.

.DESCRIPTION
    Connects to each site collection in SharePoint Online and lists files over a given size threshold.
    Useful for identifying storage hogs across the tenant.

.PARAMETER SharePointAdminUrl
  The full URL to the SharePoint site to scan (e.g. https://<your-tenant>-admin.sharepoint.com).
  Required if scanning all sites.

.PARAMETER SiteUrl
  The full URL to a specific SharePoint site to scan (e.g. https://<your-tenant>.sharepoint.com/sites/YOURSITE).
  If provided, only this site will be scanned.

.PARAMETER SizeThresholdMB
    File size threshold in megabytes (default: 500 MB).

.EXAMPLE
    Find-LargeSharePointFiles -SiteUrl "https://<your-tenant>-admin.sharepoint.com" -SizeThresholdMB 1024

.EXAMPLE
	Find-LargeSharePointFiles -SiteUrl "https://<your-tenant>.sharepoint.com/sites/YOURSITE" -SizeThresholdMB 1024

.NOTES
    Author: Ryan Blackman
    Created: 2025-03-19
#>
function Find-LargeSharePointFiles {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[string]$SharePointAdminUrl, # Required if scanning all sites

		[Parameter(Mandatory = $false)]
		[string]$SiteUrl, # If provided, scan only this one site

		[Parameter(Mandatory = $false)]
		[int]$SizeThresholdMB = 500
	)

	if (-not $SiteUrl) {
		# If the user didn't specify a single site, ensure we have the admin site for a tenant-wide scan
		if (-not $SharePointAdminUrl) {
			Write-Error "Either -SiteUrl or -SharePointAdminUrl must be provided."
			return
		}

		# 1) Connect to the tenant admin site
		Write-Host "Connecting to SharePoint Admin: $SharePointAdminUrl" -ForegroundColor Cyan
		Connect-PnPOnline -Url $SharePointAdminUrl -UseWebLogin

		# 2) Retrieve all site collections
		$sites = Get-PnPTenantSite

		# 3) Scan each site for large files
		foreach ($site in $sites) {
			ScanSiteForLargeFiles -SiteToScan $site.Url -SizeThresholdMB $SizeThresholdMB
		}
	} else {
		# We have a specific site
		ScanSiteForLargeFiles -SiteToScan $SiteUrl -SizeThresholdMB $SizeThresholdMB
	}
}

function ScanSiteForLargeFiles {
	param (
		[Parameter(Mandatory = $true)]
		[string]$SiteToScan,

		[Parameter(Mandatory = $true)]
		[int]$SizeThresholdMB
	)

	Write-Host "🔍 Scanning $SiteToScan" -ForegroundColor Cyan

	# Connect to the target site
	Connect-PnPOnline -Url $SiteToScan -UseWebLogin

	# Filter for document libraries only (BaseTemplate=101)
	$lists = Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 -and $_.Hidden -eq $false }

	foreach ($list in $lists) {
		$items = Get-PnPListItem -List $list -PageSize 1000
		foreach ($item in $items) {
			# Compare file size in bytes to threshold in bytes
			if ($item.FieldValues.File_x0020_Size -gt ($SizeThresholdMB * 1MB)) {
				[PSCustomObject]@{
					Site   = $SiteToScan
					File   = $item.FieldValues.FileLeafRef
					SizeMB = [math]::Round($item.FieldValues.File_x0020_Size / 1MB, 2)
					Url    = $item.FieldValues.FileRef
				}
			}
		}
	}
}
