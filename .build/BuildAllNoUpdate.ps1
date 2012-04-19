$script_dir = Split-Path -parent $MyInvocation.MyCommand.Definition
$baseDir = Join-Path -path $script_dir ".." -resolve

echo "Using $baseDir as base directory"
Write-Host "Platform Build: Cleaning out all built output, to ensure that clean dependencies are copied" -fo cyan

# if any files need cleaned up before build, do it here.

function Build($directory) {
	pushd "$baseDir\$directory\Build"
	if (Test-Path (".\Build.cmd")) { & ".\Build.cmd" }
	if (Test-Path (".\SetupProject.cmd")) { & ".\SetupProject.cmd" }
	popd
}

function DistributeBinaryDependencies($directory) {
	& "$script_dir\Tools\SyncDeps.exe" $baseDir "*\$directory\*\bin\Release\SevenDigital.*.dll" "*\lib\SevenDigital.*.dll"
}

function BuildAndDistribute($directory) {
	Build($directory)
	DistributeBinaryDependencies($directory)
}

# In bottom-up dependency order:
BuildAndDistribute("Media2")
BuildAndDistribute("Audio")
BuildAndDistribute("Media")
BuildAndDistribute("ImageProcessing")
BuildAndDistribute("BatchProcessing")
Build("Batcher")


Write-Host "----[ All Builds Complete ]----" -fo green
