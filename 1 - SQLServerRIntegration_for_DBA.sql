/*
-- **************************************************************
-- 
-- Tomaž Kaštrun
-- 10.12.2016 
-- SqlSaturday Slovenia 2016
-- SQL Server 2016 R Integration for database administrators
--
-- **************************************************************

*/


USE [master];
GO

CREATE DATABASE [DBA4R]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'DBA4R', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\DBA4R.mdf' , SIZE = 102400KB , FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'DBA4R_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\DBA4R_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
GO
ALTER DATABASE [DBA4R] SET COMPATIBILITY_LEVEL = 130
GO
ALTER DATABASE [DBA4R] SET RECOVERY SIMPLE 
GO

-- start Agent
EXECUTE sp_startagent 


USE [DBA4R];
GO

/*

-- 1. General R

-- show how sp_execute_external_script works
-- and how to interpret some statistical significance

*/


-- Generating Data

DECLARE @RScript nvarchar(max)
SET @RScript = N'
				 library(cluster)	
				 mydata <- InputDataSet
				 d <- dist(mydata, method = "euclidean") 
				 fit <- hclust(d, method="ward.D")
				 #plot(fit,xlab=" ", ylab=NULL, main=NULL, sub=" ")
				 groups <- cutree(fit, k=3) 
				 #rect.hclust(fit, k=3, border="DarkRed")
				 #merge mydata and clusters
				 cluster_p <- data.frame(groups)
				 mydata <- cbind(mydata, cluster_p)

				 df_qt <- data.frame(table(mydata$OrderQty, mydata$groups),name = ''Qty'')
				 df_pc <- data.frame(table(mydata$DiscountPct, mydata$groups),name = ''Pct'')
				 df_cat <- data.frame(table(mydata$Category, mydata$groups),name = ''Cat'')
				 df_total <- df_qt
				 df_total <- rbind(df_total, df_pc)
				 df_total <- rbind(df_total, df_cat)
				 OutputDataSet <- df_total'

DECLARE @SQLScript nvarchar(max)
SET @SQLScript = N'SELECT 
					 ps.[Name]
					,AVG(sod.[OrderQty]) AS OrderQty
					,so.[DiscountPct]
					,pc.name AS Category
				FROM  Adventureworks.[Sales].[SalesOrderDetail] sod
				INNER JOIN Adventureworks.[Sales].[SpecialOffer] so
				ON so.[SpecialOfferID] = sod.[SpecialOfferID]
				INNER JOIN Adventureworks.[Production].[Product] p
				ON p.[ProductID] = sod.[ProductID]
				INNER JOIN Adventureworks.[Production].[ProductSubcategory] ps
				ON ps.[ProductSubcategoryID] = p.ProductSubcategoryID
				INNER JOIN Adventureworks.[Production].[ProductCategory] pc
				ON pc.ProductCategoryID = ps.ProductCategoryID
				GROUP BY ps.[Name],so.[DiscountPct],pc.name'

EXECUTE sp_execute_external_script
	 @language = N'R'
	,@script = @RScript
	,@input_data_1 = @SQLScript
	WITH result SETS ( (
						 Var1 VARCHAR(100)
						,Var2 VARCHAR(100)
						,Freq INT
						,name VARCHAR(100))
					 );

GO


-- Predicting

SELECT CustomerKey, MaritalStatus,
 Gender, TotalChildren, NumberChildrenAtHome,
 EnglishEducation AS Education,
 EnglishOccupation AS Occupation,
 HouseOwnerFlag, NumberCarsOwned,
 CommuteDistance, Region,
 BikeBuyer, YearlyIncome,
 Age - 10 AS Age
INTO AdventureWorksDW2014.dbo.TargetMail
FROM AdventureWorksDW2014.dbo.vTargetMail;
GO

DECLARE @input AS NVARCHAR(MAX)
SET @input = N'
				SELECT CustomerKey, MaritalStatus, Gender,
				TotalChildren, NumberChildrenAtHome,
				Education, Occupation,
				HouseOwnerFlag, NumberCarsOwned, CommuteDistance,
				Region, BikeBuyer
				FROM AdventureWorksDW2014.dbo.TargetMail;'

DECLARE @RKoda NVARCHAR(MAX)
SET @RKoda = N'
	library(RevoScaleR)
	bbLogR <- rxLogit(BikeBuyer ~  MaritalStatus + Gender + TotalChildren +
                    NumberChildrenAtHome + Education + Occupation +
                    HouseOwnerFlag + NumberCarsOwned + CommuteDistance + Region,
                  data = sqlTM);
	prtm <- rxPredict(modelObject = bbLogR, data = sqlTM, outData = NULL,
                  predVarNames = "BikeBuyerPredict", type = "response",
                  checkFactorLevels = FALSE, extraVarsToWrite = c("CustomerKey"),
                  writeModelVars = TRUE, overwrite = TRUE);
	OutputDataSet <- prtm[which(prtm$CustomerKey=="11000"),]';

