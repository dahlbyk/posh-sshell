
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

function MakeNativePath([string]$Path) {
  $Path -replace '\\|/', [System.IO.Path]::DirectorySeparatorChar
}

$modulePath = Convert-Path $PSScriptRoot\..
Import-Module $PSScriptRoot\..\posh-ssh.psd1
