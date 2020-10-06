Param (
      [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Enter the Logon ID you want information about")]
      [String]$SamAccountName
)

switch ("" -eq $SamAccountName) {
      $true {
            do {
                  $SamAccountName = Read-Host "Enter the Logon ID you want information about"
            } while ($Null -eq $SamaccountName)  
      }
}

do {
      try {
            $ADInfo = Get-ADUser -Identity $SamAccountName -Properties * -ErrorAction Stop
            $SamAccountNameOK = $true
      }
      catch {
            Write-Host "That Logon ID is invalid"
            $SamAccountName = Read-Host "Enter the Logon ID you want information about"
            $SamAccountNameOK = $false
      }
} until ($SamAccountNameOK -eq $true)



Switch ($ADInfo.AccountExpirationDate) {
      { $PSItem -eq $Null } {
            Add-Member -InputObject $ADInfo -MemberType NoteProperty -Name "AcctExpires" -Value $false -Force
      }
      { $PSItem -ne $Null } {
            Add-Member -InputObject $ADInfo -MemberType NoteProperty -Name "AcctExpires" -Value $true -Force
            $AcctExpirationSpan = (New-TimeSpan -Start $ADInfo.AccountExpirationDate -End (get-Date))
            Add-Member -InputObject $ADInfo -MemberType NoteProperty -Name "ExpirationSpan" -Value $AcctExpirationSpan -Force
      }
      Default {}
}

Write-host "AD Info" -ForegroundColor Cyan

'{0,20} {1}' -f "Logon ID:", $ADInfo.SamAccountName
'{0,20} {1}' -f "Name:", $ADInfo.name
'{0,20} {1}' -f "First Name:", $ADInfo.givenname
'{0,20} {1}' -f "Last Name:", $ADInfo.surname
'{0,20} {1}' -f "Department:", $ADInfo.department
'{0,20} {1}' -f "Title:", $ADInfo.description
'{0,20} {1}' -f "Manager:", $ADInfo.Manager
Write-Host "`n`n"

Write-Host "Account Status" -ForegroundColor Cyan
'{0,20} {1}' -f "Enabled:", $ADInfo.Enabled
switch ($ADInfo.Lockedout) {
      $true {
            Write-Host "         Locked Out:" -NoNewline
            Write-Host " True" -ForegroundColor Red
      }
      $false {
            Write-Host "         Locked Out:" -NoNewline
            Write-Host " False" -ForegroundColor Green
      }
}

Switch ($ADInfo.AcctExpires) {
      $false {
            '{0,20} {1}' -f "Acct Expires:", "False"
      }
      $true {
            '{0,20} {1}' -f "Acct Expires:", "True"
            switch ($ADInfo.ExpirationSpan) {
                  { $PSItem -gt 0 } {
                        Write-Host "       Acct Expired:" -NoNewline
                        Write-Host "True" -ForegroundColor Red -NoNewline
                        Write-Host " (Account expired ($ADInfo.ExpirationSpan) day(s) ago"
                  }
                  { $PSItem -lt 0 } {
                        Write-Host "       Acct Expired:" -NoNewline
                        Write-Host "True" -ForegroundColor Red -NoNewline
                        Write-Host "Account will expire in ($ADInfo.ExpirationSpan) day(s)"
                  }
            }
      }
}

'{0,20} {1}' -f "Acct Created:", $ADInfo.whenCreated
'{0,20} {1}' -f "Acct Changed:", $ADInfo.whenChanged
Write-Host "`n`n"

$GroupsInfo = [System.Collections.ArrayList]::new()
foreach ($item in ($ADInfo.memberof) ) {
      $groupinfo = Get-ADGroup -Identity $item
      $i = New-Object psobject
      Add-Member -InputObject $i -MemberType NoteProperty -Name GroupName -Value $groupinfo.Name
      Add-Member -InputObject $i -MemberType NoteProperty -Name Category -Value $groupinfo.groupcategory
      $null = $GroupsInfo.Add($i)
}

$SecGrpList = $GroupsInfo|Where-Object {$PSItem.category -eq "Security"}|Select-Object GroupName
$DistGrpList = $GroupsInfo|Where-Object {$PSItem.category -eq "Distribution"}|Select-Object GroupName


Write-Host "Security Groups" -ForegroundColor Cyan
$SecGrpList.GroupName
Write-Host "`n`n"
Write-Host "Distribution Lists" -ForegroundColor Cyan
$DistGrpList.GroupName
Write-Host "`n`n"