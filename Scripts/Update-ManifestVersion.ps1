param (
    [string]$NewVersion
)

$manifestPath = "MTD-AdminTools.psd1"

# Read current content
$contents = Get-Content -Path $manifestPath

# Use regex to update the ModuleVersion line
$contents = $contents -replace "ModuleVersion\s*=\s*'[^']*'", "ModuleVersion = '$NewVersion'"

# Write the updated manifest back
Set-Content -Path $manifestPath -Value $contents

Write-Output "✅ Updated ModuleVersion in .psd1 to $NewVersion"