EXEC sys.sp_execute_external_script
 @language = N'R', 
 @script = @RKoda, 
  @input_data_1 = @input, 
  @input_data_1_name = N'sqlTM'

WITH RESULT SETS ((
	 BikeBuyerPredict FLOAT
	,CustomerKey INT
	,BikeBuyer INT
	,MaritalStatus NCHAR(1)
	,Gender NCHAR(1)
	,TotalChildren INT
	,NumberChildrenAtHome INT
	,Education NVARCHAR(40)
	,Occupation NVARCHAR(100)
	,HouseOwnerFlag NCHAR(1)
	,NumberCarsOwned INT
	,CommuteDistance NVARCHAR(15)
	,Region NVARCHAR(50)
 )); 
GO

DROP TABLE AdventureWorksDW2014.dbo.TargetMail;
GO


/*

-- 2. Query executions with time and slight changes (adding indexes and statistical significance)

-- adding automation index and checking time against the query, collecting information and running some correlations 

*/

--SET STATISTICS PROFILE ON
-- SET STATISTICS PROFILE OFF

-- Do some unneccessary load
USE WideWorldImportersDW;
GO

-- My Query 
--Finding arbitrary query:
SELECT cu.[Customer Key] AS CustomerKey, cu.Customer,
  ci.[City Key] AS CityKey, ci.City, 
  ci.[State Province] AS StateProvince, ci.[Sales Territory] AS SalesTeritory,
  d.Date, d.[Calendar Month Label] AS CalendarMonth, 
  d.[Calendar Year] AS CalendarYear,
  s.[Stock Item Key] AS StockItemKey, s.[Stock Item] AS Product, s.Color,
  e.[Employee Key] AS EmployeeKey, e.Employee,
  f.Quantity, f.[Total Excluding Tax] AS TotalAmount, f.Profit
FROM Fact.Sale AS f
  INNER JOIN Dimension.Customer AS cu
    ON f.[Customer Key] = cu.[Customer Key]
  INNER JOIN Dimension.City AS ci
    ON f.[City Key] = ci.[City Key]
  INNER JOIN Dimension.[Stock Item] AS s
    ON f.[Stock Item Key] = s.[Stock Item Key]
  INNER JOIN Dimension.Employee AS e
    ON f.[Salesperson Key] = e.[Employee Key]
  INNER JOIN Dimension.Date AS d
    ON f.[Delivery Date Key] = d.Date;
GO 3


-- FactSales Query
SELECT * FROM Fact.Sale
GO 4


-- Person Query
SELECT * FROM [Dimension].[Customer]
WHERE [Buying Group] <> 'Tailspin Toys'

  OR [WWI Customer ID] > 500
ORDER BY [Customer],[Bill To Customer]

GO 4



SELECT * 
FROM [Fact].[Order] AS o
INNER JOIN [Fact].[Purchase] AS p 
ON o.[Order Key] = p.[WWI Purchase Order ID]
GO 3
-- total Duration 00:00:24





-- let us run the query stats and get a headache
SELECT

	(total_logical_reads + total_logical_writes) AS total_logical_io
	,(total_logical_reads / execution_count) AS avg_logical_reads
	,(total_logical_writes / execution_count) AS avg_logical_writes
	,(total_physical_reads / execution_count) AS avg_phys_reads
	,substring(st.text,(qs.statement_start_offset / 2) + 1,  ((CASE qs.statement_end_offset 
																WHEN - 1 THEN datalength(st.text) 
																ELSE qs.statement_end_offset END  - qs.statement_start_offset) / 2) + 1) AS statement_text
	,*
-- Don't drop table query_stats_LOG - is used in Report
-- DROP TABLE query_stats_LOG_2
INTO query_stats_LOG_2
FROM
		sys.dm_exec_query_stats AS qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY
total_logical_io DESC
-- (26 row(s) affected)


SELECT 
 [total_logical_io]
,[avg_logical_reads]
,[avg_phys_reads]
,execution_count
,[total_physical_reads]
,[total_elapsed_time]
,total_dop
,left([text],100) AS [text]
,row_number() over (order by (select 1)) as ln
 FROM query_stats_LOG
WHERE Number is null





CREATE PROCEDURE [dbo].[SP_Query_Stats_Cluster]
AS
DECLARE @RScript nvarchar(max)

SET @RScript = N'
				 library(cluster)
				 All <- InputDataSet
				 image_file <- tempfile()
				 jpeg(filename = image_file, width = 500, height = 500)
					d <- dist(All, method = "euclidean") 
					fit <- hclust(d, method="ward.D")
					plot(fit,xlab=" ", ylab=NULL, main=NULL, sub=" ")
					groups <- cutree(fit, k=3) 
					rect.hclust(fit, k=3, border="DarkRed")			
				 dev.off()
				 OutputDataSet <- data.frame(data=readBin(file(image_file, "rb"), what=raw(), n=1e6))' 


