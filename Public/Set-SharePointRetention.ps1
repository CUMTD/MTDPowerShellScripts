function Set-SharePointRetention {
	<#
	.SYNOPSIS
	Enables auto-expiration version trimming on SharePoint Online sites.

	.DESCRIPTION
	This function connects to the SharePoint Online Admin Center and applies
	retention settings (auto-expiration version trimming) to a specified site
	or all site collections if no site is specified.

	.PARAMETER SharePointAdminUrl
	The URL of the SharePoint Online Admin Center (e.g., https://mysite-admin.sharepoint.com).

	.PARAMETER SiteUrl
	(Optional) The URL of a specific SharePoint Online site to configure.
	If not provided, the function will apply settings to all site collections.

	.EXAMPLE
	Set-SharePointRetention -SharePointAdminUrl "https://mysite-admin.sharepoint.com" -SiteUrl "https://mysite-admin.sharepoint.com/sites/mysite"

	.EXAMPLE
	Set-SharePointRetention -SharePointAdminUrl "https://mysite-admin.sharepoint.com"

	.NOTES
	Requires the SharePoint Online Management Shell module (Microsoft.Online.SharePoint.PowerShell).
	Make sure the user running the function has the necessary permissions to connect and modify sites.

    Author: Ryan Blackman
    Created: 2025-03-19
	#>

	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $false)]
		[string]$SharePointAdminUrl,

		[Parameter(Mandatory = $false)]
		[string]$SiteUrl
	)

	if (-not $SharePointAdminUrl) {
		throw "SharePointAdminUrl is required."
	}

	Write-Host "Connecting to SharePoint Online Admin Center at $SharePointAdminUrl..." -ForegroundColor Cyan
	Connect-SPOService -Url $SharePointAdminUrl

	$siteUrls = @()

	if ($SiteUrl) {
		Write-Host "Targeting specific site: $SiteUrl" -ForegroundColor Cyan
		$siteUrls += $SiteUrl
	} else {
		Write-Host "Retrieving all site collections..." -ForegroundColor Cyan
		$siteUrls = Get-SPOSite -Limit All | Select-Object -ExpandProperty Url
		Write-Host "Found $($siteUrls.Count) site(s)." -ForegroundColor Green
	}

	foreach ($url in $siteUrls) {
		if ($PSCmdlet.ShouldProcess("Site: $url", "Set-SPOSite retention settings")) {
			Write-Host "Applying retention settings to $url..." -ForegroundColor Yellow
			Set-SPOSite `
				-Identity $url `
				-EnableAutoExpirationVersionTrim $true `
				-ApplyToExistingDocumentLibraries
			Write-Host "✔ Retention settings applied to $url" -ForegroundColor Green
		}
	}

	Write-Host "Completed applying retention settings." -ForegroundColor Cyan
}
