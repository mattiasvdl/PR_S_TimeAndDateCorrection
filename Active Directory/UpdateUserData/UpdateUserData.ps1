$csvDataFile = Import-Csv -Delimiter "," -Path "C:\Temp\ADInformationUpdate.csv" -Encoding Default

foreach($record in $csvDataFile){

    # Find user
    $ADUser = Get-ADUser -Filter "userPrincipalName -eq '$($record.UserPrincipalName)'"

    if ($ADUser){
        Write-Output $record.UserPrincipalName
        Set-ADUser -Identity $ADUser -Clear "streetAddress"   # StreetAddress
        Set-ADUser -Identity $ADUser -Clear "st"   # State
        Set-ADUser -Identity $ADUser -Clear "l"   # City
        Set-ADUser -Identity $ADUser -Clear "postalCode"   # PostalCode

        if ($record.Title) {
            Set-ADUser -Identity $ADUser -replace @{title=$record.Title}   # Title
        } else {
            Set-ADUser -Identity $ADUser -Clear "title"
        }

        if ($record.Department) {
            Set-ADUser -Identity $ADUser -replace @{department=$record.Department}   # Department
        } else {
            Set-ADUser -Identity $ADUser -Clear "department"
        }

        if ($record.ManagerDisplayName) {
            $Manager = (Get-ADUser -Filter "displayname -eq '$($record.ManagerDisplayName)'").distinguishedName

            if ($Manager) {
                Set-ADUser -Identity $ADUser -replace @{manager=$Manager}   # Manager
            }

        } else {
            Set-ADUser -Identity $ADUser -Clear "department"
        }

        if ($record.Office) {
            Set-ADUser -Identity $ADUser -replace @{physicalDeliveryOfficeName=$record.Office}   # Office
        } else {
            Set-ADUser -Identity $ADUser -Clear "physicalDeliveryOfficeName"
        }

        if ($record.c) {
            Set-ADUser -Identity $ADUser -replace @{c=$record.c}   # Country (ex. BE)
            Set-ADUser -Identity $ADUser -replace @{msExchUsageLocation=$record.c}
        } else {
            Set-ADUser -Identity $ADUser -Clear "c"
        }

        if ($record.co) {
            Set-ADUser -Identity $ADUser -replace @{co=$record.co}   # Country (ex. Belgium)
        } else {
            Set-ADUser -Identity $ADUser -Clear "co"
        }

        if ($record.countryCode) {
            Set-ADUser -Identity $ADUser -replace @{countryCode=$record.countryCode}   # Country (ex. 56)
        } else {
            Set-ADUser -Identity $ADUser -Clear "countryCode"
        }

        if ($record.MobilePhone) {
            Set-ADUser -Identity $ADUser -replace @{mobile=$record.MobilePhone}   # MobilePhone
        } else {
            Set-ADUser -Identity $ADUser -Clear "mobile"
        }

        if ($record.OfficePhone) {
            Set-ADUser -Identity $ADUser -replace @{telephoneNumber=$record.OfficePhone}   # OfficePhone
        } else {
            Set-ADUser -Identity $ADUser -Clear "telephoneNumber"
        }
    }else{
        Write-Warning ("Failed to update " + $($record.UserPrincipalName))
    }
}