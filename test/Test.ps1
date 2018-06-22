param(
    [switch]
    $full
)
powershell -noprofile -command Invoke-Pester $args
if ($full) {
    pwsh -noprofile -command Invoke-Pester
}
