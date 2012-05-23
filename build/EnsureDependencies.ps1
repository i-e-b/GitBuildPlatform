$here = Split-Path -parent $MyInvocation.MyCommand.Definition
$tools = Join-Path -path $here "Tools" -resolve
$baseDir = Join-Path -path $here ".." -resolve

function isItThere($cmd) { # hack to work around bugs in ANSICON
	$vstr = ""
	try {
		"$cmd --version" | iex | %{$vstr = $_}
		return $vstr -match "$cmd"
	} catch {
		return $false
	}
}

Write-Progress "Ensuring that system packages are available" "Checking for Git"
try {
    if (-not (isItThere("git"))) {
		$git_dir = ls ("${env:ProgramFiles}", "${env:ProgramFiles(x86)}") -Filter "git" | %{$_.Fullname} | select-object -first 1
		if($git_dir -eq $null) {
			Write-Host "Please install a recent version of git:" -fo yellow
			Write-Host "http://code.google.com/p/msysgit/downloads/list?q=full+installer+official+git" -fo yellow
			throw "Could not find git"
		}
		
		$gitpath = Join-Path -path $git_dir "cmd" -resolve
        $env:Path += ";$gitpath"
        [System.Environment]::SetEnvironmentVariable("PATH", $env:Path, "User")
		Write-Host "Git command added to path. Please restart the setup script to continue" -fo Cyan
		exit 2
	}
} catch {
    Write-Error "Could not install Git.`r`n`r`nThis may be due to non-administrator account permissions or network problems. Please get assistance."
    exit 1
}

Write-Progress "Ensuring that system packages are available" "Readying PsGet"
try {
	if ((get-module -name psget) -eq $null) {
		(new-object Net.WebClient).DownloadString("http://psget.net/GetPsGet.ps1") | iex
	}
} catch {
    Write-Error "Could not get PsGet.`r`n`r`nThis may be due to non-administrator account permissions or network problems. Please get assistance."
    exit 1
}

Write-Progress "Setting up environment" "installing PoshGit"
try {
	install-module posh-git
} catch {
    Write-Error "Could install PoshGit.`r`n`r`nThis may be due to non-administrator account permissions or an error in PsGet. Please get assistance."
    exit 1
}

Write-Progress "Ensuring that system packages are available" "Checking for Rake"
try {
    if (-not (isItThere("rake")))  {
		if (-not (isItThere("ruby")))  {
			Write-Progress "Ensuring that system packages are available" "Downloading Ruby"
			$clnt = new-object System.Net.WebClient
			$url = "http://rubyforge.org/frs/download.php/75127/rubyinstaller-1.9.2-p290.exe"
			$file = ".\ruby_installer.exe"
			$clnt.DownloadFile($url,$file)
			Write-Progress "Ensuring that system packages are available" "Running installer"
			$install = $file + " /silent"
			cmd /c $install
			del $file
			$env:Path += ";C:\Ruby192\bin"
			[System.Environment]::SetEnvironmentVariable("PATH", $env:Path, "User")
		}
        # try again
        Write-Progress "Ensuring that system packages are available" "Checking for Rake"
        cmd /c "gem install --remote rake" | out-null
        if ($LASTEXITCODE -ne 0) {
            throw "failed to install rake"
        }
		
		Write-Host "Installed Ruby & Rake. Please close and restart the platform setup script" -fo cyan
		exit 2
    }
} catch {
    Write-Error "Could not install Rake.`r`n`r`nThis may be due to non-administrator account permissions or network problems. Please get assistance."
    exit 1
}

Write-Progress "Ensuring that system packages are available" "Checking for SQL"
try {
    $sql_vstr = cmd /c SQLCMD.EXE -S ".\SQLEXPRESS" -Q "SELECT '1' "
    if ($sql_vstr -notcontains "(1 rows affected)") {
    
        Write-Progress "Ensuring that system packages are available" "SQL is not installed... downloading"
        $msi64 = "http://go.microsoft.com/?linkid=9729746"
        $msi32 = "http://go.microsoft.com/?linkid=9729747"
        $clnt = new-object System.Net.WebClient
        $url = $msi32
        if ([IntPtr]::Size -eq 8) {
            $url = $msi64
        }
        $file = ".\sql_installer.exe"
        $clnt.DownloadFile($url,$file)
        Write-Progress "Ensuring that system packages are available" "Running SQL Express installer"
        $install = $file + " /uimode=autoadvance /action=install" 
        cmd /c $install
        
        del $file
        
        $env:Path += ";C:\Program Files (x86)\Microsoft SQL Server\100\Tools\Binn"
        [System.Environment]::SetEnvironmentVariable("PATH", $env:Path, "User")
		
	Write-Host "Installed SQL Server. Please close and restart the platform setup script" -fo green
	exit 2
    }
} catch {
    Write-Error "Could not install SQL.`r`n`r`nThis may be due to non-administrator account permissions or network problems. Please get assistance.`r`n`r`nException: $_"
    exit 1
}

