$scripts = Get-ChildItem -Path "Scripts", "Public" -Recurse -File -Filter *.ps1

foreach ($script in $scripts) {
    # Force a single string even if Get-Content returns an array
    $raw = [string]::Join("`n", (Get-Content -Path $script.FullName))

    # Normalize line endings to LF
    $normalized = $raw -replace "`r`n", "`n" -replace "`r", "`n"

    $formatted = Invoke-Formatter -ScriptDefinition $normalized

    if ($formatted -ne $normalized) {
        Set-Content -Path $script.FullName -Value $formatted -Encoding utf8NoBOM
        Write-Output "Formatted: $($script.FullName)"
    }
}
