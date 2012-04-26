cd %~dp0

rem Go install Powershell if it's not there:
PKGMGR.EXE /iu:MicrosoftWindowsPowerShell

powershell.exe -NoProfile -ExecutionPolicy ByPass ".\build\InitialSetup.ps1"

pause