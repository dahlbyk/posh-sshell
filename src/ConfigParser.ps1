# This is a Powershell port of the ssh-config node module https://github.com/dotnil/ssh-config

# Regexes used in parsing
$script:RE_SPACE = [regex]::new("\s")
$script:RE_LINE_BREAK = [regex]::new("\r|\n")
$script:RE_SECTION_DIRECTIVE = [regex]::new("^(Host|Match)$", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$script:RE_QUOTED = [regex]::new('^(")(.*)\1$')

class ConfigNode {
    [string] $Before
    [string] $After
    [string] $Type
    [string] $Content
    [string] $Param
    [string] $Separator
    [string] $Value
    [bool] $Quoted
    [SshConfig] $Config
}

class SshConfig {
    [System.Collections.Generic.List[ConfigNode]] $Nodes;

    SshConfig() {
        $this.Nodes = [System.Collections.Generic.List[ConfigNode]]::new()
    }

    RemoveHost([string] $sshHost) {
        $result = $this.Find($sshHost)

        if ($result) {
            $this.Nodes.Remove($result);
        }
    }

    Add([Hashtable] $opts) {
        $config = $this;
        $configWas = $this;
        $indent = "  ";

        foreach ($line in $this.Nodes) {
            if ($script:RE_SECTION_DIRECTIVE.IsMatch($line.Param)) {
                foreach ($subline in $line.Config.Nodes) {
                    if ($subline.Before) {
                        $indent = $subline.Before;
                        break;
                    }
                }
            }
        }

        # Make sure host/match are first.
        $keys = $opts.Keys | Sort-Object { $script:RE_SECTION_DIRECTIVE.IsMatch($_) } -Descending

        foreach ($key in $keys) {
            $line = [ConfigNode]::new()
            $line.Type = 'Directive'
            $line.Param = $key
            $line.Separator = " "
            $line.Value = $opts[$key]
            $line.Before = ""
            $line.After = "`n" # Do we want to support CRLF?

            if ($script:RE_SECTION_DIRECTIVE.IsMatch($key)) {
                $config = $configWas;

                # Make sure we insert before any wildcard lines
                $index = $config.Nodes.Count -1;

                while($config.Nodes[$index].Value -and ($config.Nodes[$index].Value.Contains("*") -or  $config.Nodes[$index].Value.Contains("?"))) {
                    $index--
                }

                if ($index -eq $config.Nodes.Count -1) {
                    $config.Nodes.Add($line)
                }
                else {
                    $config.Nodes.Insert($index, $line)
                }

                $config = $line.Config = [SshConfig]::new()
            }
            else {
                $line.Before = $indent;
                $config.Nodes.Add($line);
            }
        }

        $config.Nodes[$config.Nodes.Count - 1].After += "`n" # Do we want to support CRLF?
    }

    [ConfigNode] Find([string]$sshHost) {
        return $this.Nodes | Where-Object {
            $_.Type -eq "Directive" -and $_.Param -eq 'Host' -and $_.Value -eq $sshHost
        } | Select-Object -First 1
    }

    [string] Stringify() {
        $output = [System.Text.StringBuilder]::new()

        $formatter = {
            param([ConfigNode] $node)

            $output.Append($node.Before);

            if ($node.Type -eq 'Comment') {
                $output.Append($node.Content);
            }
            elseif ($node.Type -eq 'Directive') {
                $str = "";

                if ($node.Quoted -or ($node.Param -eq "IdentityFile" -and $script:RE_SPACE.IsMatch($node.Value))) {
                    $str = $node.Param + $node.Separator + '"' + $node.Value + '"'
                }
                else {
                    $str = $node.Param + $node.Separator + $node.Value
                }
                $output.Append($str);
            }

            $output.Append($node.After);

            if ($node.Config) {
                foreach ($child in $node.Config.Nodes) {
                    & $formatter $child
                }
            }
        }

        foreach ($node in $this.Nodes) {
            & $formatter $node
        }

        return $output.ToString();
    }

    [Hashtable] Compute([string]$sshHost) {
        $result = @{}

        $setProperty = {
            param([string] $name, [string] $value);

            if ($name -eq "IdentityFile") {
                if (!$result.ContainsKey($name)) {
                    $result[$name] = @($value)
                }
                else {
                    $result[$name] += $value
                }
            }
            elseif (!$result.ContainsKey($name)) {
                $result[$name] = $value
            }
        }

        $foundHost = $false

        foreach($node in $this.Nodes) {
            if ($node.Type -ne "Directive") {
                continue
            }
            elseif ($node.Param -eq "Host") {
                if($node.Value -eq $sshHost) {
                    $foundHost = $true
                }

                if(Test-Glob $node.Value $sshHost) {
                    & $setProperty $node.Param $node.Value

                    foreach($childNode in $node.Config.Nodes) {
                        if($childNode.Type -eq "Directive") {
                            & $setProperty $childNode.Param $childNode.Value
                        }
                    }
                }
            }
            elseif ($node.Param -eq "Match") {
                # no op
            }
            else {
               &  $setProperty $node.Param $node.Value
            }
        }

        if($foundHost) {
            return $result
        }
        else {
            return $null
        }
    }
}
<#
.SYNOPSIS
    Parses the contents of an OpenSSH config file into an object model.
.DESCRIPTION
    Takes the contents of an SSH config file and converts it into an object model.
    The root object is an SshConfig instance which contains methods for retrieving
    and manipulating config entries.
    These entries can either be returned as hashtables that represent config entries,
    for for more advanced uses can be returned as raw config nodes.
.EXAMPLE
    PS C:\> Parse-SshConfig (Get-Content "~/.ssh/config" -Raw)
    Parses teh contents of the config file at the specified path and returns an object model
.PARAMETER str
    The contents of the openssh config file.
#>
function Parse-SshConfig([string]$str) {
    $config = [SshConfig]::new()
    $rootConfig = $config

    $context = @{
        Count = 0
        Char = $null
    }

    $next = {
        # Force string instead of char
        return [string]($str[$context.Count++])
    }

    $space = {
        $spaces = "";
        while ($context.Char -and $script:RE_SPACE.IsMatch($context.Char)) {
            $spaces += $context.Char
            $context.Char = & $next
        }
        return $spaces;
    }

    $linebreak = {
        $breaks = "";
        while ($context.Char -and $script:RE_LINE_BREAK.IsMatch($context.Char)) {
            $breaks += $context.Char
            $context.Char = & $next
        }
        return $breaks
    }

    $option = {
        $opt = "";

        while ($context.Char -and $context.Char -ne " " -and $context.Char -ne "=") {
            $opt += $context.Char;
            $context.Char = & $next;
        }

        return $opt;
    }

    $separator = {
        $sep = & $space

        if ($context.Char -eq "=") {
            $sep += $context.Char;
            $context.Char = & $next;
        }

        return $sep + (& $space)
    }

    $value = {
        $val = "";

        while ($context.Char -and !$script:RE_LINE_BREAK.IsMatch($context.Char)) {
            $val += $context.Char;
            $context.Char = & $next;
        }

        return $val.Trim()
    }

    $comment = {
        $type = 'Comment';
        $content = "";
        while ($context.Char -and !$script:RE_LINE_BREAK.IsMatch($context.Char)) {
            $content += $context.Char;
            $context.Char = & $next;
        }
        $node = [ConfigNode]::new()
        $node.Type = $type
        $node.Content = $content
        return $node
    }

    $directive = {
        $node = [ConfigNode]::new()
        $node.Type = 'Directive'
        $node.Param = & $option
        $node.Separator = & $separator
        $node.Value = & $value
        return $node;
    }

    $line = {
        $before = & $space
        $node = $null

        if ($context.Char -eq "#") {
            $node = & $comment
        }
        else {
            $node = & $directive
        }

        $after = & $linebreak

        $node.Before = $before
        $node.After = $after

        if ($node.Value -and $script:RE_QUOTED.IsMatch($node.Value)) {
            $node.Value = $script:RE_QUOTED.Replace($node.Value, '$2');
            $node.Quoted = $true;
        }

        return $node;
    }

    # Start the process by getting the first character.
    $context.Char = & $next;

    while ($context.Char) {
        $node = & $line
        if ($node.Type -eq 'Directive' -and $script:RE_SECTION_DIRECTIVE.IsMatch($node.Param)) {
            $config = $rootConfig;
            $config.Nodes.Add($node);
            $config = $node.Config = [SshConfig]::new()
        }
        else {
            $config.Nodes.Add($node);
        }
    }

    return $rootConfig;
}
