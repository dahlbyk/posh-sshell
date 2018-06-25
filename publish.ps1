# Copy all files into a directory ready for publishing
# Do this because Publish-Module will publish everything in the project root
# We don't need to publish the CI config, tests, .vscode dir etc.
param(
    [Parameter()]
    [string]
    $NugetApiKey = $null
)

if (!$NugetApiKey) {
    # Allow api key to be explicitly specified, or find it locally.
    $keyfile = "$Env:USERPROFILE\Dropbox\powershellgallery-access-key.txt"

    if(!(Test-Path $keyfile)) {
        throw "No NuGet access key specified."
    }
    else {
        $NugetApiKey = (Get-Content $keyfile)
    }
}

# Create .build
Remove-Item "$PSScriptRoot\.build" -Force -Recurse -ErrorAction Ignore
New-Item -Type Directory "$PSScriptRoot\.build" -ErrorAction Ignore | Out-Null

# Copy everything we want into .build
Copy-Item "$PSScriptRoot\posh-sshell.psd1" "$PSScriptRoot\.build"
Copy-Item "$PSScriptRoot\posh-sshell.psm1" "$PSScriptRoot\.build"
Copy-Item "$PSScriptRoot\LICENSE.txt" "$PSScriptRoot\.build"
Copy-Item "$PSScriptRoot\src\" "$PSScriptRoot\.build" -Recurse

# Run publish-module against the build dir
Publish-Module -Name "$PSScriptRoot\.build\posh-sshell.psd1" -NuGetApiKey $NugetApiKey

Write-Host "Done."
