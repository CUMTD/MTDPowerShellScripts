#Requires -Version 7.0

function Get-SiteUrlFromItemUrl([string]$itemUrl) {
	$uri = [Uri]$itemUrl
	$segments = $uri.Segments

	if ($segments.Count -ge 3 -and ($segments[1] -match "sites/" -or $segments[1] -match "teams/" -or $segments[1] -match "personal/")) {
		return "$($uri.Scheme)://$($uri.Host)$($segments[0])$($segments[1])$($segments[2].TrimEnd('/'))"
	} else {
		return "$($uri.Scheme)://$($uri.Host)"
	}
}

function Get-ServerRelativeUrl([string]$itemUrl) {
	$uri = [Uri]$itemUrl
	# PS7-friendly URL decode (avoids System.Web dependency)
	return [Uri]::UnescapeDataString($uri.AbsolutePath)
}

<#
.SYNOPSIS
  Join Purview Disposition export with SharePoint file sizes + created year and
  produce totals per retention label/category + year (e.g., "X GB of Category Y from year Z").

.REQUIREMENTS
  - Install-Module PnP.PowerShell -Scope CurrentUser
  - You must be able to read the sites / libraries where these files live.
#>

function New-DispositionReport {
	param(
		[Parameter(Mandatory = $true)]
		[string]$DispositionCsvPath,          # Purview export

		[Parameter(Mandatory = $true)]
		[string]$PowerShellAppId,

		[string]$DetailOutputCsvPath = ".\DispositionWithSizes_Detail.csv",
		[string]$SummaryOutputCsvPath = ".\DispositionWithSizes_Summary.csv",

		[string]$UrlColumnName = "Location",
		[string]$LabelColumnName = "TagName"
	)

	Import-Module PnP.PowerShell -ErrorAction Stop

	Write-Output "Importing disposition CSV from $DispositionCsvPath..." -ForegroundColor Cyan
	$rows = Import-Csv -Path $DispositionCsvPath

	if (-not $rows) {
		throw "No rows found in CSV. Check the path or file contents."
	}

	# Cache connections per site to avoid reconnecting constantly
	$siteConnections = @{}
	$detailResults = New-Object System.Collections.Generic.List[object]

	# Summary keyed by Label + Year
	# Key format: "<Label>||<Year>"
	$summaryTable = @{}

	Write-Output "Processing $($rows.Count) items..." -ForegroundColor Cyan

	$counter = 0

	foreach ($row in $rows) {
		$counter++

		$url = $row.$UrlColumnName
		$label = $row.$LabelColumnName

		if ([string]::IsNullOrWhiteSpace($url)) {
			Write-Warning "Row $counter has no URL in column '$UrlColumnName'. Skipping."
			continue
		}

		if ([string]::IsNullOrWhiteSpace($label)) {
			$label = "(No Label)"
		}

		$siteUrl = Get-SiteUrlFromItemUrl -itemUrl $url
		$serverRelativeUrl = Get-ServerRelativeUrl -itemUrl $url

		# Ensure we have a connection for this site
		if (-not $siteConnections.ContainsKey($siteUrl)) {
			Write-Output "Connecting to $siteUrl..." -ForegroundColor Yellow
			try {
				Connect-PnPOnline -Url $siteUrl -Interactive -ApplicationId $PowerShellAppId -ErrorAction Stop
				$siteConnections[$siteUrl] = $true
			} catch {
				Write-Warning "Failed to connect to $($siteUrl): $($_.Exception.Message)"
				continue
			}
		} else {
			# Reuse last connection (PnP maintains current connection)
			Connect-PnPOnline -Url $siteUrl -ApplicationId $PowerShellAppId -ErrorAction SilentlyContinue | Out-Null
		}

		# Get file as list item to read its size + created date
		try {
			$fileItem = Get-PnPFile -Url $serverRelativeUrl -AsListItem -ErrorAction Stop
		} catch {
			Write-Warning "[$counter] Failed to get file '$url': $($_.Exception.Message)"
			continue
		}

		# SharePoint stores size in bytes in File_x0020_Size
		$sizeBytes = 0
		if ($fileItem.FieldValues.ContainsKey("File_x0020_Size")) {
			$sizeBytes = [int64]$fileItem.FieldValues["File_x0020_Size"]
		}

		# Created date (SharePoint internal field is "Created")
		$created = $null
		$createdYear = $null
		if ($fileItem.FieldValues.ContainsKey("Created") -and $fileItem.FieldValues["Created"]) {
			try {
				$created = [datetime]$fileItem.FieldValues["Created"]
				$createdYear = $created.Year
			} catch {
				# If casting fails, store raw value and mark year unknown
				$created = $fileItem.FieldValues["Created"]
				$createdYear = $null
			}
		}

		# Use consistent year token for both detail + summary
		$yearKey = if ($createdYear) { $createdYear.ToString() } else { "(Unknown Year)" }

		$sizeMB = [math]::Round($sizeBytes / 1MB, 3)
		$sizeGB = [math]::Round($sizeBytes / 1GB, 3)

		# Add to detail list (includes Created + CreatedYear)
		$detailResults.Add([PSCustomObject]@{
				Label       = $label
				Created     = $created
				CreatedYear = $yearKey
				ItemUrl     = $url
				SiteUrl     = $siteUrl
				SizeBytes   = $sizeBytes
				SizeMB      = $sizeMB
				SizeGB      = $sizeGB
			})

		# Accumulate in summary table by Label + Year
		$summaryKey = "$label||$yearKey"

		if (-not $summaryTable.ContainsKey($summaryKey)) {
			$summaryTable[$summaryKey] = [pscustomobject]@{
				Label       = $label
				CreatedYear = $yearKey
				FileCount   = 0
				TotalBytes  = [int64]0
			}
		}

		$summaryTable[$summaryKey].FileCount++
		$summaryTable[$summaryKey].TotalBytes += $sizeBytes

		if ($counter % 50 -eq 0) {
			Write-Output "Processed $counter items..." -ForegroundColor DarkGray
		}
	}

	Write-Output "Finished processing items. Writing output..." -ForegroundColor Cyan

	# Write detail CSV
	$detailResults |
	Sort-Object Label, CreatedYear, Created, ItemUrl |
	Export-Csv -Path $DetailOutputCsvPath -NoTypeInformation -Encoding UTF8
	Write-Output "Detail file written to $DetailOutputCsvPath" -ForegroundColor Green

	# Build summary objects (Label + Year)
	$summaryResults = foreach ($entry in $summaryTable.Values) {
		[PSCustomObject]@{
			Label       = $entry.Label
			CreatedYear = $entry.CreatedYear
			FileCount   = $entry.FileCount
			TotalBytes  = $entry.TotalBytes
			TotalMB     = [math]::Round($entry.TotalBytes / 1MB, 3)
			TotalGB     = [math]::Round($entry.TotalBytes / 1GB, 3)
		}
	}

	$summaryResults |
	Sort-Object Label, CreatedYear |
	Export-Csv -Path $SummaryOutputCsvPath -NoTypeInformation -Encoding UTF8
	Write-Output "Summary file written to $SummaryOutputCsvPath" -ForegroundColor Green

	Write-Output "Done." -ForegroundColor Cyan
}
