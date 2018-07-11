# Retrieve the current SSH agent PID (or zero). Can be used to determine if there
# is a running agent.
function Get-SshAgent() {
    if ($env:GIT_SSH -imatch 'plink') {
        $pageantPid = Get-Process | Where-Object { $_.Name -eq 'pageant' } | Select-Object -ExpandProperty Id -First 1
        if ($null -ne $pageantPid) { return $pageantPid }
    }
    elseif ($native = Get-NativeSshAgent) {
        return $native
    }
    else {
        $agentPid = $Env:SSH_AGENT_PID
        if ($agentPid) {
            $sshAgentProcess = Get-Process | Where-Object { ($_.Id -eq $agentPid) -and ($_.Name -eq 'ssh-agent') }
            if ($null -ne $sshAgentProcess) {
                return $agentPid
            }
            else {
                setenv 'SSH_AGENT_PID' $null
                setenv 'SSH_AUTH_SOCK' $null
            }
        }
    }

    return 0
}

# Attempt to guess $program's location. For ssh-agent/ssh-add.
function Find-Ssh($program = 'ssh-agent') {
    Write-Verbose "$program not in path. Trying to guess location."
    $gitItem = Get-Command git -CommandType Application -Erroraction SilentlyContinue | Get-Item
    if ($null -eq $gitItem) {
        Write-Warning 'git not in path'
        return
    }

    $sshLocation = join-path $gitItem.directory.parent.fullname bin/$program
    if (get-command $sshLocation -Erroraction SilentlyContinue) {
        return $sshLocation
    }

    $sshLocation = join-path $gitItem.directory.parent.fullname usr/bin/$program
    if (get-command $sshLocation -Erroraction SilentlyContinue) {
        return $sshLocation
    }
}

# Loosely based on bash script from http://help.github.com/ssh-key-passphrases/
function Start-SshAgent {
    param(
        [Parameter(Position = 0)]
        [ValidateSet("Automatic", "Boot", "Disabled", "Manual", "System")]
        [string]
        $StartupType = "Manual",

        [Parameter()]
        [switch]
        $Quiet
    )

    # If we're using the win10 native ssh client,
    # we can just interact with the service directly.
    if (Start-NativeSshAgent -Quiet:$Quiet -StartupType:$StartupType) {
        return
    }

    [int]$agentPid = Get-SshAgent
    if ($agentPid -gt 0) {
        if (!$Quiet) {
            $agentName = Get-Process -Id $agentPid | Select-Object -ExpandProperty Name
            if (!$agentName) { $agentName = "SSH Agent" }
            Write-Host "$agentName is already running (pid $($agentPid))"
        }
        return
    }

    if ($env:GIT_SSH -imatch 'plink') {
        Write-Host "GIT_SSH set to $($env:GIT_SSH), using Pageant as SSH agent."

        $pageant = Get-Command pageant -TotalCount 1 -Erroraction SilentlyContinue
        $pageant = if ($pageant) { $pageant } else { Find-Pageant }
        if (!$pageant) {
            if (!$Quiet) {
                Write-Warning 'Could not find Pageant'
            }
            return
        }

        Start-Process -NoNewWindow $pageant
    }
    else {
        $sshAgent = Get-Command ssh-agent -TotalCount 1 -ErrorAction SilentlyContinue
        $sshAgent = if ($sshAgent) { $sshAgent } else { Find-Ssh('ssh-agent') }
        if (!$sshAgent) {
            if (!$Quiet) {
                Write-Warning 'Could not find ssh-agent'
            }
            return
        }

        & $sshAgent | ForEach-Object {
            if ($_ -match '(?<key>[^=]+)=(?<value>[^;]+);') {
                setenv $Matches['key'] $Matches['value']
            }
        }
    }

    Add-SshKey -Quiet:$Quiet
}


# Stop a running SSH agent
function Stop-SshAgent() {
    [int]$agentPid = Get-SshAgent
    if ($agentPid -gt 0) {
        # Stop agent process
        $proc = Get-Process -Id $agentPid -ErrorAction SilentlyContinue
        if ($null -ne $proc) {
            Stop-Process $agentPid
        }

        setenv 'SSH_AGENT_PID' $null
        setenv 'SSH_AUTH_SOCK' $null
    }
}
