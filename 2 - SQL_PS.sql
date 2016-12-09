/*

-- Storing data from PowerShell into SQL Server

-- Gathering information and performing Analysis

*/


USE DBA4R;
GO

-- DROP TABLE dbo.DiskSpace

CREATE TABLE dbo.DiskSpace
(
 SystemName NVARCHAR(128)
,DeviceID CHAR(2)
,Size BIGINT
,FreeSpace BIGINT
,Time_Stamp DATETIME DEFAULT GETDATE()
);


SELECT * FROM dbo.DiskSpace

-- DROP TABLE dbo.NetworkStatistics

CREATE TABLE dbo.NetworkStatistics
(
 ifAlias NVARCHAR(128)
,ReceivedBytes BIGINT
,ReceivedUnicastPackets BIGINT
,SentBytes BIGINT
,SentUnicastPackets BIGINT
,Time_Stamp DATETIME DEFAULT GETDATE()
);



SELECT * FROM NetworkStatistics



