# posh-sshell

[![Build status](https://ci.appveyor.com/api/projects/status/e7t4cexf6xx33qv3?svg=true)](https://ci.appveyor.com/project/JeremySkinner/posh-sshell) [![Build status](https://ci.appveyor.com/api/projects/status/k6mbcfgckr3og2a7?svg=true&passingText=Linux%20-%20passing&failingText=Linux%20-%20failed&pendingText=Linux%20-%20pending)](https://ci.appveyor.com/project/JeremySkinner/posh-sshell-agkhg) [![Coverage Status](https://coveralls.io/repos/github/dahlbyk/posh-sshell/badge.svg?branch=master)](https://coveralls.io/github/dahlbyk/posh-sshell?branch=master) 
[![posh-sshell on PowerShell Gallery](https://img.shields.io/powershellgallery/dt/posh-sshell.svg)](https://www.powershellgallery.org/packages/posh-sshell/)

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
After you have installed posh-sshell, you need to configure your PowerShell session to use the posh-sshell module.

### Step 1: Import posh-sshell
The first step is to import the module into your PowerShell session.
You can do this with the command `Import-Module posh-sshell`.

### Step 2: Import posh-sshell from Your PowerShell Profile
You do not want to have to manually execute the `Import-Module` command every time you open a new PowerShell prompt.
Let's have PowerShell import this module for you in each new PowerShell session.
We can do this by either executing the command `Add-PoshSshellToProfile` or by editing your PowerShell profile script and adding the command `Import-Module posh-sshell`.

If you want posh-sshell to be available in all your PowerShell hosts (console, ISE, etc) then execute `Add-PoshSshellToProfile -AllHosts`.
This will add a line containing `Import-Module posh-sshell` to the file `$profile.CurrentUserAllHosts`.
If you want posh-sshell to be available in just the current host, then execute `Add-PoshSshellToProfile`.
This will add the same command but to the file `$profile.CurrentUserCurrentHost`.

If you'd prefer, you can manually edit the desired PowerShell profile script.
Open (or create) your profile script with the command `notepad $profile.CurrentUserAllHosts`.
In the profile script, add the following line:
```powershell
Import-Module posh-sshell
```
Save the profile script, then close PowerShell and open a new PowerShell session.

## Features

Posh-Sshell has several features:

### SSH Connection Manager

The SSH connection manager allows you to work with hosts defined in your `~/.ssh/config` file. Typing `Connect-Ssh` will display all the hosts in the file, and allow you to connect to one of them. For example, if you have the following in your config file:

```
Host Server1
  HostName server1.jeremyskinner.co.uk
  User jeremy

Host Server2
  HostName server1.jeremyskinner.co.uk
  User jeremy
```

...then typing `Connect-Ssh` will present you with the following interface where you can select a connection:

![image](https://user-images.githubusercontent.com/90130/42387651-e0d90f7c-813a-11e8-90cf-cfdac885ce37.png)

You can also connect directly to a particular session, by using `Connect-Ssh <server name>`, eg `Connect-Ssh Server1`.

### Adding and removing connections

As well as displaying connections, you can add new connections directly to your ssh config file using, `Add-SshConnection`, eg:

```powershell
Add-SshConnection -Name Server1 -Uri server1.jeremyskinner.co.uk -User jeremy
```

You can also use a short-hand syntax:

```powershell
Add-SshConnection Server1 jeremy@server1.jeremyskinner.co.uk
```

Similarily, you can remove connections with `Remove-SshConnection`

### Automatically start the SSH Agent

Posh-Sshell can automatically start your SSH agent by adding a call to `Start-SshAgent -Quiet` in your profile. 

If you are using the Windows-native version of OpenSSH that ships with Windows 10 1803 or newer, then this will simply start the agent service if it's not already running and add your keys. You will be prompted once to enter your key passphrase. Once the service is running, you will not be prompted again.

If you are using the version of OpenSSH that comes with Git for Windows, then you will be prompted to enter your key the first time you open a Powershell session following a restart.

Ifyou are using Pageant as your SSH agent, then Pagent will automatically started and your keys will be added.

## Based on work by:

 - Keith Dahlby, http://solutionizing.net/
 - Mark Embling, http://www.markembling.info/
 - Jeremy Skinner, http://www.jeremyskinner.co.uk/
