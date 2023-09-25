
#check if reg key exists and set variable accordingly
$CurrentAutoUpdatesSettingsPresent = Test-Path -Path "HKLM:\Software\Microsoft\MSRDC\Policies"


if (!$CurrentAutoUpdatesSettingsPresent){
    
    $CurrentAutoUpdatesSetting = $null

}
else {

    $CurrentAutoUpdatesSetting = Get-ItemProperty -Path "HKLM:\Software\Microsoft\MSRDC\Policies" -Name AutomaticUpdates -ErrorAction SilentlyContinue | Select-Object AutomaticUpdates

}


#check value of the reg item and determine if remediation is needed
if ($CurrentAutoUpdatesSetting.AutomaticUpdates -eq 0){
    Write-Host "Registry is correct. No changes needed!"
    exit 0
}
else{
    Write-Host "Registry is NOT correct. Changes needed!"
    exit 1
    
}