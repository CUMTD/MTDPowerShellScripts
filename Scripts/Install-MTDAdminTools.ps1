param (
    [string]$TargetPath = "$env:ProgramFiles\WindowsPowerShell\Modules\MTD-AdminTools"
)

Write-Output "🔧 Installing MTD-AdminTools module to: $TargetPath"

function Copy-ModuleItem {
    param (
        [string]$Source,
        [string]$Destination
    )

    if (Test-Path -LiteralPath $Source -PathType Container) {
        Write-Output "Copying $Source to $Destination"

        if (-not (Test-Path -LiteralPath $Destination)) {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }

        $sourceRoot = Get-Item -LiteralPath $Source

        Get-ChildItem -LiteralPath $Source -Recurse -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($sourceRoot.FullName.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
            $targetFile = Join-Path $Destination $relativePath
            $targetDir = Split-Path -Path $targetFile -Parent

            if (-not (Test-Path -LiteralPath $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }

            [System.IO.File]::Copy($_.FullName, $targetFile, $true)
        }

        return
    }

    if (Test-Path -LiteralPath $Source -PathType Leaf) {
        Write-Output "Copying $Source to $Destination"

        $targetDir = Split-Path -Path $Destination -Parent
        if (-not (Test-Path -LiteralPath $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        [System.IO.File]::Copy($Source, $Destination, $true)
        return
    }

    Write-Warning "⚠️ Missing expected item: $Source"
}

# Warn if module is currently loaded
$loaded = Get-Module -Name "MTD-AdminTools" -ErrorAction SilentlyContinue
if ($loaded) {
    Write-Warning "⚠️ The module is currently loaded in memory."
    Write-Warning "   Run 'Remove-Module MTD-AdminTools' before updating."
    return
}

# Check for existing install
if (Test-Path $TargetPath) {
    Write-Output "⚠️ Existing version found at $TargetPath"
    $confirm = Read-Host "Do you want to overwrite the existing version? (Y/N)"
    if ($confirm -ne 'Y') {
        Write-Output "❌ Install cancelled."
        return
    }

    # Remove existing version before copying new one
    Remove-Item -Path $TargetPath -Recurse -Force
}

# Ensure target directory exists
if (-not (Test-Path $TargetPath)) {
    Write-Output "Creating target directory: $TargetPath"
    New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
}

# Copy module files
$moduleRoot = if ((Split-Path -Path $PSScriptRoot -Leaf) -eq 'Scripts') {
    Split-Path -Path $PSScriptRoot -Parent
} else {
    $PSScriptRoot
}

if (-not (Test-Path -LiteralPath (Join-Path $moduleRoot 'MTD-AdminTools.psd1'))) {
    $alternateRoot = Split-Path -Path $moduleRoot -Parent

    if (Test-Path -LiteralPath (Join-Path $alternateRoot 'MTD-AdminTools.psd1')) {
        $moduleRoot = $alternateRoot
    } else {
        throw "Unable to locate module files relative to '$PSScriptRoot'."
    }
}

$itemsToCopy = @(
    "MTD-AdminTools.psd1",
    "MTD-AdminTools.psm1",
    "Public"
    # "Private"
)

Write-Output "Using module source at: $moduleRoot"

foreach ($item in $itemsToCopy) {
    $src = Join-Path $moduleRoot $item
    $dst = Join-Path $TargetPath $item

    Copy-ModuleItem -Source $src -Destination $dst
}

#  ─── UNBLOCK DOWNLOADED SCRIPTS ───────────────────────────────────────────────
if ($IsWindows) {
    Write-Output "🔓 Unblocking all downloaded module files…"
    Get-ChildItem -Path $TargetPath -Recurse -File | Unblock-File
}

Write-Output ""
Write-Output "✅ MTD-AdminTools module installed to: $TargetPath"
Write-Output "ℹ️  You can now load the module with:"
Write-Output "    Import-Module MTD-AdminTools"

