#Requires -Version 7.0

<#
.SYNOPSIS
    Removes stale Intune devices from Microsoft Endpoint Manager (Intune).

.DESCRIPTION
    The Remove-StaleIntuneDevices function takes pipeline input (e.g., from Get-StaleIntuneDevices)
    and removes each specified device from Intune. It leverages the Microsoft Graph SDK and
    supports native -WhatIf / -Confirm for confirmation prompts.

.EXAMPLE
    PS C:\> Get-StaleIntuneDevices -DaysInactive 120 | Remove-StaleIntuneDevices -Confirm

    Prompt for each device removal.

.EXAMPLE
    PS C:\> Get-StaleIntuneDevices -DaysInactive 120 | Remove-StaleIntuneDevices -WhatIf

    Preview which devices would be removed without actually removing them.

.NOTES
    Author: Ryan Blackman
    Created: 2025-03-19
#>
function Remove-StaleIntuneDevices {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(
			ValueFromPipeline = $true,
			Mandatory = $true
		)]
		[PSObject[]]$InputObject
	)

	begin {
		# Connect with the correct scope for removing devices
		Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All" -NoWelcome
	}

	process {
		foreach ($device in $InputObject) {
			$deviceId = $device.Id
			$deviceName = $device.DeviceName

			if (-not $deviceId) {
				Write-Warning "Skipping device with missing Id. DeviceName: '$deviceName'"
				continue
			}

			# The direct call to $PSCmdlet.ShouldProcess() is what PSScriptAnalyzer looks for.
			if ($PSCmdlet.ShouldProcess($deviceName, "Remove device with Id [$deviceId]")) {
				try {
					Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $deviceId -ErrorAction Stop
					Write-Host "🗑️ Removed device: $deviceName (Id: $deviceId)" -ForegroundColor Red
				} catch {
					Write-Warning "⚠️ Failed to remove device $deviceName (Id: $deviceId). Error: $_"
				}
			}
		}
	}

	end {
		# Disconnect from the Microsoft Graph
		Disconnect-MgGraph
	}
}
