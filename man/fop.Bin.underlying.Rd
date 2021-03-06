% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/EPFR.r
\name{fop.Bin.underlying}
\alias{fop.Bin.underlying}
\title{fop.Bin.underlying}
\usage{
fop.Bin.underlying(fcn, x, y, n, w, h, fcn.prd)
}
\arguments{
\item{fcn}{= overall summary function}

\item{x}{= a matrix/df with rows indexed by time and columns indexed by bins}

\item{y}{= a matrix/data frame of returns of the same dimension as <x>}

\item{n}{= a vector corresponding to the rows of <x> that maps each row to a sub-period of interest (e.g. calendat year)}

\item{w}{= return horizon in weekdays or months}

\item{h}{= number of bins into which you are going to divide your predictors}

\item{fcn.prd}{= per period summary function}
}
\description{
Summarizes bin excess returns by sub-periods of interest (as defined by <vec>)
}
\seealso{
Other fop: \code{\link{fop.Bin}},
  \code{\link{fop.IC.summ}}, \code{\link{fop.IC}},
  \code{\link{fop.correl}}, \code{\link{fop.grp.map}},
  \code{\link{fop.rank.xRet}}, \code{\link{fop.wrapper}},
  \code{\link{fop}}
}
\keyword{fop.Bin.underlying}
