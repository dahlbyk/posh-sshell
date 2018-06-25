Import-Module $PSScriptRoot\..\posh-sshell.psd1

$newLine = "`n" # [System.Environment]::NewLine

describe "Config Parser" {

    It "Parses simple config" {
        $cfg = Get-SshConfig -Raw -Path "fixtures\config"

        $cfg.Nodes.Count| Should -Be 7
        $cfg.Nodes[0].Param| Should -Be "ControlMaster"
        $cfg.Nodes[0].Value| Should -Be "auto"

        $result = $cfg.Find("tahoe1")
        $result | Should Not Be $null
        $result.Type| Should -Be "Directive"
        $result.Before| Should -Be ""
        $result.After| Should -Be $newLine
        $result.Param| Should -Be "Host"
        $result.Separator| Should -Be " "
        $result.Value| Should -Be "tahoe1"

        $childConfig = $result.Config;
        $childConfig.Nodes[0].Type| Should -Be "Directive"
        $childConfig.Nodes[0].Before| Should -Be "  "
        $childConfig.Nodes[0].After| Should -Be $newLine
        $childConfig.Nodes[0].Param| Should -Be "HostName"
        $childConfig.Nodes[0].Separator| Should -Be " "
        $childConfig.Nodes[0].Value| Should -Be "tahoe1.com"

        $childConfig.Nodes[1].Type| Should -Be "Directive"
        $childConfig.Nodes[1].Before| Should -Be "  "
        $childConfig.Nodes[1].After| Should -Be "$newLine$newLine"
        $childConfig.Nodes[1].Param| Should -Be "Compression"
        $childConfig.Nodes[1].Separator| Should -Be " "
        $childConfig.Nodes[1].Value| Should -Be "yes"
    }
    It "Parses config with parameters and values separated by equal" {
        $cfg = Get-SshConfig -Raw -Path "fixtures\config04"

        $n = $cfg.Nodes[0];

        $n.Type| Should -Be "Directive"
        $n.Before| Should -Be ""
        $n.After| Should -Be $newLine
        $n.Param| Should -Be "Host"
        $n.Value| Should -Be "tahoe4"

        $c1 = $n.Config.Nodes[0];
        $c2 = $n.Config.Nodes[1];

        $c1.Type| Should -Be "Directive"
        $c1.Before| Should -Be "  "
        $c1.After| Should -Be $newLine
        $c1.Param| Should -Be "HostName"
        $c1.Separator| Should -Be "="
        $c1.Value| Should -Be "tahoe4.com"

        $c2.Type| Should -Be "Directive"
        $c2.Before| Should -Be "  "
        $c2.After| Should -Be $newLine
        $c2.Param| Should -Be "User"
        $c2.Separator| Should -Be "="
        $c2.Value| Should -Be "keanu"
    }
    It "Parses comments" {
        $cfg = Get-SshConfig -Raw -Path "fixtures\config05"
        $cfg.Nodes[0].Type| Should -Be "Comment"
        $cfg.Nodes[0].Content| Should -Be "# I'd like to travel to lake tahoe."

        # The comments goes with sections. So the structure is not the way it seems.
        $cfg.Nodes[1].Config.Nodes[1].Type| Should -Be "Comment"
        $cfg.Nodes[1].Config.Nodes[1].Content| Should -Be "# or whatever place it is."
    }
    It "Parses multiple identityFiles" {
        $cfg = Get-SshConfig -Raw -Path "fixtures\config06"

        $cfg.Nodes[1].Param| Should -Be "IdentityFile"
        $cfg.Nodes[1].Value| Should -Be "~/.ssh/ids/%h/%r/id_rsa"

        $cfg.Nodes[2].Param| Should -Be "IdentityFile"
        $cfg.Nodes[2].Value| Should -Be "~/.ssh/ids/%h/id_rsa"

        $cfg.Nodes[3].Param| Should -Be "IdentityFile"
        $cfg.Nodes[3].Value| Should -Be "~/.ssh/id_rsa"
    }
    It "Parses IdentityFile with spaces" {
        $cfg = Get-SshConfig -Raw -Path "fixtures\config07"

        $cfg.Nodes[0].Param| Should -Be "IdentityFile"
        $cfg.Nodes[0].Value| Should -Be "C:\Users\fname lname\.ssh\id_rsa"

        $cfg.Nodes[1].Param| Should -Be "IdentityFile"
        $cfg.Nodes[1].Value| Should -Be "C:\Users\fname lname\.ssh\id_rsa"
    }
    It "Parses host with double quotes" {
        $config = Get-SshConfig -Raw -Path "fixtures\config08"

        $config.Nodes[0].Param| Should -Be "Host"
        $config.Nodes[0].Value| Should -Be 'foo "!*.bar"'
    }
    It "Converts object back to string" {
        $fixture = Get-Content -Raw "fixtures\config"
        $config = Get-SshConfig -Raw -Path "fixtures\config"
        $config.Stringify() | Should -Be $fixture
    }
    It "Converts to string with whitespace and comments in place" {
        $fixture = Get-Content -Raw "fixtures\config09"
        $config = Get-SshConfig -Raw -Path "fixtures\config09"
        $config.Stringify()| Should -Be $fixture
    }
    It "Converts IdentityFile entires with double quotes to string" {
        $fixture = Get-Content -Raw "fixtures\config10"
        $config = Get-SshConfig -Raw -Path "fixtures\config10"
        $config.Stringify() | Should -Be $fixture
    }
    It "Find returns null when none found" {
        $config = Get-SshConfig -Raw -Path "fixtures\config"
        $config.Find("not.exist") | Should -Be $null
    }
    It "Finds by host" {
        $config = Get-SshConfig -Raw -Path "fixtures\config"

        $result = $config.Find("tahoe1")
        $result.Type| Should -Be "Directive"
        $result.Before| Should -Be ""
        $result.After| Should -Be $newLine
        $result.Param| Should -Be "Host"
        $result.Separator| Should -Be " "
        $result.Value| Should -Be "tahoe1"

        $c1 = $result.Config.Nodes[0];
        $c1.Type| Should -Be "Directive"
        $c1.Before| Should -Be "  "
        $c1.After| Should -Be "$newLine"
        $c1.Param| Should -Be "HostName"
        $c1.Separator| Should -Be " "
        $c1.Value| Should -Be "tahoe1.com"

        $c2 = $result.Config.Nodes[1];
        $c2.Type| Should -Be "Directive"
        $c2.Before| Should -Be "  "
        $c2.After| Should -Be "$newLine$newLine"
        $c2.Param| Should -Be "Compression"
        $c2.Separator| Should -Be " "
        $c2.Value| Should -Be "yes"

        $result = $config.Find("*")
        $result.Type| Should -Be "Directive"
        $result.Before| Should -Be ""
        $result.After| Should -Be $newLine
        $result.Param| Should -Be "Host"
        $result.Separator| Should -Be " "
        $result.Value| Should -Be "*"

        $c1 = $result.Config.Nodes[0];
        $c1.Type| Should -Be "Directive"
        $c1.Before| Should -Be "  "
        $c1.After| Should -Be "$newLine$newLine"
        $c1.Param| Should -Be "IdentityFile"
        $c1.Separator| Should -Be " "
        $c1.Value| Should -Be "~/.ssh/id_rsa"
    }

    It "Removes by host" {
        $config = Get-SshConfig -Raw -Path "fixtures\config"
        $length = $config.Nodes.Count

        $config.RemoveHost("no.such.host")
        $config.Nodes.Count| Should -Be $length

        $config.RemoveHost("tahoe2")
        $config.Find("tahoe2") | Should -Be $null
        $config.Nodes.Count| Should -Be ($length - 1)
    }
    It "Appends new lines" {
        $cfg = Get-SshConfig -Raw -Path "fixtures\config02"

        $o = @{
            Host = "example2.com"
            User = "pegg"
            IdentityFile = "~/.ssh/id_rsa"
        }

        $cfg.Add($o)
        $opts = $cfg.Compute("example2.com")

        $opts["User"] | Should -Be "pegg"
        $opts["IdentityFile"] | Should -Be @("~/.ssh/id_rsa")

        $result = $cfg.Find("example2.com")

        $result.Type| Should -Be "Directive"
        $result.Before| Should -Be ""
        $result.After| Should -Be $newLine
        $result.Separator| Should -Be " "
        $result.Value| Should -Be "example2.com"

        # Use of hashtable to insert means they could've been added in any order
        # Force alphabetical on parameter name.
        $children = $result.Config.Nodes | Sort-Object -Property 'Param'

        $c1 = $rchildren[0];
        $c2 = $children[1];

        $c1.Type| Should -Be "Directive"
        $c1.Before| Should -Be "  "
        $c1.Param| Should -Be "IdentityFile"
        $c1.After| Should -Be $newLine
        $c1.Separator| Should -Be " "
        $c1.Value| Should -Be "~/.ssh/id_rsa"

        $c2.Type| Should -Be "Directive"
        $c2.Before| Should -Be "  "
        $c2.After| Should -Be "$newLine$newLine"
        $c2.Param| Should -Be "User"
        $c2.Separator| Should -Be " "
        $c2.Value| Should -Be "pegg"
    }
    It "Appends with original indentation recognised" {
        $cfg = Get-SshConfig -Raw -Path "fixtures\config03"

        $cfg.Add(@{Host = "example3.com"; User = "paul"});

        $result = $cfg.Find("example3.com")
        $result.Type| Should -Be "Directive"
        $result.Before| Should -Be ""
        $result.After| Should -Be $newLine
        $result.Param| Should -Be "Host"
        $result.Separator| Should -Be " "
        $result.Value| Should -Be "example3.com"

        $c1 = $result.Config.Nodes[0];
        $c1.Type| Should -Be "Directive"
        $c1.Before| Should -Be "`t"
        $c1.After| Should -Be "$newLine$newLine"
        $c1.Param| Should -Be "User"
        $c1.Separator| Should -Be " "
        $c1.Value| Should -Be "paul"
    }
    It "Adds host with alias using hash" {
        $d = @{
            Host = "test1"
            HostName = "jeremyskinner.co.uk"
            User = "jeremy"
            Port = "123"
        }

        $cfg = Get-SshConfig -Raw -Path "fixtures\config"
        $cfg.Add($d);

        $h = $cfg.Find("test1")
        $h | Should Not Be $null
        $h.Value| Should -Be "test1"
        $h.Param| Should -Be "Host"

        #Can't rely on index - hashtable not ordered
        $h.Config.Nodes.Count| Should -Be 3
        $h.Config.Nodes | where { $_.Param -eq "HostName" } | Select -ExpandProperty Value | Should -Be "jeremyskinner.co.uk"
        $h.Config.Nodes | where { $_.Param -eq "User" } | Select -ExpandProperty Value | Should -Be "jeremy"
        $h.Config.Nodes | where { $_.Param -eq "Port" } | Select -ExpandProperty Value | Should -Be "123"
    }

    It "Gets result by host with globbing" {
        $config = Get-SshConfig -Raw -Path "fixtures\config"
        $opts = $config.Compute("tahoe2");

        $opts["User"] | Should -Be "nil"
        $opts.User | Should -Be "nil"

        $opts.IdentityFile | Should -Be "~/.ssh/id_rsa"
        $opts["ServerAliveInterval"] | Should -Be "80"

        $opts = $config.Compute("tahoe1");
        $opts["Compression"] | Should -Be "yes"
        $opts["ControlMaster"] | Should -Be "auto"
        $opts["ControlPath"] | Should -Be "~/.ssh/master-%r@%h:%p"
        $opts["Host"] | Should -Be "tahoe1"
        $opts.Host | Should -Be "tahoe1"
        $opts["HostName"] | Should -Be "tahoe1.com"
        $opts.HostName | Should -Be "tahoe1.com"
        $opts["IdentityFile"] | Should -Be "~/.ssh/id_rsa"
        $opts.IdentityFile | Should -Be "~/.ssh/id_rsa"
        $opts["ProxyCommand"] | Should -Be "ssh -q gateway -W %h:%p"
        $opts["ServerAliveInterval"] | Should -Be "80"
        $opts["User"] | Should -Be "nil"
        $opts.User | Should -Be "nil"
        $opts["ForwardAgent"] | Should -Be "true"
        $opts.ForwardAgent | Should -Be "true"
    }
    It "Gets by host with globbing" {
        $config = Get-SshConfig -Raw -Path "fixtures\config02"
        $result = $config.Compute("example1")
        $result["Host"] | Should -Be "example1"
        $result["HostName"] | Should -Be "example1.com"
        $result["User"] | Should -Be "simon"
        $result["Port"] | Should -Be "1000"
        $result["IdentityFile"] | Should -Be "/path/to/key"
    }
}
