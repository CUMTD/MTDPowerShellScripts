#
# Module manifest for module 'MTD-AdminTools'
#
# Generated by: Ryan Blackman
#
# Generated on: 3/24/2025
#

@{

	# Script module or binary module file associated with this manifest.
	RootModule                 = 'MTD-AdminTools.psm1'

	# Version number of this module.
	ModuleVersion = '0.1.0'

	# Supported PSEditions
	# CompatiblePSEditions = @()

	# ID used to uniquely identify this module
	GUID                       = '38bcdc81-47f4-41e3-9899-bc809aca36b2'

	# Author of this module
	Author                     = 'Ryan Blackman'

	# Company or vendor of this module
	CompanyName                = 'MTD'

	# Copyright statement for this module
	Copyright                  = '(c) Ryan Blackman. All rights reserved.'

	# Description of the functionality provided by this module
	Description                = 'PowerShell tools for managing MTD''s tech.'

	# Minimum version of the PowerShell engine required by this module
	PowerShellVersion          = '5.1'

	ExternalModuleDependencies = @(
		'PnP.PowerShell'
	)

	RequiredModules            = @(
		@{ ModuleName = 'PnP.PowerShell'; ModuleVersion = '0.1.0' }
	)

	# Name of the PowerShell host required by this module
	# PowerShellHostName = ''

	# Minimum version of the PowerShell host required by this module
	# PowerShellHostVersion = ''

	# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
	# DotNetFrameworkVersion = ''

	# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
	# ClrVersion = ''

	# Processor architecture (None, X86, Amd64) required by this module
	# ProcessorArchitecture = ''

	# Modules that must be imported into the global environment prior to importing this module
	# RequiredModules = @()

	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @()

	# Script files (.ps1) that are run in the caller's environment prior to importing this module.
	# ScriptsToProcess = @()

	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @()

	# Format files (.ps1xml) to be loaded when importing this module
	# FormatsToProcess = @()

	# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
	# NestedModules = @()

	# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
	FunctionsToExport          = '*'

	# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
	CmdletsToExport            = '*'

	# Variables to export from this module
	VariablesToExport          = '*'

	# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
	AliasesToExport            = '*'

	# DSC resources to export from this module
	# DscResourcesToExport = @()

	# List of all modules packaged with this module
	# ModuleList = @()

	# List of all files packaged with this module
	# FileList = @()


	PrivateData                = @{
		PSData = @{
			Tags                     = @('SharePoint', 'PnP', 'MTD', 'AdminTools')
			LicenseUri               = 'https://github.com/orgs/CUMTD/MTDPowerShellScripts/blob/main/LICENSE'
			ProjectUri               = 'https://github.com/orgs/CUMTD/MTDPowerShellScripts'
			ReleaseNotes             = 'Initial release. Includes Cleanup-OldSharePointVersions.'
			RequireLicenseAcceptance = $true
		}
	}
}