DECLARE @SQLScript nvarchar(max)
SET @SQLScript = N'
				SELECT 
					 [total_logical_io]
					,[avg_logical_reads]
					,[avg_phys_reads]
					,execution_count
					,[total_physical_reads]
					,[total_elapsed_time]
					,total_dop
					,[text]
				 FROM query_stats_LOG
				WHERE Number is null';

EXECUTE sp_execute_external_script
@language = N'R',
@script = @RScript,
@input_data_1 = @SQLScript
WITH RESULT SETS ((Plot varbinary(max)))

GO










/*
-- 3. Job executions and drawing statistical comparison and correlations
*/


USE msdb;
GO


WITH jobs_to_run AS
(
	SELECT 

	 h.job_id
	,j.name
	,CAST( SUBSTRING(CONVERT(VARCHAR(10),h.run_date) , 5,2) +'-'
		+ SUBSTRING(CONVERT(VARCHAR(10),h.run_date) , 7,2) +'-'
		+ SUBSTRING(CONVERT(VARCHAR(10),h.run_date),1,4) + ' ' +
		+ SUBSTRING(CONVERT(VARCHAR(10),replicate('0',6-len(h.run_time)) + CAST(h.run_time AS VARCHAR)), 1, 2) + ':' 
		+ SUBSTRING(CONVERT(VARCHAR(10),replicate('0',6-len(h.run_time)) + CAST(h.run_time AS VARCHAR)), 3, 2) + ':' 
		+ SUBSTRING(CONVERT(VARCHAR(10),replicate('0',6-len(h.run_time)) + CAST(h.run_time AS VARCHAR)), 5, 2)  AS SMALLDATETIME)
		AS JobStart
	,DATEADD(SECOND, CASE WHEN h.run_duration > 0 THEN (h.run_duration / 1000000) * (3600 * 24) 
		+ (h.run_duration / 10000 % 100) * 3600 
		+ (h.run_duration / 100 % 100) * 60 
		+ (h.run_duration % 100) ELSE 0 END,CAST( SUBSTRING(CONVERT(VARCHAR(10),h.run_date) , 5,2) +'-'
		+ SUBSTRING(CONVERT(VARCHAR(10),h.run_date) , 7,2) +'-'
		+ SUBSTRING(CONVERT(VARCHAR(10),h.run_date),1,4) + ' ' +
		+ SUBSTRING(CONVERT(VARCHAR(10),replicate('0',6-len(h.run_time)) + CAST(h.run_time AS VARCHAR)), 1, 2) + ':' 
		+ SUBSTRING(CONVERT(VARCHAR(10),replicate('0',6-len(h.run_time)) + CAST(h.run_time AS VARCHAR)), 3, 2) + ':' 
		+ SUBSTRING(CONVERT(VARCHAR(10),replicate('0',6-len(h.run_time)) + CAST(h.run_time AS VARCHAR)), 5, 2)  AS SMALLDATETIME))
		AS JobEND
	,outcome = CASE 
			WHEN h.run_status = 0 THEN 'Fail'
			WHEN h.run_status = 1 THEN 'Success'
			WHEN h.run_status = 2 THEN 'Retry'
			WHEN h.run_status = 3 THEN 'Cancel'
			WHEN h.run_status = 4 THEN 'In progress'
		END

	FROM sysjobhistory AS h
	JOIN sysjobs AS j
		on j.job_id = h.job_id
	WHERE
		h.step_id = 0
	AND j.enabled = 1
	AND CAST(SUBSTRING(CONVERT(VARCHAR(10),h.run_date) , 5,2) +'-'
		+ SUBSTRING(CONVERT(VARCHAR(10),h.run_date) , 7,2) +'-'
		+ SUBSTRING(CONVERT(VARCHAR(10),h.run_date),1,4) AS SMALLDATETIME) = CONVERT(VARCHAR(10), GETDATE(), 121)

)
,tf_5m AS -- 5-minuute interval
(

SELECT 
	 v.number
	,DATEADD(SECOND,300*v.number,DATEDIFF(dd,0,GETDATE())) AS timeInterval_FROM  -- ,DATEADD(MINUTE,v.number,DATEDIFF(dd,0,GETDATE())) -- for 1minute timeframe
	,DATEADD(SECOND,300*v.number+299,DATEDIFF(dd,0,GETDATE())) AS timeInterval_to
FROM 
	master.dbo.spt_values AS v
WHERE 
	v.type = 'P'
AND v.number  <= 288 --= 5min   -- <= 1440 -- for 1minute timeframe

)
, timeset AS 
(
SELECT 
	 t.timeInterval_FROM AS timeInterval
	 ,ISNULL(j.name,'') AS JobName
	 ,ISNULL(j.outcome,'') AS outcome
	 ,j.jobstart
	 ,j.jobEND
	 ,ROW_NUMBER() OVER (PARTITION BY ISNULL(j.name,''),ISNULL(j.outcome,''),j.jobstart ORDER BY (SELECT t.timeInterval_FROM)) AS rn
 FROM jobs_to_run AS j
RIGHT JOIN tf_5m AS t
ON (j.jobstart BETWEEN t.timeinterval_FROM AND t.timeinterval_to
 OR j.jobEND BETWEEN t.timeinterval_FROM AND t.timeinterval_to)

)

