#get current values
$CurrentMSRDCKeyPresent = Test-Path -Path "HKLM:\Software\Microsoft\MSRDC\Policies"
$CurrentAutoUpdatesSetting = Get-ItemProperty -Path "HKLM:\Software\Microsoft\MSRDC\Policies" -Name AutomaticUpdates -ErrorAction SilentlyContinue | Select-Object AutomaticUpdates

#case 1 - No reg key present at all
if (!$CurrentMSRDCKeyPresent){
    try{
        Write-Host "Creating Reg Keys and Reg Item since it wasn't initially detected"
        New-Item -Path "HKLM:\Software\Microsoft" -Name MSRDC
        New-Item -Path "HKLM:\Software\Microsoft\MSRDC" -Name Policies
        New-ItemProperty -Path "HKLM:\Software\Microsoft\MSRDC\Policies" -Name AutomaticUpdates -PropertyType DWORD -Value 0
        Exit 0
     }
     Catch {
        Write-Host "Error Creating Reg Key"
        Write-error $_
        Exit 1
     }
}

#case 2 - Reg key present, but no reg item present
elseif (!$CurrentAutoUpdatesSetting){
    try{
        Write-Host "Creating Reg Item since it wasn't initially detected"
        New-ItemProperty -Path "HKLM:\Software\Microsoft\MSRDC\Policies" -Name AutomaticUpdates -PropertyType DWORD -Value 0
        Exit 0
     }
     Catch {
        Write-Host "Error Creating Reg Item"
        Write-error $_
        Exit 1
     }
}

#case 3 - Reg key and reg item present, but the value was wrong
elseif ($CurrentAutoUpdatesSetting.AutomaticUpdates -ne 0){
    try{
        Write-host "Reg item already exists, but the value is wrong. Fixing this now."
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\MSRDC\Policies" -Name AutomaticUpdates -Value 0
        Exit 0
    }
    catch{
        Write-Host "Error Updating Reg Item"
        Write-error $_
        Exit 1
    }
}

#case 4 - All is correct
elseif ($CurrentAutoUpdatesSetting.AutomaticUpdates -eq 0){
    try{
        Write-host "Registry is correct - Good to go!"
        Exit 0
    }
    catch{
        Write-Host "Error Creating Reg Item"
        Write-error $_
        Exit 1
    }
}