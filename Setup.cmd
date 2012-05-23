cd %~dp0

rem Go install Powershell if it's not there:
WHERE PKGMGR
IF %ERRORLEVEL% EQU 0 (PKGMGR.EXE /iu:MicrosoftWindowsPowerShell)

powershell.exe -NoProfile -ExecutionPolicy ByPass ".\build\InitialSetup.ps1"

pause