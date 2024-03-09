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
            # Convert cygwin PID to Windows PID
            $ps = Find-Ssh('ps')
            if (!$ps) {
                Write-Warning 'Could not find ps'
                return 0
            }
            $pidMap = @{ }
            (& $ps) | Select-Object -skip 1 | ForEach-Object {
                $line = ($_ -split "\s+" -match "\S")
                $pidMap[$line[0]] = $line[3]
            }
            $winPid = $pidMap[$agentPid]
            if ($winPid) {
                $sshAgentProcess = Get-Process | Where-Object { ($_.Id -eq $winPid) -and ($_.Name -eq 'ssh-agent') }
                if ($null -ne $sshAgentProcess) {
                    return $winPid
                }
            }
            setenv 'SSH_AGENT_PID' $null
            setenv 'SSH_AUTH_SOCK' $null
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

    $sshLocation = join-path $gitItem.directory.parent.fullname[0] bin/$program
    if (get-command $sshLocation -Erroraction SilentlyContinue) {
        return $sshLocation
    }

    $sshLocation = join-path $gitItem.directory.parent.fullname[0] usr/bin/$program
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
        $Quiet,

        [Parameter()]
        [ValidateSet("Process", "User")]
        [string]
        $Scope = "Process"
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

        $pageant = Get-Command pageant -CommandType Application -TotalCount 1 -Erroraction SilentlyContinue
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
        $sshAgent = Get-Command ssh-agent -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue
        $sshAgent = if ($sshAgent) { $sshAgent } else { Find-Ssh('ssh-agent') }
        if (!$sshAgent) {
            if (!$Quiet) {
                Write-Warning 'Could not find ssh-agent'
            }
            return
        }

        & $sshAgent | ForEach-Object {
            if ($_ -match '(?<key>[^=]+)=(?<value>[^;]+);') {
                setenv $Matches['key'] $Matches['value'] $Scope
            }
        }
    }

    Add-SshKey -Quiet:$Quiet
}


# Stop a running SSH agent
function Stop-SshAgent() {
    if ($nativeAgent = Get-NativeSshAgent) {
        Stop-Service $nativeAgent.Name
        return
    }

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
