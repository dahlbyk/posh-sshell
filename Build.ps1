# Prepeares the repository for a new release.
param(
    [string]
    $Version,

    [switch]
    $Prerelease,

    [switch]
    $Publish,

    [string]
    $NugetApiKey = $null
)

function Prepare-Release {
    $options = @(
        [System.Management.Automation.Host.ChoiceDescription]::new('&No', 'No')
        [System.Management.Automation.Host.ChoiceDescription]::new('&Yes', 'Yes')
    )

    $module = Get-Content "posh-sshell.psd1" -Raw
    $moduleUnmodified = $module

    # If no version is specified, infer it by extracting the version from the module file.
    if (!$Version) {
        if($module -match "ModuleVersion = '([0-9.]+)'") {
            $Version = $Matches[1]
        }
        else {
            throw "No version found in the module file."
        }
    }

    $confirm = $host.ui.PromptForChoice("Preparing release $Version. Continue?", "", $options, 1)

    if (!$confirm) {
        return
    }

    # Update the release notes and license URL
    $module = $module -replace "https://github.com/dahlbyk/posh-sshell/blob/master/LICENSE.txt", "https://github.com/dahlbyk/posh-sshell/blob/v$Version/LICENSE.txt"
    $module = $module -replace "https://github.com/dahlbyk/posh-sshell/blob/master/CHANGELOG.md", "https://github.com/dahlbyk/posh-sshell/blob/v$Version/CHANGELOG.md"

    # Remove the Prerelease info.
    if (!$Prerelease) {
        $module = $module -replace "(Prerelease = '[a-zA-Z0-9\.]+')", ""
    }

    # Commit the changed module file
    $module | Out-File posh-sshell.psd1 -Encoding utf8
    git add posh-sshell.psd1 | Out-Null
    git commit -m "Preparing $Version release" | Out-Null

    # Tag the release
    $tag = "v$Version"
    Write-Host "Tagging release $Version"
    git tag -a "$tag" -m "Tagging $Version" | Out-Null

    # Bump the version number's minor component
    $versionBits = $Version.Split(".")
    $versionBits[1] = ([int]$versionBits[1]) + 1
    $Version = $versionBits -join "."

    # Revert to original module file to bring back the prerelease and URLs.
    $module = $moduleUnmodified
    # Write the new version number to the module
    $module = $module -replace "ModuleVersion = '([0-9.]+)'", "ModuleVersion = '$Version'"

    # Write the module file back and create a new commit
    $module | Out-File posh-sshell.psd1 -Encoding utf8
    git add posh-sshell.psd1 | Out-Null
    git commit -m "Increase version number" | Out-Null

    # Prompt to push.
    $confirm = $host.ui.PromptForChoice("", "Do you want to push tag $tag to github?", $options, 1)

    if($confirm) {
        git push origin --tags
        Write-Host "Checking out tag ready for publish..."
        git checkout "$tag"
    }

    Write-Host "Done."
}

function Publish {
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
}

if ($Publish) {
    Publish
}
else {
    Prepare-Release
}
