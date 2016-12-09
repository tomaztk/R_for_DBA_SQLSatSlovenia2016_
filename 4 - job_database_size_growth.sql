
/*
-- create several jobs for showing the "independance"
-- show report for the timeline of these jobs 
*/


USE MSDB;
GO


BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Job1_W30S_5MIN', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'SPAR\si01017988', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'1. Step', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @i int = 10
while @i > (select floor(rand()*10))
	begin
		waitfor delay ''00:00:30''
		select 11
		set @i = @i -1 
	end', 
		@database_name=N'DBA4R', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Sche1', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20161209, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'18980124-3ec9-4359-b1dd-2a4fe32b21c0'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Job2_W15S_1MIN', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'SPAR\si01017988', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'1. Step', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @i int = 10
				 while @i > (select floor(rand()*10))
				 begin
				 waitfor delay ''00:00:10''
				select 11
				set @i = @i -1 
				end', 
		@database_name=N'DBA4R', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Sche2', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20161209, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'4aa2bf7d-a238-46fd-9318-78725d624bc7'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO



BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Job3_1Hour', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'SPAR\si01017988', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'1.Step', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SELECT 1', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'sh3', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20161209, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'e2736f95-b50a-4a7d-ac54-c70a26bc858a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Job4_Fails', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'SPAR\si01017988', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'1.Step', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'WAITFOR DELAY ''00:24:00
SELEC 1', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Sh4', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20161209, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'cf4b2106-7752-4907-8637-914929ece553'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO




/*
--  create fix size database, no growth...and create a job...job is adding 1 MB per run.... and creating some random deletes...
--  do statistics, showing when you will most likely to run out of disk
*/


-- Let's create database with fixed lenght

SET NOCOUNT ON;

USE master;
GO


CREATE DATABASE FixSizeDB
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'FixSizeDB', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\FixSizeDB.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 0)
 LOG ON 
