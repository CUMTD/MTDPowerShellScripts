$scripts = Get-ChildItem -Path "Scripts", "Public" -Recurse -Filter *.ps1

foreach ($script in $scripts) {
	$formatted = Invoke-Formatter -ScriptDefinition (Get-Content $script.FullName -Raw)
	Set-Content -Path $script.FullName -Value $formatted -Encoding utf8NoBOM
}
