#
#
# Disk space
#
#

# Wrapper around
# $computer_list = computers.txt


# Test cdmlet
Get-WmiObject Win32_LogicalDisk -computer 'SICN-KASTRUN' | Select SystemName,DeviceID,VolumeName,Size,FreeSpace | Format-Table




$conn=new-object System.Data.SqlClient.SQLConnection 
$ConnectionString = "Server=SICN-KASTRUN;Database=DBA4R;Integrated Security=True;Connect Timeout=0"
$conn.ConnectionString=$ConnectionString 
$conn.Open()

$isFirst = $true
$commandText = "INSERT INTO DiskSpace(SystemName,DeviceID,Size,FreeSpace) VALUES"

$wmiObject = Get-WmiObject Win32_LogicalDisk -computer 'SICN-KASTRUN' 
Foreach ($logicalDisk in $wmiObject)
{
    if($isFirst) { $isFirst = $false } else { $commandText += "," }
    $commandText += " ('"  + $logicalDisk["SystemName"] + "','"+ $logicalDisk["DeviceID"] +"','"+ $logicalDisk["Size"] +"','"+ $logicalDisk["FreeSpace"] +"')"
}

$command = $conn.CreateCommand()
$command.CommandText = $commandText
#$command.ExecuteNonQuery()
$command.ExecuteReader()

Write-Output $commandText

$conn.Close()
