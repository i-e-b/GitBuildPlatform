$script_dir = Split-Path -parent $MyInvocation.MyCommand.Definition
$baseDir = Join-Path -path $script_dir ".." -resolve
$rulesDir = Join-Path -path $script_dir "..\_rules" -resolve

$dependency_path = (gc "$rulesDir\DependencyPath.rule").Replace("\","/") #fix for git's Linux conventions

 & "$script_dir\CheckSubmodules.ps1"

Remove-Job *   #remove all the back ground jobs in this session

$task = {
	param (
		$directory, $dependency_path
	)
	
	function CleanBuildDirectory($directory) {
		pushd "$directory\build"
		
		@(git status -s) | ?{$_.StartsWith(" M")} | ?{ -not ($_ -match "Build.cmd") } | 
			?{-not ($_.StartsWith(" M ../"))} | %{ git checkout $_.SubString(3) }
		
		popd
	}

	function Update($directory) {
		pushd "$directory"
		$currentBranch = git branch | ?{$_.StartsWith("*")} | %{$_.Substring(2)}
		
		Write-Host "Updating $directory to latest $currentBranch " -fo cyan -NoNewLine
		if (Test-Path "$dependency_path/*") {git checkout "$dependency_path/*"} # lib will get updated by build, so drop changed files.
		$changes = ((git status -s).Count -ne $null) -and ((git status -s).Count -gt 0)
		if ($changes -eq $true) {
			Write-Host "Changes will be stashed and re-applied" -fo darkcyan
			git stash save "automatic stash"
		} else {
			Write-Host "No local changes" -fo darkcyan
		}
		
		# fetch and merge changes, updating submodule refences, prefer incoming changes, from origin on current branch:
		git pull -q --recurse-submodules=yes -Xtheirs origin "$currentBranch"
		git submodule update
		
		if ($changes) {git stash pop}
		popd
	}


	CleanBuildDirectory($directory)
	Update($directory)
}

$directories = cat "$rulesDir\Modules.rule" | %{
	$data = $_.Split('=')
	return $directory = $data[0].Trim()
}

echo "Running all updates -- please wait" #start update jobs

foreach($target in $directories)
{
    Start-Job -ScriptBlock $task -Name "Updating_$target" -ArgumentList @("$baseDir\$target", $dependency_path) | out-null
}

get-job | wait-job | out-null

foreach($target in $directories)
{
    Receive-Job -Name "Updating_$target" | out-host
}

# Remove dead directories
$directories = cat "$rulesDir\PathsToDelete.rule" | %{
	$removalPath = "$baseDir\$_";
	if (Test-Path $removalPath) {
		rm -recurse -force $removalPath
	}
}

echo "done"
Get-Date
