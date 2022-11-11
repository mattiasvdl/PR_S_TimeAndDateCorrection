# Script:
#   App_MattiasVdl_Detection.ps1
# Version:
#   2022-11-10
# Author:
#   Mattias Vandelannoote
# Purpose:
#   Detection script to determine if MattiasVdl is installed correctly

# Variables

    $appScriptURL = "$($env:PROGRAMDATA)\MattiasVdl\Scripts\App_MattiasVdl.ps1"
    $appIconURL = "$($env:PROGRAMDATA)\MattiasVdl\Icons\MattiasVdl_Logo.ico"
    $StartMenuShortcutURL = "$($env:PROGRAMDATA)\Microsoft\Windows\Start Menu\Programs\MattiasVdl\MattiasVdl.lnk"

    $isAppInstalled = $true

# Generated

    # Logs

    $InstallLocationLogs = "$($env:PROGRAMDATA)\MattiasVdl\Logs"
    $LogFileName = "App_MattiasVdl.log"
    $LogFileURL = "$InstallLocationLogs\$LogFileName"

# Functions

    # Create Write-Log function
    function Write-Log() {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [ValidateNotNullOrEmpty()]
            [Alias("LogContent")]
            [string]$Message,
            [Parameter(Mandatory=$false)]
            [Alias('LogPath')]
            [string]$Path = $LogfileURL,
            [Parameter(Mandatory=$false)]
            [ValidateSet("Error","Warn","Info")]
            [string]$Level = "Info"
        )

        Begin {
            # Set VerbosePreference to Continue so that verbose messages are displayed.
            $VerbosePreference = 'SilentlyContinue'
        }
        Process {
            if (Test-Path $Path) {
                $LogSize = (Get-Item -Path $Path).Length/1MB
                $MaxLogSize = 5
            }
            # Check for file size of the log. If greater than 5MB, it will create a new one and delete the old.
            if ((Test-Path $Path) -AND $LogSize -gt $MaxLogSize) {
                Write-Error "Log file $Path already exists and file exceeds maximum file size. Deleting the log and starting fresh."
                Remove-Item $Path -Force
                $NewLogFile = New-Item $Path -Force -ItemType File
            }
            # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
            elseif (-NOT(Test-Path $Path)) {
                $NewLogFile = New-Item $Path -Force -ItemType File
            }
            else {
                # Nothing to see here yet.
            }
            # Format Date for our Log File
            $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            # Write message to error, warning, or verbose pipeline and specify $LevelText
            switch ($Level) {
                'Error' {
                    Write-Error $Message
                    $LevelText = 'ERROR:'
                }
                'Warn' {
                    Write-Warning $Message
                    $LevelText = 'WARNING:'
                }
                'Info' {
                    $LevelText = 'INFO:'
                }
            }
            # Write log entry to $Path
            "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
        }
        End {
        }
    }

# Script

    if (!(Test-Path $appScriptURL)) {
        Write-Log "Unable to detect the script on this location: $($appScriptURL)"
        $isAppInstalled = $false
    }

    if (!(Test-Path $appIconURL)) {
        Write-Log "Unable to detect the icon on this location: $($appIconURL)"
        $isAppInstalled = $false
    }

    if (!(Test-Path $StartMenuShortcutURL)) {
        Write-Log "Unable to detect the shortcut on this location: $($StartMenuShortcutURL)"
        $isAppInstalled = $false
    }

    if ($isAppInstalled) {
        Write-Log "The application is correctly installed"
        Write-Host "The applicaiton is correctly installed"
        exit 0
    } else {
        Write-Log "One or more files are missing!"
        Write-Host "One or more files are missing!"
        exit 1
    }
