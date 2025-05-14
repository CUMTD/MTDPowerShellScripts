<#
.SYNOPSIS
    Lists stale devices from Intune.

.DESCRIPTION
    Devices that haven't checked in within the specified number of days will be listed. Optionally, they can be removed.

.PARAMETER DaysInactive
    Number of days since last check-in (default: 90)

.EXAMPLE
    Find-StaleIntuneDevices -DaysInactive 120

.NOTES
    Author: Ryan Blackman
    Created: 2025-03-19
#>
function Find-StaleIntuneDevices {
	[CmdletBinding()]
	param (
		[int]$DaysInactive = 90
	)

	# Connect to Microsoft Graph with the permissions needed to manage devices.
	# For interactive login, do:
	Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All" -NoWelcome

	$cutoffDate = (Get-Date).AddDays(-$DaysInactive)

	# Retrieve **all** devices in the tenant.
	# The -All switch auto-paginates, returning the entire set instead of just the first page of results.
	$devices = Get-MgDeviceManagementManagedDevice -All

	# Filter devices that haven't contacted Intune since the cutoff date
	$staleDevices = $devices | Where-Object {
		$_.LastSyncDateTime -lt $cutoffDate
	}

	foreach ($device in $staleDevices) {
		[PSCustomObject]@{
			Id              = $device.Id
			DeviceName      = $device.DeviceName
			LastSyncDate    = $device.LastSyncDateTime
			EnrolledDate    = $device.EnrolledDateTime
			Manufacturer    = $device.Manufacturer
			Model           = $device.Model
			OperatingSystem = $device.OperatingSystem
			OSVersion       = $device.OSVersion
		}
	}
}
