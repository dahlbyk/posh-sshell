# Tests for the Glob functionality used in the SSH Config parser
# Ported from https://github.com/dotnil/ssh-config

. $PSScriptRoot\..\src\Globber.ps1

Describe "Globber" {
    It "globs_asterisk" {
        Test-Glob "*" "laputa" | Should Be $true
        Test-Glob "lap*" "laputa" | Should Be $true
        Test-Glob "lap*ta" "laputa" | Should Be $true
        Test-Glob "laputa*" "laputa" | Should Be $true
        Test-Glob "lap*" "castle" | Should Be $false
    }
    It "globs_question_mark" {
        Test-Glob "lap?ta" "laputa" | Should Be $true
        Test-Glob "laputa?" "laputa" | Should Be $true
        Test-Glob "lap?ta" "castle" | Should Be $false
    }
    It "globs_pattern_list" {
        Test-Glob "laputa,castle" "laputa" | Should Be $true
        Test-Glob "castle,in,the,sky" "laputa" | Should Be $false
    }
    It "globs_negated_pattern_list" {
        Test-Glob "!*.dialup.example.com,*.example.com" "www.example.com" | Should Be $true
        Test-Glob "!*.dialup.example.com,*.example.com" "www.dialup.example.com" | Should Be $false
        Test-Glob "*.example.com,!*.dialup.example.com" "www.dialup.example.com" | Should Be $false
    }
    It "globs_the_whole_string" {
        Test-Glob "example" "example1" | Should Be $false
    }
}

