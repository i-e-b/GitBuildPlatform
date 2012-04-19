$script_dir = Split-Path -parent $MyInvocation.MyCommand.Definition
$baseDir = Join-Path -path $script_dir ".." -resolve

& "$script_dir\StartSshAgent.ps1"
cd $baseDir

function StartsNonSpace($str) {!([System.Char]::IsWhiteSpace($str[0]))}

function Update($directory) {
	Write-Host "Updating $directory to current master " -fo cyan -NoNewLine
	Write-Host "Changes will be stashed and re-applied" -fo darkcyan
	#pushd "$baseDir\$directory"
	#git checkout lib/* # lib will get updated by build, so drop changed files.
	#git stash save "automatic stash"
	#git pull
	#git stash pop
	#popd
}

gc "$script_dir\RequiredModules.txt" | ConvertFrom-StringData | %{Update($_.Keys)}

Write-Host "----[ All Modules Updated ]----" -fo green