-- Data "imputation" of empty rows for all jobs. 
-- To appear in SSRS as a continous block, when job is running for more than 5 minutes
SELECT
	 DATEADD(SECOND,300*s.number,DATEDIFF(dd,0,GETDATE())) AS TimeInterval
	,a.JobName
	,a.outcome
 FROM
	(
		SELECT
			 a.JobName
			,a.outcome
			,a.jobStart
			,MIN(a.TimeInterval) AS minTI
			,MAX(a.TimeInterval) AS maxTI

			FROM timeset AS a

			GROUP BY
				 a.JobName
				,a.outcome
				,a.jobStart
	) AS a

INNER JOIN master.dbo.spt_values AS s
	ON DATEADD(SECOND,300*s.number,DATEDIFF(dd,0,GETDATE()))  BETWEEN a.minTI AND a.maxTI

WHERE
	s.type = 'P'
AND s.number  <= 288

ORDER BY TimeInterval;
GO









/*

-- 4. Extended events (database growth; table growth (sp_spaceused)

*/

-- create extended event
CREATE EVENT SESSION [Check_Queries] ON SERVER 
ADD EVENT sqlserver.query_post_execution_showplan(
					WHERE (
								[sqlserver].[equal_i_sql_unicode_string]([object_name],N'Dynamic SQL') 
							AND [package0].[equal_uint64]([object_type],(20801)) 
							AND [source_database_id]=(13)
							)
												 )
WITH (
	 MAX_MEMORY=4096 KB
	,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS
	,MAX_DISPATCH_LATENCY=30 SECONDS
	,MAX_EVENT_SIZE=0 KB
	,MEMORY_PARTITION_MODE=NONE
	,TRACK_CAUSALITY=OFF
	,STARTUP_STATE=ON)
GO


-- ADD BDA4R database_id
SELECT db_id()

-- Create extended event for tracking database size
CREATE EVENT SESSION [DB_file_size_changed] ON SERVER 
ADD EVENT sqlserver.database_file_size_change
		(SET collect_database_name=(1)
				ACTION
					(
						 sqlserver.client_app_name
						,sqlserver.client_hostname
						,sqlserver.database_id
						,sqlserver.session_id
						,sqlserver.session_nt_username
						,sqlserver.username
						,package0.collect_system_time
					)
		   WHERE ([database_id]=(21)) 
		 ) 
/* ADD EVENT sqlos.async_io_requested,  */
ADD TARGET package0.event_file
(SET FILENAME=N'C:\DataTK\0_XEL_SS2016\DB_file_size_changed.xel')
WITH (
	    MAX_DISPATCH_LATENCY=1 SECONDS
	  )



-- START EX
ALTER EVENT SESSION DB_File_size_Changed 
ON SERVER STATE = START -- START/STOP to start and stop the event session


-- ADD some shit to database to make a file grow
USE [master];
GO


SELECT
        Case when file_type = 'Data file' Then 'Data File Grow' Else File_Type End AS [Event Name]
	   , database_name AS DatabaseName
	   , file_names
	   , size_change_kb
	   , duration
       , client_app_name AS Client_Application
	   , client_hostname
       , session_id AS SessionID
	   , Is_Automatic 
	   , Curr_Time
       
FROM (
       SELECT
             n.value ('(data[@name="size_change_kb"]/value)[1]', 'int') AS size_change_kb
           , n.value ('(data[@name="database_name"]/value)[1]', 'nvarchar(50)') AS database_name
           , n.value ('(data[@name="duration"]/value)[1]', 'int') AS duration
           , n.value ('(data[@name="file_type"]/text)[1]','nvarchar(50)') AS file_type
           , n.value ('(action[@name="client_app_name"]/value)[1]','nvarchar(50)') AS client_app_name
           , n.value ('(action[@name="session_id"]/value)[1]','nvarchar(50)') AS session_id
		   , n.value ('(action[@name="client_hostname"]/value)[1]','nvarchar(50)') AS Client_HostName
		   , n.value ('(data[@name="file_name"]/value)[1]','nvarchar(50)') AS file_names
		   , n.value ('(data[@name="is_automatic"]/value)[1]','nvarchar(50)') AS Is_Automatic
		   , n.value ('(action[@name="collect_system_time"]/value)[1]','datetime2') AS Curr_Time 
		   --xed.event_data.value('(@timestamp)[1]', 'datetime2') AS [timestamp] --- ni na nodeu
           
       FROM 
           (   SELECT CAST(event_data AS XML) AS event_data
               FROM sys.fn_xe_file_target_read_file(
				 --N'C:\DataTK\0_XEL_SS2016\DB_file_size_changed_0_131254252272590000.xel',
                   N'C:\DataTK\0_XEL_SS2016\DB_file_size_changed*.xel',  
                   NULL,
                   NULL,
                   NULL)
           ) AS Event_Data_Table
CROSS APPLY event_data.nodes('event') AS q(n)) xyz
ORDER BY database_name




