% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rdwd-package.R
\docType{package}
\name{rdwd}
\alias{rdwd}
\alias{rdwd-package}
\title{Download Climate Data from DWD (German Weather Service)}
\description{
Select weather data from the DWD (Deutscher Wetterdienst) with
\code{\link{selectDWD}} or \code{\link{nearbyStations}}. \cr
Download and process data sets with \code{\link{dataDWD}} and \code{\link{readDWD}}.\cr
Station selection is done offline with \code{\link{fileIndex}} and
\code{\link{findID}} (which uses \code{\link{metaIndex}}).\cr
The Index objects are created with \code{\link{indexFTP}} and \code{\link{createIndex}}.\cr
For an introduction to the package, see the \href{../doc/rdwd.html}{main vignette}.\cr
For an overview of available data, see \code{\link{selectDWD}}.\cr
}
\section{Searchability Terms}{

Weather Data Germany download with R, Climate Data Germany\cr
Deutscher Wetterdienst R Daten download Klimastationen\cr
DWD Daten mit R runterladen, Wetter und Klimadaten in R
}

\seealso{
USA data: \href{https://www.rdocumentation.org/packages/countyweather}{countyweather},
         \href{https://www.rdocumentation.org/packages/rnoaa}{rnoaa}\cr
         World data: \href{https://ropensci.org/blog/blog/2017/04/04/gsodr}{Global Surface Summary of the Day}\cr
         Durch data: \url{https://github.com/bvhest/KNMIr}\cr
         Canadian data: \url{https://cran.r-project.org/package=rclimateca}\cr
}
\author{
Berry Boessenkool, \email{berry-b@gmx.de}, June-Nov 2016, June 2017
}
\keyword{documentation}
\keyword{package}
