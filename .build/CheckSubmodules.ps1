$script_dir = Split-Path -parent $MyInvocation.MyCommand.Definition
$baseDir = Join-Path -path $script_dir ".." -resolve

& "$script_dir\StartSshAgent.ps1"
Write-Progress "Setting up " "git submodules"

echo "Using $baseDir as base directory"
Write-Host "Adding submodules" -fo cyan
cd $baseDir

function AddSubmodule($module, $to) {
	git submodule add $module "$to"
}

function CheckoutMaster($directory) {
	Write-Host "Switching $directory to master" -fo cyan
	pushd "$baseDir\$directory"
	git checkout master
	git submodule update --init # incase of sub-sub modules
	popd
}

Write-Host "Updating submodules" -fo cyan
gc "Modules.rule" | %{
	$data = $_.Split('=')
	$directory = $data[0].Trim()
	$module = $data[1].Trim()
	
	AddSubmodule -module $module -to $directory;
	CheckoutMaster $directory
}

