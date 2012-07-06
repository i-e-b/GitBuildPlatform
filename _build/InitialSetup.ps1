$here = Split-Path -parent $MyInvocation.MyCommand.Definition

& "$here\EnsureDependencies.ps1"
if ($LASTEXITCODE -ne 0) {exit $LASTEXITCODE}
& "$here\CheckSubmodules.ps1"
if ($LASTEXITCODE -ne 0) {exit $LASTEXITCODE}
& "$here\UpdateAll.ps1"

Write-Host "****************************************" -fo green
Write-Host "* Platform is now set up               *" -fo green
Write-Host "* Please now run the PlatformBuild.cmd *" -fo green
Write-Host "****************************************" -fo green