( NAME = N'FixSizeDB_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\FixSizeDB_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

ALTER DATABASE [FixSizeDB] SET COMPATIBILITY_LEVEL = 130
GO


USE FixSizeDB;
GO

-- drop table DataPack
-- drop table DataPack_Info_SMALL

-- create a table
CREATE TABLE DataPack
	(
	  DataPackID BIGINT IDENTITY NOT NULL
	 ,col1 VARCHAR(1000) NOT NULL
	 ,col2 VARCHAR(1000) NOT NULL
	 )


-- check space used
SP_SPACEUSED N'DataPack'

/* 
name		rows					reserved	data	index_size	unused
DataPack	0                   	0 KB		0 KB	0 KB		0 KB
*/


-- let's insert 1000 rows
-- populate data
DECLARE @i INT = 1;
BEGIN TRAN
	WHILE @i <= 1000
		BEGIN
			INSERT dbo.DataPack(col1, col2)
				SELECT 
					  REPLICATE('A',200)
					 ,REPLICATE('B',300);
			SET @i = @i + 1;
		END
COMMIT;
GO


-- check space used again
SP_SPACEUSED N'DataPack'

/*

name		rows					reserved	data	index_size	unused
DataPack	1000                	712 KB		680 KB	8 KB		24 KB
*/



-- using allocation_units sys table
SELECT 
    t.NAME AS TableName
    ,s.Name AS SchemaName
    ,p.rows AS RowCounts
    ,SUM(a.total_pages) * 8 AS TotalSpaceKB
    ,SUM(a.used_pages) * 8 AS UsedSpaceKB
    ,(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM 
    sys.tables t
INNER JOIN sys.indexes AS i 
	ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions AS p 
	ON i.object_id = p.OBJECT_ID 
	AND i.index_id = p.index_id
INNER JOIN sys.allocation_units AS a 
	ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas AS s 
	ON t.schema_id = s.schema_id

WHERE 
	     t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
	AND t.Name = 'DataPack'
GROUP BY t.Name, s.Name, p.Rows


/*
-- or using dmv: dm_db_index_physical_stats
SELECT
     i.name	 AS IndexName
    ,SUM(page_count * 8) AS PageSizeKB
FROM 
	sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.DataPack'), NULL, NULL, 'DETAILED') AS s
	JOIN sys.indexes AS i
	ON s.[object_id] = i.[object_id] 
	AND s.index_id = i.index_id

GROUP BY i.name
ORDER BY i.name
*/



-- creating log table
SELECT 
    t.NAME AS TableName
    ,s.Name AS SchemaName
    ,p.rows AS RowCounts
    ,SUM(a.total_pages) * 8 AS TotalSpaceKB
    ,SUM(a.used_pages) * 8 AS UsedSpaceKB
    ,(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
	,GETDATE() AS TimeMeasure

INTO dbo.DataPack_Info_SMALL

FROM 
    sys.tables AS t
INNER JOIN sys.indexes AS i 
	ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions AS p 
	ON i.object_id = p.OBJECT_ID 
	AND i.index_id = p.index_id
INNER JOIN sys.allocation_units AS a 
	ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas AS s 
	ON t.schema_id = s.schema_id

WHERE 
	     t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
	AND t.name = 'DataPack'
    AND i.OBJECT_ID > 255 
GROUP BY t.Name, s.Name, p.Rows
ORDER BY  t.Name


-- let's check the info table

SELECT * FROM dbo.DataPack_Info_SMALL

-- loop through the data
-- and run table size

-- it should fail at 8th step when step is 1000 rows
DECLARE @nof_steps INT = 0

WHILE @nof_steps < 15
BEGIN
	BEGIN TRAN
		-- insert some data
		DECLARE @i INT = 1;
		WHILE @i <= 1000 -- step is 100 rows
					BEGIN
						INSERT dbo.DataPack(col1, col2)
							SELECT 
								  REPLICATE('A',FLOOR(RAND()*200))
								 ,REPLICATE('B',FLOOR(RAND()*300));
						SET @i = @i + 1;
					END
			

		-- run statistics on table
		INSERT INTO dbo.DataPack_Info_SMALL
		SELECT 
			t.NAME AS TableName
			,s.Name AS SchemaName
			,p.rows AS RowCounts
			,SUM(a.total_pages) * 8 AS TotalSpaceKB
			,SUM(a.used_pages) * 8 AS UsedSpaceKB
			,(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
			,GETDATE() AS TimeMeasure
		FROM  
				sys.tables AS t
			INNER JOIN sys.indexes AS i 
			ON t.OBJECT_ID = i.object_id
			INNER JOIN sys.partitions AS p 
			ON i.object_id = p.OBJECT_ID 
			AND i.index_id = p.index_id
			INNER JOIN sys.allocation_units AS a 
			ON p.partition_id = a.container_id
			LEFT OUTER JOIN sys.schemas AS s 
			ON t.schema_id = s.schema_id

		WHERE 
				 t.NAME NOT LIKE 'dt%' 
			AND t.is_ms_shipped = 0
			AND t.name = 'DataPack'
			AND i.OBJECT_ID > 255 
		GROUP BY t.Name, s.Name, p.Rows
	
		WAITFOR DELAY '00:00:02'

	COMMIT;

END
-- Duration 00:00:35



-- let's check the content
SELECT
*
--INTO AdventureWorks.dbo.DataPack_Info_SMALL_bck
FROM DataPack_Info_SMALL



-- Do some R


-- and run statistical correlation between
DECLARE @RScript nvarchar(max)
SET @RScript = N'
				 library(Hmisc)	
				 mydata <- InputDataSet
				 all_sub <- mydata[2:3]
				 c <- cor(all_sub, use="complete.obs", method="pearson") 
				 t <- rcorr(as.matrix(all_sub), type="pearson")
			 	 c <- cor(all_sub, use="complete.obs", method="pearson") 
				 c <- data.frame(c)
				 OutputDataSet <- c'

DECLARE @SQLScript nvarchar(max)
SET @SQLScript = N'SELECT
						 TableName
						,RowCounts
						,UsedSpaceKB
						,TimeMeasure
						FROM DataPack_Info_SMALL'

EXECUTE sp_execute_external_script
	 @language = N'R'
	,@script = @RScript
	,@input_data_1 = @SQLScript
	WITH result SETS ( (
						 RowCounts VARCHAR(100)
						,UsedSpaceKB  VARCHAR(100)
						)
					 );

GO
/*

RowCounts	UsedSpaceKB
1			0.999905
0.999905	1
*/

-- imagine having some  deletes in between
SET NOCOUNT ON;

DROP TABLE DataPack;
DROP TABLE DataPack_Info_LARGE;


-- create a table
CREATE TABLE DataPack
	(
	  DataPackID BIGINT IDENTITY NOT NULL
	 ,col1 VARCHAR(1000) NOT NULL
	 ,col2 VARCHAR(1000) NOT NULL
	 )



-- populate data
DECLARE @i INT = 1;
BEGIN TRAN
	WHILE @i <= 1000
		BEGIN
			INSERT dbo.DataPack(col1, col2)
				SELECT 
					  REPLICATE('A',200)
					 ,REPLICATE('B',300);
			SET @i = @i + 1;
		END
COMMIT;
GO



-- creating log table
SELECT 
    t.NAME AS TableName
    ,s.Name AS SchemaName
    ,p.rows AS RowCounts
    ,SUM(a.total_pages) * 8 AS TotalSpaceKB
    ,SUM(a.used_pages) * 8 AS UsedSpaceKB
    ,(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
	,GETDATE() AS TimeMeasure

INTO dbo.DataPack_Info_LARGE

FROM 
    sys.tables AS t
INNER JOIN sys.indexes AS i 
	ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions AS p 
	ON i.object_id = p.OBJECT_ID 
	AND i.index_id = p.index_id
INNER JOIN sys.allocation_units AS a 
	ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas AS s 
	ON t.schema_id = s.schema_id

WHERE 
	     t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
	AND t.name = 'DataPack'
    AND i.OBJECT_ID > 255 
GROUP BY t.Name, s.Name, p.Rows



-- Add delete into the inserts 
DECLARE @nof_steps INT = 0

WHILE @nof_steps < 15
BEGIN
	BEGIN TRAN
		-- insert some data
		DECLARE @i INT = 1;

		IF RAND()*10 < 5
		  BEGIN
					WHILE @i <= 1000 -- step is 100 rows
								BEGIN
									INSERT dbo.DataPack(col1, col2)
										SELECT 
											  REPLICATE('A',FLOOR(RAND()*200))  -- pages are filling up differently
											 ,REPLICATE('B',FLOOR(RAND()*300));
									SET @i = @i + 1;
								END


					
			END
		 IF RAND()*10 >= 5
			BEGIN			
					DELETE FROM dbo.DataPack
							WHERE
					DataPackID % 3 = 0
			END


		-- run statistics on table
		INSERT INTO dbo.DataPack_Info_LARGE
		SELECT 
			t.NAME AS TableName
			,s.Name AS SchemaName
			,p.rows AS RowCounts
			,SUM(a.total_pages) * 8 AS TotalSpaceKB
			,SUM(a.used_pages) * 8 AS UsedSpaceKB
			,(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
			,GETDATE() AS TimeMeasure
		FROM  
				sys.tables AS t
			INNER JOIN sys.indexes AS i 
			ON t.OBJECT_ID = i.object_id
			INNER JOIN sys.partitions AS p 
			ON i.object_id = p.OBJECT_ID 
			AND i.index_id = p.index_id
			INNER JOIN sys.allocation_units AS a 
			ON p.partition_id = a.container_id
			LEFT OUTER JOIN sys.schemas AS s 
			ON t.schema_id = s.schema_id

		WHERE 
				 t.NAME NOT LIKE 'dt%' 
			AND t.is_ms_shipped = 0
			AND t.name = 'DataPack'
			AND i.OBJECT_ID > 255 
		GROUP BY t.Name, s.Name, p.Rows
	
		WAITFOR DELAY '00:00:01'

	COMMIT;

END
-- Duration 00:00:49

-- check the distribution ... slightly not "that straightforward"
SELECT * FROM DataPack_Info_LARGE


-- Let's check the correlation in R 
-- In previous case we had 0,9999 correlation

DECLARE @RScript nvarchar(max)
SET @RScript = N'
				 library(Hmisc)	
				 mydata <- InputDataSet
				 all_sub <- mydata[2:3]
				 c <- cor(all_sub, use="complete.obs", method="pearson") 
				 c <- data.frame(c)
				 OutputDataSet <- c'

DECLARE @SQLScript nvarchar(max)
SET @SQLScript = N'SELECT
						 TableName
						,RowCounts
						,UsedSpaceKB
						,TimeMeasure
						FROM DataPack_Info_LARGE'

EXECUTE sp_execute_external_script
	 @language = N'R'
	,@script = @RScript
	,@input_data_1 = @SQLScript
	WITH result SETS ( (
						 RowCounts VARCHAR(100)
						,UsedSpaceKB  VARCHAR(100)
						)
					 );

GO
/*
RowCounts	UsedSpaceKB
1			0.996744
0.996744	1
*/

-- I presumme, everything is fine
-- but what if we switch the correlation between 
-- UnusedSpaceKB and UsedSpacesKB
-- I will run concurrently both Logs - small and large


DECLARE @RScript1 nvarchar(max)
SET @RScript1 = N'
				 library(Hmisc)	
				 mydata <- InputDataSet
				 all_sub <- mydata[4:5]
				 c <- cor(all_sub, use="complete.obs", method="pearson") 
				 c <- data.frame(c)
				 OutputDataSet <- c'

DECLARE @SQLScript1 nvarchar(max)
SET @SQLScript1 = N'SELECT
						 TableName
						,RowCounts
						,TimeMeasure
						,UsedSpaceKB	
						,UnusedSpaceKB
						FROM DataPack_Info_SMALL'

EXECUTE sp_execute_external_script
	 @language = N'R'
	,@script = @RScript1
	,@input_data_1 = @SQLScript1
	WITH result SETS ( (
						 RowCounts VARCHAR(100)
						,UsedSpaceKB  VARCHAR(100)
						)
					 );

GO


DECLARE @RScript2 nvarchar(max)
SET @RScript2 = N'
				 library(Hmisc)	
				 mydata <- InputDataSet
				 all_sub <- mydata[4:5]
				 c <- cor(all_sub, use="complete.obs", method="pearson") 
				 c <- data.frame(c)
				 OutputDataSet <- c'

DECLARE @SQLScript2 nvarchar(max)
SET @SQLScript2 = N'SELECT
						 TableName
						,RowCounts
						,TimeMeasure
						,UsedSpaceKB	
						,UnusedSpaceKB
						FROM DataPack_Info_LARGE'

EXECUTE sp_execute_external_script
	 @language = N'R'
	,@script = @RScript2
	,@input_data_1 = @SQLScript2
	WITH result SETS ( (
						 RowCounts VARCHAR(100)
						,UsedSpaceKB  VARCHAR(100)
						)
					 );

GO







-- clean database

DROP TABLE DataPack;

DROP DATABASE FixSizeDB;
GO
