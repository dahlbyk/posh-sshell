# posh-sshell

<!--[![posh-git on PowerShell Gallery](https://img.shields.io/powershellgallery/dt/posh-sshell.svg)](https://www.powershellgallery.org/packages/posh-sshell/)-->

[![Build status](https://ci.appveyor.com/api/projects/status/e7t4cexf6xx33qv3?svg=true)](https://ci.appveyor.com/project/JeremySkinner/posh-sshell) [![Build status](https://ci.appveyor.com/api/projects/status/k6mbcfgckr3og2a7?svg=true&passingText=Linux%20-%20passing&failingText=Linux%20-%20failed&pendingText=Linux%20-%20pending)](https://ci.appveyor.com/project/JeremySkinner/posh-sshell-agkhg) [![Coverage Status](https://coveralls.io/repos/github/dahlbyk/posh-sshell/badge.svg?branch=master)](https://coveralls.io/github/dahlbyk/posh-sshell?branch=master)


Originally part of the [posh-git](https://github.com/dahlbyk/posh-git) project, posh-sshell is a PowerShell module that provides utilities for working with SSH connections within PowerShell.

## Installation
### Prerequisites
Before installing posh-sshell make sure the following prerequisites have been met.

1. PowerShell 5 or higher. Check your PowerShell version by executing `$PSVersionTable.PSVersion`.

2. Script execution policy must be set to either `RemoteSigned` or `Unrestricted`.
   Check the script execution policy setting by executing `Get-ExecutionPolicy`.
   If the policy is not set to one of the two required values, run PowerShell as Administrator and execute `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Confirm`.

### Installing posh-sshell via PowerShellGet
Execute the following command to install from the [PowerShell Gallery](https://www.powershellgallery.com/):

```powershell
PowerShellGet\Install-Module posh-sshell -Scope CurrentUser
```
You may be asked if you trust packages coming from the PowerShell Gallery. Answer yes to allow installation of this module to proceed.

Note: If you get an error message from `Install-Module` about NuGet being required to interact with NuGet-based repositories, execute the following commands to bootstrap the NuGet provider:
```powershell
Install-PackageProvider NuGet -Force
Import-PackageProvider NuGet -Force
```
Then retry the `Install-Module` command above.

After you have successfully installed the posh-sshell module from the PowerShell Gallery, you will be able to update to a newer version by executing the command:
```powershell
Update-Module posh-sshell
```

## Using posh-sshell
After you have installed posh-sshell, you need to configure your PowerShell session to use the posh-git module.

### Step 1: Import posh-sshell
The first step is to import the module into your PowerShell session which will enable git tab completion.
You can do this with the command `Import-Module posh-sshell`.

### Step 2: Import posh-sshell from Your PowerShell Profile
You do not want to have to manually execute the `Import-Module` command every time you open a new PowerShell prompt.
Let's have PowerShell import this module for you in each new PowerShell session.
We can do this by either executing the command `Add-PoshSshToProfile` or by editing your PowerShell profile script and adding the command `Import-Module posh-sshell`.

If you want posh-sshell to be available in all your PowerShell hosts (console, ISE, etc) then execute `Add-PoshGitToProfile -AllHosts`.
This will add a line containing `Import-Module posh-git` to the file `$profile.CurrentUserAllHosts`.
If you want posh-sshell to be available in just the current host, then execute `Add-PoshSshToProfile`.
This will add the same command but to the file `$profile.CurrentUserCurrentHost`.

If you'd prefer, you can manually edit the desired PowerShell profile script.
Open (or create) your profile script with the command `notepad $profile.CurrentUserAllHosts`.
In the profile script, add the following line:
```powershell
Import-Module posh-sshell
```
Save the profile script, then close PowerShell and open a new PowerShell session.

## Based on work by:

 - Keith Dahlby, http://solutionizing.net/
 - Mark Embling, http://www.markembling.info/
 - Jeremy Skinner, http://www.jeremyskinner.co.uk/
