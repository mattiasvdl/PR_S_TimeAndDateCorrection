Param
(
    [Parameter(Mandatory=$true,Position=0)]
    [String]$Action
)

#Script:
#   App_MattiasVdl_Setup.ps1
# Version:
    $Version = "2022-11-10"
# Author:
#   Mattias Vandelannoote
# Purpose:
#   Installs the MattiasVdl shortcut and adds it to the Start Menu.
#   The installation happens on a system level.

# Variables

    $InstallLocation = "$env:PROGRAMDATA\MattiasVdl"
    $StartMenuLocation = "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\MattiasVdl"

    $AppName = "MattiasVdl";
    $AppScript = "App_MattiasVdl.ps1";
    $AppIcon = "MattiasVdl_Logo.ico"

# Generated

    # Scripts
    $InstallLocationScripts = "$InstallLocation\Scripts"        
    
    # Icons
    $InstallLocationIcons = "$InstallLocation\Icons"

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

    # Create / Remove App
    function CreateRemoveApp() {
        param(
            [Parameter(Mandatory=$true)]
            [String]$Action,
            [Parameter(Mandatory=$true)]
            [string]$AppName,
            [Parameter(Mandatory=$true)]
            [string]$AppScript,
            [Parameter(Mandatory=$true)]
            [string]$AppIcon
        )
        
        #Set up variables
        $StartMenuShortcutURL = "$StartMenuLocation\$AppName.lnk"
        $AppScriptURL = "$InstallLocationScripts\$AppScript"
        $AppIconURL = "$InstallLocationIcons\$AppIcon"

        if($Action -eq "Install") { # Installation

            createShortcut -StartMenuShortcutURL $StartMenuShortcutURL -AppScriptURL $AppScriptURL -AppIconURL $AppIconURL

            if (!(Test-Path $StartMenuShortcutURL -PathType Leaf)) {
                Write-Log -Message "Unable to detect $StartMenuShortcutURL"
            }

        } elseif($Action -eq "Uninstall") { #Uninstall

            Write-Log -Message "Removing $StartMenuShortcutURL"
            Remove-Item -LiteralPath $StartMenuShortcutURL -Force
            removeFolderIfEmpty -FolderURL $StartMenuLocation

            Write-Log -Message "Removing $AppIconURL"
            Remove-Item -LiteralPath $AppIconURL -Force
            removeFolderIfEmpty -FolderURL $InstallLocationIcons

            Write-Log -Message "Removing $AppScriptURL"
            Remove-Item -LiteralPath $AppScriptURL -Force
            removeFolderIfEmpty -FolderURL $InstallLocationScripts

        }

    }

    # Create shortcut
    function createShortcut() {
        param(
            [Parameter(Mandatory=$true)] [string]$StartMenuShortcutURL,
            [Parameter(Mandatory=$true)] [string]$AppScriptURL,
            [Parameter(Mandatory=$true)] [string]$AppIconURL
        )

        # First check if the folder exists, if not, create it
        If(!(test-path $StartMenuLocation)) {
            New-Item -ItemType Directory -Force -Path $StartMenuLocation
        }

        #New-Object : Creates an instance of a Microsoft .NET Framework or COM object.
        #-ComObject WScript.Shell: This creates an instance of the COM object that represents the WScript.Shell for invoke CreateShortCut
        $WScriptShell = New-Object -ComObject WScript.Shell

        Write-Log -Message "Creating shortcut at location $StartMenuShortcutURL"
        $Shortcut = $WScriptShell.CreateShortcut($StartMenuShortcutURL)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -File ""$AppScriptURL"""
        $Shortcut.WorkingDirectory = "$InstallLocationScripts"
        $Shortcut.WindowStyle = 4   # Normal (7 = Minimized, 0 = Maximized)
        $Shortcut.IconLocation = $AppIconURL
        $Shortcut.Save()
    }

    # Remove folder if empty
    function removeFolderIfEmpty() {
        param(
            [Parameter(Mandatory=$true)]
            [string]$FolderURL
        )

        cd $FolderURL

        if ((Get-ChildItem | Measure-Object).Count -eq 0) {
            Write-Log -Message "The main folder ($FolderURL) is empty. Deleting it now."
            cd ..
            Remove-Item -LiteralPath $FolderURL -Force -Recurse
        } else {
            Write-Log -Message "The main folder ($FolderURL) is not empty."
        }

    }

# Script

    if($Action -eq "Install") {     # Installation

        # Create the application
        # Copy the scripts from the package to the installation folder

            # First check if the folder exists, if not, create it
            Write-Log -Message "Checking if folder $InstallLocationScripts exists"

            If(!(test-path $InstallLocationScripts)) {
                Write-Log -Message "Creating $InstallLocationScripts"
                New-Item -ItemType Directory -Force -Path $InstallLocationScripts
            }

        Write-Log -Message "Copying over the script $AppScript to $InstallLocationScripts"
        Copy-Item -Path $AppScript -Destination $InstallLocationScripts -Force

        # Copy the icons from the package to the installation folder
        Write-Log -Message "Checking if folder $InstallLocationIcons exists"

        # First check if the folder exists, if not, create it
        If(!(test-path $InstallLocationIcons)) {
            Write-Log -Message "Creating $InstallLocationIcons"
            New-Item -ItemType Directory -Force -Path $InstallLocationIcons
        }
        
        Write-Log -Message "Copying over the icon $AppIcon to $InstallLocationIcons"
        Copy-Item -Path $AppIcon -Destination $InstallLocationIcons -Force

        # Create the shortcut under the start menu
        Write-Log -Message "Creating the shortcut for the application"
        CreateRemoveApp -Action $Action -AppName $AppName -AppScript $AppScript -AppIcon $AppIcon
            
    } elseif($Action -eq "Uninstall") { # Uninstall
        # Remove the application
        CreateRemoveApp -Action $Action -AppName $AppName -AppScript $AppScript -AppIcon $AppIcon

    }

    Exit 0
