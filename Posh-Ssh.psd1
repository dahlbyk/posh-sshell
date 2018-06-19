@{

  # Script module or binary module file associated with this manifest.
  RootModule = 'posh-ssh.psm1'
  
  # Version number of this module.
  ModuleVersion = '0.1.0.0'
  
  # ID used to uniquely identify this module
  GUID = '2716974a-b8d1-440d-acdd-3e28d83e18d4'
  
  # Author of this module
  Author = 'Jeremy Skinner, Keith Dahlby, Mark Embling and contributors'
  
  # Copyright statement for this module
  Copyright = '(c) 2010-2018 Jeremy Skinner, Keith Dahlby, Mark Embling and contributors'
  
  # Description of the functionality provided by this module
  Description = 'Provides integration with ssh-agent and pageant from within Powershell'
  
  # Minimum version of the Windows PowerShell engine required by this module
  PowerShellVersion = '5.0'
  
  # Functions to export from this module
  FunctionsToExport = @(
    'Get-SshAgent',
    'Start-SshAgent',
    'Stop-SshAgent',
    'Add-SshKey',
    'Get-SshPath',
    'Add-PoshSshToProfile'
  )
  
  # Cmdlets to export from this module
  CmdletsToExport = @()
  
  # Variables to export from this module
  VariablesToExport = @()
  
  # Aliases to export from this module
  AliasesToExport = @()
  
  # Private data to pass to the module specified in RootModule/ModuleToProcess.
  # This may also contain a PSData hashtable with additional module metadata used by PowerShell.
  PrivateData = @{
      PSData = @{
          # Tags applied to this module. These help with module discovery in online galleries.
          Tags = @('ssh', 'openssh', 'open-ssh', 'putty', 'pageant', 'PSEdition_Core')
          # TODO: These Urls will need updating.
          # A URL to the license for this module.
          LicenseUri = 'https://github.com/dahlbyk/posh-git/blob/master/LICENSE.txt'
  
          # A URL to the main website for this project.
          ProjectUri = 'https://github.com/dahlbyk/posh-git'
  
          # ReleaseNotes of this module
          ReleaseNotes = 'https://github.com/dahlbyk/posh-git/blob/master/CHANGELOG.md'
  
          # OVERRIDE THIS FIELD FOR PUBLISHED RELEASES - LEAVE AT 'alpha' FOR CLONED/LOCAL REPO USAGE
          Prerelease = 'beta2x'
      }
  }
  
  }