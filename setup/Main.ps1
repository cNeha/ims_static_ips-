Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

Upgrade-PowerShell.ps1 -Version 5.1 -Username $username -Password $password -Verbose

Set-ExecutionPolicy -ExecutionPolicy Restricted -Force

$reg_winlogon_path = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $reg_winlogon_path -Name AutoAdminLogon -Value 0

Remove-ItemProperty -Path $reg_winlogon_path -Name DefaultUserName -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $reg_winlogon_path -Name DefaultPassword -ErrorAction SilentlyContinue
 
powershell.exe -ExecutionPolicy ByPass Install-WMF3Hotfix.ps1 -Verbose
powershell.exe -ExecutionPolicy ByPass ConfigureRemotingForAnsible.ps1
