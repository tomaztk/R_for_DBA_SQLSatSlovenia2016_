USE DBA4R;
GO

-- create baseline
 	
SELECT DB_NAME(mf.database_id) AS databaseName , 
    mf.physical_name , 
    divfs.num_of_reads , 
    divfs.num_of_bytes_read , 
    divfs.io_stall_read_ms , 
    divfs.num_of_writes , 
    divfs.num_of_bytes_written , 
    divfs.io_stall_write_ms , 
    divfs.io_stall , 
    size_on_disk_bytes , 
    GETDATE() AS baselineDate 
INTO #baseline 
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs 
    JOIN sys.master_files AS mf ON mf.database_id = divfs.database_id 
          AND mf.file_id = divfs.file_id


-- check the baseline agains the current stats

WITH currentLine 
     AS ( SELECT DB_NAME(mf.database_id) AS databaseName ,
           mf.physical_name , 
           num_of_reads , 
           num_of_bytes_read , 
           io_stall_read_ms , 
           num_of_writes , 
           num_of_bytes_written , 
           io_stall_write_ms , 
           io_stall , 
           size_on_disk_bytes , 
           GETDATE() AS currentlineDate 
     FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs 
           JOIN sys.master_files AS mf 
              ON mf.database_id = divfs.database_id 
                 AND mf.file_id = divfs.file_id 
     ) 
  SELECT currentLine.databaseName , 
     LEFT(currentLine.physical_name, 1) AS drive ,  
     currentLine.physical_name , 
     --gets the time diference in milliseconds since 
     -- the baseline was taken 
     DATEDIFF(millisecond,baseLineDate,currentLineDate) AS elapsed_ms,
       currentLine.io_stall - #baseline.io_stall AS io_stall_ms ,
       currentLine.io_stall_read_ms - #baseline.io_stall_read_ms 
                                       AS io_stall_read_ms ,
       currentLine.io_stall_write_ms - #baseline.io_stall_write_ms 
                                       AS io_stall_write_ms ,
       currentLine.num_of_reads - #baseline.num_of_reads 
                                       AS num_of_reads ,
       currentLine.num_of_bytes_read - #baseline.num_of_bytes_read 
                                       AS num_of_bytes_read , 
       currentLine.num_of_writes - #baseline.num_of_writes 
                                       AS num_of_writes , 
       currentLine.num_of_bytes_written - #baseline.num_of_bytes_written 
                                       AS num_of_bytes_written 
  FROM currentLine 
     INNER JOIN #baseline 
        ON #baseLine.databaseName = currentLine.databaseName 
     AND #baseLine.physical_name = currentLine.physical_name 
  WHERE #baseline.databaseName = 'DBA4R'



-- top 50 shitiest queries

SELECT

	(total_logical_reads + total_logical_writes) AS total_logical_io
	,(total_logical_reads / execution_count) AS avg_logical_reads
	,(total_logical_writes / execution_count) AS avg_logical_writes
	,(total_physical_reads / execution_count) AS avg_phys_reads
	,substring(st.text,(qs.statement_start_offset / 2) + 1,  ((CASE qs.statement_end_offset 
																WHEN - 1 THEN datalength(st.text) 
																ELSE qs.statement_end_offset END  - qs.statement_start_offset) / 2) + 1) AS statement_text
	,*
FROM
		sys.dm_exec_query_stats AS qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY
total_logical_io DESC







-- getting information for each object
SELECT usecounts, cacheobjtype, objtype, text, query_plan, value as set_options
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) 
cross APPLY sys.dm_exec_plan_attributes(plan_handle) AS epa
where text like '%MYTasks%' and attribute='set_options'



SELECT
	 cp.refcounts
	,cp.usecounts
	,cp.objtype
	,st.dbid
	,st.objectid
	,st.text
	,qp.query_plan
FROM 
			sys.dm_exec_cached_plans cp 
CROSS APPLY sys.dm_exec_sql_text ( cp.plan_handle ) AS st 
CROSS APPLY sys.dm_exec_query_plan ( cp.plan_handle ) AS qp ;