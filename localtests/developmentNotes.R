
stop("Don't source this document")

# add new folders to fileIndex ----
# If rdwd has new folders, add them to fileIndex manually, in order to still use
# indexFTP with folder="currentfindex".
# Don't forget to update the overview in selectDWD as well!

{
data("fileIndex")
currentindexfolders <- unique(dirname(fileIndex$path))
cat(currentindexfolders, sep="\n")
hr <- c("historical", "recent")
new_folders <- c(paste0("/annual/kl/",hr), paste0("/annual/more_precip/",hr), paste0("/subdaily/pressure/",hr))
cat(new_folders, sep="\n")
fileIndex <- data.frame(path=c(currentindexfolders,new_folders), stringsAsFactors=FALSE)
message("saving and compressing reduced data/fileIndex.rda. Please run Index recreation now.")
save(fileIndex, file="data/fileIndex.rda")
tools::resaveRdaFiles("data/fileIndex.rda")
}






# fread speed test
links <- selectDWD(res="daily", var="kl", per="h")[1:30]
files <- dataDWD(links, dir="testfread", read=F)

system.time(  data1 <- readDWD(files, fread=FALSE)  )    # 10.4-11.3 secs for 30 files
system.time(  data2 <- readDWD(files, fread=TRUE )  )    #  7.5- 7.7 secs
system.time(  data3 <- readDWD(files)               )
all.equal(data1, data2) # TRUE


# not used for fwf meta files, hence the following is useles:
f <- dir("DWDdata/meta/",full.names=T)
system.time(  data1 <- readDWD(f, fread=FALSE) )  # 3.7 secs for 26 meta files
system.time(  data2 <- readDWD(f, fread=TRUE)  )  # 3.7





# libcurl returning OS dependent results:

if(!requireNamespace("RCurl", quietly=TRUE)) install.packages("RCurl")
link <- "ftp://ftp-cdc.dwd.de/pub/CDC/observations_germany/climate"
RCurl::getURL(link, ftp.use.epsv=TRUE, dirlistonly=TRUE)
Sys.info()['sysname']
.Platform$OS.type

library(curl)
readLines(curl(link, handle=new_handle(dirlistonly=TRUE, ftp_use_epsv=TRUE)))


wp <- curl::curl(link, handle=curl::new_handle(dirlistonly=TRUE, ftp_use_epsv=TRUE))
readLines(wp)

# Windows / windows:
w <- "climate\r\nphenology\r\nradiosondes\r\nclimate_urban\r\n"
# Linux / unix:
l <- "climate\nphenology\nradiosondes\nclimate_urban\n"
# Darwin? (Mac)
# SunOS? (Solaris)

# generic solution:
gsub("\r", "", strsplit(w, "\n")[[1]])
gsub("\r", "", strsplit(l, "\n")[[1]])






# readDWD meta = TRUE
# Development process and tests

# in october 2016, DWD slightly changed monthly/kl meta file column widths
# Here are alternative thoughs on how to automatize width detection


"
> spaces
[1]   6  15  24  25  26  27  28  29  30
[10]  31  32  33  34  38  39  40  41  42
[19]  50  51  52  53  60  65  66  67  68
[28]  69  70  71  72  73  74  75  76  77
[37]  78  79  80  81  82  83  84  85  86
[46]  87  88  89  90  91  92  93  94  95
[55]  96  97  98  99 100 101 119 120 121
[64] 122 123 124 125 126 127 128 129 130
[73] 131 132 133 134 135 136 137 138 139
[82] 140 141 142 143 144 145 146 147 148
[91] 149 150 151 152 153 154 155 156 157
[100] 158 159 160 161 162 163 164 165 166
[109] 167 168 169 170 171 172 173 174 175
[118] 176 177 178 179 180 181 182 183 184
[127] 185 186 187 188 189 190 191 192 193
[136] 194 195 196 197 198 199 200


> sb
[1]   1   2   3   4   5   6   7   8   9
[10]  10  12  21  30  31  32  33  34  35
[19]  36  37  38  39  40  41  45  46  47
[28]  48  49  57  58  59  60  67  72  73
[37]  74  75  76  77  78  79  80  81  82
[46]  83  84  85  86  87  88  89  90  91
[55]  92  93  94  95  96  97  98  99 100
[64] 101 102 103 104 105 106 107 108 126
[73] 127 128 129 130 131 132 133 134 135
[82] 136 137 138 139 140 141 142 143 144
[91] 145 146 147 148 149 150 151 152 153
[100] 154 155 156 157 158 159 160 161 162
[109] 163 164 165 166 167 168 169 170 171
[118] 172 173 174 175 176 177 178 179 180
[127] 181 182 183 184 185 186 187 188 189
[136] 190 191 192 193 194 195 196 197 198
[145] 199 200
"

#             .        .        ..                .          .      .                                        .                      .
#             6        15       24   -   34   38-42      50-53      60   65               -                101                 119-200
a="00001 18910101 19860630           478     47.8413    8.8493 Aach                                     Baden-Württemberg                                                                                  "
b="          1 19370101 19860630            478     47.8413    8.8493 Aach                                     Baden-Württemberg                                                                           "
#  1   -   10 12       21       30    -   41   45-49      57-60      67    72            -                  108                 126-200
#             *        *        **                *           *     *                                         *                       *
sa <- unlist(gregexpr(" ", a)) # monthly more_precip historical
sb <- unlist(gregexpr(" ", b)) # daily   kl          historical
sa[which(diff(sa)!=1)]
sa[which(diff(sa)!=1)+1]
sb[which(diff(sb)!=1)]


