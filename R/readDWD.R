# read dwd data ----

#' Process data from the DWD CDC FTP Server
#' 
#' Read climate data that was downloaded with \code{\link{dataDWD}}.
#' The data is unzipped and subsequently, the file is read, processed and
#' returned as a data.frame.\cr
#' New users are advised to set \code{varnames=TRUE} to obtain more informative
#' column names.\cr\cr
#' \code{readDWD} will call internal (but documented) functions depending on the
#' arguments \code{meta, binary, raster, multia, asc}:\cr
#' to read observational data: \code{\link{readDWD.data},
#'          \link{readDWD.meta}, \link{readDWD.multia}}\cr
#' to read interpolated gridded data: \code{\link{readDWD.binary},
#'          \link{readDWD.raster}, \link{readDWD.asc}}\cr
#' Not all arguments to \code{readDWD} are used for all functions, e.g. 
#' \code{fread} is used only by \code{.data}, while \code{dividebyten} 
#' is used in \code{.raster} and \code{.asc}.\cr\cr
#' \code{file} can be a vector with several filenames. Most other arguments can
#' also be a vector and will be recycled to the length of \code{file}.
#' 
#' @return Invisible data.frame of the desired dataset, 
#'         or a named list of data.frames if length(file) > 1.
#'         \code{\link{readDWD.binary}} returns a vector, 
#'         \code{\link{readDWD.raster}} and \code{\link{readDWD.asc}} 
#'         return raster objects instead of data.frames.
#' @author Berry Boessenkool, \email{berry-b@@gmx.de}, Jul-Oct 2016, Winter 2018/19
#' @seealso \code{\link{dataDWD}}, \code{\link{readVars}}, 
#'          \code{\link{readMeta}}, \code{\link{selectDWD}}
#' @keywords file chron
#' @importFrom utils read.table unzip read.fwf untar write.table
#' @importFrom berryFunctions checkFile na9 traceCall l2df owa
#' @importFrom pbapply pblapply
#' @importFrom tools file_path_sans_ext
#' @export
#' @examples
#' # see dataDWD
#' 
#' @param file   Char (vector): name(s) of the file(s) downloaded with 
#'               \code{\link{dataDWD}},
#'               e.g. "~/DWDdata/tageswerte_KL_02575_akt.zip" or
#'               "~/DWDdata/RR_Stundenwerte_Beschreibung_Stationen.txt"
#' @param progbar Logical: present a progress bar with estimated remaining time?
#'               If missing and length(file)==1, progbar is internally set to FALSE.
#'               DEFAULT: TRUE
#' @param fread  Logical (vector): read fast? See \code{\link{readDWD.data}}.
#'               DEFAULT: FALSE (some users complain it doesn't work on their PC)
#' @param varnames Logical (vector): Expand column names? 
#'               See \code{\link{readDWD.data}}. DEFAULT: FALSE
#' @param format,tz Format and time zone of time stamps, see \code{\link{readDWD.data}}
#' @param dividebyten Logical (vector): Divide the values in raster files by ten?
#'               Used in \code{\link{readDWD.raster}} and \code{\link{readDWD.asc}}.
#'               DEFAULT: TRUE
#' @param meta   Logical (vector): is the \code{file} a meta file (Beschreibung.txt)?
#'               See \code{\link{readDWD.meta}}.
#'               DEFAULT: TRUE for each file ending in ".txt"
#' @param multia Logical (vector): is the \code{file} a multi_annual file?
#'               Overrides \code{meta}, so set to FALSE manually if 
#'               \code{\link{readDWD.meta}} needs to be called on a file ending
#'               with "Standort.txt". See \code{\link{readDWD.multia}}.
#'               DEFAULT: TRUE for each file ending in "Standort.txt"
#' @param binary Logical (vector): does the \code{file} contain binary files?
#'               See \code{\link{readDWD.binary}}.
#'               DEFAULT: TRUE for each file ending in ".tar.gz"
#' @param raster Logical (vector): does the \code{file} contain a raster file?
#'               See \code{\link{readDWD.raster}}.
#'               DEFAULT: TRUE for each file ending in ".asc.gz"
#' @param asc    Logical (vector): does the \code{file} contain asc files?
#'               See \code{\link{readDWD.asc}}.
#'               DEFAULT: TRUE for each file ending in ".tar"
#' @param \dots  Further arguments passed to the internal \code{readDWD.*} 
#'               functions and from those to the underlying reading functions
#'               documented in each internal function.
#' 
readDWD <- function(
file,
progbar=TRUE,
fread=FALSE,
varnames=FALSE,
format=NA,
tz="GMT",
dividebyten=TRUE,
meta=  grepl(        '.txt$', file),
multia=grepl('Standort.txt$', file),
binary=grepl(     '.tar.gz$', file),
raster=grepl(     '.asc.gz$', file),
asc=   grepl(        '.tar$', file),
...
)
{
# recycle arguments:
len <- length(file)
if(missing(progbar) & len==1 & all(!binary) & all(!asc)) progbar <- FALSE
if(anyNA(fread)) fread[is.na(fread)] <- requireNamespace("data.table",quietly=TRUE)
if(len>1)
  {
  fread       <- rep(fread,       length.out=len)
  varnames    <- rep(varnames,    length.out=len)
  format      <- rep(format,      length.out=len)
  tz          <- rep(tz,          length.out=len)
  dividebyten <- rep(dividebyten, length.out=len)
  meta        <- rep(meta,        length.out=len)
  multia      <- rep(multia,      length.out=len)
  binary      <- rep(binary,      length.out=len)
  raster      <- rep(raster,      length.out=len)
  asc         <- rep(asc,         length.out=len) 
  }
meta[multia] <- FALSE
# Optional progress bar:
if(progbar) lapply <- pbapply::pblapply
# check package availability:
if(any(fread))   if(!requireNamespace("data.table", quietly=TRUE))
    stop("in rdwd::readDWD: to use fread=TRUE, please first install data.table:",
         "   install.packages('data.table')", call.=FALSE)
#
checkFile(file)
# Handle German Umlaute:
if(any(meta)) # faster to change locale once here, instead of in each readDWD.meta call
{
lct <- Sys.getlocale("LC_CTYPE")
on.exit(Sys.setlocale(category="LC_CTYPE", locale=lct), add=TRUE)
if(!grepl(pattern="german", lct, ignore.case=TRUE))
  {
  lctry <- c("German","de_DE","de_DE.UTF-8","de_DE.utf8","de")
  for(lc in lctry) if(suppressWarnings(Sys.setlocale("LC_CTYPE", lc))!="") break
  }
}
#
if(progbar) message("Reading ", length(file), " file", if(length(file)>1)"s", "...")
#
# loop over each filename
output <- lapply(seq_along(file), function(i)
{
# if meta/binary/raster/multia:
if(meta[i])   return(readDWD.meta(  file[i], ...))
if(binary[i]) return(readDWD.binary(file[i], progbar=progbar, ...))
if(raster[i]) return(readDWD.raster(file[i], dividebyten=dividebyten[i], ...))
if(multia[i]) return(readDWD.multia(file[i], ...))
if(asc[i])    return(readDWD.asc(   file[i], progbar=progbar, dividebyten=dividebyten[i], ...))
# if data:
readDWD.data(file[i], fread=fread[i], varnames=varnames[i], 
             format=format[i], tz=tz[i], ...)
}) # lapply loop end
#
names(output) <- tools::file_path_sans_ext(basename(file))
output <- if(length(file)==1) output[[1]] else output
return(invisible(output))
}





