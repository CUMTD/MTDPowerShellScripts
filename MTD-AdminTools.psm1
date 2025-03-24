# Dot-source all public functions
Get-ChildItem -Path "$PSScriptRoot/Public" -Filter *.ps1 | ForEach-Object {
	. $_.FullName
}

# Optional: Dot-source private helpers
# if (Test-Path "$PSScriptRoot/Private") {
# 	Get-ChildItem -Path "$PSScriptRoot/Private" -Filter *.ps1 | ForEach-Object {
# 		. $_.FullName
# 	}
# }
