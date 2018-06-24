param(
    [switch]
    $full
)

$windows = (($PSVersionTable.PSVersion.Major -lt 6) -or $IsWindows)

if ($windows) {
    # Running on windows; default to running under PS5
    powershell -noprofile -command Invoke-Pester $args

    # Optionally run under pwsh too, if specified.
    if ($full) {
        pwsh -noprofile -command Invoke-Pester $args
    }
}
else {
    # Mac/linux; just use pwsh
    pwsh -noprofile -command Invoke-Pester $args
}