# Check a couple different styles with:
mf <- selectDWD(res=c(rep("hourly",3), "monthly", "daily"), var=c("cloudiness","solar","sun","kl","kl"),
                time=c(rep("r",4), "h"), meta=TRUE, outvec=T, current=TRUE)

m <- dataDWD(mf)
lapply(m, head)

# Also removed from readDWD (see note on selectDWD id argument):

#                ID           VON         BIS        HOEHE    LAT       LONG      NAME     BUNDESLAND
#colClasses <- c("character", "integer", "integer", "numeric","numeric","numeric","factor","factor")
# some meta files have no leading zeros, so this package uses integer all the time. # colClasses=colClasses



context("Station coordinates")

# check coordinates:
coord_ok <- pbsapply(unique(metaIndex$Stationsname), function(n)
{
 sel <- metaIndex$Stationsname==n
 lat <- metaIndex$geoBreite[sel]
 lon <- metaIndex$geoLaenge[sel]
 ele <- metaIndex$Stationshoehe[sel]
 d <- 6 # number of digits rounded to
 all(round(lat,d)==round(lat[1],d)  &  round(lon,d)==round(lon[1],d)  & ele==ele[1]  )
})
mean(coord_ok) # 79% is OK, 94.9 % with d=2, 98% with d=1
names(coord_ok[!coord_ok])


# some more checks:
mean(metaIndex$hasfile) # 72% has a file
length(unique(metaIndex$Stations_id)) # 5778 IDs (5660 in geoIndex)
hist(table(metaIndex$Stations_id), breaks=100, col="cadetblue", xlab="number of entries per ID")

checkdupli <- function(a,b, x=metaIndex)
{
 d <- tapply(x[,a], x[,b], unique)
 list( morethan1=d[sapply(d, length)!=1],   table=table(sapply(d, length)) )
}

checkdupli("Bundesland", "Stationsname") # $`Holzdorf (Flugplatz)` "Sachsen-Anhalt" "Brandenburg"
checkdupli("Stations_id", "Stationsname") # $Hoerstel 2254 15559
checkdupli("Stationsname", "Stations_id") # 53 with 2

checkdupli("name", "id", geoIndex) # 44 with 2

sum(geoIndex$nfiles_coord) # 25482
hist(geoIndex$nfiles_coord, breaks=100, col="cadetblue", xlab="number of files per location")


# static maps -----

if(!requireNameSpace("OSMscale")) install.packages("OSMscale")
library("OSMscale")

# Map of all precipitation stations (metaindex):
map <- pointsMap(geoBreite, geoLaenge, data=metaIndex, fx=0.28, fy=0.06)
pdf("DWDdata/RainfallStationsMap.pdf")
plot(map)
scaleBar(map, x=0.05, y=0.03, abslen=200)
pp <- projectPoints(geoBreite, geoLaenge, data=metaIndex, to=posm())
points(pp[!metaIndex$hasfile,], col="red", pch=3)
points(pp[ metaIndex$hasfile,], col="blue", pch=3)
legend("bottomright", c("in matadata only", "file on FTP server"),
       col=c("red", "blue"), pch=3, bg="white")
title(main="DWD stations: data on ftp server", line=3)
dev.off()


# map geoIndex

map <- pointsMap(lat, long, data=geoIndex, fx=0.06, fy=0.06)
pdf("DWDdata/RainfallStationsMap_nfiles.pdf", width=5)
plot(map)
scaleBar(map, x=0.05, y=0.03, abslen=200)
geoIndex <- sortDF(geoIndex, "nfiles_coord", decreasing=FALSE)
pp <- projectPoints(lat, long, data=geoIndex, to=posm())
points(pp, cex=0.6)
colPoints(pp$x, pp$y, geoIndex$nfiles_coord, cex=0.6, zlab="")
title(main="DWD stations: number of files on ftp server", line=3)
dev.off()


# Time series duration:
# colPoints <- berryFunctions::colPoints
colPoints(geoLaenge, geoBreite, Stations_id, data=metaIndex, add=F, asp=1.5)
colPoints(geoLaenge, geoBreite, Stationshoehe, data=metaIndex, add=F, asp=1.5)
metaIndex$von_jahr <- metaIndex$von_datum/1e4
metaIndex$bis_jahr <- metaIndex$bis_datum/1e4
metaIndex$dauer <- metaIndex$bis_jahr - metaIndex$von_jahr
colPoints(geoLaenge, geoBreite, von_jahr, data=metaIndex, add=F, asp=1.5)
colPoints(geoLaenge, geoBreite, bis_jahr, data=metaIndex, add=F, asp=1.5)
colPoints(geoLaenge, geoBreite, dauer, data=metaIndex, add=F, asp=1.5)
hist(metaIndex$bis_jahr, breaks=50, col="purple")
hist(metaIndex$dauer, breaks=50, col="purple")
sum(metaIndex$dauer>50); mean(metaIndex$dauer>50)
# 45% of stations with more than 50 years of data (according to metadata)




link <- selectDWD("Potsdam", res="10_minutes", var="wind", per="recent")
file <- dataDWD(link, read=FALSE, dir=tempdir())
vars <- readVars(file); vars



file <- dataDWD("ftp://ftp-cdc.dwd.de/pub/CDC/observations_germany/climate/hourly/solar/stundenwerte_ST_05906_row.zip", read=FALSE)
clim <- readDWD(file) # format not autodetected, read.table charstring?