# read observational data ----

# ~ data ----

#' @title read regular dwd data
#' @description Read regular dwd data. 
#' Intended to be called via \code{\link{readDWD}}.
#' @return data.frame
#' @author Berry Boessenkool, \email{berry-b@@gmx.de}
#' @seealso \code{\link{readDWD}}, Examples in \code{\link{dataDWD}}
#' @param file     Name of file on harddrive, like e.g. 
#'                 DWDdata/daily_kl_recent_tageswerte_KL_03987_akt.zip
#' @param fread    Logical: read faster with \code{data.table::\link[data.table]{fread}}?
#'                 When reading many large historical files, speedup is significant.
#'                 NA can also be used, which means TRUE if data.table is available.
#'                 DEFAULT: FALSE
#' @param varnames Logical (vector): add a short description to the DWD variable 
#'                 abbreviations in the column names?
#'                 E.g. change \code{FX,TNK} to \code{FX.Windspitze,TNK.Lufttemperatur_Min},
#'                 see \code{\link{newColumnNames}}.
#'                 DEFAULT: FALSE (for backwards compatibility) 
#' @param format   Char (vector): Format passed to
#'                 \code{\link{as.POSIXct}} (see \code{\link{strptime}})
#'                 to convert the date/time column to POSIX time format.\cr
#'                 If NULL, no conversion is performed (date stays a factor).
#'                 If NA, \code{readDWD} tries to find a suitable format based
#'                 on the number of characters. DEFAULT: NA
#' @param tz       Char (vector): time zone for \code{\link{as.POSIXct}}.
#'                 "" is the current time zone, and "GMT" is UTC (Universal Time,
#'                 Coordinated). DEFAULT: "GMT"
#' @param \dots    Further arguments passed to \code{\link{read.table}} or 
#'                 \code{data.table::\link[data.table]{fread}}
readDWD.data <- function(file, fread=FALSE, varnames=FALSE, format=NA, tz="GMT", ...)
{
if(fread)
  {
  # http://dsnotes.com/post/2017-01-27-lessons-learned-from-outbrain-click-prediction-kaggle-competition/
  fp <- unzip(file, list=TRUE) # file produkt*, the actual datafile
  fp <- fp$Name[grepl("produkt",fp$Name)]
  dat <- data.table::fread(cmd=paste("unzip -p", file, fp), na.strings=na9(nspace=0),
                           header=TRUE, sep=";", stringsAsFactors=TRUE, data.table=FALSE, ...)
  } else
{
# temporary unzipping directory
fn <- tools::file_path_sans_ext(basename(file))
exdir <- paste0(tempdir(),"/", fn)
unzip(file, exdir=exdir)
on.exit(unlink(exdir, recursive=TRUE), add=TRUE)
# Read the actual data file:
f <- dir(exdir, pattern="produkt*", full.names=TRUE)
if(length(f)!=1) stop("There should be a single 'produkt*' file, but there are ",
                      length(f), " in\n  ", file, "\n  Consider re-downloading (with force=TRUE).")
dat <- read.table(f, na.strings=na9(), header=TRUE, sep=";", as.is=FALSE, ...)
} # end if(!fread)
#
if(varnames)  dat <- newColumnNames(dat)
# return if file is empty, e.g. for daily/more_precip/hist_05988 2019-05-16:
if(nrow(dat)==0)
  {
  warning("File contains no rows: ", file)
  return(dat)
  }
# process time-stamp: http://stackoverflow.com/a/13022441
if(!is.null(format))
  {
  # for res=monthly data:
  if("MESS_DATUM_BEGINN" %in% colnames(dat))
    dat <- cbind(dat[,1, drop=FALSE], MESS_DATUM=dat$MESS_DATUM_BEGINN + 14, dat[,-1])
  if(!"MESS_DATUM" %in% colnames(dat)) 
    warning("There is no column 'MESS_DATUM' in ",file, call.=FALSE) else
    {
    nch <- nchar(as.character(dat$MESS_DATUM[1]))
    if(is.na(format)) format <- if(nch== 8) "%Y%m%d" else 
                                if(nch==13) "%Y%m%d%H:%M" else"%Y%m%d%H"
    dat$MESS_DATUM <- as.POSIXct(as.character(dat$MESS_DATUM), format=format, tz=tz)
    }
  }
# final output:
return(dat)
}



