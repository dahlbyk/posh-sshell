# Copy all files into a directory ready for publishing
# Do this because Publish-Module will publish everything in the project root
# We don't need to publish the CI config, tests, .vscode dir etc.
param(
    [Parameter()]
    [string]
    $NugetApiKey = $null
)

if (!$NugetApiKey) {
    $homePath = if ($Env:HOME) {$Env:HOME} else {$Home}
    # Allow api key to be explicitly specified, or find it locally.
    $keyfile = "$homePath\Dropbox\powershellgallery-access-key.txt"

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
Copy-Item "posh-sshell.psd1" ".build"
Copy-Item "posh-sshell.psm1" ".build"
Copy-Item "LICENSE.txt" ".build"
Copy-Item "src\" ".build" -Recurse

$options = @(
    [System.Management.Automation.Host.ChoiceDescription]::new('&No', 'No')
    [System.Management.Automation.Host.ChoiceDescription]::new('&Yes', 'Yes')
)

$module = Invoke-Expression (Get-Content ".\posh-sshell.psd1" -Raw)
$version = $module.ModuleVersion

$confirm = $host.ui.PromptForChoice("Publish release $version to PS Gallery?", "", $options, 0)

if($confirm) {
    Write-Host "Publishing..."
    # Run publish-module against the build dir
    Publish-Module -Name "$PSScriptRoot\.build\posh-sshell.psd1" -NuGetApiKey $NugetApiKey
    Write-Host "Done."
}
