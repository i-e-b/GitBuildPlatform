$script_dir = Split-Path -parent $MyInvocation.MyCommand.Definition
$baseDir = Join-Path -path $script_dir ".." -resolve

& "$script_dir\StartSshAgent.ps1"
cd $baseDir

function Update($directory) {
	$currentBranch = git branch | ?{$_.StartsWith("*")} | %{$_.Substring(2)}
	Write-Host "Updating $directory to latest $currentBranch " -fo cyan -NoNewLine
	pushd "$baseDir\$directory"
	git checkout lib/* | out-null # lib will get updated by build, so drop changed files.
	$changes = (git status --porcelain).Count -ne $null 
	if ($changes -eq $true) {
		Write-Host "Changes will be stashed and re-applied" -fo darkcyan
		git stash save "automatic stash"
	} else {
		Write-Host "No local changes" -fo darkcyan
	}
	
	git pull
	
	if ($changes) {git stash pop}
	popd
}

gc "Modules.rule" | %{
	$data = $_.Split('=')
	$directory = $data[0].Trim()
	$module = $data[1].Trim()
	
	Update($directory)
}

Write-Host "----[ All Modules Updated ]----" -fo green