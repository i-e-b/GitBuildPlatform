$script_dir = Split-Path -parent $MyInvocation.MyCommand.Definition
$baseDir = Join-Path -path $script_dir ".." -resolve
$rulesDir = Join-Path -path $script_dir "..\_rules" -resolve

& "$script_dir\StartSshAgent.ps1"

function AddSubmodule($module, $to) {
	if (-not (Test-Path "$to")) {
		Write-Host "Adding $module to $to"
		git clone $module "$to"
		pushd "$baseDir\$to"
		git submodule update --init # incase of sub modules
		popd
	}
}

function RemoveSubmodule($modulePath) {
	rm -recurse -force "$modulePath"
}

echo "Using $baseDir as base directory"
cd $baseDir

Write-Host "Updating submodules" -fo cyan
gc "$rulesDir\Modules.rule" | %{
	$data = $_.Split('=')
	$directory = $data[0].Trim()
	$module = $data[1].Trim()
	
	AddSubmodule -module $module -to $directory;
}
