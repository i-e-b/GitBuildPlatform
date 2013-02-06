$script_dir = Split-Path -parent $MyInvocation.MyCommand.Definition
$baseDir = Join-Path -path $script_dir ".." -resolve
$rulesDir = Join-Path -path $script_dir "..\_rules" -resolve
$ErrorView = "CategoryView"

$dependency_path = gc "$rulesDir\DependencyPath.rule"

echo "Using $baseDir as base directory"
Write-Host "Platform Build: Cleaning out all built output, to ensure that clean dependencies are copied" -fo cyan

# Clean up bin and obj folders, to get a really clean build.
ls $baseDir -Recurse -Include ("bin", "obj") | rm -Recurse -Force -ErrorAction SilentlyContinue

function Build($directory) {
	pushd "$baseDir\$directory\Build"
	if (Test-Path (".\Build.cmd")) { & ".\Build.cmd" }
	if (Test-Path (".\SetupProject.cmd")) { & ".\SetupProject.cmd" }
	popd
}

function DistributeBinaryDependencies($directory) {
	$endOfDir = $directory.Split(@('/', '\')) | select -last 1
	echo "Synchronising from $baseDir : $endOfDir  -> $dependency_path"
	gc "$rulesDir\DependencyPatterns.rule" | %{
		& "$script_dir\Tools\SyncDeps.exe" -base $baseDir  -src "*\$endOfDir\*\bin\*\$_" -dst "*\$dependency_path\$_" -masters "Platform\Messaging\merged" -masters "Platform\ServiceStack\merged" #-v -log "$baseDir\$directory\Build\Output\DepsLog.txt"
	}
}

function BuildAndDistribute($directory) {
	Build($directory)
	DistributeBinaryDependencies($directory)
}

# BuildModules.txt must be in bottom-up dependency order:
gc "$rulesDir\Modules.rule" | %{
	$data = $_.Split('=')
	$directory = $data[0].Trim()
	
	BuildAndDistribute("$directory")
}


Write-Host "----[ All Builds Complete ]----" -fo green
