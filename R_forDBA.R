# 
# SQLSat Slovenia 2016
#
# Sample on fixsizeDB
#
library(e1071)
library(RODBC)
library(dplyr)
library(mclust)
library(ggplot2)
library(lubridate)
library(randomForest)
library(Hmisc)


# Get Data from MS SQL Server to R Environment
myconn <-odbcDriverConnect("driver={SQL Server};Server=SICN-KASTRUN;database=FixSizeDB;trusted_connection=true")

# All transactions 
All <- sqlQuery(myconn, "SELECT TableName,RowCounts,UsedSpaceKB,TimeMeasure FROM DataPack_Info")
close(myconn) 

#drop connection
rm(myconn)

head(All)

str(All)

all_sub <- All[2:3]


c <- cor(all_sub, use="complete.obs", method="pearson") 
t <- rcorr(as.matrix(all_sub), type="pearson")

c <- cor(all_sub, use="complete.obs", method="pearson") 
c <- data.frame(c)


# Get Data from MS SQL Server to R Environment
myconn <-odbcDriverConnect("driver={SQL Server};Server=SICN-KASTRUN;database=WideWorldImportersDW;trusted_connection=true")

# All 
All <- sqlQuery(myconn, "SELECT [total_logical_io],[avg_logical_reads],[avg_phys_reads],execution_count,[total_physical_reads],[total_elapsed_time],total_dop FROM query_stats_LOG WHERE Number is null")
close(myconn) 



All

library(cluster)
d <- dist(All, method = "euclidean") 
fit <- hclust(d, method="ward.D")
plot(fit,xlab=" ", ylab=NULL, main=NULL, sub=" ")
groups <- cutree(fit, k=3) 
rect.hclust(fit, k=3, border="DarkRed")


# Get Data from MS SQL Server to R Environment
myconn <-odbcDriverConnect("driver={SQL Server};Server=SICN-KASTRUN;database=DBA4R;trusted_connection=true")

# All 
All_QS <- sqlQuery(myconn, 'SELECT  * FROM QS_Query_stats_bck_2')
close(myconn) 

library(d3heatmap)
str(All_QS)
#d3heatmap(All_QS, scale = "column")

# sort data
All_QS <- All_QS[order(All_QS$avg_compile_duration),]

#row_names
row.names(All_QS) <- All_QS$Query_Name

All_QS <- All_QS[,2:10]
All_QS_matrix <- data.matrix(All_QS)

QS_Query_heatmap <- heatmap(All_QS_matrix, Rowv=NA, Colv=NA, col = cm.colors(256), scale="column", margins=c(5,10))

QS_Query_heatmap <- heatmap(All_QS_matrix, Rowv=NA, Colv=NA, col = heat.colors(256), scale="column", margins=c(5,10))






