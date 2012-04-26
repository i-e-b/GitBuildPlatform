$script_dir = Split-Path -parent $MyInvocation.MyCommand.Definition
$baseDir = Join-Path -path $script_dir ".." -resolve


# Change this to the path fragment for stored dependencies:
#$dependency_path = "lib" #  ruby-style pattern
$dependency_path = "Dependencies\Internal" # pattern for the two supplied demos


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
	# TODO: create a pattern file to read for these
	gc "DependencyPatterns.rule" | %{
		& "$script_dir\Tools\SyncDeps.exe" $baseDir "*\$directory\*\bin\Release\$_" "*\$dependency_path\$_"
	}
}

function BuildAndDistribute($directory) {
	Build($directory)
	DistributeBinaryDependencies($directory)
}

# BuildModules.txt must be in bottom-up dependency order:
gc "Modules.rule" | %{
	$data = $_.Split('=')
	$directory = $data[0].Trim()
	$module = $data[1].Trim()
	
	BuildAndDistribute("$directory")
}

# If you know which projects need to distribute dependencies, you can optimise by hardcoding like this:
#BuildAndDistribute("a")
#Build("b")
#Build("c")
#BuildAndDistribute("d")
#BuildAndDistribute("e")
#Build("f")


Write-Host "----[ All Builds Complete ]----" -fo green
