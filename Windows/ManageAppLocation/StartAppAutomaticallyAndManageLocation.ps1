# Script:
#   Script_StartAppAutomaticallyAndManageLocation.ps1
# Author:
#   Mattias Vandelannoote
# Date:
#   2023-12-31
# Description:
#   This script is used to start the necessary applications
#   After the applications have started, the script is called to set the position of the windows automatically.

# Variables:

$NirCmd = "$env:ProgramData\MattiasVdl\Utils\nircmd-x64\nircmd.exe"

$Applications = @(

    # Windows Explorer

    [PSCustomObject]@{
        AppName = "Windows Explorer"
        AppLaunchCommand = Invoke-Item "C:\ProgramData\MattiasVdl\Scripts"
    }

    # Website MattiasVdl
    
    [PSCustomObject]@{
        AppName = "Windows Explorer"
        AppLaunchCommand = Start-Process msedge '--new-window "https:\\www.mattiasvdl.be"'
    }

    # Calculator
    
    [PSCustomObject]@{
        AppName = "Calculator"
        AppLaunchCommand = Start-Process calc.exe
    }

)

# Script:

    foreach ($App in $Applications) {

        #$App.AppLaunchCommand

    }

    # Slight hold to make sure the application is opened and the window can be found.
    Start-Sleep -Milliseconds 500

    # Call the script to put the windows in the correct location
    $scriptPath = "$env:ProgramData\MattiasVdl\Scripts\ManageAppWindowLocations.ps1"
    Invoke-Expression $scriptPath