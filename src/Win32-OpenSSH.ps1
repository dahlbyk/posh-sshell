function Get-NativeSshAgent {
    # $IsWindows is defined in PS Core.
    if (($PSVersionTable.PSVersion.Major -lt 6) -or $IsWindows) {
        # The ssh.exe binary version must include "OpenSSH"
        # The windows ssh-agent service must exist
        $service = Get-Service ssh-agent -ErrorAction Ignore
        $executableMatches = Get-Command ssh.exe | ForEach-Object FileVersionInfo | Where-Object ProductVersion -match OpenSSH
        $valid = $service -and $executableMatches
        if ($valid) {
            return $service;
        }
    }
}

function Start-NativeSshAgent([switch]$Quiet, [string]$StartupType = 'Manual') {
    $service = Get-NativeSshAgent

    if (!$service) {
        return $false;
    }

    # Enable the servivce if it's disabled and we're an admin
    if ($service.StartType -eq "Disabled") {
        if (Test-Administrator) {
            Set-Service "ssh-agent" -StartupType $StartupType
        }
        else {
            Write-Error "The ssh-agent service is disabled. Please start the service and try again."
            # Exit with true so Start-SshAgent doesn't try to do any other work.
            return $true
        }
    }

    # Start the service
    if ($service.Status -ne "Running") {
        if (!$Quiet) {
            Write-Host "Starting ssh agent service."
        }
        Start-Service "ssh-agent"
    }

    if ($env:GIT_SSH) {
        if (!$Quiet) {
            Write-Host "GIT_SSH is set, not setting core.sshCommand in .gitconfig"
        }
    }
    else {
        # Make sure git is configured to use OpenSSH-Win32
        $sshCommand = (Get-Command ssh.exe -ErrorAction Ignore | Select-Object -ExpandProperty Path).Replace("\", "/")
        $configuredSshCommand = git config --global core.sshCommand

        if ($configuredSshCommand) {
            # If it's already set to something else, warn the user.
            if ($configuredSshCommand -ne $sshCommand) {
                Write-Warning "core.sshCommand in your .gitconfig is set to $configuredSshCommand, but it should be set to $sshCommand."
            }
        }
        else {
            if (!$Quiet) {
                Write-Host "Setting core.sshCommand to $sshCommand in .gitconfig"
            }
            $sshCommand = "`"$sshCommand`""
            git config --global core.sshCommand $sshCommand
        }
    }

    Add-SshKey -Quiet:$Quiet

    return $true
}
