# Script:
#   {appScript}
# Version:
#   {version}
# Author:
#   {author}
# Purpose:
#   Demo script for {appName}.

Add-Type -AssemblyName System.Windows.Forms

# Variables

    $AppName = "{appName}"

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