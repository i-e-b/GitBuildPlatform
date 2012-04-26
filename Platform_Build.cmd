:: Switch to batch source folder
cd %~dp0

@echo off
powershell -NoProfile -ExecutionPolicy ByPass ".\build\SelfUpdate.ps1"
powershell -NoProfile -ExecutionPolicy ByPass ".\build\UpdateAll.ps1"
powershell -NoProfile -ExecutionPolicy ByPass ".\build\BuildAllNoUpdate.ps1"
@echo on 
pause
