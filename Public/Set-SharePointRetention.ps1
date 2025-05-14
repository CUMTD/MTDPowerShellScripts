function Set-SharePointRetention {
	<#
    .SYNOPSIS
    Configure version‐history retention on SharePoint Online sites.

    .DESCRIPTION
    Connects to the SPO Admin Center, then either:
      - Enables intelligent (automatic) trimming of old versions, or
      - Applies manual version/age limits to document libraries.

    You must choose *one* mode:
      - **Auto**: supply `-EnableAutoExpirationVersionTrim`
      - **Custom**: supply at least one of `-ExpireVersionsAfterDays`, `-MajorVersionLimit`, `-MajorWithMinorVersionsLimit`

    By default, settings are applied to existing libraries; use the switches to include new libraries.

    .PARAMETER SharePointAdminUrl
    The SPO Admin Center URL (e.g. https://contoso-admin.sharepoint.com). **Required.**

    .PARAMETER EnableAutoExpirationVersionTrim
    (Auto mode) Turn on Microsoft’s automatic version-trim policy. Mutually exclusive with the Custom parameters.

    .PARAMETER ExpireVersionsAfterDays
    (Custom mode) Delete versions older than this many days.

    .PARAMETER MajorVersionLimit
    (Custom mode) Keep only this many major versions.

    .PARAMETER MajorWithMinorVersionsLimit
    (Custom mode) Keep all minor versions for the most recent N major versions.

    .PARAMETER ApplyToExistingDocumentLibraries
    Apply settings to libraries that already exist (default).

    .PARAMETER ApplyToNewDocumentLibraries
    Also apply settings to libraries created *after* this change.

    .PARAMETER SiteUrl
    A single site URL. If omitted, the change is applied to all sites in the tenant.

    .EXAMPLE
    # Automatic trimming on all sites, existing and new libs
    Set-SharePointRetention `
      -SharePointAdminUrl https://contoso-admin.sharepoint.com `
      -EnableAutoExpirationVersionTrim `
      -ApplyToNewDocumentLibraries

    .EXAMPLE
    # Keep max 100 majors & expire after 180 days on a specific site
    Set-SharePointRetention `
      -SharePointAdminUrl https://contoso-admin.sharepoint.com `
      -SiteUrl https://contoso.sharepoint.com/sites/TeamA `
      -MajorVersionLimit 100 `
      -ExpireVersionsAfterDays 180

    .NOTES
    Needs the SharePoint Online Management Shell module.
    #>
	[CmdletBinding(DefaultParameterSetName = 'Auto', SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true)]
		[string]$SharePointAdminUrl,

		# Auto mode
		[Parameter(Mandatory = $true, ParameterSetName = 'Auto')]
		[switch]$EnableAutoExpirationVersionTrim,

		# Custom mode (at least one required)
		[Parameter(ParameterSetName = 'Custom')]
		[int]$ExpireVersionsAfterDays,

		[Parameter(ParameterSetName = 'Custom')]
		[int]$MajorVersionLimit,

		[Parameter(ParameterSetName = 'Custom')]
		[int]$MajorWithMinorVersionsLimit,

		# These apply in both modes
		[switch]$ApplyToExistingDocumentLibraries,
		[switch]$ApplyToNewDocumentLibraries,

		[string]$SiteUrl
	)

	if ($PSCmdlet.ParameterSetName -eq 'Custom' -and
		-not ($PSBoundParameters.ContainsKey('ExpireVersionsAfterDays') `
				-or $PSBoundParameters.ContainsKey('MajorVersionLimit') `
				-or $PSBoundParameters.ContainsKey('MajorWithMinorVersionsLimit'))
	) {
		throw "In Custom mode you must specify at least one of ExpireVersionsAfterDays, MajorVersionLimit, or MajorWithMinorVersionsLimit."
	}

	Write-Host "Connecting to SPO Admin Center at $SharePointAdminUrl…" -ForegroundColor Cyan
	Connect-SPOService -Url $SharePointAdminUrl

	# Gather sites
	$siteUrls = if ($SiteUrl) {
		Write-Host "Targeting specific site: $SiteUrl" -ForegroundColor Cyan
		, $SiteUrl
	} else {
		Write-Host "Retrieving all site collections…" -ForegroundColor Cyan
		$all = Get-SPOSite -Limit All | Select-Object -ExpandProperty Url
		Write-Host "Found $($all.Count) sites." -ForegroundColor Green
		$all
	}

	# Default to existing libs if none specified
	if (-not ($ApplyToExistingDocumentLibraries -or $ApplyToNewDocumentLibraries)) {
		$ApplyToExistingDocumentLibraries = $true
	}

	foreach ($url in $siteUrls) {
		if ($PSCmdlet.ShouldProcess("Site: $url", "Configure retention policy")) {
			Write-Host "Processing $url…" -ForegroundColor Yellow

			# Build param splat
			$splat = @{
				Identity                        = $url
				# Auto if in Auto set
				EnableAutoExpirationVersionTrim = ($PSCmdlet.ParameterSetName -eq 'Auto')
			}

			if ($ApplyToExistingDocumentLibraries) { $splat.ApplyToExistingDocumentLibraries = $true }
			if ($ApplyToNewDocumentLibraries) { $splat.ApplyToNewDocumentLibraries = $true }

			if ($PSCmdlet.ParameterSetName -eq 'Custom') {
				$splat.EnableAutoExpirationVersionTrim = $false
				if ($PSBoundParameters.ContainsKey('ExpireVersionsAfterDays')) { $splat.ExpireVersionsAfterDays = $ExpireVersionsAfterDays }
				if ($PSBoundParameters.ContainsKey('MajorVersionLimit')) { $splat.MajorVersionLimit = $MajorVersionLimit }
				if ($PSBoundParameters.ContainsKey('MajorWithMinorVersionsLimit')) { $splat.MajorWithMinorVersionsLimit = $MajorWithMinorVersionsLimit }
			}

			Set-SPOSite @splat
			Write-Host "✔ Done for $url" -ForegroundColor Green
		}
	}

	Write-Host "All done." -ForegroundColor Cyan
}
