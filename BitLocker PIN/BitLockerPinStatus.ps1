#Get BitLocker info
$bitLockerVolumes = Get-BitLockerVolume

#create array
$BitLockerState = new-object -TypeName PSObject

#loop through each BitLocker Volume to get key protector info for each drive
foreach ($bitLockerVolume in $bitLockerVolumes) {

    $keyProtectors = $bitLockerVolume.KeyProtector

#look at each prtotector to see if it's a PIN type.
    foreach ($keyProtector in $keyProtectors){

        If ($keyProtector.KeyProtectorType -eq "TpmPin") {
            $keyProtectorId = $keyProtector.KeyProtectorId
            $keyProtectorType = $keyProtector.KeyProtectorType
            $pinset = "True"
            $pinCreationEventLogs = Get-WinEvent -LogName 'Microsoft-Windows-Bitlocker/Bitlocker Management' | Where-Object {($_.id -eq "775") -and ($_.message -like "*$keyProtectorId*")}

            foreach ($pinCreationEvent in $pinCreationEventLogs){
                $pinCreationTime = $pinCreationEvent.TimeCreated
                $pinCreationUserSid = $pinCreationEvent.userid
                $pinCreationUser = $pinCreationUserSid.Translate([System.Security.Principal.NTAccount])
            }
        }
        else {
            $pinset = "False"
            $pinCreationTime = $null
            $pinCreationUserSid = $null
            $pinCreationUser = $null
            $keyProtectorId = $null
            $keyProtectorType = $null
        }
    }

}

#create the PSObject that ontains data to be sent to Log Analytics
$BitLockerState | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $bitLockerVolume.ComputerName
$BitLockerState | Add-Member -MemberType NoteProperty -Name "MountPoint" -Value $bitLockerVolume.MountPoint
$BitLockerState | Add-Member -MemberType NoteProperty -Name "EncryptionMethod" -Value $bitLockerVolume.EncryptionMethod
$BitLockerState | Add-Member -MemberType NoteProperty -Name "PinIsSet" -Value $pinset
$BitLockerState | Add-Member -MemberType NoteProperty -Name "LastPinCreationTime" -Value $pinCreationTime
$BitLockerState | Add-Member -MemberType NoteProperty -Name "PinCreationUser" -Value $pinCreationUser
$BitLockerState | Add-Member -MemberType NoteProperty -Name "KeyProtectorID" -Value $keyProtectorId
$BitLockerState | Add-Member -MemberType NoteProperty -Name "KeyProtectorType" -Value $keyProtectorType
