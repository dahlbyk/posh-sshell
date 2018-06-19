# Allows for overriding of module path during test.
$ModuleBasePath = Convert-Path $PSScriptRoot\..

<#
.SYNOPSIS
    Configures your PowerShell profile (startup) script to import the posh-sshell
    module when PowerShell starts.
.DESCRIPTION
    Checks if your PowerShell profile script is not already importing posh-sshell
    and if not, adds a command to import the posh-sshell module. This will cause
    PowerShell to load posh-sshell whenever PowerShell starts.
.PARAMETER AllHosts
    By default, this command modifies the CurrentUserCurrentHost profile
    script.  By specifying the AllHosts switch, the command updates the
    CurrentUserAllHosts profile (or AllUsersAllHosts, given -AllUsers).
.PARAMETER AllUsers
    By default, this command modifies the CurrentUserCurrentHost profile
    script.  By specifying the AllUsers switch, the command updates the
    AllUsersCurrentHost profile (or AllUsersAllHosts, given -AllHosts).
    Requires elevated permissions.
.PARAMETER Force
    Do not check if the specified profile script is already importing
    posh-sshell. Just add Import-Module posh-sshell command.
.EXAMPLE
    PS C:\> Add-PoshSshToProfile
    Updates your profile script for the current PowerShell host to import the
    posh-sshell module when the current PowerShell host starts.
.EXAMPLE
    PS C:\> Add-PoshSshToProfile -AllHosts
    Updates your profile script for all PowerShell hosts to import the posh-sshell
    module whenever any PowerShell host starts.
.INPUTS
    None.
.OUTPUTS
    None.
#>
function Add-PoshSshToProfile {
  [CmdletBinding(SupportsShouldProcess)]
  param(
      [Parameter()]
      [switch]
      $AllHosts,

      [Parameter()]
      [switch]
      $AllUsers,

      [Parameter()]
      [switch]
      $Force,

      [Parameter(ValueFromRemainingArguments)]
      [psobject[]]
      $TestParams
  )

  if ($AllUsers -and !(Test-Administrator)) {
      throw 'Adding posh-sshell to an AllUsers profile requires an elevated host.'
  }

  $underTest = $false

  $profileName = $(if ($AllUsers) { 'AllUsers' } else { 'CurrentUser' }) `
               + $(if ($AllHosts) { 'AllHosts' } else { 'CurrentHost' })
  Write-Verbose "`$profileName = '$profileName'"

  $profilePath = $PROFILE.$profileName
  Write-Verbose "`$profilePath = '$profilePath'"

  # Under test, we override some variables using $args as a backdoor.
  if (($TestParams.Count -gt 0) -and ($TestParams[0] -is [string])) {
      $profilePath = [string]$TestParams[0]
      $underTest = $true
      if ($TestParams.Count -gt 1) {
          $ModuleBasePath = [string]$TestParams[1]
      }
  }

  if (!$profilePath) { $profilePath = $PROFILE }

  if (!$Force) {
      # Search the user's profiles to see if any are using posh-sshell already, there is an extra search
      # ($profilePath) taking place to accomodate the Pester tests.
      $importedInProfile = Test-PoshSshImportedInScript $profilePath
      if (!$importedInProfile -and !$underTest) {
          $importedInProfile = Test-PoshSshImportedInScript $PROFILE
      }
      if (!$importedInProfile -and !$underTest) {
          $importedInProfile = Test-PoshSshImportedInScript $PROFILE.CurrentUserCurrentHost
      }
      if (!$importedInProfile -and !$underTest) {
          $importedInProfile = Test-PoshSshImportedInScript $PROFILE.CurrentUserAllHosts
      }
      if (!$importedInProfile -and !$underTest) {
          $importedInProfile = Test-PoshSshImportedInScript $PROFILE.AllUsersCurrentHost
      }
      if (!$importedInProfile -and !$underTest) {
          $importedInProfile = Test-PoshSshImportedInScript $PROFILE.AllUsersAllHosts
      }

      if ($importedInProfile) {
          Write-Warning "Skipping add of posh-sshell import to file '$profilePath'."
          Write-Warning "posh-sshell appears to already be imported in one of your profile scripts."
          Write-Warning "If you want to force the add, use the -Force parameter."
          return
      }
  }

  if (!$profilePath) {
      Write-Warning "Skipping add of posh-sshell import to profile; no profile found."
      Write-Verbose "`$PROFILE              = '$PROFILE'"
      Write-Verbose "CurrentUserCurrentHost = '$($PROFILE.CurrentUserCurrentHost)'"
      Write-Verbose "CurrentUserAllHosts    = '$($PROFILE.CurrentUserAllHosts)'"
      Write-Verbose "AllUsersCurrentHost    = '$($PROFILE.AllUsersCurrentHost)'"
      Write-Verbose "AllUsersAllHosts       = '$($PROFILE.AllUsersAllHosts)'"
      return
  }

  # If the profile script exists and is signed, then we should not modify it
  if (Test-Path -LiteralPath $profilePath) {
      if (!(Get-Command Get-AuthenticodeSignature -ErrorAction SilentlyContinue)) {
          Write-Verbose "Platform doesn't support script signing, skipping test for signed profile."
      }
      else {
          $sig = Get-AuthenticodeSignature $profilePath
          if ($null -ne $sig.SignerCertificate) {
              Write-Warning "Skipping add of posh-sshell import to profile; '$profilePath' appears to be signed."
              Write-Warning "Add the command 'Import-Module posh-sshell' to your profile and resign it."
              return
          }
      }
  }

  # Check if the location of this module file is in the PSModulePath
  if (Test-InPSModulePath $ModuleBasePath) {
      $profileContent = "`nImport-Module posh-sshell"
  }
  else {
      $modulePath = Join-Path $ModuleBasePath posh-sshell.psd1
      $profileContent = "`nImport-Module '$modulePath'"
  }

  # Make sure the PowerShell profile directory exists
  $profileDir = Split-Path $profilePath -Parent
  if (!(Test-Path -LiteralPath $profileDir)) {
      if ($PSCmdlet.ShouldProcess($profileDir, "Create current user PowerShell profile directory")) {
          New-Item $profileDir -ItemType Directory -Force -Verbose:$VerbosePreference > $null
      }
  }

  if ($PSCmdlet.ShouldProcess($profilePath, "Add 'Import-Module posh-sshell' to profile")) {
      Add-Content -LiteralPath $profilePath -Value $profileContent -Encoding UTF8
  }

  $StartSshAgent = $true
  
  if ($StartSshAgent -and $PSCmdlet.ShouldProcess($profilePath, "Add 'Start-SshAgent -Quiet' to profile")) {
    Add-Content -LiteralPath $profilePath -Value 'Start-SshAgent -Quiet' -Encoding UTF8
  }
}