$script_dir = Split-Path -parent $MyInvocation.MyCommand.Definition
$baseDir = Join-Path -path $script_dir ".." -resolve

#& "$script_dir\StartSshAgent.ps1"

#echo "Using $baseDir as base directory"
#Write-Host "Adding submodules" -fo cyan
#cd $baseDir

function AddSubmodule($module, $path) {
	echo "git submodules add $module '$path'"
}

function CheckoutMaster($directory) {
	Write-Host "Switching $directory to master" -fo cyan
	#pushd "$baseDir\$directory"
	#git checkout master
	#git submodule update --init # incase of sub-sub modules
	#popd
}

gc "$script_dir\RequiredModules.txt" | ConvertFrom-StringData | %{@($_.keys, $_)} | %{echo "$_" }


#Write-Host "Updating submodules" -fo cyan
#git submodule update --inits

#gc "$script_dir\RequiredModules.txt" | ConvertFrom-StringData | %{AddSubmodule($_.Keys)}
