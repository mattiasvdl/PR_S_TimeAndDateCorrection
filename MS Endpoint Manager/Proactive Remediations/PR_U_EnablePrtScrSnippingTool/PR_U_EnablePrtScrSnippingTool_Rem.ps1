# Script:
#   PR_U_EnablePrtScrSnippingTool_Rem.ps1
# Run as:
#   User
# Author:
#   Mattias Vandelannoote
# Date:
#   2022-11-01
# Description:
#   Sets the printscreen button on the users device to open the snipping tool.

# Variables:
    $ExitCode = 0
    $RegPath = "Registry::HKEY_CURRENT_USER\Control Panel\Keyboard"
    $RegKey = "PrintScreenKeyForSnippingEnabled"
    $RegKeyValue = 1
    $LogFolderLocation = "$env:LOCALAPPDATA\MattiasVdl\Logs"

# Functions:
    Function Write-Log() {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$Message,
            [Parameter(Mandatory=$false)]
            [string]$Path,
            [Parameter(Mandatory=$false)]
            [ValidateSet("Error","Warn","Info")]
            [string]$Level = "Info"
        )

        # Variables:
        $VerbosePreference = "Continue"
        $MaxLogSize = 1
        $Path = $Path.Trim()
        if (-not $Path) {
            $ScriptName = $MyInvocation.ScriptName.split("\")[-1]
            $PRName = $ScriptName.Substring(0, $ScriptName.Length-8)
            $PRType = $ScriptName.Substring($ScriptName.Length-7, 3)
            $Path = "$LogFolderLocation\$PRName\$PRType.log"
        }

        # Script:

            # Check if the log already excists, and if it does, get the file size in MB.
            if (Test-Path $Path) {
                $LogSize = (Get-Item -Path $Path).Length/1MB
            }

            # Check for file size of the log. If greater than 5MB, create a new one and delete the old.
            if ((Test-Path $Path) -AND $LogSize -gt $MaxLogSize) {
                Write-Verbose "Log file $Path already exists and file exceeds maximum file size. Deleting the log and starting fresh."
                Remove-Item $Path -Force
                $NewLogFile = New-Item $Path -Force -ItemType File
            }

            # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
            elseif (-NOT(Test-Path $Path)) {
                Write-Verbose "Creating $Path."
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
                    Write-Verbose $Message
                    $LevelText = 'INFO:'
                }
            }
            
            # Write log entry to $Path
            "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
        }

    Function Compare-RegKey() {
        param (
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]$Path,
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]$Key,
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]$ExpectedValue
        )

        try {
            $CurrentValue = (Get-ItemProperty "$Path").$Key
            Write-Log -Message "Checking Registry entry at:   $Path\$Key"
            Write-Log -Message "Current Registry Key on this location:   $CurrentValue"
            if ($CurrentValue -eq $ExpectedValue) {
                Write-Log -Message "The current registry value matches the expected value."
                return $True
            } else {
                Write-Log -Message "The current registry value doesn't match the expected value."
                return $False
            }
        }
        catch {
            return $False
        }
    }

# Script

    Write-Log "Adding / modifying the necessary Registry key ($RegKey) to   $RegPath   with value:   $RegValue"
    New-ItemProperty -Path $RegPath -Name $RegKey -Value $RegKeyValue -PropertyType DWORD -Force

    # Check if the key was successfully added
    if (Compare-RegKey -Path $RegPath -Key $RegKey -ExpectedValue $RegKeyValue) {
        Write-Log -Message "The remediation was executed succesfully"
    } else {
        Write-Log -Message "An error has occurred"
        $ExitCode = 1
    }

    Write-Log " "
    Write-Log "---"
    Write-Log " "

    Exit $ExitCode