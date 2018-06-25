# This must global in order to be accessible in posh-git module scope
function global:Convert-NativeLineEnding([string]$content, [switch]$SplitLines) {
  $tmp = $content -split "`n" | ForEach-Object { $_.TrimEnd("`r")}
  if ($SplitLines) {
      $tmp
  }
  else {
      $content = $tmp -join [System.Environment]::NewLine
      $content
  }
}

# We need this or the Git mocks don't work
function global:git {
    $OFS = ' '
    $cmdline = "$args"
    switch ($cmdline) {
        '--version' { 'git version 2.11.0.windows.1' }
        default     {
            $res = $null
            if (($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows) {
                $res = Invoke-Expression "git.exe $cmdline"
            }
            else {
                $res = Invoke-Expression "git $cmdline"
            }
            $res
        }
    }
}

function MakeNativePath([string]$Path) {
  $Path -replace '\\|/', [System.IO.Path]::DirectorySeparatorChar
}

$ModulePath = Convert-Path $PSScriptRoot\..
