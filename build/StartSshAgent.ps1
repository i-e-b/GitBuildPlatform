$git_dir = ls ("${env:ProgramFiles}", "${env:ProgramFiles(x86)}") -Filter "git" | %{$_.Fullname} | select-object -first 1
$env:path += ";$git_dir\bin" # temp add git-bin to path
import-module posh-git
Start-SshAgent -Quiet