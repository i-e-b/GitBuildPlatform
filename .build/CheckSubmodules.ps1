$script_dir = Split-Path -parent $MyInvocation.MyCommand.Definition
$baseDir = Join-Path -path $script_dir ".." -resolve

& "$script_dir\StartSshAgent.ps1"

echo "Using $baseDir as base directory"
Write-Host "Adding submodules" -fo cyan
cd $baseDir

function AddSubmodule($module, $to) {
	git submodules add $module '$to'
}

function CheckoutMaster($directory) {
	Write-Host "Switching $directory to master" -fo cyan
	pushd "$baseDir\$directory"
	git checkout master
	git submodule update --init # incase of sub-sub modules
	popd
}

Write-Host "Updating submodules" -fo cyan
gc "BuildModules.txt" | %{
	$data = $_.Split('=')
	$directory = $data[0].Trim()
	$module = $data[1].Trim()
	
	AddSubmodule -module $module -to $directory;
	CheckoutMaster $directory
}

