# Prepeares the repository for a new release.
param(
    [string]
    $Version,

    [switch]
    $Prerelease
)

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

# Create a branch for this version
$branch = "release-v$Version"
Write-Host "Creating branch $branch for release..."
git checkout -b $branch | Out-Null

# Update the release notes and license URL
$module = $module -replace "https://github.com/dahlbyk/posh-sshell/blob/master/LICENSE.txt", "https://github.com/dahlbyk/posh-sshell/blob/$branch/LICENSE.txt"
$module = $module -replace "https://github.com/dahlbyk/posh-sshell/blob/master/CHANGELOG.md", "https://github.com/dahlbyk/posh-sshell/blob/$branch/CHANGELOG.md"

# Remove the Prerelease info.
if (!$Prerelease) {
    $module = $module -replace "(Prerelease = '[a-zA-Z0-9\.]+')", ""
}

# Commit the changed module file
$module > posh-sshell.psd1
git add posh-sshell.psd1 | Out-Null
git commit -m "Preparing $Version release" | Out-Null

# Tag the release
Write-Host "Tagging release $Version"
git tag -a "v$Version" -m "Tagging $Version" | Out-Null

# Bump the version number's minor component
$versionBits = $Version.Split(".")
$versionBits[1] = ([int]$versionBits[1]) + 1
$Version = $versionBits -join "."

# Revert to original module file to bring back the prerelease and URLs.
$module = $moduleUnmodified
# Write the new version number to the module
$module = $module -replace "ModuleVersion = '([0-9.]+)'", "ModuleVersion = '$Version'"

# Write the module file back and create a new commit
$module > posh-sshell.psd1
git add posh-sshell.psd1 | Out-Null
git commit -m "Increase version number" | Out-Null

# Prompt to push.
$confirm = $host.ui.PromptForChoice("Push branch?", "Do you want to push branch $branch to github?", $options, 1)

if($confirm) {
    git push origin $branch
    git push origin --tags
}

write-host "Done."
