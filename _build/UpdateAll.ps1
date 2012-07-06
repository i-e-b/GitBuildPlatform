$script_dir = Split-Path -parent $MyInvocation.MyCommand.Definition
$baseDir = Join-Path -path $script_dir ".." -resolve
$rulesDir = Join-Path -path $script_dir "..\_rules" -resolve

$dependency_path = (gc "$rulesDir\DependencyPath.rule").Replace("\","/") #fix for git's Linux conventions

& "$script_dir\StartSshAgent.ps1"
cd $baseDir

function Update($directory) {
	$currentBranch = git branch | ?{$_.StartsWith("*")} | %{$_.Substring(2)}
	Write-Host "Updating $directory to latest $currentBranch " -fo cyan -NoNewLine
	pushd "$baseDir\$directory"
	$quiet = git checkout "$dependency_path/*" # lib will get updated by build, so drop changed files.
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

function Count-Object() {begin {$count = 0};process {$count += 1};end {$count}}
function AnyModulesMissing() {
	return (gc "$rulesDir\Modules.rule" | %{($_.Split('='))[0].Trim()} | ?{ -not (Test-Path "$baseDir\$_")} | Count-Object) -ne 0
}

if (AnyModulesMissing) {
	& "$script_dir\CheckSubmodules.ps1"
}

gc "$rulesDir\Modules.rule" | %{
	$data = $_.Split('=')
	$directory = $data[0].Trim()
	$module = $data[1].Trim()
	
	Update($directory)
}

Write-Host "----[ All Modules Updated ]----" -fo green