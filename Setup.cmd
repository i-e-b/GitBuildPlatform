cd %~dp0
@echo off

rem Go install Powershell if it's not there:
WHERE PKGMGR
IF %ERRORLEVEL% EQU 0 (PKGMGR.EXE /iu:MicrosoftWindowsPowerShell)

powershell -NoProfile -ExecutionPolicy ByPass ".\_build\SelfUpdate.ps1"
powershell.exe -NoProfile -ExecutionPolicy ByPass ".\_build\InitialSetup.ps1"

pause