# ~ meta ----

#' @title read dwd metadata (Beschreibung*.txt files)
#' @description read dwd metadata (Beschreibung*.txt files).
#'  Intended to be called via \code{\link{readDWD}}.\cr
#'  Column widths for \code{\link{read.fwf}} are computed internally.\cr
#'  if(any(meta)), \code{\link{readDWD}} tries to set the locale to German 
#'  (to handle Umlaute correctly). It is hence not recommended to call
#'  \code{rdwd:::readDWD.meta} directly on a file!\cr
#'  Names can later be changed to ascii with 
#'  \code{berryFunctions::\link{convertUmlaut}}.
#' @return data.frame
#' @author Berry Boessenkool, \email{berry-b@@gmx.de}
#' @seealso \code{\link{readDWD}}
#' @examples
#' \dontrun{ # Excluded from CRAN checks, but run in localtests
#' 
#' link <- selectDWD(res="daily", var="kl", per="r", meta=TRUE)
#' if(length(link)!=1) stop("length of link should be 1, but is ", length(link), 
#'                 ":\n", berryFunctions::truncMessage(link,prefix="",sep="\n"))
#' 
#' file <- dataDWD(link, dir=localtestdir(), read=FALSE)
#' meta <- readDWD(file)
#' head(meta)
#' 
#' cnm <- colnames(meta)
#' if(length(cnm)!=8) stop("number of columns should be 8, but is ", length(cnm),
#'                         ":\n", toString(cnm))
#' }
#' @param file  Name of file on harddrive, like e.g. 
#'              DWDdata/daily_kl_recent_KL_Tageswerte_Beschreibung_Stationen.txt
#' @param \dots Further arguments passed to \code{\link{read.fwf}}
readDWD.meta <- function(file, ...)
{
# read one line to get column widths and names
oneline <- readLines(file, n=3, encoding="latin1")
# column widths (automatic detection across different styles used by the DWD)
spaces <- unlist(gregexpr(" ", oneline[3]))
breaks <- spaces[which(diff(spaces)!=1)]
if(substr(oneline[3],1,1)==" ") breaks <- breaks[-1]
breaks[3] <- breaks[3] -9 # right-adjusted column
breaks[4:5] <- breaks[4:5] -1 # right-adjusted columns
widths <- diff(c(0,breaks,200))
sdsf <- grepl("subdaily_standard_format", file)
if(sdsf) widths <- c(6,6,9,10,10,10,10,26,200)
# actually read metadata, suppress readLines warning about EOL:
stats <- suppressWarnings(read.fwf(file, widths=widths, skip=2, strip.white=TRUE, 
                                   fileEncoding="latin1", ...) )
# column names:
# remove duplicate spaces (2018-03 only in subdaily_stand...Beschreibung....txt)
while( grepl("  ",oneline[1]) )  oneline[1] <- gsub("  ", " ", oneline[1])
colnames(stats) <- strsplit(oneline[1], " ")[[1]]
if(sdsf)
 {
 stats <- stats[ ! stats[,1] %in% c("","ST_KE","-----") , ]
 tf <- tempfile()
 write.table(stats[,-1], file=tf, quote=FALSE, sep="\t")
 stats <- read.table(tf, sep="\t")
 colnames(stats) <- c("Stations_id", "von_datum", "bis_datum", "Stationshoehe", 
                      "geoBreite", "geoLaenge", "Stationsname", "Bundesland")
 }
# check classes:
classes <- c("integer", "integer", "integer", "integer", "numeric", "numeric", "factor", "factor")
actual <- sapply(stats, class)
if(actual[4]=="numeric") classes[4] <- "numeric"
if(!all(actual == classes))
  {
  msg <- paste0(names(actual)[actual!=classes], ": ", actual[actual!=classes],
                " instead of ", classes[actual!=classes], ".")
  msg <- paste(msg, collapse=" ")
  warning(traceCall(3, "", ": "), "reading file '", file,
          "' did not give the correct column classes. ", msg, call.=FALSE)
  }
# return meta data.frame:
stats
}



