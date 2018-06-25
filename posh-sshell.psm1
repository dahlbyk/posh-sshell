. $PSScriptRoot\src\Utils.ps1
. $PSScriptRoot\src\Agent.ps1
. $PSScriptRoot\src\Pageant.ps1
. $PSScriptRoot\src\Keys.ps1
. $PSScriptRoot\src\Installer.ps1
. $PSScriptRoot\src\Win32-OpenSSH.ps1

if (!(Get-NativeSshAgent)) {
    # Do not set these variables if we're using the Win10 native SSH agent as it breaks ssh-add.
    Get-TempEnv 'SSH_AGENT_PID'
    Get-TempEnv 'SSH_AUTH_SOCK'
}

Export-ModuleMember -Function Get-SshAgent, Start-SshAgent, Stop-SshAgent, Add-SshKey, Get-SshPath, Add-PoshSshellToProfile
