% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/readRadarFile.R
\name{readRadarFile}
\alias{readRadarFile}
\title{read binary radolan radar file}
\usage{
readRadarFile(binfile, na = NA, clutter = NA)
}
\arguments{
\item{binfile}{Name of a single binary file}

\item{na}{Value to be set for missing data (bit 14). DEFAULT: NA}

\item{clutter}{Value to be set for clutter data (bit 16). DEFAULT: NA}
}
\value{
A list with dat (matrix) and meta (list with elements from header, 
  see Kompositformatbeschreibung)
}
\description{
Read a single binary DWD Radolan file.
  To be used in \code{\link{readDWD.binary}}.\cr
  If any files ar not read correctly, please let me know. So far, tests have 
  only been conducted for daily SF files. Optimally, check the 
  Kompositformatbeschreibung at \url{https://www.dwd.de/DE/leistungen/radolan/radolan.html}
  and let me know what needs to be changed.\cr
  Binary bits are converted to decimal numbers with Fortran routines, see
  \url{https://github.com/brry/rdwd/tree/master/src}. 
  They are called in an unexported function called \code{bin2num}.
}
\examples{
# see readDWD.binary
}
\seealso{
\code{\link{readDWD.binary}}
}
\author{
Maintained by Berry Boessenkool, \email{berry-b@gmx.de}, May 2019.\cr
  Original codebase by Henning Rust & Christoph Ritschel at FU Berlin
}
\keyword{binary}
\keyword{file}
