:: Switch to batch source folder
cd %~dp0

@echo off
powershell -NoProfile -ExecutionPolicy ByPass ".\_build\SelfUpdate.ps1"
powershell -NoProfile -ExecutionPolicy ByPass ".\_build\UpdateAll.ps1"
powershell -NoProfile -ExecutionPolicy ByPass ".\_build\BuildAllNoUpdate.ps1"
@echo on 
pause
