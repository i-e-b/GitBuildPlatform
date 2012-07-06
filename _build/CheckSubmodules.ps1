$script_dir = Split-Path -parent $MyInvocation.MyCommand.Definition
$baseDir = Join-Path -path $script_dir ".." -resolve
$rulesDir = Join-Path -path $script_dir "..\rules" -resolve

& "$script_dir\StartSshAgent.ps1"

echo "Using $baseDir as base directory"
Write-Host "Adding submodules" -fo cyan
cd $baseDir

function AddSubmodule($module, $to) {
	if (-not (Test-Path "$directory")) {
		git submodule add  $module "$to"
	} else {
		git submodule update --init 
	}
}

function RemoveSubmodule($modulePath) { # why does git make this so hard?!
	pushd "$modulePath"
	git stash
	git stash drop
	popd
	git rm --cached "$modulePath"
	git config -f .git/config --remove-section "submodule.$modulePath"
	git config -f .gitmodules --remove-section "submodule.$modulePath"
	rm -recurse -force "$modulePath"
}

function CheckoutMaster($directory) {
	Write-Host "Switching $directory to master" -fo cyan
	pushd "$baseDir\$directory"
	git checkout master
	git submodule update --init # incase of sub-sub modules
	popd
}

Write-Host "Updating submodules" -fo cyan
gc "$rulesDir\Modules.rule" | %{
	$data = $_.Split('=')
	$directory = $data[0].Trim()
	$module = $data[1].Trim()
	
	AddSubmodule -module $module -to $directory;
	CheckoutMaster $directory
}

Write-Host "Removing any stale submodules" -fo cyan # (ones not referenced in the modules.rule file)

$currentModules = git submodule | %{ $_.Split(' ')[2].Trim() }
$freshDirs = gc "$rulesDir\Modules.rule" | %{$_.Split('=')[0].Trim()}

$currentModules | %{ 
	if ($freshDirs -contains "$_") {echo "keeping $_"} 
	else {
		echo "removing $_"
		RemoveSubmodule($_)
	}
}
