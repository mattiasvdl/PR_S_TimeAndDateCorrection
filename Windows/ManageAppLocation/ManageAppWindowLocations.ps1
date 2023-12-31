# Script:
#   Script_ManageAppWindowLocations.ps1
# Author:
#   Mattias Vandelannoote
# Date:
#   2023-12-31
# Description:
#   This script makes use of the NirCmd Command line utility
#   in order to change the size and position of application windows.
#
#   Make sure you have the application NirCmd on your pc and change
#   the variable $NirCmd as needed.
#   
#   You can find the command reference page of NirCmd here:
#   https://nircmd.nirsoft.net/win.html
#
#   Remark:   When you use this script to move windows from one screen to another and the screens don't have the same screen scaling,
#             then the size of the windows will be wrong due to the scaling differences.

# Variables:

    $NirCmd = "$env:ProgramData\MattiasVdl\Utils\nircmd-x64\nircmd.exe"

    $Applications = @(

        # Windows Explorer

        [PSCustomObject]@{
            AppTitle = "Scripts"
            AppX = 64
            AppY = 32
            AppWidth = 320
            AppHeight = 480
        }

        # Website MattiasVdl
        
        [PSCustomObject]@{
            AppTitle = "MattiasVdl"
            AppX = 416
            AppY = 32
            AppWidth = 480
            AppHeight = 640
        }

        # Calculator
        
        [PSCustomObject]@{
            AppTitle = "Calculator"
            AppX = 928
            AppY = 32
            AppWidth = 240
            AppHeight = 320
        }

    )

# Script:

    foreach ($App in $Applications) {

        # First make sure the window is not full screen or minimized.
        Start-Process -NoNewWindow -FilePath $NirCmd -ArgumentList "win normal ititle $($App.AppTitle)"
    
        write-output "win setsize ititle $($App.AppTitle) $($App.AppX) $($App.AppY) $($App.AppWidth) $($App.AppHeight)"
        # Set Window X, Y, Width and Height
        Start-Process -NoNewWindow -FilePath $NirCmd -ArgumentList "win setsize ititle $($App.AppTitle) $($App.AppX) $($App.AppY) $($App.AppWidth) $($App.AppHeight)"

    }