#Requires -Version 7.0
#Requires -Modules PnP.PowerShell

Import-Module PnP.PowerShell

<#
.SYNOPSIS
    Configure document-library version retention via PnP.

.PARAMETER SharePointAdminUrl
    SPO Admin center URL (e.g. https://contoso-admin.sharepoint.com). Required.

.PARAMETER EnableAutoExpirationVersionTrim
    (Auto mode) Turn on Microsoft's automatic trimming of old versions.

.PARAMETER ExpireVersionsAfterDays
    (Custom mode) Purge versions older than this many days.

.PARAMETER MajorVersions
    (Custom mode) Keep only this many major versions.

.PARAMETER MajorWithMinorVersions
    (Custom mode) Keep minor versions for the most recent N major versions.

.PARAMETER ApplyToExistingDocumentLibraries
    Apply policy to existing document libraries.

.PARAMETER ApplyToNewDocumentLibraries
    Also apply policy to libraries created after this change.

.PARAMETER SiteUrl
    A single site URL. If omitted, the policy is applied to *all* sites.

.EXAMPLE
    # Auto-trim on all sites, including new libs
    Set-SharePointRetention `
      -SharePointAdminUrl https://contoso-admin.sharepoint.com `
      -EnableAutoExpirationVersionTrim `
      -ApplyToNewDocumentLibraries

.EXAMPLE
    # Custom: keep 100 majors & expire after 180 days on one site
    Set-SharePointRetention `
      -SharePointAdminUrl https://contoso-admin.sharepoint.com `
      -SiteUrl https://contoso.sharepoint.com/sites/Team `
      -MajorVersions 100 `
      -ExpireVersionsAfterDays 180 `
      -ApplyToExistingDocumentLibraries
#>
#Requires -Version 7.0
#Requires -Modules PnP.PowerShell

Import-Module PnP.PowerShell

function Set-SharePointRetention {
    [CmdletBinding(DefaultParameterSetName = 'Auto', SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SharePointAdminUrl,

        [Parameter(Mandatory = $true, ParameterSetName = 'Auto')]
        [switch]$EnableAutoExpirationVersionTrim,

        [Parameter(ParameterSetName = 'Custom')]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$ExpireVersionsAfterDays = [int]::MaxValue,

        [Parameter(ParameterSetName = 'Custom')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$MajorVersions = [int]::MaxValue,

        [Parameter(ParameterSetName = 'Custom')]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$MajorWithMinorVersions = [int]::MaxValue,

        [switch]$ApplyToExistingDocumentLibraries,
        [switch]$ApplyToNewDocumentLibraries,

        [string]$SiteUrl
    )

    Write-Output "🔗 Connecting to admin: $SharePointAdminUrl" -ForegroundColor Cyan
    Connect-PnPOnline -Url $SharePointAdminUrl -UseWebLogin

    # Build site list
    $siteUrls = if ($SiteUrl) { @($SiteUrl) }
    else { (Get-PnPTenantSite).Url }

    foreach ($url in $siteUrls) {
        if (-not $PSCmdlet.ShouldProcess($url, 'Configure retention policy')) {
            continue
        }

        Write-Output "⚙️  Applying retention on $url" -ForegroundColor Yellow
        Connect-PnPOnline -Url $url -UseWebLogin

        # Always include the three version params in Custom mode (they have defaults)
        $splat = @{
            EnableAutoExpirationVersionTrim = $EnableAutoExpirationVersionTrim.IsPresent
            ExpireVersionsAfterDays         = $ExpireVersionsAfterDays
            MajorVersions                   = $MajorVersions
            MajorWithMinorVersions          = $MajorWithMinorVersions
        }

        if ($ApplyToExistingDocumentLibraries) { $splat.ApplyToExistingDocumentLibraries = $true }
        if ($ApplyToNewDocumentLibraries) { $splat.ApplyToNewDocumentLibraries = $true }

        Set-PnPSiteVersionPolicy @splat
        Write-Output "✔ Done for $url" -ForegroundColor Green
    }

    Write-Output "🎉 All done." -ForegroundColor Cyan
}

