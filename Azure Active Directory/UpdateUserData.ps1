Connect-AzureAD

$csvDataFile = Import-Csv -Delimiter ";" -Path "C:\Temp\AAD\ADInformationUpdate.csv"

foreach($record in $csvDataFile){

    Write-Output $record.UserPrincipalName

    if ($record.c) {
        Set-AzureADUser -ObjectId $record.UserPrincipalName -UsageLocation $record.c
    }
}

Disconnect-AzureAD