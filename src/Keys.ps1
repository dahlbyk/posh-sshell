function Get-SshPath($File = 'id_rsa') {
  # Avoid paths with path separator char since it is different on Linux/macOS.
  # Also avoid ~ as it is invalid if the user is cd'd into say cert:\ or hklm:\.
  # Also, apparently using the PowerShell built-in $HOME variable may not cut it for msysGit with has different
  # ideas about the path to the user's home dir e.g. /c/Users/Keith
  # $homePath = Invoke-NullCoalescing $Env:HOME $Home
  $homePath = if ($Env:HOME) {$Env:HOME} else {$Home}
  Join-Path $homePath (Join-Path .ssh $File)
}

<#
.SYNOPSIS
  Add a key to the SSH agent
.DESCRIPTION
  Adds one or more SSH keys to the SSH agent.
.EXAMPLE
  PS C:\> Add-SshKey
  Adds ~\.ssh\id_rsa to the SSH agent.
.EXAMPLE
  PS C:\> Add-SshKey ~\.ssh\mykey, ~\.ssh\myotherkey
  Adds ~\.ssh\mykey and ~\.ssh\myotherkey to the SSH agent.
.INPUTS
  None.
  You cannot pipe input to this cmdlet.
#>
function Add-SshKey([switch]$Quiet, [switch]$All) {
  if ($env:GIT_SSH -imatch 'plink') {
      $pageant = Get-Command pageant -Erroraction SilentlyContinue | Select-Object -First 1 -ExpandProperty Name
      $pageant = if ($pageant) { $pageant } else { Find-Pageant }
      if (!$pageant) {
          if (!$Quiet) {
              Write-Warning 'Could not find Pageant'
          }
          return
      }

      if ($args.Count -eq 0) {
          $keyPath = Join-Path $Env:HOME .ssh
          $keys = Get-ChildItem $keyPath/*.ppk -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
          if ($keys) {
              & $pageant $keys
          }
      }
      else {
          foreach ($value in $args) {
              & $pageant $value
          }
      }
  }
  else {
      $sshAdd = Get-Command ssh-add -TotalCount 1 -ErrorAction SilentlyContinue
      $sshAdd = if ($sshAdd) { $sshAdd } else { Find-Ssh('ssh-add') }
      if (!$sshAdd) {
          if (!$Quiet) {
              Write-Warning 'Could not find ssh-add'
          }
          return
      }

      if ($args.Count -eq 0) {
        # Win10 ssh agent will prompt for key password even if the key has already been added
        # Check to see if any keys have been added. Only add keys if it's empty.
        if (Get-NativeSshAgent) {
            (& $sshAdd -L) | Out-Null
            if ($LASTEXITCODE -eq 0) {
                # Keys have already been added
                if (!$Quiet) {
                    Write-Host Keys have already been added to the ssh agent.
                }
               return;
            }
        }

        if ($All) {
            # If All is specified, then parse the config file for keys to add.
            $config = Get-SshConfig
            foreach($entry in $config) {
                if ($entry['IdentityFile']) {
                    & $sshAdd $config['IdentityFile']
                }
            }
        }
        else {
            # Otherwise just run without args, so it'll add the default key.
            & $sshAdd
        }
    }
    else {
        foreach ($value in $args) {
            & $sshAdd $value
        }
    }
  }
}
