# Script:
#   PackageAndUploadIntuneWin32App.ps1
# Author:
    $author = "Mattias Vandelannoote"
# Date:
    $version = "2022-11-10"
# Description:
#   This script packages the app mentioned in the variables.
#   Then the packaged app gets uploaded to Intune.

# Variables

    $templateFolder = $PSScriptRoot + "\Template\"
    $iconFolder = $PSScriptRoot + "\Icons\"
    $GenerateScriptsTo = $PSScriptRoot + "\Generated\"
    $whatToGenerateArray = @("Setup"; "App"; "Detection")

    $templateSetup = "App_Link_Application_Setup.ps1"
    $template = "App_Link_Application.ps1"
    $templateDetection = "App_Link_Application_Detection.ps1"

    $fileNameStart = "App_MattiasVdl";
    $appName = "MattiasVdl";
    $appIcon = "MattiasVdl_Logo.ico";
    $intuneLogo = "MattiasVdl_Logo.png"

# Generated

    # Logs
    $InstallLocationLogs = "$($env:PROGRAMDATA)\MattiasVdl\Logs"
    $LogFileName = "{LogFile}"
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

    Write-Host "Starting script:"

    Write-Host "  - $($appName):"

    foreach ($whatToGenerate in $whatToGenerateArray) {

        Write-Host "    - $($whatToGenerate):"

        # Load the correct template
        if ($whatToGenerate -eq "Setup") {
            $templateURL = $templateFolder + $templateSetup
            $script = Get-Content -Path $templateURL
            $outputScriptURL = $GenerateScriptsTo + $appName + "\" + $fileNameStart + "_Setup.ps1"
        } elseif ($whatToGenerate -eq "App") {
            $templateURL = $templateFolder + $template
            $script = Get-Content -Path $templateURL
            $outputScriptURL = $GenerateScriptsTo + $appName + "\" + $fileNameStart + ".ps1"
        } elseif ($whatToGenerate -eq "Detection") {
            $templateURL = $templateFolder + $templateDetection
            $script = Get-Content -Path $templateURL
            $outputScriptURL = $GenerateScriptsTo + "DetectionScripts\" + $fileNameStart + "_$($version)_Detection.ps1"
        } else {
            Write-Host "An error has occured !" -ForegroundColor "Red"
        }

        # Replace the necessary values
        $script = $script -replace "{version}", $version
        $script = $script -replace "{author}", $author
        $script = $script -replace "{setupScript}", "$($fileNameStart)_Setup.ps1"
        $script = $script -replace "{detectionScript}", "$($fileNameStart)_Detection.ps1"
        $script = $script -replace "{appScript}", "$($fileNameStart).ps1"
        $script = $script -replace "{installStatusFile}", "$($fileNameStart)_Setup_$($version)"
        $script = $script -replace "{LogFile}" , "$($fileNameStart).log"
        $script = $script -replace "{appName}", $appName
        $script = $script -replace "{appIcon}", $appIcon

        # Save the script to the relevant location
        if (!(Test-Path $outputScriptURL)) {
            New-Item -Force ([System.IO.Path]::GetDirectoryName($outputScriptURL)) -ItemType Directory | Out-Null
        }

        Write-Host "      - $($outputScriptURL)"
        
        $script | Set-Content -Path $outputScriptURL -Force

    }
            
    # Copy icon to the correct folder
        Write-Host "    - Icon:"

        if ($app.appIcon -ne "") {
            $outputIconURL = $GenerateScriptsTo + $appName + "\" + $appIcon

            Write-Host "      - $($outputIconURL)"

            $SourceIconURL = $iconFolder + $appIcon
            Copy-Item -LiteralPath $SourceIconURL -Destination $outputIconURL
        }

    # Package the app
    $appSetup = "$($fileNameStart)_Setup.ps1"
    $outputFile = $appSetup.Substring(0,$appSetup.Length-4) + ".intunewin"
    $packageName = "$($fileNameStart)_$($version).intunewin"
    $source = $GenerateScriptsTo + $appName

    &$PSScriptRoot\IntuneWinAppUtil.exe -c $source -s $appSetup -o $GenerateScriptsTo

    Move-Item -LiteralPath "$($GenerateScriptsTo)\$OutputFile" -Destination "$($GenerateScriptsTo)\$packageName" -Force

    # Upload to Intune

        # Intune variables
        $intunePublisher = "MattiasVdl"
        $intuneInstallExperience = "System"   # System / User
        $intuneRestartBehavior = "allow"   # allow, basedOnReturnCode, suppress, force
        $intuneRequirementRule = New-IntuneWin32AppRequirementRule -Architecture All -MinimumSupportedWindowsRelease 21H1

        Connect-MSIntuneGraph -TenantID "mattiasvdl.onmicrosoft.com" -Interactive

        $intuneDetectionScriptURL = $GenerateScriptsTo + "DetectionScripts\" + $fileNameStart + "_$($version)_Detection.ps1"
        $intuneDetectionRule = New-IntuneWin32AppDetectionRuleScript -ScriptFile $intuneDetectionScriptURL -EnforceSignatureCheck $false -RunAs32Bit $false
        $InstallCommandLine = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -command "".\$($fileNameStart)_Setup.ps1"" ""Install"""
        $UninstallCommandLine = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -command "".\$($fileNameStart)_Setup.ps1"" ""Uninstall"""
        
        $intuneLogoURL = New-IntuneWin32AppIcon -FilePath "$PSScriptRoot\Logos\$($intuneLogo)"

        Add-IntuneWin32App `
            -FilePath "$($GenerateScriptsTo)\$packageName" `
            -DisplayName $appName `
            -Description $fileNameStart `
            -Publisher $intunePublisher `
            -AppVersion $version `
            -InstallCommandLine $InstallCommandLine `
            -UninstallCommandLine $UninstallCommandLine `
            -InstallExperience $intuneInstallExperience `
            -RestartBehavior $intuneRestartBehavior `
            -DetectionRule $intuneDetectionRule `
            -RequirementRule $intuneRequirementRule `
            -Icon $intuneLogoURL `
            -Verbose

exit 0