# ~ multia ----

#' @title read multi_annual dwd data
#' @description read multi_annual dwd data. 
#' Intended to be called via \code{\link{readDWD}}.\cr
#' All other observational data at \code{\link{dwdbase}} can be read
#' with \code{\link{readDWD.data}}, except for the multi_annual data.
#' @return data.frame
#' @author Berry Boessenkool, \email{berry-b@@gmx.de}, Feb 2019
#' @seealso \code{\link{readDWD}}
#' @examples
#' \dontrun{ # Excluded from CRAN checks, but run in localtests
#' 
#' # Temperature aggregates (2019-04 the 9th file):
#' durl <- selectDWD(res="multi_annual", var="mean_81-10", per="")[9]
#' murl <- selectDWD(res="multi_annual", var="mean_81-10", per="", meta=TRUE)[9]
#' 
#' ma_temp <- dataDWD(durl, dir=localtestdir())
#' ma_meta <- dataDWD(murl, dir=localtestdir())
#' 
#' head(ma_temp)
#' head(ma_meta)
#' 
#' ma <- merge(ma_meta, ma_temp, all=TRUE)
#' berryFunctions::linReg(ma$Stationshoehe, ma$Jahr)
#' op <- par(mfrow=c(3,4), mar=c(0.1,2,2,0), mgp=c(3,0.6,0))
#' for(m in colnames(ma)[8:19])
#'   {
#'   berryFunctions::linReg(ma$Stationshoehe, ma[,m], xaxt="n", xlab="", ylab="", main=m)
#'   abline(h=0)
#'   }
#' par(op)
#' 
#' par(bg=8)
#' berryFunctions::colPoints(ma$geogr..Laenge, ma$geogr..Breite, ma$Jahr, add=F, asp=1.4)
#' 
#' data("DEU")
#' pdf("MultiAnn.pdf", width=8, height=10)
#' par(bg=8)
#' for(m in colnames(ma)[8:19])
#'   {
#'   raster::plot(DEU, border="darkgrey")
#'   berryFunctions::colPoints(ma[-262,]$geogr..Laenge, ma[-262,]$geogr..Breite, ma[-262,m], 
#'                             asp=1.4, # Range=range(ma[-262,8:19]), 
#'                             col=berryFunctions::divPal(200, rev=TRUE), zlab=m, add=T)
#'   }
#' dev.off()
#' berryFunctions::openFile("MultiAnn.pdf")
#' }
#' @param file  Name of file on harddrive, like e.g. 
#'              DWDdata/multi_annual_mean_81-10_Temperatur_1981-2010_aktStandort.txt or
#'              DWDdata/multi_annual_mean_81-10_Temperatur_1981-2010_Stationsliste_aktStandort.txt
#' @param fileEncoding \link{read.table} \link{file} encoding.
#'              DEFAULT: "latin1" (needed on Linux, optional but not hurting on windows)
#' @param comment.char \link{read.table} comment character.
#'              DEFAULT: "\\032" (needed 2019-04 to ignore the binary 
#'              control character at the end of multi_annual files)
#' @param \dots Further arguments passed to \code{\link{read.table}}
readDWD.multia <- function(file, fileEncoding="latin1", comment.char="\032", ...)
{
out <- read.table(file, sep=";", header=TRUE, fileEncoding=fileEncoding, 
                  comment.char=comment.char, ...)
nc <- ncol(out)
# presumably, all files have a trailing empty column...
if(colnames(out)[nc]=="X") out <- out[,-nc]
out
}



# read gridded data ----

# ~ binary ----

