This repo is a custom PowerShell **module** for managing MTD systems and accounts.

## General rules

- Prefer compatibility with **PowerShell 7+** when practical.
- New exported functions should go in `Public\` and be added to `FunctionsToExport` in `MTD-AdminTools.psd1`.
- Non-exported helper functions should go in `Private\` (if needed) and should not be listed in `FunctionsToExport`.
- Follow the formatting and style conventions in `.editorconfig`.
- Avoid using `Write-Host` instead use `Write-Output `, `Write-Verbose`, or `Write-Information`.
- Use approved PowerShell verbs. Follow other common PowerShell conventions.
- Add `#Requires -Version <VERSION>` and `#Requires -Modules <MODULE>` to the beginning of script files as appropriate.

## PnP.PowerShell (SharePoint/OneDrive)

- Use **PnP.PowerShell v3+** patterns and documentation.
- Connect using an Entra App registration **Client ID** (App ID). Do **not** use `-UseWebLogin` (deprecated/removed).
  - Preferred interactive pattern:
    - `Connect-PnPOnline -Url <SiteUrl> -Interactive -ClientId <AppId>`
- When in doubt, consult the cmdlet documentation:
  - https://pnp.github.io/powershell/cmdlets/index.html

## String interpolation

- Be careful with string interpolation. When in doubt, use subexpressions like:
  - `"$($variable)"`

## Safety for write operations

- For functions that make changes, use:
  - `[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]`
- Use `if ($PSCmdlet.ShouldProcess(...)) { ... }` around modifications.
- Avoid destructive defaults. Prefer explicit switches (e.g., `-Force`, `-Delete`) for deletions.

## Documentation

- When adding or changing scripts, make sure to update the README.md file to reflect the changes.
- Document functions with PowerShell docs: `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.NOTES`, etc.

## Linting and formatting before commits

Run Script Analyzer:

1. `Install-Module PSScriptAnalyzer -Scope CurrentUser`
2. `Import-Module PSScriptAnalyzer`
3. `Invoke-ScriptAnalyzer -Path .\Public -Recurse -Settings .\PSScriptAnalyzerSettings.psd1`
4. Do not add a BOM if the `PSUseBOMForUnicodeEncodedFile` is detected.

Run formatter (example):

1. `Install-Module PSScriptAnalyzer -Scope CurrentUser`
2. `Import-Module PSScriptAnalyzer`
3. Run `Scripts\Format-PowerShellScripts.ps1`
