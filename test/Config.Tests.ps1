Import-Module $PSScriptRoot\..\posh-sshell.psd1

. $PSScriptRoot\Shared.ps1

Describe "Config" {
    Context "Get-SshConfig" {
        It "Gets a single host" {
            $h = Get-SshConfig "tahoe1" -Path "$PSScriptRoot\fixtures\config"
            $h["HostName"]  | Should -Be "tahoe1.com"
        }
        It "Gets all hosts" {
            # Only 2 because the 2 wildcard hosts should be merged into the others.
            $h = Get-SshConfig -Path "$PSScriptRoot\fixtures\config"
            $h.Count | Should -Be 2
        }
        It "Gets host as raw node" {
            $h = Get-SshConfig "tahoe1" -Raw -Path "$PSScriptRoot\fixtures\config"
            $h.Param | Should -Be "Host"
            $h.Value | Should -Be "tahoe1"
        }
        It "Gets all hosts as raw nodes" {
            $h = Get-SshConfig -Raw -Path "$PSScriptRoot\fixtures\config"
            $h.Nodes.Count | Should -Be 7
        }
    }
}
