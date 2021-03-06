% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/selectDWD.R
\name{selectDWD}
\alias{selectDWD}
\title{Select data from the DWD CDC FTP Server}
\usage{
selectDWD(name = "", res = NA, var = NA, per = NA,
  exactmatch = TRUE, mindex = metaIndex, id = findID(name, exactmatch
  = exactmatch, mindex = mindex), base = dwdbase, findex = fileIndex,
  current = FALSE, meta = FALSE, meta_txt_only = TRUE,
  outvec = any(per \%in\% c("rh", "hr")), ...)
}
\arguments{
\item{name}{Char: station name(s) passed to \code{\link{findID}}, along with
\code{exactmatch} and \code{mindex}. 
All 3 arguments are ignored if \code{id} is given. DEFAULT: ""}

\item{res}{Char: temporal \bold{res}olution available at \code{base}, usually one of
\code{c("hourly","daily","monthly")}, see section 'Description' above.
\code{res/var/per} together form the \bold{path}. 
DEFAULT: NA for interactive selection}

\item{var}{Char: weather \bold{var}iable of interest, like e.g.
\code{"air_temperature", "cloudiness", "precipitation",
        "soil_temperature", "solar", "kl", "more_precip"}
See above and in \code{View(rdwd:::\link{fileIndex})}. 
DEFAULT: NA for interactive selection}

\item{per}{Char: desired time \bold{per}iod. One of
"recent" (data from the last year, up to date usually within a few days) or
"historical" (long time series). Can be abbreviated (if the first
letter is "r" or "h", full names are used). To get both datasets,
use \code{per="hr"} or \code{per="rh"} (and \code{outvec=TRUE}).
\code{per} is set to "" if var=="solar". 
DEFAULT: NA for interactive selection}

\item{exactmatch}{Logical passed to \code{\link{findID}}: match \code{name}
with \code{\link{==}})? Else with \code{\link{grepl}}. DEFAULT: TRUE}

\item{mindex}{Single object: Index with metadata passed to \code{\link{findID}}.
DEFAULT: \code{rdwd:::\link{metaIndex}}}

\item{id}{Char/Number: station ID with or without leading zeros, e.g. "00614" or 614.
Is internally converted to an integer, because some DWD meta data
files also contain no leading zeros. DEFAULT: findID(name, exaxtmatch, mindex)}

\item{base}{Single char: main directory of DWD ftp server.
Must be the same \code{base} used to create \code{findex}.
DEFAULT: \code{\link{dwdbase}}}

\item{findex}{Single object: Index used to select filename, as returned by
\code{\link{createIndex}}.To use a current / custom index, use
\code{myIndex <- createIndex(indexFTP("/daily/solar"))}
(with desired path, of course). DEFAULT: \code{rdwd:::\link{fileIndex}}}

\item{current}{Single logical for case 3/4 with given \code{path}: instead of
\code{findex}, use a list of the currently available files at
base/res/var/per? This will call \code{\link{indexFTP}}, thus
requires availability of the \code{RCurl} package.
DEFAULT: FALSE}

\item{meta}{Logical: return metadata txt file name instead of climate data zip file?
Relevant only in case 4 (path and id given) and case 3 for res="multi_annual".
See \code{\link{metaIndex}} for a compilation of all metaData files.
DEFAULT: FALSE}

\item{meta_txt_only}{Logical: if \code{meta}, only return .txt files, not the 
pdf and html files? DEFAULT: TRUE}

\item{outvec}{Single logical: if \bold{path} or \bold{ID} length > 1,
instead of a list, return a vector? (via \code{\link{unlist}}).
DEFAULT: \code{per \%in\% c("rh","hr")}}

