if (Test-Path Function:\TabExpansion) {
    Rename-Item Function:\TabExpansion PoshShellTabExpansionBackup
}

function global:TabExpansion($line, $lastWord) {
    $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()
    TabExpansionInternal $lastBlock
}

function TabExpansionInternal($lastBlock, $config) {
    switch -regex ($lastBlock) {
        # Execute git tab completion for all git-related commands
        "^Connect-Ssh (.*)" {
            if (!$config) { $config = Get-SshConfig -Raw }
            Expand-Connection $lastBlock $config
        }
        "^ssh (.*)" {
            if (isSshAliased) {
                if (!$config) { $config = Get-SshConfig -Raw }
                Expand-Connection $lastBlock $config
            }
            else {
                Expand-Ssh $lastBlock
            }
        }
        "^ssh-add (.*)" { Expand-SshAdd $lastBlock }
        "^ssh-keygen (.*)" { Expand-SshKeygen $lastBlock }
        "^sftp (.*)" { Expand-Sftp $lastBlock }
        "^scp (.*)" { Expand-Scp $lastBlock }
        # Fall back on existing tab expansion
        default {
            if (Test-Path Function:\PoshShellTabExpansionBackup) {
                PoshShellTabExpansionBackup $line $lastWord
            }
        }
    }
}

function Expand-Connection($lastBlock, $config) {
    # Handles Connect-Ssh <name>
    # Handles ssh <name> (if ssh is alised to Connect-Ssh)
    if ($lastBlock -match "^Connect-Ssh (?<cmd>\S*)$" -or (isSshAliased -and ($lastBlock -match "^ssh (?<cmd>\S*)$"))) {
        $config.Nodes  | Where-Object { $_.Type -eq "Directive" -and $_.Param -eq "Host" } `
                       | Where-Object { $_.Value -ne "*" -and !$_.Value.Contains("?") } `
                       | Where-Object { $_.Value -like "$($matches['cmd'])*" } `
                       | Foreach-Object { $_.Value } | Sort-Object
    }
}

function Expand-SshAdd($cmd) {

}

function Expand-SshKegen($cmd) {

}

function Expand-Sftp($cmd) {

}

function Expand-Scp($cmd) {

}
