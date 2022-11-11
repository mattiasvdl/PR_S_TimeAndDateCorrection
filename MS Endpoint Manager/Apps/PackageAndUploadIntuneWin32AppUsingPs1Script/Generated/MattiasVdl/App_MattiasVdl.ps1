# Script:
#   App_MattiasVdl.ps1
# Version:
#   2022-11-10
# Author:
#   Mattias Vandelannoote
# Purpose:
#   Demo script for MattiasVdl.

Add-Type -AssemblyName System.Windows.Forms

# Variables

    $AppName = "MattiasVdl"

# Script

    # Show a message box with the name of the app

        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

        $oReturn=[System.Windows.Forms.Messagebox]::Show("Demo script for $($AppName)")

        switch ($oReturn){
            "Ok" {
                Exit
            } 
        }

exit
