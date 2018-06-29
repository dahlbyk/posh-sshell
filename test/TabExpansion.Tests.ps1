. $PSScriptRoot\Shared.ps1
. $PSScriptRoot\..\src\Globber.ps1
. $PSScriptRoot\..\src\ConfigParser.ps1
. $PSScriptRoot\..\src\OpenSsh.ps1
. $PSScriptRoot\..\src\TabExpansion.ps1

Describe "TabExpansion" {
    Context "Connect-Ssh" {
        It "Completes all connections" {
            $cfg = Get-SshConfig -Raw -Path "$PSScriptRoot\fixtures\config"
            $result = TabExpansionInternal "Connect-Ssh " $cfg
            # Should only be 2. The wildcard entries should be stripped out.
            $result.Count | Should -Be 2
            $result -contains "tahoe1" | Should -Be $true
            $result -contains "tahoe2" | Should -Be $true
        }
        It "Completes single connection" {
            $cfg = Get-SshConfig -Raw -Path "$PSScriptRoot\fixtures\config11"
            $result = TabExpansionInternal "Connect-Ssh e" $cfg
            $result.Count | Should -Be 1
            $result -contains "example" | Should -Be $true
        }
    }
    Context "ssh" {
        BeforeEach {
            Remove-SshAlias
        }
        AfterEach {
            Remove-SshAlias
        }
        It "Completes connections when ssh is aliased to Connect-Ssh" {
            Add-SshAlias
            $cfg = Get-SshConfig -Raw -Path "$PSScriptRoot\fixtures\config11"
            $result = TabExpansionInternal "ssh e" $cfg
            $result.Count | Should -Be 1
            $result -contains "example" | Should -Be $true
        }
        It "Doesn't complete connections when ssh is not aliased to Connect-Ssh" {
            $cfg = Get-SshConfig -Raw -Path "$PSScriptRoot\fixtures\config11"
            $result = TabExpansionInternal "ssh e" $cfg
            $result.Count | Should -Be 0
        }
    }
}
