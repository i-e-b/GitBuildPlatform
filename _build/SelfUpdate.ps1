$script_dir = Split-Path -parent $MyInvocation.MyCommand.Definition
$baseDir = Join-Path -path $script_dir ".." -resolve

& "$script_dir\StartSshAgent.ps1"
cd $baseDir
git pull origin master