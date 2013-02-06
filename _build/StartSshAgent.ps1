$git_dir = ls ("${env:ProgramFiles}", "${env:ProgramFiles(x86)}") -Filter "git" | %{$_.Fullname} | select-object -first 1
$env:path += ";$git_dir\bin" # temp add git-bin to path

$module = "posh-git"
if (Get-Module -ListAvailable | Where-Object { $_.Name -eq $module })
{
	import-module $module
	Start-SshAgent -Quiet
}