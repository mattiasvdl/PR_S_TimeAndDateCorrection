# Script:
#   PR_S_TimeAndDateCorrection_Det.ps1
# Run as:
#   System
# Author:
#   Mattias Vandelannoote
# Date:
#   2022-10-31
# Description:
#   Checks if the Time and Date are correctly set up on the user device.

# Variables:

    $ExitCode = 0

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
            $Path = "$env:LOCALAPPDATA\MattiasVdl\Logs\$PRName\$PRType.log"
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

    Function Get-CurrentNtpServer() {
        try {
            $NtpServer = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters\" -Name "NtpServer"
            $NtpServer = ($NtpServer -split (","))[0]
            Write-Log -Message "The current Ntp Server for this device is: $NtpServer"
            return $NtpServer
        } catch {
            Write-Log -Level Error -Message "Couldn't retrieve the current NtpServer."
            exit
        }
    }

    Function Get-NtpTime ( [String]$NTPServer ) {

        # All credits to Tim Curwick for this function.
        # https://madwithpowershell.blogspot.com/2016/06/getting-current-time-from-ntp-service.html

        # Build NTP request packet. We'll reuse this variable for the response packet
        $NTPData    = New-Object byte[] 48  # Array of 48 bytes set to zero
        $NTPData[0] = 27                    # Request header: 00 = No Leap Warning; 011 = Version 3; 011 = Client Mode; 00011011 = 27
        $Attempts = 0

        While ($Attempts -lt 3) {
            try {
                $Attempts ++
                # Open a connection to the NTP service
                $Socket = New-Object Net.Sockets.Socket ( 'InterNetwork', 'Dgram', 'Udp' )
                $Socket.SendTimeOut    = 2000  # ms
                $Socket.ReceiveTimeOut = 2000  # ms
                $Socket.Connect( $NTPServer, 123 )
                
                # Make the request
                $Null = $Socket.Send(    $NTPData )
                $Null = $Socket.Receive( $NTPData )
                
                # Clean up the connection
                $Socket.Shutdown( 'Both' )
                $Socket.Close()
                break
            } catch {
                Write-Log -Level Error -Message "Unable to retrieve date and time from the NTP server."
                Start-Sleep -Seconds 30
            }
        }

        # Extract relevant portion of first date in result (Number of seconds since "Start of Epoch")
        $Seconds = [BitConverter]::ToUInt32( $NTPData[43..40], 0 )
        
        # Add them to the "Start of Epoch", convert to local time zone, and return
        ( [datetime]'1/1/1900' ).AddSeconds( $Seconds ).ToLocalTime()
    }

# Script

    # Check if the StartupType of the Windows Time Service is set to "Manual"
    $w32TimeStartupType = (Get-Service w32time).StartType
    Write-Log "The Windows Time Service Startup Type is set to: $w32TimeStartupType"
    
    if ($w32TimeStartupType -ne "Manual") {
        $ExitCode = 1
    }

    Write-Log " "

    # Check if the Windows Time Service is started
    $w32TimeStatus = (Get-Service w32time).Status
    Write-Log "The Windows Time Service Startup Type is set to: $w32TimeStatus"
    
    if ($w32TimeStatus -ne "Running") {
        $ExitCode = 1
    }

    Write-Log " "

    # Check if "Set the time automatically" is activated
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
    $RegKey = "Type"
    $RegKeyValue = "NTP"
    $STA = Get-ItemPropertyValue -Path $RegPath  -Name $RegKey
    Write-Log """Set the time automatically"" is set to $STA"
    
    if ($STA -ne $RegKeyValue) {
        $ExitCode = 1
    }

    Write-Log " "

    # Check if Location is allowed to be used
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
    $RegKey = "Value"
    $RegKeyValue = "Allow"
    $LocationUse = Get-ItemPropertyValue -Path $RegPath -Name $RegKey
    Write-Log "The use of Location is $LocationUse"

    if ($LocationUse -ne $RegKeyValue) {
        $ExitCode = 1
    }

    Write-Log " "

    # Check if "Set Time Zone Automatically" is activated
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate"
    $RegKey = "Start"
    $RegKeyValue = "3"
    $STZA = Get-ItemPropertyValue -Path $RegPath -Name $RegKey
    
    if ($STZA -eq $RegKeyValue) {
        Write-Log """Set Time Zone Automatically"" is set to ""Enabled"""
    } else {
        Write-Log """Set Time Zone Automatically"" is set to ""Disabled"""
        $ExitCode = 1
    }

    Write-Log " "

    # Get the current time from the NTP server
    $CurrentTime = Get-Date(Get-NtpTime("$(Get-CurrentNtpServer)"))
    Write-Log "The current date and time according to the NtpServer is: $CurrentTime"
    
    # Get the current time from the computer
    $ComputerTime = Get-Date
    Write-Log "The current date and time according to the computer is: $ComputerTime"

    # Check if the difference between the current time and the NTP server time is less than 15 seconds
    if ($CurrentTime.AddSeconds(-15) -lt $ComputerTime -And
    $CurrentTime.AddSeconds(15) -gt $ComputerTime) {
        Write-Log "The Computer date and time is within 30 secods of the Current date and time."
    } else {
        Write-Log "The difference between the Computer date and time and the Current date and time is to large."
        $ExitCode = 1
    }

    Write-Log " "

    If ($ExitCode -eq 1) {
        Write-Log "Triggering the remediation"
    } else {
        Write-Log "No action needed."
    }

    Write-Log " "
    Write-Log "---"
    Write-Log " "

    exit $ExitCode