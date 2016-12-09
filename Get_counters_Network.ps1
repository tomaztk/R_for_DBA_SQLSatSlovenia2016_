#
#
# Network statistics
#
#


Get-NetAdapter

Get-NetAdapterStatistics

Get-NetAdapter | Get-NetAdapterStatistics | format-list *

Get-NetAdapterStatistics | Select ifAlias,ReceivedBytes, ReceivedUnicastPackets, SentBytes, SentUnicastPackets | format-list *



$conn=new-object System.Data.SqlClient.SQLConnection 
$ConnectionString = "Server=SICN-KASTRUN;Database=DBA4R;Integrated Security=True;Connect Timeout=0"
$conn.ConnectionString=$ConnectionString 
$conn.Open()

$isFirst = $true
$commandText = "INSERT INTO NetworkStatistics(ifAlias,ReceivedBytes, ReceivedUnicastPackets, SentBytes, SentUnicastPackets) VALUES"

$nasObject = Get-NetAdapterStatistics  #-Name "Wi-Fi 2"
Foreach ($Name in $nasObject)
{
    if($isFirst) { $isFirst = $false } else { $commandText += "," }
    $commandText += " ('"  + $Name.ifAlias + "','"+ $Name.ReceivedBytes +"','"+ $Name.ReceivedUnicastPackets +"','"+ $Name.SentBytes +"','"+ $Name.SentUnicastPackets +"')"
}

$command = $conn.CreateCommand()
$command.CommandText = $commandText
$command.ExecuteReader()

Write-Output $commandText

$conn.Close()