-- Go back to DBA4R
USE [DBA4R];
GO

-- ADD huge table:
IF OBJECT_ID('dbo.Numbers') IS NOT NULL
  DROP TABLE [DBA4R].dbo.Numbers;
GO
 
CREATE TABLE [DBA4R].dbo.Numbers (
  n BIGINT NOT NULL,
  CONSTRAINT PK_Numbers PRIMARY KEY CLUSTERED (n) /*WITH FILLFACTOR = 100*/
);
GO
 
WITH
  L0   AS(SELECT 1 AS c UNION ALL SELECT 1),
  L1   AS(SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
  L2   AS(SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
  L3   AS(SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
  L4   AS(SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
  L5   AS(SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
  Nums AS(SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS n FROM L5)
INSERT INTO [DBA4R].dbo.Numbers (n)
SELECT TOP (10000000) n FROM Nums ORDER BY n; -- Insert as many numbers as you need
GO

EXECUTE sp_spaceused N'dbo.Numbers';
GO

USE [DBA4R];
GO

-- ADD huge table:
IF OBJECT_ID('dbo.Numbers2') IS NOT NULL
  DROP TABLE [DBA4R].dbo.Numbers2;
GO
 
CREATE TABLE [DBA4R].dbo.Numbers2 (
  n BIGINT NOT NULL,
  CONSTRAINT PK_Numbers2 PRIMARY KEY CLUSTERED (n) /*WITH FILLFACTOR = 100*/
);
GO
 
WITH
  L0   AS(SELECT 1 AS c UNION ALL SELECT 1),
  L1   AS(SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
  L2   AS(SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
  L3   AS(SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
  L4   AS(SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
  L5   AS(SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
  Nums AS(SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS n FROM L5)
INSERT INTO [DBA4R].dbo.Numbers2 (n)
SELECT TOP (10000000) n FROM Nums ORDER BY n; -- Insert as many numbers as you need
GO

EXECUTE sp_spaceused N'dbo.Numbers2';
GO


-- DROP TABLE [DBA4R].dbo.EX_DB_file_size

--- After extracting data, we can  
--  save the data to table
SELECT
        Case when file_type = 'Data file' Then 'Data File Grow' Else File_Type End AS [Event Name]
	   ,database_name AS DatabaseName
	   ,file_names
	   ,size_change_kb
	   ,duration
       ,client_app_name AS Client_Application
	   ,client_hostname
       ,session_id AS SessionID
	   ,Is_Automatic 
	   ,Curr_Time

INTO [DBA4R].dbo.EX_DB_file_size
       
FROM (
       SELECT
            n.value ('(data[@name="size_change_kb"]/value)[1]', 'int') AS size_change_kb
           ,n.value ('(data[@name="database_name"]/value)[1]', 'nvarchar(50)') AS database_name
           ,n.value ('(data[@name="duration"]/value)[1]', 'int') AS duration
           ,n.value ('(data[@name="file_type"]/text)[1]','nvarchar(50)') AS file_type
           ,n.value ('(action[@name="client_app_name"]/value)[1]','nvarchar(50)') AS client_app_name
           ,n.value ('(action[@name="session_id"]/value)[1]','nvarchar(50)') AS session_id
		   ,n.value ('(action[@name="client_hostname"]/value)[1]','nvarchar(50)') AS Client_HostName
		   ,n.value ('(data[@name="file_name"]/value)[1]','nvarchar(50)') AS file_names
		   ,n.value ('(data[@name="is_automatic"]/value)[1]','nvarchar(50)') AS Is_Automatic
	       ,n.value ('(action[@name="collect_system_time"]/value)[1]','datetime2') AS Curr_Time 
           
       FROM 
           (   SELECT CAST(event_data AS XML) AS event_data
               FROM sys.fn_xe_file_target_read_file(
                   N'C:\DataTK\0_XEL_SS2016\DB_file_size_changed*.xel',
                   NULL,
                   NULL,
                   NULL)
           ) AS Event_Data_Table
CROSS APPLY event_data.nodes('event') AS q(n)) xyz
ORDER BY database_name

-- STOP EVENT
ALTER EVENT SESSION DB_File_size_Changed 
ON SERVER STATE = STOP 

DROP EVENT SESSION [DB_file_size_changed] ON SERVER 
GO





/*

-- 6. Query store

*/
USE DBA4R;
GO

-- Enable the Query Store through T-SQL
ALTER DATABASE [DBA4R] SET QUERY_STORE = ON;


ALTER DATABASE [DBA4R]
SET QUERY_STORE
  (
  MAX_STORAGE_SIZE_MB = 100, -- Maximum size of the Query Store
  SIZE_BASED_CLEANUP_MODE = AUTO, -- Cleanup mode
  CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30) -- Cleanup policy, 30 days
  );


  
CREATE TABLE MyTable 
(
	 col1 INT
	,col2 INT
	,col3 BINARY(2000)
);
GO

-- ROLLBACK TRANSACTION
SET NOCOUNT ON

BEGIN TRANSACTION
	DECLARE @i INT=0
		WHILE @i < 10000
			BEGIN
				INSERT INTO MyTable(col1,col2) VALUES (@i,@i)
				SET @i += 1
			END
COMMIT TRANSACTION;
GO

INSERT INTO MyTable (col1, col2) VALUES (1,1);
GO 10000

-- Beginning execution loop
-- Batch execution completed 10000 times.
-- Duration Time (00:00:11)


CREATE INDEX i1 ON MyTable(col1)
CREATE INDEX i2 ON MyTable(col2)




SELECT @@SERVERNAME


SELECT * from [DBA4R].dbo.MyTable


IF EXISTS (SELECT * FROM sys.objects WHERE type = 'U' AND [name] = 'MyTable1')
DROP TABLE dbo.MyTable1;
GO


CREATE TABLE MyTable1 
	(ID TINYINT NOT NULL
	,VAL TINYINT NOT NULL)

INSERT INTO MyTable1 (ID,VAL)
		  SELECT  1,1
UNION ALL SELECT  1,2
UNION ALL SELECT  1,3
UNION ALL SELECT  1,4
UNION ALL SELECT  1,5
UNION ALL SELECT  1,6
UNION ALL SELECT  1,7
UNION ALL SELECT  1,8
UNION ALL SELECT  1,9
UNION ALL SELECT  2,9
-- (10 row(s) affected)


IF EXISTS (SELECT * FROM sys.objects WHERE type = 'U' AND [name] = 'MyTable2')
DROP TABLE dbo.MyTable2;
GO


CREATE TABLE MyTable2
	(ID TINYINT NOT NULL
	,VAL TINYINT NOT NULL)

INSERT INTO MyTable2 (ID,VAL)
		  SELECT  3,1
UNION ALL SELECT  3,2
UNION ALL SELECT  3,3
UNION ALL SELECT  3,4
UNION ALL SELECT  3,5
UNION ALL SELECT  3,6
UNION ALL SELECT  3,7
UNION ALL SELECT  3,8
UNION ALL SELECT  3,9
UNION ALL SELECT  4,9
-- (10 row(s) affected)

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'U' AND [name] = 'MyTable3')
DROP TABLE dbo.MyTable3;
GO


CREATE TABLE MyTable3
	(ID TINYINT NOT NULL
	,VAL TINYINT NOT NULL)

INSERT INTO MyTable3 (ID,VAL)
		  SELECT  5,1
UNION ALL SELECT  5,2
UNION ALL SELECT  5,3
UNION ALL SELECT  5,4
UNION ALL SELECT  5,5
UNION ALL SELECT  5,6
UNION ALL SELECT  5,7
UNION ALL SELECT  5,8
UNION ALL SELECT  5,9
UNION ALL SELECT  6,9
-- (10 row(s) affected)


DECLARE @i AS INT = 0
DECLARE @r AS DECIMAL(10,4)

WHILE (100 >= @i)
BEGIN
SET @r = RAND()
	IF @r < 0.310
		BEGIN
			--SELECT * FROM MyTable1  WHERE ID = 1
			PRINT CAST(@i AS VARCHAR(10))+ ' | ' + 'Table1' + ' | ' + CAST(@r AS VARCHAR(20))
			SET @i = @i +1
		END

	IF @r >= 0.310 AND @r < 0.330
		BEGIN
			--SELECT * FROM MyTable1  WHERE ID = 2
			PRINT CAST(@i AS VARCHAR(10))+ ' | ' + 'Table1 - Spike' + ' | ' + CAST(@r AS VARCHAR(20))
			SET @i = @i +1
		END

	IF @r >= 0.330 AND @r <= 0.630
		BEGIN
			--SELECT * FROM MyTable2  WHERE ID = 3
			PRINT CAST(@i AS VARCHAR(10))+ ' | '  + 'Table2' + ' | ' + CAST(@r AS VARCHAR(20))
			SET @i = @i +1
		END

	IF @r > 0.630 AND @r <= 0.660
		BEGIN
			--SELECT * FROM MyTable2  WHERE ID = 4
			PRINT CAST(@i AS VARCHAR(10))+ ' | '  + 'Table2  - Spike' + ' | ' + CAST(@r AS VARCHAR(20))
			SET @i = @i +1
		END

	IF @r > 0.660 AND @r <= 0.970
		BEGIN
			--SELECT * FROM MyTable3 WHERE ID = 5
			PRINT CAST(@i AS VARCHAR(10))+ ' | '  + 'Table3' + ' | ' + CAST(@r AS VARCHAR(20))
			SET @i = @i +1
		END
    /* "% Probability of spike of */
	IF @r > 0.970
		BEGIN
			--SELECT * FROM MyTable3 WHERE ID = 6
			PRINT CAST(@i AS VARCHAR(10)) + ' | ' + 'Table3 - Spike' + ' | ' + CAST(@r AS VARCHAR(20))
			SET @i = @i +1
		END
END;
GO


-- Get statistics from Query Store


SELECT  TOP 10 
	 qt.query_sql_text
	,q.query_id
	,qt.query_text_id
	,p.plan_id
	,rs.last_execution_time
FROM 
	 sys.query_store_query_text AS qt 
	JOIN sys.query_store_query AS q 
    ON qt.query_text_id = q.query_text_id 
	JOIN sys.query_store_plan AS p 
    ON q.query_id = p.query_id 
	JOIN sys.query_store_runtime_stats AS rs 
    ON p.plan_id = rs.plan_id

ORDER BY 
	rs.last_execution_time DESC;
GO



-- 1. QUERY TEXT 
-- Query text as entered by the user, including white space, hints, and comments.
/* Query_text_id = 12, 14, 15 */
SELECT * FROM sys.query_store_query_text
where query_text_id in (2,4)
-- 2. QUERY
-- Query information and its overall aggregated run-time execution statistics.
/* For Query_text_id get the Query_ID */
/* for Query_text_id = 1 is Query_id = 2 */
SELECT * FROM sys.query_store_query
WHERE Query_id in (2,4)
   -- More info on Query Context -> sys.query_context_settings (BIT mask for several SET Statements, Query Status,...)

-- 3. PLAN FOR QUERY
-- Execution plan information for queries.
/* for Query_ID = 2 get the plan is Plan_id = 1 */
SELECT * FROM sys.query_store_plan
WHERE Query_ID in (2,4)



--- let's make a bunch of queries
--- select all the queries in AdventureWorks database :-)

SELECT 

'SELECT * FROM AdventureWorks.'+QUOTENAME(s.Name)+'.' + QUOTENAME(t.Name) + '; '
FROM AdventureWorks.sys.Tables as T
JOIN AdventureWorks.sys.schemas AS S
ON T.SCHEMA_ID = S.schema_id
WHERE [type] = 'U'
GO


-- run bunch of queries :-)
SELECT * FROM AdventureWorks.[Production].[ScrapReason]; 
SELECT * FROM AdventureWorks.[HumanResources].[Shift]; 
SELECT * FROM AdventureWorks.[Production].[ProductCategory]; 
SELECT * FROM AdventureWorks.[Purchasing].[ShipMethod]; 
SELECT * FROM AdventureWorks.[Production].[ProductCostHistory]; 
SELECT * FROM AdventureWorks.[Production].[ProductDescription]; 
SELECT * FROM AdventureWorks.[Sales].[ShoppingCartItem]; 
SELECT * FROM AdventureWorks.[Production].[ProductDocument]; 
SELECT * FROM AdventureWorks.[dbo].[DatabaseLog]; 
SELECT * FROM AdventureWorks.[Production].[ProductInventory]; 
SELECT * FROM AdventureWorks.[Sales].[SpecialOffer]; 
SELECT * FROM AdventureWorks.[dbo].[ErrorLog]; 
SELECT * FROM AdventureWorks.[Production].[ProductListPriceHistory]; 
SELECT * FROM AdventureWorks.[Person].[Address]; 
SELECT * FROM AdventureWorks.[Sales].[SpecialOfferProduct]; 
SELECT * FROM AdventureWorks.[Production].[ProductModel]; 
SELECT * FROM AdventureWorks.[Person].[AddressType]; 
SELECT * FROM AdventureWorks.[Person].[StateProvince]; 
SELECT * FROM AdventureWorks.[Production].[ProductModelIllustration]; 
SELECT * FROM AdventureWorks.[dbo].[AWBuildVersion]; 
SELECT * FROM AdventureWorks.[Production].[ProductModelProductDescriptionCulture]; 
SELECT * FROM AdventureWorks.[Production].[BillOfMaterials]; 
SELECT * FROM AdventureWorks.[Sales].[Store]; 
SELECT * FROM AdventureWorks.[Production].[ProductPhoto]; 
SELECT * FROM AdventureWorks.[Production].[ProductProductPhoto]; 
SELECT * FROM AdventureWorks.[Production].[TransactionHistory]; 
SELECT * FROM AdventureWorks.[Production].[ProductReview]; 
SELECT * FROM AdventureWorks.[Person].[BusinessEntity]; 
SELECT * FROM AdventureWorks.[Production].[TransactionHistoryArchive]; 
SELECT * FROM AdventureWorks.[Production].[ProductSubcategory]; 
SELECT * FROM AdventureWorks.[Person].[BusinessEntityAddress]; 
SELECT * FROM AdventureWorks.[Purchasing].[ProductVendor]; 
SELECT * FROM AdventureWorks.[Person].[BusinessEntityContact]; 
SELECT * FROM AdventureWorks.[Production].[UnitMeasure]; 
SELECT * FROM AdventureWorks.[Purchasing].[Vendor]; 
SELECT * FROM AdventureWorks.[Person].[ContactType]; 
SELECT * FROM AdventureWorks.[Sales].[CountryRegionCurrency]; 
SELECT * FROM AdventureWorks.[Person].[CountryRegion]; 
SELECT * FROM AdventureWorks.[Production].[WorkOrder]; 
SELECT * FROM AdventureWorks.[Purchasing].[PurchaseOrderDetail]; 
SELECT * FROM AdventureWorks.[Sales].[CreditCard]; 
SELECT * FROM AdventureWorks.[Production].[Culture]; 
SELECT * FROM AdventureWorks.[Production].[WorkOrderRouting]; 
SELECT * FROM AdventureWorks.[Sales].[Currency]; 
SELECT * FROM AdventureWorks.[Purchasing].[PurchaseOrderHeader]; 
SELECT * FROM AdventureWorks.[Sales].[CurrencyRate]; 
SELECT * FROM AdventureWorks.[Sales].[Customer]; 
SELECT * FROM AdventureWorks.[HumanResources].[Department]; 
SELECT * FROM AdventureWorks.[Production].[Document]; 
SELECT * FROM AdventureWorks.[Sales].[SalesOrderDetail]; 
SELECT * FROM AdventureWorks.[Person].[EmailAddress]; 
SELECT * FROM AdventureWorks.[HumanResources].[Employee]; 
SELECT * FROM AdventureWorks.[dbo].[TK]; 
SELECT * FROM AdventureWorks.[Sales].[SalesOrderHeader]; 
SELECT * FROM AdventureWorks.[HumanResources].[EmployeeDepartmentHistory]; 
SELECT * FROM AdventureWorks.[HumanResources].[EmployeePayHistory]; 
SELECT * FROM AdventureWorks.[Sales].[SalesOrderHeaderSalesReason]; 
SELECT * FROM AdventureWorks.[Sales].[SalesPerson]; 
SELECT * FROM AdventureWorks.[Production].[Illustration]; 
SELECT * FROM AdventureWorks.[HumanResources].[JobCandidate]; 
SELECT * FROM AdventureWorks.[Production].[Location]; 
SELECT * FROM AdventureWorks.[Person].[Password]; 
SELECT * FROM AdventureWorks.[dbo].[Orders]; 
SELECT * FROM AdventureWorks.[Sales].[SalesPersonQuotaHistory]; 
SELECT * FROM AdventureWorks.[Person].[Person]; 
SELECT * FROM AdventureWorks.[dbo].[T1]; 
SELECT * FROM AdventureWorks.[Sales].[SalesReason]; 
SELECT * FROM AdventureWorks.[Sales].[SalesTaxRate]; 
SELECT * FROM AdventureWorks.[Sales].[PersonCreditCard]; 
SELECT * FROM AdventureWorks.[Person].[PersonPhone]; 
SELECT * FROM AdventureWorks.[Sales].[SalesTerritory]; 
SELECT * FROM AdventureWorks.[Person].[PhoneNumberType]; 
SELECT * FROM AdventureWorks.[Production].[Product]; 
SELECT * FROM AdventureWorks.[dbo].[DataPack_Info_SMALL_bck]; 
SELECT * FROM AdventureWorks.[Sales].[SalesTerritoryHistory]; 



-- Collect the data from Query Store

SELECT 
qsq.*
,query_sql_text 
INTO QS_Query_stats_bck
FROM sys.query_store_query as qsq
JOIN sys.query_store_query_text AS qsqt
ON qsq.query_text_id = qsqt.query_text_id
WHERE Query_id >= 41
order by qsq.query_id


SELECT 
 query_sql_text
,last_compile_batch_offset_start
,last_compile_batch_offset_end
,count_compiles
,avg_compile_duration
,last_compile_duration
,avg_bind_duration
,last_bind_duration
,avg_bind_cpu_time
,last_bind_cpu_time
,avg_optimize_duration
,last_optimize_duration
,avg_optimize_cpu_time
,last_optimize_cpu_time
,avg_compile_memory_kb
,last_compile_memory_kb
,max_compile_memory_kb

FROM QS_Query_stats_bck


-- for R table
SELECT  Left(query_sql_text,70) AS Query_Name,last_compile_batch_offset_start,last_compile_batch_offset_end
,count_compiles,avg_compile_duration,avg_bind_duration,avg_bind_cpu_time,avg_optimize_duration,avg_optimize_cpu_time
                   ,avg_compile_memory_kb 
into QS_Query_stats_bck_2				   
				   FROM QS_Query_stats_bck

WHERE
	Left(query_sql_text,70) like 'SELECT * FROM AdventureWorks.%'
order by 1


-- Query store OFF
ALTER DATABASE [DBA4R] SET QUERY_STORE = OFF;



/*

-- 7. Clean database

*/

-- CLEAN
USE [master];
GO
DROP DATABASE [DBA4R];
GO
