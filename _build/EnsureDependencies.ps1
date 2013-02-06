$here = Split-Path -parent $MyInvocation.MyCommand.Definition
$tools = Join-Path -path $here "Tools" -resolve
$baseDir = Join-Path -path $here ".." -resolve

. "$here\Helpers.ps1"

Write-Progress "Ensuring that system packages are available" "Checking for Mongo Db 2.2"
try{
$mongodirectory = "c:\mongodb"
if (-not (Test-Path $mongodirectory)) {
		$client = new-object System.Net.WebClient
		$mongoInstaller = "http://downloads.mongodb.org/win32/mongodb-win32-x86_64-2008plus-2.2.2.zip"
		$fileName = $here + "\mongodb_2_2.zip"
		
		$client.DownloadFile($mongoInstaller, $fileName)
		$unzip = "$here\Tools\7z.exe -y x " + $fileName
		cmd /c $unzip
		del $fileName
		mv  .\mongo* $mongodirectory -Force
		mkdir c:\data\db 
	}
} catch {
	Write-Error "Could not install Mongo Db 2.2"
	exit 1
}

Write-Progress "Ensuring that system packages are available" "Checking for Git"
try {
    if (-not (isItThere("git"))) {
		$git_dir = ProgramDirectory("git")
		if($git_dir -eq $null) {
			Write-Host "Please install a recent version of git:" -fo yellow
			Write-Host "http://code.google.com/p/msysgit/downloads/list?q=full+installer+official+git" -fo yellow
			throw "Could not find git"
		}
		
		$gitpath = Join-Path -path $git_dir "cmd" -resolve
		AddToEnvPath($gitpath)
		Write-Host "Git command added to path. Please restart the setup script to continue" -fo Cyan
		exit 2
	}
} catch {
    Write-Error "Could not install Git.`r`n`r`nThis may be due to non-administrator account permissions or network problems. Please get assistance."
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
        $msi64 = "http://care.dlservice.microsoft.com/download/8/D/D/8DD7BDBA-CEF7-4D8E-8C16-D9F69527F909/ENU/x64/SQLEXPRWT_x64_ENU.exe?lcid=1033&cprod=SQLDENEXPPOST32"
        $msi32 = "http://care.dlservice.microsoft.com/download/8/D/D/8DD7BDBA-CEF7-4D8E-8C16-D9F69527F909/ENU/x86/SQLEXPRWT_x86_ENU.exe?lcid=1033&cprod=SQLDENEXPPOST32"
        $clnt = new-object System.Net.WebClient
        $url = $msi32
        if ([IntPtr]::Size -eq 8) {
            $url = $msi64
        }
        $file = ".\sql_installer.exe"
        $clnt.DownloadFile($url,$file)
        Write-Progress "Ensuring that system packages are available" "Running SQL Express 2012 installer"
        $install = $file + " /uimode=autoadvance /action=install" 
        cmd /c $install
        
        del $file
        
		AddToEnvPath("C:\Program Files (x86)\Microsoft SQL Server\110\Tools\Binn")
		
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

Write-Progress "Ensuring that system packages are available" "Checking for Erlang"
try {
    if (-not (canCall("erl.exe -version")))  {
			if (HasProgramDirectory("erl*")) {
				$erl_dir = ProgramDirectory("erl*")
				if (canCall("& '$erl_dir\bin\erl.exe' -version")) {

					AddToEnvPath("$erl_dir\bin")
					Write-Host "Added Erlang to Path. Please close and restart the platform setup script" -fo green
					exit 2
				}
			}

			Write-Progress "Ensuring that system packages are available" "Downloading Erlang"
			$clnt = new-object System.Net.WebClient
			$url_32 = "http://www.erlang.org/download/otp_win32_R15B01.exe"
			$url_64 = "http://www.erlang.org/download/otp_win64_R15B01.exe"
			$url = $url_32
			if ([IntPtr]::Size -eq 8) {
				$url = $url_64
			}
			$file = ".\erlangInstaller.exe"
			$clnt.DownloadFile($url,$file)
			Write-Progress "Ensuring that system packages are available" "Running Erlang installer"
			$install = $file + " /S"
			cmd /c $install
			del $file

			$erl_dir = ProgramDirectory("erl*")

            Write-Progress "Ensuring that erlang works" "Running erl -version"
            if (-not (canCall("& '$erl_dir\bin\erl.exe' -version"))) {
                throw "failed to install erlang"
            }

			AddToEnvPath("$erl_dir\bin")
			Write-Host "Installed Erlang. Please close and restart the platform setup script" -fo green
            exit 2
    }
    
} catch {
    Write-Error "Could not install Erlang.`r`n`r`nThis may be due to non-administrator account permissions or network problems. Please get assistance."
    exit 1
}

Write-Progress "Ensuring that system packages are available" "Checking for RabbitMQ"
try {
	$rabbitDir = ProgramDirectory("RabbitMq Server")
    if (-not (canCall("& '$rabbitDir\rabbitmq_server-2.8.4\sbin\rabbitmqctl' status")))  {

			if (HasFileOrDirectory($rabbitDir)) {
				Write-Progress "An different version of RabbitMQ might be installed, please uninstall and re-run this script." -fo yellow
				exit 2
			}
	
    		Write-Progress "Ensuring that system packages are available" "Downloading RabbitMQ"
    		$clnt = new-object System.Net.WebClient
    		$url = "http://www.rabbitmq.com/releases/rabbitmq-server/v2.8.4/rabbitmq-server-2.8.4.exe"
    		$file = ".\rabbitmq-server-2.8.4.exe"
    		$clnt.DownloadFile($url,$file)
    		Write-Progress "Ensuring that system packages are available" "Running  rabbitmq installer"
    		$install = $file + " /S"
    		cmd /c $install
    		del $file

            Write-Progress "Ensuring that RabbitMQ is installed" "Running rabbitmqctl"
			$rabbitDir = ProgramDirectory("RabbitMQ Server")
            cmd /c "$rabbitDir\rabbitmq_server-2.8.4\sbin\rabbitmqctl" status | out-null
            if ($LASTEXITCODE -ne 0) {
                   throw "Failed to install RabbitMQ"
            }
			
            Write-Host "Installed RabbitMQ. Please close and restart the platform setup script" -fo green
            exit 2
    }
    
} catch {
    Write-Host $errors
    Write-Error "Could not install RabbitMQ.`r`n`r`nThis may be due to non-administrator account permissions or network problems. Please get assistance."
    exit 1
}


Write-Progress "Ensuring that system packages are available" "Checking for RabbitMQ Management plugin"
try {
	$rabbitDir = ProgramDirectory("RabbitMQ Server")
	$list = & "$rabbitDir\rabbitmq_server-2.8.4\sbin\rabbitmq-plugins.bat" list
	$managementOn = "$list".Contains("[E] rabbitmq_management")
    $vhosts = & "$rabbitDir\rabbitmq_server-2.8.4\sbin\rabbitmqctl.bat" list_vhosts
    $haveJesterVhost = "$vhosts".ToLower().Contains("jester")

    if (-not ($managementOn))  {
		# Activate management plugin:
		cmd /c "$rabbitDir\rabbitmq_server-2.8.4\sbin\rabbitmq-plugins" enable rabbitmq_management
		cmd /c "$rabbitDir\rabbitmq_server-2.8.4\sbin\rabbitmq-service.bat" stop
		cmd /c "$rabbitDir\rabbitmq_server-2.8.4\sbin\rabbitmq-service.bat" install
		cmd /c "$rabbitDir\rabbitmq_server-2.8.4\sbin\rabbitmq-service.bat" start

        Restart-Service RabbitMQ
		
		Write-Host "Management plugin activated" -fo green
	}

    if (-not ($haveJesterVhost)) {
        cmd /c "$rabbitDir\rabbitmq_server-2.8.4\sbin\rabbitmqctl.bat" add_vhost jester
        cmd /c "$rabbitDir\rabbitmq_server-2.8.4\sbin\rabbitmqctl.bat" set_permissions -p jester guest ".*" ".*" ".*"
		Write-Host "Added Jester VHost" -fo green
    }

} catch {
    Write-Host $errors
    Write-Error "Could not configure RabbitMQ.`r`n`r`nThis may be due to non-administrator account permissions or network problems. Please get assistance."
    exit 1
}
Write-Progress "Cleaning up" "removing temp files"
pushd "$baseDir"
git clean -f
popd
