
$account="new_local_account"
$pass="password"
$scht="migetu"
$path="C:\scripts"
$scrfile=$path+"\setnet.ps1"
$diskfile=":\diskfilemig.txt"

if (!(get-item $path -ErrorAction SilentlyContinue)) { New-Item "C:\scripts" -Type directory -path $path }

New-LocalUser -Name $account -Password (ConvertTo-SecureString -String $pass -AsPlainText -Force)
Add-LocalGroupMember -Group Administrators -Member $account

Get-NetAdapter | % { 
    write-output ("`$ifi=(get-netadapter | where { `$_.macaddress -like '"+$_.macaddress+"' }).interfaceindex") > $scrfile
    Get-NetIPAddress -InterfaceIndex $_.ifIndex | where {$_.prefixorigin -like "Manual" -or $_.suffixorigin -like "Manual"} | % {
       write-output( "New-NetIPAddress -InterfaceIndex `$ifi -IPAddress '"+$_.IPAddress+"' -prefixlength "+$_.PrefixLength) >> $scrfile
    }
    Set-NetIPInterface -InterfaceIndex $_.ifIndex -Dhcp Enabled
    Get-NetRoute -InterfaceIndex $_.interfaceindex | where { $_.nexthop -notlike "0.0.0.0" -and $_.DestinationPrefix -like "*.*" } | % {
       write-output( "new-NetRoute -InterfaceIndex `$ifi -DestinationPrefix '"+$_.DestinationPrefix+"' -NextHop '"+$_.NextHop+"'") >> $scrfile
    }
    $a=(Get-DnsClientServerAddress -InterfaceIndex $_.ifIndex | where { $_.addressfamily -eq 2}).serveraddresses
    write-output("Set-DnsClientServerAddress -InterfaceIndex `$ifi -ServerAddresses '"+$a[0]+"','"+$a[1]+"'") >> $scrfile

    Set-NetIPInterface -InterfaceIndex $_.ifIndex -Dhcp Enabled
}

write-output("Get-Disk | where { `$_.OperationalStatus -like 'Offline' } | % {") >> $scrfile
write-output("   `$_ | Set-Disk -IsOffline `$false") >> $scrfile
write-output("   `$_ | Set-Disk -IsReadOnly `$false") >> $scrfile
write-output("}") >> $scrfile

write-output("`$a=(Get-Item env:systemdrive).value.substring(0,1)") >> $scrfile
write-output("get-partition | where { `$_.DriveLetter -notlike `$a -and `$_.driveletter.length -gt 0 } | % { Remove-PartitionAccessPath -DiskNumber `$_.DiskNumber -PartitionNumber `$_.PartitionNumber -AccessPath (`$_.driveletter+':')}") >> $scrfile

write-output("`$c=Get-WmiObject win32_volume -filter drivetype=5") >> $scrfile
$d=Get-Volume | where {$_.DriveType -like "CD-ROM"}
if ( $d -isnot [array] ) {
   Write-Output("`$a=`$c") >> $scrfile
   Write-Output("`$a.driveletter='"+$d.driveletter+":'") >> $scrfile
   Write-Output("`$a.put()") >> $scrfile
}
else {
   $b=0;
#   $d | % { 
#      Write-Output("`$a=`$c[$b]") >> $scrfile
#      Write-Output("`$a.driveletter='"+$_.driveletter+":'") >> $scrfile
#      Write-Output("`$a.put()") >> $scrfile
#      $b=$b+1
#   }
   Write-Output("`$a=`$c[$0]") >> $scrfile
   Write-Output("`$a.driveletter='"+$_.driveletter+":'") >> $scrfile
   Write-Output("`$a.put()") >> $scrfile
}


Get-Volume | where {$_.DriveType -notlike "CD-ROM" -and $_.SizeRemaining -gt 0 -and $_.DriveLetter.length -gt 0} | % { 
   $a=$_.driveletter+$diskfile
   Write-Output($_.driveletter) > $a
}


write-output("Get-Partition | where { ([int]`$_.driveletter) -eq 0} | % {") >> $scrfile
write-output("   for (`$a=68; `$a -le 90; `$a=`$a+1) {") >> $scrfile
write-output("      if ((get-volume | where {`$_.DriveLetter -eq `$a} | measure).count -eq 0) { break }") >> $scrfile
write-output("   }") >> $scrfile
write-output("   `$_ | set-partition -NewDriveLetter ([char]`$a)") >> $scrfile
write-output("   `$str=[string]([char]`$a)+'$diskfile'") >> $scrfile
write-output("   if ((Get-item `$str -ErrorAction SilentlyContinue | measure).count -eq 0) { Remove-PartitionAccessPath -DiskNumber `$_.DiskNumber -PartitionNumber `$_.PartitionNumber -AccessPath (([char]`$a)+':')}") >> $scrfile
write-output("   else { ") >> $scrfile
write-output("      `$str=[char](Get-Content `$str)") >> $scrfile
write-output("      Set-Partition -DriveLetter ([char]`$a) -NewDriveLetter `$str") >> $scrfile
write-output("   }") >> $scrfile
write-output("}") >> $scrfile

$a="-ExecutionPolicy Bypass -File "+$scrfile
Register-ScheduledTask $scht -action (New-ScheduledTaskAction -Execute "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe" -Argument $a) -Trigger (New-ScheduledTaskTrigger -Once -at (get-date).date -RepetitionInterval (New-TimeSpan -Minutes 10) -RepetitionDuration (New-TimeSpan -Hours 24)) -RunLevel Highest -user $account -Password $pass
write-output("Disable-ScheduledTask $scht") >> $scrfile
