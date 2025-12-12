#Requires -Version 7.0
#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.Governance, Microsoft.Graph.Users, ExchangeOnlineManagement, ActiveDirectory
#
function Write-CustomLog {
    param (
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("Error", "Warning", "Info", "Debug", "Verbose")]
        [string]$Level = "Info",
        [string]$Path = (Join-Path $env:USERPROFILE "UserOffboarding.log")
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$ts [$Level] $Message"
    Add-Content -Path $Path -Value $entry
    switch ($Level) {
        "Error" { Write-Error $entry; break }
        "Warning" { Write-Warning $entry; break }
        "Debug" { Write-Debug $entry; break }
        "Verbose" { Write-Verbose $entry; break }
        default { Write-Information $entry -InformationAction Continue }
    }
}

function Get-StrongPassword {
    param (
        [int]$Length = 30,
        [int]$NonAlphanumericLength = 8
    )
    if ($NonAlphanumericLength -gt $Length) {
        throw "Non-alphanumeric count cannot exceed total length."
    }
    if ($PSVersionTable.PSEdition -eq 'Desktop') {
        Add-Type -AssemblyName System.Web
        return [System.Web.Security.Membership]::GeneratePassword($Length, $NonAlphanumericLength)
    }
    $lower = 'abcdefghijklmnopqrstuvwxyz'.ToCharArray()
    $upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.ToCharArray()
    $digits = '0123456789'.ToCharArray()
    $special = '!@#$%^&*()-_=+[]{}|;:,.<>?'.ToCharArray()
    $alphanum = $lower + $upper + $digits

    $alphaPart = -join (1..($Length - $NonAlphanumericLength) |
            ForEach-Object { Get-Random -InputObject $alphanum })
    $specPart = -join (1..$NonAlphanumericLength |
            ForEach-Object { Get-Random -InputObject $special })
    return ( -join (($alphaPart + $specPart).ToCharArray() | Sort-Object { Get-Random }))
}

