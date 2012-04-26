This folder contains the backing scripts for the local build & update process
Call the Platform_Build.cmd and Setup.cmd scripts for day-to-day operations. 

Script purposes
---------------
BuildAllNoUpdate.ps1 (called by Platform_Build.cmd): For each build module, tries to run local build commands and then update dependencies in the platform

CheckSubmodules.ps1 (called by InitialSetup.ps1): For each module in "BuildModules.txt" adds, inits, updates and switches to master branch

EnsureDependencies.ps1 (called by InitialSetup.ps1 ): Checks for a whole load of build and test dependencies. This is a bit of a beast and could do with improvement (potentially just a set of NuGet calls?)

InitialSetup.ps1 (called by Setup.cmd): Make sure the running OS is ready to build and test the platform. Does not provide a Git install or a VisualStudio install. Should manage *everything* else, as far as possible.

SelfUpdate.ps1 (called by Platform_Build.cmd): Update the build environment scripts before they are run.

StartSshAgent.ps1 (called by most scripts): Ensure that an SSH agent is ready (saves on passphrase typing)

UpdateAll.ps1 (called by Platform_Build.cmd): Update all Build Modules, stashing and re-applying changes if needed.

