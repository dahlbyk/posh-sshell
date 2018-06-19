$script:Splitter = [Regex]::new("[,\s]+")

function Test-Glob([string] $patternList, [string] $str)  {
    $patterns = $script:Splitter.Split($patternList) | Sort-Object { $_.StartsWith("!") } -Descending

    foreach ($pattern in $patterns) {
        $negate = $pattern[0] -eq '!'

        if ($negate) {
            $pattern = $pattern.Substring(1)
        }

        $pattern = $pattern.Replace(".", "\.").Replace("*", ".*").Replace("?", ".?")
        $result = [Regex]::new('^(?:' + $pattern + ')$').IsMatch($str)

        if ($negate -and $result) {
            return $false;
        }

        if ($result) {
            return $true;
        }
    }

    return $false;
}