Write-Progress "Checking SQL Server Setup" "Checking Login Configuration"
try {
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
	$sqlserver = new-object ('Microsoft.SqlServer.Management.Smo.Server') '.\SQLExpress'
	if ($sqlserver.Settings.LoginMode -ne [Microsoft.SqlServer.Management.SMO.ServerLoginMode]::Mixed) {
		$sqlserver.Settings.LoginMode = [Microsoft.SqlServer.Management.SMO.ServerLoginMode]::Mixed
		$sqlserver.Alter()
		Write-Host "Sql Server set to mixed mode authentication." -fo green
	}
} catch {
    Write-Error "Could not set SQL Authentication code.`r`n`r`nThis may be due to non-administrator account permissions. Please get assistance.`r`n`r`nException: $_"
    exit 1
}

Write-Progress "Checking SQL Server Setup" "Checking connection protocols"
try {
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Sqlserver.SqlWmiManagement") | out-null
	$wmi = New-Object("Microsoft.SqlServer.Management.SMO.Wmi.ManagedComputer")
	$wmi.ClientProtocols["np"].IsEnabled = $true
	$wmi.ClientProtocols["np"].Alter()
	$wmi.ClientProtocols["tcp"].IsEnabled = $true
	$wmi.ClientProtocols["tcp"].Alter()
} catch {
	Write-Error "Could not enable Pipes and TCP/IP on SQL Express`r`n`r`nThis may be due to non-administrator account permissions. Please get assistance.`r`n`r`nException: $_"
	exit 1
}

Write-Progress "Checking SQL Server Setup" "Restarting SQL Services"
Get-Service | ?{$_.Name.Contains("SQL")} | ?{$_.Status -eq "Running"} | Restart-Service -fo

Write-Progress "Ensuring that system packages are available" "Checking for MVC3"
try {
	& "$tools\WebpiCmdLine.exe" /Products:MVC3,MVC3Loc,MVC3Runtime /accepteula /SuppressReboot
} catch {
	Write-Error "Could not install MVC3.`r`n`r`n$_"
	exit 1
}

Write-Progress "Ensuring that system packages are available" "Checking Windows Components (may take a long time)"
try {
    CMD /C "START /w PKGMGR.EXE /norestart /iu:IIS-WebServerRole;IIS-WebServer;IIS-CommonHttpFeatures;IIS-StaticContent;IIS-DefaultDocument;IIS-DirectoryBrowsing;IIS-HttpErrors;IIS-HttpRedirect;IIS-ApplicationDevelopment;IIS-ISAPIExtensions;IIS-ISAPIFilter;IIS-ServerSideIncludes;IIS-HealthAndDiagnostics;IIS-HttpLogging;IIS-LoggingLibraries;IIS-RequestMonitor;IIS-HttpTracing;IIS-CustomLogging;IIS-ODBCLogging;IIS-Security;IIS-BasicAuthentication;IIS-WindowsAuthentication;IIS-DigestAuthentication;IIS-ClientCertificateMappingAuthentication;IIS-IISCertificateMappingAuthentication;IIS-URLAuthorization;IIS-RequestFiltering;IIS-IPSecurity;IIS-Performance;IIS-HttpCompressionStatic;IIS-HttpCompressionDynamic;IIS-WebServerManagementTools;IIS-ManagementScriptingTools;IIS-WMICompatibility;WAS-WindowsActivationService;WAS-ProcessModel;IIS-ASPNET;IIS-NetFxExtensibility;WAS-NetFxEnvironment;WAS-ConfigurationAPI;IIS-ManagementService"
    CMD /C "START /w PKGMGR.EXE /norestart /iu:MSMQ-Container;MSMQ-Server;WCF-HTTP-Activation;WCF-NonHTTP-Activation;"
} catch {
    Write-Error "Could not install required system components.`r`n`r`nThis may be due to non-administrator account permissions. Please get assistance."
    exit 1
}

Write-Progress "Cleaning up" "removing temp files"
pushd "$baseDir"
git clean -f
popd