#' @title read dwd gridded radolan binary data
#' @description read gridded radolan binary data.
#' Intended to be called via \code{\link{readDWD}}.\cr
#' @return list depending on argument \code{toraster}, see there for details
#' @author Berry Boessenkool, \email{berry-b@@gmx.de}, Dec 2018. 
#'         Significant input for the underlying \code{\link{readRadarFile}} came
#'         from Henning Rust & Christoph Ritschel at FU Berlin.
#' @seealso \code{\link{readDWD}}\cr
#'   \url{https://wradlib.org} for much more extensive radar analysis in Python\cr
#'   Kompositformatbeschreibung at \url{https://www.dwd.de/DE/leistungen/radolan/radolan.html}
#'   for format description
#' @examples
#' \dontrun{ # Excluded from CRAN checks, but run in localtests
#' 
#' # SF file as example: ----
#' 
#' SF_link <- "/daily/radolan/historical/bin/2017/SF201712.tar.gz"
#' SF_file <- dataDWD(file=SF_link, base=gridbase, joinbf=TRUE,   # 204 MB
#'                      dir=localtestdir(), read=FALSE)
#' # exdir radardir set to speed up my tests:
#' SF_exdir <- "C:/Users/berry/Desktop/DWDbinarySF"
#' if(!file.exists(SF_exdir)) SF_exdir <- tempdir()
#' # no need to read all 24*31=744 files, so setting selection:
#' SF_rad <- readDWD(SF_file, selection=1:10, exdir=SF_exdir) #with toraster=TRUE 
#' if(length(SF_rad)!=2) stop("length(SF_rad) should be 2, but is ", length(SF_rad))
#' 
#' SF_radp <- projectRasterDWD(SF_rad$data)
#' raster::plot(SF_radp[[1]], main=SF_rad$meta$date[1])
#' data(DEU)
#' raster::plot(DEU, add=TRUE)
#' 
#' 
#' # RW file as example: ----
#' 
#' RW_link <- "hourly/radolan/reproc/2017_002/bin/2017/RW2017.002_201712.tar.gz"
#' RW_file <- dataDWD(file=RW_link, base=gridbase, joinbf=TRUE,   # 25 MB
#'                   dir=localtestdir(), read=FALSE)
#' RW_exdir <- "C:/Users/berry/Desktop/DWDbinaryRW"
#' if(!file.exists(RW_exdir)) RW_exdir <- tempdir()
#' RW_rad <- readDWD(RW_file, selection=1:10, exdir=RW_exdir)
#' RW_radp <- projectRasterDWD(RW_rad$data, extent="rw")
#' raster::plot(RW_radp[[1]], main=RW_rad$meta$date[1])
#' raster::plot(DEU, add=TRUE)
#' 
#' # ToDo: why are values + patterns not the same?
#' 
#' # list of all Files: ----
#' data(gridIndex)
#' head(grep("historical", gridIndex, value=TRUE))
#' }
#' @param file      Name of file on harddrive, like e.g. 
#'                  DWDdata/daily_radolan_historical_bin_2017_SF201712.tar.gz
#' @param exdir     Directory to unzip into. If existing, only the needed files
#'                  will be unpacked with \code{\link{untar}}. Note that exdir
#'                  size will be around 1.1 GB. exdir can contain other files, 
#'                  these will be ignored for the actual reading with 
#'                  \code{\link{readRadarFile}} (function not exported, but documented).
#'                  DEFAULT exdir: sub(".tar.gz$", "", file)
#' @param toraster  Logical: convert output (list of matrixes + meta informations)
#'                  to a list with data (\code{raster \link[raster]{stack}}) + 
#'                  meta (list from the first subfile, but with vector of dates)?
#'                  DEFAULT: TRUE
#' @param progbar   Show messages and progress bars? \code{\link{readDWD}} will
#'                  keep progbar=TRUE for binary files, even if length(file)==1.
#'                  DEFAULT: TRUE
#' @param selection Optionally read only a subset of the ~24*31=744 files.
#'                  Called as \code{f[selection]}. DEFAULT: NULL (ignored)
#' @param \dots     Further arguments passed to \code{\link{readRadarFile}}, 
#'                  i.e. \code{na} and \code{clutter}
readDWD.binary <- function(file, exdir=sub(".tar.gz$", "", file), 
                           toraster=TRUE, progbar=TRUE, selection=NULL, ...)
{
pmessage <- function(...) if(progbar) message(...)
# Untar as needed:
pmessage("\nChecking which files need to be untarred to ", exdir, "...")
lf <- untar(file, list=TRUE)
tountar <- !lf %in% dir(exdir)
if(any(tountar)) 
  {
  pmessage("Unpacking ",sum(tountar), " of ",length(lf), " files in ",file,"...")
  untar(file, files=lf[tountar], exdir=exdir)
  } else 
  pmessage("All files were already untarred.")
#
# hourly files:
f <- dir(exdir, full.names=TRUE) # 31*24 = 744 files  (daily/hist/2017-12)
# read only the ones from file, not other stuff at exdir:
f <- f[basename(f) %in% lf]
if(!is.null(selection)) f <- f[selection]
#
pmessage("Reading ",length(f)," binary files...")
if(progbar) lapply <- pbapply::pblapply
# Read the actual binary file:
rb <- lapply(f, readRadarFile, ...)
# list element names (time stamp):
time <- sapply(rb, function(x) as.character(x$meta$date))
names(rb) <- time
if(!toraster) return(invisible(rb))
# else if toraster:
if(!requireNamespace("raster", quietly=TRUE))
 stop("To use rdwd:::readDWD.binary with toraster=TRUE, please first install raster:",
      "   install.packages('raster')", call.=FALSE)
pmessage("Converting to raster stack....")
rbmat <- base::lapply(rb,"[[",1)
rbmat <- base::lapply(rbmat, raster::raster)
rbmat <- raster::stack(rbmat)
# rbmeta <- base::lapply(rb,"[[",2)
# rbmeta <- base::lapply(rbmeta, function(x){x$radars <- toString(x$radars);
#                                            x$radarn <- toString(x$radarn);
#                                            x$dim    <- toString(x$dim)   ; x})
# mnames <- names(rbmeta[[1]])[-(1:2)] # filename and date will differ
# sapply(mnames, function(mn) length(unique(sapply(rbmeta, "[[", mn)))) # all equal
rbmeta <- rb[[1]]$meta
rbmeta$filename <- file
rbmeta$date <- as.POSIXct(time)
return(invisible(list(data=rbmat, meta=rbmeta)))
}




