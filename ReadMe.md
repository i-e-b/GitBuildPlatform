A build system for local dependency management using Powershell

What it does
============
Provides a cross-solution build environment for local development which can be mirrored on an Integration Server (such as TeamCity). See Readme.pdf for an overview of rationale.

How to setup
============
Change ".build/EnsureDependencies.ps1" to match your requirements
Change ".rules/Modules.rule" to includ all your solution repos as "Folder = repourl" lines
Update ".rules/DependencyPatterns.rule" and ".rules/DependencyPath.rule" to match your binary and library-folder conventions.

How to use
==========
Run Setup.cmd at least once and ensure it has run successfully.
Run Platform_build.cmd before EVERY bit of work you do.

Make sure you commit your changes, checking submodules. Commit your dependencies.
