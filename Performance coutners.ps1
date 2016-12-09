#
#
# Performance Counters
#
#

#netsh interface ipv4 show  | Select-String "stats"


Get-Counter -ListSet * | Sort-Object CounterSetName | Select-Object CounterSetName

Get-Counter -ListSet 'SQLAgent:Jobs'


$SQLStats = (Get-Counter -ListSet 'SQLAgent:Jobs').paths 

Get-Counter -Counter $SQLStats | Select-Object  'jobs(_total)\queued jobs','jobs(_total)\failed jobs'


Get-Counter -Counter $SQLStats -SampleInterval 5 -MaxSamples 50 | Select-Object  'jobs(_total)\queued jobs','jobs(_total)\failed jobs' 
Get-Counter -Counter $SQLStats -SampleInterval 5 -Continuous    | Select-Object  'jobs(_total)\queued jobs','jobs(_total)\failed jobs' 




# Export to file - CSV, TSV, BLG
 $JobListExport = @(
        "\SQLAgent:Jobs(_total)\Active jobs"
        ,"\SQLAgent:Jobs(_total)\Successful jobs"
        )

Get-Counter -Counter $JobListExport -SampleInterval 2 -MaxSamples 5 | format-table * 

Get-Counter -Counter $JobListExport -SampleInterval 60 -MaxSamples 5 | Export-Counter -Path C:\DataTK\PerfCounters\PerfExampleC.csv -FileFormat CSV -Force 

Get-Counter -Counter $JobListExport -SampleInterval 2 -MaxSamples 5 | Export-Counter -Path C:\DataTK\PerfCounters\PerfExampleB.blg -FileFormat BLG -Force 