# ~ raster ----

#' @title read dwd gridded raster data
#' @description Read gridded raster data. 
#' Intended to be called via \code{\link{readDWD}}.\cr
#' Note that \code{R.utils} must be installed to unzip the .asc.gz files.
#' @return \code{raster::\link[raster]{raster}} object
#' @author Berry Boessenkool, \email{berry-b@@gmx.de}, Dec 2018
#' @seealso \code{\link{readDWD}}
#' @examples
#' \dontrun{ # Excluded from CRAN checks, but run in localtests
#' 
#' rasterbase <- paste0(gridbase,"/seasonal/air_temperature_mean")
#' ftp.files <- indexFTP("/16_DJF", base=rasterbase, dir=tempdir())
#' localfiles <- dataDWD(ftp.files[1:2], base=rasterbase, joinbf=TRUE,
#'                       dir=localtestdir(), read=FALSE)
#' rf <- readDWD(localfiles[1])
#' rf <- readDWD(localfiles[1]) # runs faster at second time due to skip=TRUE
#' raster::plot(rf)
#' 
#' rfp <- projectRasterDWD(rf, proj="seasonal", extent=rf@extent)
#' raster::plot(rfp)
#' data(DEU)
#' raster::plot(DEU, add=TRUE)
#' 
#' testthat::expect_equal(raster::cellStats(rf, range), c(-8.2,4.4))
#' rf10 <- readDWD(localfiles[1], dividebyten=FALSE)
#' raster::plot(rf10)
#' testthat::expect_equal(raster::cellStats(rf10, range), c(-82,44))
#' }
#' @param file        Name of file on harddrive, like e.g. 
#'                    DWDdata/grids_germany/seasonal/air_temperature_mean/
#'                    16_DJF_grids_germany_seasonal_air_temp_mean_188216.asc.gz
#' @param gargs       Named list of arguments passed to 
#'                    \code{R.utils::\link[R.utils]{gunzip}}. The internal 
#'                    defaults are: \code{remove=FALSE} (recommended to keep this
#'                    so \code{file} does not get deleted) and \code{skip=TRUE}
#'                    (which reads previously unzipped files as is).
#'                    If \code{file} has changed, you might want to use 
#'                    \code{gargs=list(skip=FALSE, overwrite=TRUE)}
#'                    or alternatively \code{gargs=list(temporary=TRUE)}.
#'                    The \code{gunzip} default \code{destname} means that the 
#'                    unzipped file is stored at the same path as \code{file}.
#'                    DEFAULT gargs: NULL
#' @param dividebyten Logical: Divide the numerical values by 10?
#'                    DEFAULT: TRUE
#' @param \dots       Further arguments passed to \code{raster::\link[raster]{raster}}
readDWD.raster <- function(file, gargs=NULL, dividebyten, ...)
{
if(!requireNamespace("R.utils", quietly=TRUE))
  stop("To use rdwd:::readDWD.raster, please first install R.utils:",
       "   install.packages('R.utils')", call.=FALSE)
if(!requireNamespace("raster", quietly=TRUE))
 stop("To use rdwd:::readDWD.raster, please first install raster:",
      "   install.packages('raster')", call.=FALSE)
#https://stackoverflow.com/questions/5227444/recursively-ftp-download-then-extract-gz-files
# gunzip arguments:
gdef <- list(filename=file, remove=FALSE, skip=TRUE)
gfinal <- berryFunctions::owa(gdef, gargs, "filename")
rdata <- do.call(R.utils::gunzip, gfinal)
# raster reading:
r <- raster::raster(rdata, ...)
if(dividebyten) r <- r/10
return(invisible(r))
}



# ~ asc ----

