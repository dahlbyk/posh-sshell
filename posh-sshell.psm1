. $PSScriptRoot\src\Utils.ps1
. $PSScriptRoot\src\Agent.ps1
. $PSScriptRoot\src\Pageant.ps1
. $PSScriptRoot\src\Keys.ps1
. $PSScriptRoot\src\Installer.ps1
. $PSScriptRoot\src\Win32-OpenSSH.ps1
. $PSScriptRoot\src\Globber.ps1
. $PSScriptRoot\src\ConfigParser.ps1
. $PSScriptRoot\src\OpenSsh.ps1
. $PSScriptRoot\src\TabExpansion.ps1

if (!(Get-NativeSshAgent)) {
    # Do not set these variables if we're using the Win10 native SSH agent as it breaks ssh-add.
    Get-TempEnv 'SSH_AGENT_PID'
    Get-TempEnv 'SSH_AUTH_SOCK'
}

Export-ModuleMember -Function @(
    'Get-SshAgent',
    'Start-SshAgent',
    'Stop-SshAgent',
    'Add-SshKey',
    'Get-SshPath',
    'Add-PoshSshellToProfile',
    'Get-SshConfig',
    'Connect-Ssh',
    'Add-SshConnection',
    'Remove-SshConnection',
    'Add-SshAlias'
)