function Enable-PIMRole {
    param (
        [Parameter(Mandatory)][string]$RoleName,
        [Parameter(Mandatory)][string]$UserObjectId
    )
    try {
        Write-CustomLog "Enabling PIM role '$RoleName' for object $UserObjectId" "Verbose"
        $assignment = Get-MgPrivilegedRoleAssignment `
            -Filter "principalId eq '$UserObjectId' and roleDefinitionId eq '$RoleName'"
        if ($assignment) {
            Enable-MgPrivilegedRoleAssignment -PrivilegedRoleAssignmentId $assignment.Id
            Write-CustomLog "PIM role enabled: $RoleName" "Info"
        }
        else {
            Write-CustomLog "No PIM assignment found for $RoleName" "Warning"
        }
    }
    catch {
        Write-CustomLog "Error enabling PIM: $_" "Error"
    }
}

function Connect-MicrosoftService {
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^[^@\s]+@[^@\s]+\.[^@\s]+$')]
        [string]$RunAsUser,
        [string[]]$PIMRoles = @(
            "License Administrator",
            "Exchange Administrator",
            "Helpdesk User Management"
        )
    )
    # 1) Activate PIM roles
    Connect-MgGraph -Scopes "PrivilegedAccess.ReadWrite.AzureADGroup" -UseDeviceAuthentication
    $user = Get-MgUser -UserId $RunAsUser
    foreach ($role in $PIMRoles) {
        Enable-PIMRole -RoleName $role -UserObjectId $user.Id
    }
    # 2) Connect with full Graph scopes
    Connect-MgGraph -Scopes `
        "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All", "Mail.ReadWrite", "Sites.ReadWrite.All" `
        -UseDeviceAuthentication
    # 3) Connect Exchange Online
    Connect-ExchangeOnline -UserPrincipalName $RunAsUser
}

<#
.SYNOPSIS
Offboards a user from M365 and optionally on-prem Active Directory (hybrid), converting their mailbox, disabling accounts, forwarding mail, and sharing OneDrive content.

.DESCRIPTION
This function disables or deletes a user account in Entra ID and optionally in on-prem Active Directory (if hybrid). It converts the user's mailbox to a shared mailbox, configures auto-replies and mail forwarding to the manager, removes group memberships, and grants the manager write access to the user's OneDrive.

.PARAMETER RunAsUser
The UPN of the admin running the script. This account will be used to authenticate with Microsoft Graph and Exchange Online.

.PARAMETER UserPrincipalName
The UPN of the user being offboarded.

.PARAMETER ManagerEmail
The UPN of the manager who should receive mailbox access, forwarding, and OneDrive permissions.

.PARAMETER DeleteAccount
If specified, the user account is deleted from Entra ID (and from AD if hybrid). Otherwise, the account is disabled.

.PARAMETER HybridUser
If specified, treats the user as an on-prem synced (hybrid) user and attempts to disable or remove the AD account as well.

.EXAMPLE
Disable-MtdUser -RunAsUser admin@mtd.org -UserPrincipalName jdoe@mtd.org -ManagerEmail supervisor@mtd.org -HybridUser

.EXAMPLE
Disable-MtdUser -RunAsUser admin@mtd.org -UserPrincipalName jdoe@mtd.org -ManagerEmail supervisor@mtd.org -DeleteAccount

.NOTES
Requires the following modules:
- Microsoft.Graph.Authentication
- Microsoft.Graph.Identity.Governance
- Microsoft.Graph.Users
- ExchangeOnlineManagement
- ActiveDirectory (if using HybridUser)

Auto-replies will be set as follows:
- External: "<First Name> is no longer with MTD."
- Internal: "<First Name> is no longer with MTD. Please contact <Manager Name> for assistance."

Author: Ryan Blackman
Created: 2025-05-14
#>
function Disable-MtdUser {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^[^@\s]+@[^@\s]+\.[^@\s]+$')]
        [string]$RunAsUser,

        [Parameter(Mandatory)]
        [ValidatePattern('^[^@\s]+@[^@\s]+\.[^@\s]+$')]
        [string]$UserPrincipalName,

        [Parameter(Mandatory)]
        [ValidatePattern('^[^@\s]+@[^@\s]+\.[^@\s]+$')]
        [string]$ManagerEmail,

        [switch]$DeleteAccount,
        [switch]$HybridUser
    )

    Write-CustomLog "==== Begin offboarding $UserPrincipalName ====" "Info"

    # Prompt for on-prem credentials if hybrid
    if ($HybridUser) {
        Write-CustomLog "Hybrid mode: prompting for on‑prem AD admin credentials" "Info"
        $OnPremCred = Get-Credential -Message "Enter on‑prem AD admin credentials"
    }

    Connect-MicrosoftService -RunAsUser $RunAsUser

    # Fetch target & manager objects for names
    $target = Get-MgUser -UserId $UserPrincipalName
    $manager = Get-MgUser -UserId $ManagerEmail

    # Build auto-reply texts
    $internalMsg = "$($target.GivenName) is no longer with MTD. Please contact $($manager.GivenName) $($manager.Surname) for assistance."
    $externalMsg = "$($target.GivenName) is no longer with MTD."

    #
    # 1) Disable or Delete accounts
    #
    if ($DeleteAccount) {
        # Hybrid: delete on-prem + Entra ID
        if ($HybridUser) {
            if ($PSCmdlet.ShouldProcess("AD:$UserPrincipalName", "Remove on-prem AD user")) {
                Remove-ADUser -Identity $UserPrincipalName -Credential $OnPremCred -Confirm:$false
                Write-CustomLog "On-prem AD user deleted" "Info"
            }
        }
        # Entra ID deletion
        if ($PSCmdlet.ShouldProcess("Entra ID:$UserPrincipalName", "Remove Entra ID user")) {
            Remove-MgUser -UserId $UserPrincipalName -Confirm:$false
            Write-CustomLog "Entra ID user deleted" "Info"
        }
    }
    else {
        # Hybrid disable
        if ($HybridUser) {
            if ($PSCmdlet.ShouldProcess("AD:$UserPrincipalName", "Disable on-prem AD user")) {
                Disable-ADAccount -Identity $UserPrincipalName -Credential $OnPremCred
                Set-ADUser -Identity $UserPrincipalName -Add @{msExchHideFromAddressLists = "TRUE" } -Credential $OnPremCred
                Write-CustomLog "On-prem AD user disabled & hidden from GAL" "Info"
            }
        }
        # Entra ID disable
        if ($PSCmdlet.ShouldProcess("Entra ID:$UserPrincipalName", "Disable Entra ID account")) {
            Update-MgUser -UserId $UserPrincipalName -AccountEnabled:$false
            Invoke-MgGraphRequest -Method POST `
                -Uri "https://graph.microsoft.com/v1.0/users/$UserPrincipalName/revokeSignInSessions"
            Write-CustomLog "Entra ID account disabled & sessions revoked" "Info"
        }
    }

    #
    # 2) Remove from groups
    #
    if ($HybridUser) {
        $localGroups = Get-ADPrincipalGroupMembership -Identity $UserPrincipalName -Credential $OnPremCred
        foreach ($g in $localGroups) {
            if ($PSCmdlet.ShouldProcess("AD Group:$($g.SamAccountName)", "Remove $UserPrincipalName")) {
                Remove-ADGroupMember -Identity $g.SamAccountName -Members $UserPrincipalName -Credential $OnPremCred -Confirm:$false
                Write-CustomLog "Removed from local AD group $($g.SamAccountName)" "Debug"
            }
        }
    }
    # Azure/Entra ID groups
    $azureGroups = Get-MgUserMemberOf -UserId $UserPrincipalName -All |
        Where-Object { $_.'@odata.type' -eq '#microsoft.graph.group' }
    foreach ($g in $azureGroups) {
        if ($PSCmdlet.ShouldProcess("Entra Group:$($g.DisplayName)", "Remove $UserPrincipalName")) {
            Remove-MgGroupMember -GroupId $g.Id -MemberId $UserPrincipalName -ErrorAction SilentlyContinue
            Write-CustomLog "Removed from Entra group $($g.DisplayName)" "Debug"
        }
    }

    #
    # 3) Mailbox conversion & config (both hybrid & cloud)
    #
    $mb = Get-Mailbox -Identity $UserPrincipalName -ErrorAction SilentlyContinue
    if ($mb) {
        if ($PSCmdlet.ShouldProcess("Mailbox:$UserPrincipalName", "Convert to Shared & configure")) {
            Set-Mailbox    -Identity $UserPrincipalName -Type Shared
            Set-Mailbox    -Identity $UserPrincipalName -HiddenFromAddressListsEnabled $true
            Set-Mailbox    -Identity $UserPrincipalName `
                -ForwardingSMTPAddress $ManagerEmail -DeliverToMailboxAndForward $true
            Add-MailboxPermission -Identity $UserPrincipalName -User $ManagerEmail `
                -AccessRights FullAccess -AutoMapping:$false
            Set-MailboxAutoReplyConfiguration -Identity $UserPrincipalName `
                -AutoReplyState Enabled `
                -InternalMessage $internalMsg `
                -ExternalMessage $externalMsg
            Write-CustomLog "Mailbox converted & auto-reply configured" "Info"
        }
    }

    #
    # 4) OneDrive share + grant permissions
    #
    if ($PSCmdlet.ShouldProcess("OneDrive:$UserPrincipalName", "Share root with $ManagerEmail")) {
        # invite
        $inviteBody = @{
            recipients     = @(@{email = $ManagerEmail })
            requireSignIn  = $true
            sendInvitation = $false
            roles          = @("write")
        }
        Invoke-MgGraphRequest -Method POST `
            -Uri "https://graph.microsoft.com/v1.0/users/$UserPrincipalName/drive/root/invite" `
            -Body ($inviteBody | ConvertTo-Json -Depth 4)

        # explicit create permission (the “gotcha”)
        $permBody = @{
            requireSignIn = $true
            roles         = @("write")
            grantees      = @(@{user = @{email = $ManagerEmail } })
        }
        Invoke-MgGraphRequest -Method POST `
            -Uri "https://graph.microsoft.com/v1.0/users/$UserPrincipalName/drive/root/permissions" `
            -Body ($permBody | ConvertTo-Json -Depth 4)

        Write-CustomLog "OneDrive shared and permissions granted" "Info"
    }

    Write-CustomLog "==== Offboarding complete for $UserPrincipalName ====" "Info"
}

