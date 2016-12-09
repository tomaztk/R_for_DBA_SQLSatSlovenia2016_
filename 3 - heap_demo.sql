/*

HEAP DEMO

*/


USE DBA4R;
GO


SET NOCOUNT ON;
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


-- create test table
CREATE TABLE dbo.DataPile
	(
		 datapileid BIGINT IDENTITY NOT NULL
		,col1 VARCHAR(1024) NOT NULL
	);
GO




-- populate data
DECLARE @i INT = 1;
BEGIN TRAN
	WHILE @i <= 1000
		BEGIN
			INSERT dbo.DataPile(col1)
				SELECT REPLICATE('A',200);
			SET @i = @i + 1;
		END
COMMIT;
GO




--- query to find heaps
-- look for Index_id = 0

SELECT
	 sc.Name AS Schema_name_
	,so.Name AS Table_name_
FROM
	sys.indexes AS i
	JOIN sys.objects AS so
	ON i.object_id = so.object_id
	JOIN sys.schemas AS sc
	ON so.schema_id = sc.schema_id
WHERE
		so.is_ms_shipped = 0 -- is not Microsoft object
	AND i.index_id = 0 -- is Heap
	AND so.type = 'U';   -- is user-created object
GO


-- other way to do it :-)
EXEC sp_helpindex 'DataPile';
GO




--- use DBCC IND to see internals of the table
-- Pay attention to: PageType = 10 is IAM page (Index Allocation Map Page); PageType = 1 is data page
-- look at the Next and Prev Page Columns
DBCC IND('', 'DataPile', 0);
GO



-- SQL Server 2012 and above DMV
-- with 2014 is documented! :)
SELECT
*
FROM sys.dm_db_database_page_allocations(DB_ID(), OBJECT_ID('DataPile'), 0, null, 'DETAILED');
GO




--- Check the information about fragmentation of this table
-- caution with word DETAILED!!!! it is scanning every page! ne nucat na produkciji! ali paè.
SELECT
	 alloc_unit_type_desc
	,index_depth
	,page_count
	,avg_page_space_used_in_percent
	,record_count
	,forwarded_record_count
FROM
	sys.dm_db_index_physical_stats(db_id(), OBJECT_ID('DataPile'), 0, NULL, 'DETAILED');
GO


--- look at the metadata for the partitions and page counts
SELECT
	 used_page_count
	,in_row_used_page_count
	,reserved_page_count
	,row_count
FROM
	sys.dm_db_partition_stats
WHERE
	OBJECT_NAME(OBJECT_ID) = 'DataPile';
GO



--- Have you noticed!!! We are actually looking in statistics, numbers (or metadata) that 
--- is helping us understand the nature and state of a particular object



--- let's do some loads!

SET STATISTICS IO ON;
SET STATISTICS TIME ON;


-- i should get 29 logical reads (which corresponds / relates to number of pages we have ween before in DMV)
SELECT
	*
FROM
	DataPile;
GO



-- let's do some updates!
-- make half of the rows larger values (so we would make page splits, fill factor fu*** up and bigger sparsity)
-- check the logical reads; "logical reads 4498"
UPDATE DataPile
SET 
	col1 = REPLICATE('B', 1000)
WHERE
	dataPileID % 2 = 0; -- modulo 2 makes 50% of the rows.
GO



--- now, how many reads does it take to scan the table?

SELECT
	*
FROM
	DataPile;
GO

/* Scan count 1, logical reads 486, ph.... */

-- rerun the DMV from before

-- forwarded reads + page count is  number of logical reads of 486
SELECT
	 alloc_unit_type_desc
	,index_depth
	,page_count
	,avg_page_space_used_in_percent
	,record_count
	,forwarded_record_count
FROM
	sys.dm_db_index_physical_stats(db_id(), OBJECT_ID('DataPile'), 0, NULL, 'DETAILED');
GO



--- Let's check also what happens with reading

SELECT
	leaf_insert_count
	,leaf_update_count
	,forwarded_fetch_count
FROM
	sys.dm_db_index_operational_stats(DB_ID(), OBJECT_ID('DataPile'),0,NULL);
GO



--- Check the forwarded_fetch_count
--- and now.... let's SELECT the table again
/*
1. Run
leaf_insert_count	leaf_update_count	forwarded_fetch_count
1000				500					800
*/

SELECT
	*
FROM
	DataPile;
GO



-- and check the changes for forwarded counts, including 2. run


SELECT
	leaf_insert_count
	,leaf_update_count
	,forwarded_fetch_count
FROM
	sys.dm_db_index_operational_stats(DB_ID(), OBJECT_ID('DataPile'),0,NULL);
GO

/*
we have added additional 400 rows
2. run
leaf_insert_count	leaf_update_count	forwarded_fetch_count
1000				500					1200

*/


--- what about deletes?
DELETE FROM DataPile
WHERE
	DataPileID > 5;
GO
/* I got: logical reads 486 which is as expected */



--- read the table
SELECT
	*
FROM
	DataPile;
GO
/* I still get: Scan count 1, logical reads 88.... WTF?! */


--- CHECK the fragmentation
SELECT
	 alloc_unit_type_desc
	,index_depth
	,page_count
	,avg_page_space_used_in_percent
	,record_count
	,forwarded_record_count
FROM
	sys.dm_db_index_physical_stats(db_id(), OBJECT_ID('DataPile'), 0, NULL, 'DETAILED');
GO

/* LOL: avg_page_space_used_in_percent: 0,770743760810477 ; less than 1 % :) */


-- craete nonclustered index on our heap
-- to look at the ID for page allocaiton
CREATE UNIQUE NONCLUSTERED INDEX ix_ncl_datapiledID ON DataPile(datapileID);
GO



--- now find page allocation!!!
-- and grab the allocated_page_page_id for INDEX_PAGE
SELECT
* 
FROM
	sys.dm_db_database_page_allocations(DB_ID(),OBJECT_ID('DataPile'),3,NULL,'DETAILED');
GO


--- blah blah blah
--- hash values for HEAP RID of the table
-- allocated_page_page_id for the row where page_type_desc=INDEX_PAGE
DBCC TRACEON (3604);
DBCC PAGE ('',1,169849,3);
GO
/*
HEAP RID:
0xC1FC000001000000
0xC1FC000001000100
0xC1FC000001000200
0xC1FC000001000300
0xC1FC000001000400*/


--- now let's rebuld the table

ALTER TABLE DataPile REBUilD;
GO


--- check for the page_type_desc=INDEX_paGE
SELECT
* 
FROM
	sys.dm_db_database_page_allocations(DB_ID(),OBJECT_ID('DataPile'),3,NULL,'DETAILED');
GO


DBCC TRACEON (3604);
DBCC PAGE ('',1,232840,3);
GO


/*
HEAP RID:
0x688D030001000000
0x688D030001000100
0x688D030001000200
0x688D030001000300
0x688D030001000400
*/

-- this will result in a looooooot of IO and running statistics and checking for correlation etc...is nonsense!



--- clean up
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


DROP TABLE DataPile;
GO