#' @title read dwd gridded radolan asc data
#' @description read grid-interpolated radolan asc data. 
#' Intended to be called via \code{\link{readDWD}}.\cr
#' See \url{ftp://ftp-cdc.dwd.de/pub/CDC/grids_germany/hourly/radolan/README.txt}
#' All layers (following \code{selection} if given) in all .tar.gz files are 
#' combined into a raster stack with \code{raster::\link[raster]{stack}}.\cr
#' To project the data, use \code{\link{projectRasterDWD}}
#' @return data.frame
#' @author Berry Boessenkool, \email{berry-b@@gmx.de}, April 2019
#' @seealso \code{\link{readDWD}}
# @importFrom raster raster stack crs projection extent plot
#' @examples 
#' \dontrun{ # Excluded from CRAN checks, but run in localtests
#' 
#' # File selection and download:
#' datadir <- localtestdir()
#' # 2019-05-18, hourly radolan files not yet copied to new ftp, hence:
#' gridbase <- "ftp://ftp-cdc.dwd.de/pub/CDC/grids_germany" 
#' radbase <- paste0(gridbase,"/hourly/radolan/historical/asc/")
#' radfile <- "2018/RW-201809.tar" # 25 MB to download
#' file <- dataDWD(radfile, base=radbase, joinbf=TRUE, dir=datadir,
#'                 dfargs=list(mode="wb"), read=FALSE) # download with mode=wb!!!
#'                 
#' #asc <- readDWD(file) # 4 GB in mem. ~ 20 secs unzip, 30 secs read, 10 min divide
#' asc <- readDWD(file, selection=1:20, dividebyten=TRUE)
#' asc <- projectRasterDWD(asc)
#' 
#' raster::plot(asc[[1]], main=names(asc)[1])
#' data(DEU)
#' raster::plot(DEU, add=TRUE)
#' 
#' rng <- range(raster::cellStats(asc, "range"))
#' nframes <- 3 # raster::nlayers(asc) for all (time intensive!)
#' viddir <- paste0(tempdir(),"/RadolanVideo")
#' dir.create(viddir)
#' png(paste0(viddir,"/Radolan_%03d.png"), width=7, height=5, units="in", res=300)
#' dummy <- pbsapply(1:nframes, function(i) 
#'          raster::plot(asc[[i]], main=names(asc)[i], zlim=rng)) # 3 secs per layer
#' dev.off()
#' berryFunctions::openFile(paste0(viddir,"/Radolan_001.png"))
#' 
#' # Time series of a given point in space:
#' plot(as.vector(asc[800,800,]), type="l", xlab="Time [hours]")
#' 
#' # if dividebyten=FALSE, raster stores things out of memory in the exdir.
#' # by default, this is in tempdir, hence you would need to save asc manually:
#' # raster::writeRaster(asc, paste0(datadir,"/RW2018-09"), overwrite=TRUE) 
#' }
#' @param file        Name of file on harddrive, like e.g. 
#'                    DWDdata/grids_germany/hourly/radolan/historical/asc/
#'                    2018_RW-201809.tar.
#'                    Must have been downloaded with \code{mode="wb"}!
#' @param exdir       Directory to unzip into. Unpacked files existing therein
#'                    will not be untarred again, saving up to 15 secs per file.
#'                    DEFAULT: NULL (subfolder of \code{\link{tempdir}()})
#' @param dividebyten Divide numerical values by 10? 
#'                    If dividebyten=FALSE and exdir left at NULL (tempdir), save 
#'                    the result on disc with \code{raster::\link[raster]{writeRaster}}.
#'                    Accessing out-of-memory raster objects won't work if 
#'                    exdir is removed! -> Error in .local(.Object, ...)
#'                    DEFAULT: TRUE
#' @param progbar     Show messages and progress bars? \code{\link{readDWD}} will
#'                    keep progbar=TRUE for asc files, even if length(file)==1.
#'                    DEFAULT: TRUE
#' @param selection   Optionally read only a subset of the ~24*31=744 files.
#'                    Called as \code{f[selection]}. DEFAULT: NULL (ignored)
#' @param \dots       Further arguments passed to \code{raster::\link[raster]{raster}}
readDWD.asc <- function(file, exdir=NULL, dividebyten=TRUE, 
                        selection=NULL, progbar=TRUE, ...)
{
if(!requireNamespace("raster", quietly=TRUE))
stop("To use rdwd:::readDWD.asc, please first install raster:",
     "   install.packages('raster')", call.=FALSE)
if(progbar) lapply <- pbapply::pblapply
# prepare to untar data (two layers):
fn <- tools::file_path_sans_ext(basename(file))
if(is.null(exdir)) exdir <- paste0(tempdir(),"/", fn)
#
# untar layer 1:
daydir <- paste0(exdir,"/dayfiles")
untar(file, exdir=daydir) # 30/31 .tar.gz files (one for each day). overwrites existing files
dayfiles <- dir(daydir, full.names=TRUE)
#
# untar layer 2:
if(progbar) message("\nChecking if already unpacked: ", file, "...")
to_untar <- lapply(dayfiles, untar, list=TRUE)
untarred <- dir(exdir, pattern=".asc$")
to_untar <- !sapply(to_untar, function(x) all(x %in% untarred))
if(any(to_untar)){
  if(progbar) message("Unpacking tar files into ",exdir,"...")
  lapply(dayfiles[to_untar], untar, exdir=exdir) 
} else if(progbar) message("Tar file was already unpacked into ",exdir," :)")
# yields 31 * 24 .asc files each 1.7MB, takes ~20 secs
#
#
# read data (hourly files):
f <- dir(exdir, pattern=".asc$", full.names=TRUE) # 720 files
if(!is.null(selection)) f <- f[selection]
if(progbar) message("Reading ",length(f)," files...")
dat <- lapply(f, raster::raster, ...)
#
# divide by ten (takes ~9 min!)
if(progbar & dividebyten) message("Dividing values by ten...")
if(dividebyten) dat <- lapply(dat, function(x) x/10)
#
# stack layers:
dat <- raster::stack(dat)
#
# output:
return(invisible(dat))
}



