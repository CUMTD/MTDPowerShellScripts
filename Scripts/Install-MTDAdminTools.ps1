param (
	[string]$TargetPath = "$env:ProgramFiles\WindowsPowerShell\Modules\MTD-AdminTools"
)

Write-Host "🔧 Installing MTD-AdminTools module to: $TargetPath" -ForegroundColor Cyan

# Warn if module is currently loaded
$loaded = Get-Module -Name "MTD-AdminTools" -ErrorAction SilentlyContinue
if ($loaded) {
	Write-Warning "⚠️ The module is currently loaded in memory."
	Write-Warning "   Run 'Remove-Module MTD-AdminTools' before updating."
	return
}

# Check for existing install
if (Test-Path $TargetPath) {
	Write-Host "⚠️ Existing version found at $TargetPath" -ForegroundColor Yellow
	$confirm = Read-Host "Do you want to overwrite the existing version? (Y/N)"
	if ($confirm -ne 'Y') {
		Write-Host "❌ Install cancelled."
		return
	}

	# Remove existing version before copying new one
	Remove-Item -Path $TargetPath -Recurse -Force
}

# Ensure target directory exists
if (-not (Test-Path $TargetPath)) {
	Write-Host "Creating target directory: $TargetPath" -ForegroundColor Cyan
	New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
}

# Copy module files
$sourcePath = $PSScriptRoot
$itemsToCopy = @(
	"MTD-AdminTools.psd1",
	"MTD-AdminTools.psm1",
	"Public"
	# "Private"
)

foreach ($item in $itemsToCopy) {
	$src = Join-Path $sourcePath $item
	$dst = Join-Path $TargetPath $item

	if (Test-Path $src) {
		Copy-Item -Path $src -Destination $dst -Recurse -Force
	} else {
		Write-Warning "⚠️ Missing expected item: $item"
	}
}

Write-Host ""
Write-Host "✅ MTD-AdminTools module installed to: $TargetPath" -ForegroundColor Green
Write-Host "ℹ️  You can now load the module with:" -ForegroundColor Yellow
Write-Host "    Import-Module MTD-AdminTools"