\item{\dots}{Further arguments passed to \code{\link{indexFTP}} if \code{current=TRUE},
like dir, quiet}
}
\value{
Character string with file path and name(s) in the format
        "base/res/var/per/filename.zip"
}
\description{
Select files for downloading with \code{\link{dataDWD}}.
All arguments (except for \code{mindex}, \code{findex} and \code{base})
can be a vector and will be recycled to the maximum length of all arguments.
If that length > 1, the output is a list of filenames (or vector if \code{outvec=TRUE}).\cr
If station \code{name} is given, but \code{id} is empty (""),
\bold{id} is inferred via \code{mindex}.
If \code{res/var/per} are given and valid (existing in \code{findex}),
they are pasted together to form a \bold{path}.
Here is an overview of the behavior in each case of availability:
\tabular{llll}{
case \tab |  \bold{id} \tab |  \bold{path} \tab | output \cr
 1 \tab |  ""  \tab |  ""  \tab | \code{base} (and some warnings) \cr
 2 \tab | "xx" \tab |  ""  \tab | All file names (across paths) for station \bold{id} \cr
 3 \tab |  ""  \tab | "xx" \tab | The zip file names at \bold{path} \cr
 4 \tab | "xx" \tab | "xx" \tab | Regular single data file name \cr
}
For case 2, you can explicitly set \code{res="",var="",per=""} to avoid the 
default interactive selection.\cr
For case 3 and 4 (\bold{path} given), you can set \code{meta=TRUE}.
Then selectDWD will return the name of the station description file at \bold{path}.
This is why case 3 with \code{meta=FALSE} only returns the data file names (ending in .zip).\cr\cr\cr
The following folders in \bold{\code{res/var/per}} notation
(resolution/variable/period) are available at \code{\link{dwdbase}}:\cr
"<" signifies a split into the folders \code{per} = "recent" and "historical".\cr
"<<" signifies a split into the folders \code{per} = "now", recent", "historical" and "meta_data".\cr
"-" signifies that there are no further sub-folders. \cr
Please note that both "solar" (-/<<) and "sun" (<) are available!
\tabular{lllll}{
\code{res}=\bold{10_minutes} \tab | \code{res}=\bold{hourly} \tab | \code{res}=\bold{daily} \tab | \code{res}=\bold{monthly} \tab | \code{res}=\bold{annual} \cr
\code{var=}            \tab                      \tab                      \tab                 \tab                 \cr
                       \tab |                    \tab | kl <               \tab | kl <          \tab | kl <          \cr
                       \tab |                    \tab | more_precip <      \tab | more_precip < \tab | more_precip < \cr
air_temperature <<     \tab | air_temperature <  \tab |                    \tab |               \tab |               \cr
extreme_temperature << \tab |                    \tab |                    \tab |               \tab |               \cr
extreme_wind <<        \tab |                    \tab |                    \tab |               \tab |               \cr
                       \tab | cloudiness <       \tab |                    \tab |               \tab |               \cr
                       \tab | cloud_type <       \tab |                    \tab |               \tab |               \cr
                       \tab | dew_point <        \tab |                    \tab |               \tab |               \cr
precipitation <<       \tab | precipitation <    \tab |                    \tab |               \tab |               \cr
                       \tab | pressure <         \tab |                    \tab |               \tab |               \cr
                       \tab | soil_temperature < \tab | soil_temperature < \tab |               \tab |               \cr
solar <<               \tab | solar -            \tab | solar -            \tab |               \tab |               \cr
                       \tab | sun <              \tab |                    \tab |               \tab |               \cr
                       \tab | visibility <       \tab |                    \tab |               \tab |               \cr
                       \tab |                    \tab | water_equiv <      \tab |               \tab |               \cr
wind <<                \tab | wind <             \tab |                    \tab |               \tab |               \cr
                       \tab | wind_synop <       \tab |                    \tab |               \tab |               \cr
}
Please note that \code{1_minute/precipitation/historical} has subfolders for each year.
\tabular{lll}{
\code{res}=\bold{1_minute} \tab | \code{res}=\bold{multi_annual} \tab | \code{res}=\bold{subdaily} \cr 
\code{var=}      \tab                \tab                     \cr
precipitation << \tab |              \tab |                   \cr
                 \tab | mean_61-90 - \tab |                   \cr
                 \tab | mean_71-00 - \tab |                   \cr
                 \tab | mean_81-10 - \tab |                   \cr
                 \tab |              \tab | air_temperature < \cr
                 \tab |              \tab | cloudiness <      \cr
                 \tab |              \tab | moisture <        \cr
                 \tab |              \tab | pressure <        \cr
                 \tab |              \tab | soil <            \cr
                 \tab |              \tab | standard_format - \cr
                 \tab |              \tab | visibility <      \cr
                 \tab |              \tab | wind <            \cr
}
}
\examples{
# Give weather station name (must be existing in metaIndex):
selectDWD("Potsdam", res="daily", var="kl", per="historical")

# all files for all stations matching "Koeln":
selectDWD("Koeln", res="", var="", per="", exactmatch=FALSE)
findID("Koeln", FALSE)

\dontrun{ # Excluded from CRAN checks to save time

# selectDWD("Potsdam") # interactive selection of res/var/per

# directly give station ID, can also be id="00386" :
selectDWD(id=386, res="daily", var="kl", per="historical")

# period can be abbreviated:
selectDWD(id="00386", res="daily", var="kl", per="h")
selectDWD(id="00386", res="daily", var="kl", per="h", meta=TRUE)

# vectorizable:
selectDWD(id="01050", res="daily", var="kl", per="rh") # list if outvec=F
selectDWD(id="01050", res=c("daily","monthly"), var="kl", per="r")
# vectorization gives not the outer product, but elementwise comparison:
selectDWD(id="01050", res=c("daily","monthly"), var="kl", per="hr")

# all zip files in all paths matching id:
selectDWD(id=c(1050, 386), res="",var="",per="")
# all zip files in a given path (if ID is empty):
head(  selectDWD(id="", res="daily", var="kl", per="recent")   )

}

}
\seealso{
\code{\link{dataDWD}}, \code{\link{metaIndex}}, \url{../doc/mapDWD.html},
         \code{vignette("mapDWD", package="rdwd")}
}
\author{
Berry Boessenkool, \email{berry-b@gmx.de}, Oct 2016
}
\keyword{file}
