
# Attempt to guess Pageant's location
function Find-Pageant() {
  Write-Verbose "Pageant not in path. Trying to guess location."

  $gitSsh = $env:GIT_SSH
  if ($gitSsh -and (test-path $gitSsh)) {
      $pageant = join-path (split-path $gitSsh) pageant
  }

  if (!(get-command $pageant -Erroraction SilentlyContinue)) {
      return # Guessing failed.
  }
  else {
      return $pageant
  }
}