# helper functionality ----

#' @title project DWD raster data
#' @description Set projection and extent for DWD raster data. Optionally (and
#' per default) also reprojects to latlon data.
#' The internal defaults are extracted from the
#' Kompositformatbeschreibung at \url{https://www.dwd.de/DE/leistungen/radolan/radolan.html},
#' as provided 2019-04 by Antonia Hengst.
#' @return Raster object with projection and extent, invisible
#' @author Berry Boessenkool, \email{berry-b@@gmx.de}, May 2019
#' @seealso \code{raster::\link[raster]{crs}}, 
#'          \code{raster::\link[raster]{projection}},
#'          \code{raster::\link[raster]{extent}},
#'          \code{raster::\link[raster]{projectRaster}},
#'          \code{\link{readDWD.binary}, \link{readDWD.raster}, \link{readDWD.asc}}
#' @keywords aplot
#' @export
#' @examples
#' # To be used after readDWD.binary, readDWD.raster, readDWD.asc
#' @param r        Raster object
#' @param proj     Desired projection. Can be a \code{raster::\link[raster]{crs}} output,
#'                 a projection character string (will be passed to \code{crs}), 
#'                 "radolan" or "seasonal" with internal defaults defined per DWD standard, 
#'                 or NULL to not set proj+extent but still consider \code{latlon}.
#'                 DEFAULT: "radolan"
#' @param extent   Desired \code{\link[raster]{extent}}. Can be an extent object,
#'                 a vector with 4 numbers, or "radolan" / "rw" / "seasonal" 
#'                 with internal defaults.
#'                 DEFAULT: "radolan"
#' @param latlon   Logical: reproject \code{r} to lat-lon crs? DEFAULT: TRUE
#'
projectRasterDWD <- function(r, proj="radolan", extent="radolan", latlon=TRUE)
{
# package check
if(!requireNamespace("raster", quietly=TRUE))
 stop("To use rdwd::projectRasterDWD, please first install raster:",
      "   install.packages('raster')", call.=FALSE)
#
if(!is.null(proj))
{
# Default projection and extent:
# Projection as per Kompositbeschreibung 1.5
p_radolan <- "+proj=stere +lat_0=90 +lat_ts=90 +lon_0=10 +k=0.93301270189
              +x_0=0 +y_0=0 +a=6370040 +b=6370040 +to_meter=1000 +no_defs"
# ftp://opendata.dwd.de/climate_environment/CDC/grids_germany/seasonal/air_temperature_max/
#       BESCHREIBUNG_gridsgermany_seasonal_air_temperature_max_de.pdf
p_seasonal <- "+proj=tmerc +lat_0=0 +lon_0=9 +k=1 +x_0=3500000 +y_0=0 
               +ellps=bessel +datum=potsdam +units=m +no_defs"
#
if(is.character(proj))
  {   
  if(proj=="radolan")  proj <- p_radolan else
  if(proj=="seasonal") proj <- p_seasonal
  }
if(!inherits(proj, "CRS")) proj <- raster::crs(proj)
#
# Extent as per Kompositbeschreibung 1.4 / seasonal DESCRIPTION pdf:
e_radolan <- c(-523.4622,376.5378,-4658.645,-3758.645)
e_rw <-      c(-443.4622,456.5378,-4758.645,-3658.645) # 1.2, Abb 3
# e_radolan <- c(-673.4656656,726.5343344,-5008.642536,-3508.642536) # ME
e_seasonal <- c(3280414.71163347, 3934414.71163347, 5237500.62890625, 6103500.62890625)
if(is.character(extent))
  {  
  if(extent=="radolan")  extent <- e_radolan else
  if(extent=="rw")       extent <- e_rw      else
  if(extent=="seasonal") extent <- e_seasonal
  }
if(!inherits(extent,"Extent")) extent <- raster::extent(extent)
#
# actually project:
raster::projection(r) <- proj
raster::extent(    r) <- extent
} # end if not null proj
#
# lat-lon projection:
proj_ll <- raster::crs("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")
if(latlon) r <- raster::projectRaster(r, crs=proj_ll)
# invisible output:
return(invisible(r))
}
