. $PSScriptRoot\Shared.ps1
. $PSScriptRoot\..\src\Globber.ps1
. $PSScriptRoot\..\src\ConfigParser.ps1
. $PSScriptRoot\..\src\OpenSsh.ps1
. $PSScriptRoot\..\src\TabExpansion.ps1

Describe "TabExpansion" {
    Context "Connect-Ssh" {
        BeforeAll {
            $cfg = Get-SshConfig -Raw -Path "$PSScriptRoot\fixtures\config"
        }
        It "Completes all connections" {
            $result = TabExpansionInternal "Connect-Ssh " $cfg
            $result.Count | Should -Be 2
            $result -contains "tahoe1" | Should -Be $true
            $result -contains "tahoe2" | Should -Be $true

        }
    }
}
