#Requires -Version 7.0

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
	Get-LargeSharePointFile -SiteUrl "https://<your-tenant>-admin.sharepoint.com" -SizeThresholdMB 1024

.EXAMPLE
	Get-LargeSharePointFile -SiteUrl "https://<your-tenant>.sharepoint.com/sites/YOURSITE" -SizeThresholdMB 1024

.NOTES
    Author: Ryan Blackman
    Created: 2025-03-19
	Updated: 2025-05-14
#>
function Get-LargeSharePointFile {
	[CmdletBinding(DefaultParameterSetName = 'Single')]
	param (
		[Parameter(ParameterSetName = 'Single', Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$SiteUrl,

		[Parameter(ParameterSetName = 'Admin', Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$SharePointAdminUrl,

		[Parameter()]
		[ValidateRange(1, [int]::MaxValue)]
		[int]$SizeThresholdMB = 500
	)

	# figure out which set of sites to scan
	if ($PSCmdlet.ParameterSetName -eq 'Admin') {
		Write-Verbose "Connecting to tenant admin: $SharePointAdminUrl"
		Connect-PnPOnline -Url $SharePointAdminUrl -UseWebLogin
		$targetSites = (Get-PnPTenantSite).Url
	} else {
		$targetSites = , $SiteUrl
	}

	$thresholdBytes = $SizeThresholdMB * 1MB
	Write-Verbose "Filtering for files > $SizeThresholdMB MB ($thresholdBytes bytes)"

	foreach ($url in $targetSites) {
		Write-Output "🔍 Scanning $url" -ForegroundColor Cyan
		Connect-PnPOnline -Url $url -UseWebLogin

		# get all doc-libs
		$libs = Get-PnPList -Includes BaseTemplate, Hidden | Where-Object { $_.BaseTemplate -eq 101 -and $_.Hidden -eq $false }


		foreach ($lib in $libs) {
			# fetch items + only keep the large ones
			Get-PnPListItem -List $lib -PageSize 1000 -Fields File_x0020_Size, FileLeafRef, FileRef |
			Where-Object { $_.FieldValues.File_x0020_Size -gt $thresholdBytes } |
			Select-Object @{
				Name = 'Site'; Expression = { $url }
			}, @{
				Name = 'File'; Expression = { $_.FieldValues.FileLeafRef }
			}, @{
				Name = 'SizeMB'; Expression = { [math]::Round($_.FieldValues.File_x0020_Size / 1MB, 2) }
			}, @{
				Name = 'Url'; Expression = { $_.FieldValues.FileRef }
			}
		}
	}
}
