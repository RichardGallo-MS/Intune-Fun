<#
#This Sample Code is provided for the purpose of illustration only
#and is not intended to be used in a production environment.  THIS
#SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT
#WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
#LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
#FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free
#right to use and modify the Sample Code and to reproduce and distribute
#the object code form of the Sample Code, provided that You agree:
#(i) to not use Our name, logo, or trademarks to market Your software
#product in which the Sample Code is embedded; (ii) to include a valid
#copyright notice on Your software product in which the Sample Code is
#embedded; and (iii) to indemnify, hold harmless, and defend Us and
#Our suppliers from and against any claims or lawsuits, including
#attorneys' fees, that arise or result from the use or distribution
#of the Sample Code.
#>
<#
Pre-requisites
You need to have MGGRaph module installed
Install-Module -Name Microsoft.Graph
Need to have a registered App with delegated permissions.
Scopes needed
DeviceManagementApps.ReadWrite.All
User.Read
#>

#Variables and configs needed
$TenantID = "enter tenant ID here"
$ClientID = "eneter client ID here"
$global:userID = $null

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$conTest = Get-MgContext
if($null -eq $conTest -or $conTest -eq ""){
    Connect-MgGraph -TenantId $TenantID -ClientId $ClientID
    Select-MgProfile -Name beta
}

function alertPopUp ([string] $alert){
    [System.Windows.Forms.MessageBox]::Show($null,$alert,"Alert!")
}

#Get User GUID from AAD based on UPN
function retrievedata{
    if(![string]::IsNullOrEmpty($txtBoxUPN.Text)){
        $dataGridView.Rows.Clear()
        $dgvData = @{}
        if($null -ne $txtBox.Text -or $txtBox.Text -ne ""){
            try{
                $user = Get-MgUser -Filter "UserPrincipalName eq '$($txtBoxUPN.Text)'"
                $global:userID = $user.Id
                $URI = "https://graph.microsoft.com/beta/users('$($global:userID)')/managedAppRegistrations?select=deviceTag,deviceName,lastSyncDateTime,azureADDeviceId,deviceModel"
                $QueryResults = @()
                do {
                    $Results = Invoke-MGGraphRequest -Uri $URI -Method GET
                    if ($Results.value) {
                        $QueryResults += $Results.value
                    }
                    else {
                        $QueryResults += $Results
                    }
                    $URI = $Results.'@odata.nextlink'
                } until (!($URI))
                #Iterates through found objects and builds a unique DeviceTag list
                foreach($QueryResult in $QueryResults){
                    if(!$dgvData.ContainsKey($QueryResult.deviceTag)){
                        $dgvData.Add($QueryResult.deviceTag,$QueryResult.deviceModel)
                        $dataGridView.Rows.Add($QueryResult.azureADDeviceId,$QueryResult.deviceName,$QueryResult.deviceModel,$QueryResult.deviceTag,$QueryResult.lastSyncDateTime)
                    }
                }
            }
            catch{
                $exception = $_.Exception
                alertPopUp -alert "Issue with finding User ID. $exception"
            }
        }
    }
    else{
        alertPopUp -alert "***Please specify a valid UPN***"
        $txtBoxUPN.Text = $null
        $txtBoxUPN.Select()
    }
}

function wipeSelectedData{
    #Process DeviceTags and initiate a selective wipe #https://learn.microsoft.com/en-us/graph/api/intune-shared-user-wipemanagedappregistrationbydevicetag?view=graph-rest-beta
    foreach($dgviewRow in $dataGridView.Rows){
        $returnVar = $null
        $params = @{}
        if($dgviewRow.Cells["Selected Action"].Value -eq $true){
            try{
                $params.Add("deviceTag",$dgviewRow.Cells["Device Tag"].Value)
                $newURI = "https://graph.microsoft.com/beta/users/{$($global:userID)}/wipeManagedAppRegistrationByDeviceTag"
                $returnVar = Invoke-MgGraphRequest -Uri $newURI -Method POST -Body $params -OutputType HttpResponseMessage
                $lblStat2.Text = $returnVar.IsSuccessStatusCode
            }
            catch{
                $exception = $_.Exception
                alertPopUp -alert "Issue with Device Tag:$($dgviewRow.Cells["Device Tag"].Value). $exception"
            }
        }
    }
}

#Windows Form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Selective wipe data tool'
$form.Size = New-Object System.Drawing.Size(675,500)
$form.StartPosition = 'CenterScreen'
$form.AutoSize = $true
$form.AutoScale = $true
$loadButton = New-Object System.Windows.Forms.Button
$loadButton.Location = New-Object System.Drawing.Point(25,450)
$loadButton.Size = New-Object System.Drawing.Size(75,23)
$loadButton.Text = 'Get Data'
$loadButton_OnClick = {
    retrievedata
}
$loadButton.add_click($loadButton_OnClick)
$form.Controls.Add($loadButton)
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(105,450)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'Wipe Selected'
$okButton_OnClick = {
    wipeSelectedData
}
$okButton.add_click($okButton_OnClick)
$form.Controls.Add($okButton)
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(190,450)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)
$txtLbl = New-Object System.Windows.Forms.Label
$txtLbl.Name = "UPN"
$txtLbl.Text = "User's UPN:"
$txtLbl.AutoSize = $true
$txtLbl.Location = New-Object System.Drawing.Point(70,250)
$txtLbl.Size = New-Object System.Drawing.Size(100,23)
$form.Controls.Add($txtLbl)
$txtBoxUPN = New-Object System.Windows.Forms.TextBox
$txtBoxUPN.Text = ""
$txtBoxUPN.Size = New-Object System.Drawing.Size(200,23)
$txtBoxUPN.Location = New-Object System.Drawing.Point(150,250)
$form.Controls.Add($txtBoxUPN)

$lblStat1 = New-Object System.Windows.Forms.Label
$lblStat1.Name = "Status"
$lblStat1.Text = "Status:"
$lblStat1.AutoSize = $true
$lblStat1.Location = New-Object System.Drawing.Point(70,350)
$lblStat1.Size = New-Object System.Drawing.Size(100,23)
$form.Controls.Add($lblStat1)
$lblStat2 = New-Object System.Windows.Forms.Label
$lblStat2.Text = ""
$lblStat2.Size = New-Object System.Drawing.Size(400,400)
$lblStat2.Location = New-Object System.Drawing.Point(150,350)
$form.Controls.Add($lblStat2)

#DataGridView for Device Tag Info
$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.ColumnCount = 5
$dataGridView.ColumnHeadersVisible = $true
$datagridview.ReadOnly = $false
$datagridview.AllowUserToAddRows = $false
$chkBox = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$chkBox.Name = "Selected Action"
$dataGridView.Columns.Add($chkBox)
$dataGridView.Columns["Selected Action"].DisplayIndex = 0
$dataGridView.Columns[0].Name = "Azure AD Device ID"
$dataGridView.Columns[1].Name = "Device Name"
$dataGridView.Columns[2].Name = "Device Model"
$dataGridView.Columns[3].Name = "Device Tag"
$dataGridView.Columns[4].Name = "Last Sync Date Time"
$dataGridView.Columns | Foreach-Object{
    $_.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
}
$form.Controls.Add($dataGridView)
$dataGridView.AutoSize = $true
$form.TopMost = $true
$form.Add_Shown({$txtBoxUPN.Select()})
$result = $form.ShowDialog()
#End DataGrid View
