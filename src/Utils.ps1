$ModuleBasePath = "$PSScriptRoot\.."

function setenv {
    param(
        [Parameter()]
        [string]
        $key,

        [Parameter()]
        [string]
        $value,

        [Parameter()]
        [ValidateSet("Process", "User")]
        [string]
        $Scope = "Process"
    )
    [void][Environment]::SetEnvironmentVariable($key, $value, $Scope)
    Set-TempEnv $key $value
}

function Get-TempEnv($key) {
    $path = Get-TempEnvPath($key)
    if (Test-Path $path) {
        $value =  Get-Content $path
        [void][Environment]::SetEnvironmentVariable($key, $value)
    }
}

function Set-TempEnv($key, $value) {
    $path = Get-TempEnvPath($key)
    if ($null -eq $value) {
        if (Test-Path $path) {
            Remove-Item $path
        }
    }
    else {
        New-Item $path -Force -ItemType File > $null
        $value | Out-File -FilePath $path -Encoding ascii -Force
    }
}

function Get-TempEnvPath($key){
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ".ssh\$key.env"
    return $path
}

function Test-Administrator {
    # PowerShell 5.x only runs on Windows so use .NET types to determine isAdminProcess
    # Or if we are on v6 or higher, check the $IsWindows pre-defined variable.
    if (($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows) {
        $currentUser = [Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent())
        return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    # Must be Linux or OSX, so use the id util. Root has userid of 0.
    return 0 -eq (id -u)
}
function Test-PoshSshImportedInScript {
    param (
        [Parameter(Position=0)]
        [string]
        $Path
    )

    if (!$Path -or !(Test-Path -LiteralPath $Path)) {
        return $false
    }

    $match = (@(Get-Content $Path -ErrorAction SilentlyContinue) -match 'posh-ssh').Count -gt 0
    if ($match) { Write-Verbose "posh-sshell found in '$Path'" }
    $match
}

function Get-PSModulePath {
    $modulePaths = $Env:PSModulePath -split ';'
    $modulePaths
}

function Test-InPSModulePath {
    param (
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $Path
    )

    $modulePaths = Get-PSModulePath
    if (!$modulePaths) { return $false }

    $pathStringComparison = Get-PathStringComparison
    $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $inModulePath = @($modulePaths | Where-Object { $Path.StartsWith($_.TrimEnd([System.IO.Path]::DirectorySeparatorChar), $pathStringComparison) }).Count -gt 0

    if ($inModulePath -and ('src' -eq (Split-Path $Path -Leaf))) {
        Write-Warning 'posh-sshell repository structure is incompatible with %PSModulePath%.'
        Write-Warning 'Importing with absolute path instead.'
        return $false
    }

    $inModulePath
}

<#
.SYNOPSIS
    Gets the file encoding of the specified file.
.DESCRIPTION
    Gets the file encoding of the specified file.
.PARAMETER Path
    Path to the file to check.  The file must exist.
.EXAMPLE
    PS C:\> Get-FileEncoding $profile
    Get's the file encoding of the profile file.
.INPUTS
    None.
.OUTPUTS
    [System.String]
.NOTES
    Adapted from http://www.west-wind.com/Weblog/posts/197245.aspx
#>
function Get-FileEncoding($Path) {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $bytes = [byte[]](Get-Content $Path -AsByteStream -ReadCount 4 -TotalCount 4)
    }
    else {
        $bytes = [byte[]](Get-Content $Path -Encoding byte -ReadCount 4 -TotalCount 4)
    }

    if (!$bytes) { return 'utf8' }

    switch -regex ('{0:x2}{1:x2}{2:x2}{3:x2}' -f $bytes[0],$bytes[1],$bytes[2],$bytes[3]) {
        '^efbbbf'   { return 'utf8' }
        '^2b2f76'   { return 'utf7' }
        '^fffe'     { return 'unicode' }
        '^feff'     { return 'bigendianunicode' }
        '^0000feff' { return 'utf32' }
        default     { return 'ascii' }
    }
}

<#
.SYNOPSIS
    Gets a StringComparison enum value appropriate for comparing paths on the OS platform.
.DESCRIPTION
    Gets a StringComparison enum value appropriate for comparing paths on the OS platform.
.EXAMPLE
    PS C:\> $pathStringComparison = Get-PathStringComparison
.INPUTS
    None
.OUTPUTS
    [System.StringComparison]
#>
function Get-PathStringComparison {
    # File system paths are case-sensitive on Linux and case-insensitive on Windows and macOS
    if (($PSVersionTable.PSVersion.Major -ge 6) -and $IsLinux) {
        [System.StringComparison]::Ordinal
    }
    else {
        [System.StringComparison]::OrdinalIgnoreCase
    }
}
