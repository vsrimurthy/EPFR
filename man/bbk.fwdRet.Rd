% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/EPFR.r
\name{bbk.fwdRet}
\alias{bbk.fwdRet}
\title{bbk.fwdRet}
\usage{
bbk.fwdRet(x, y, n, w, h, u)
}
\arguments{
\item{x}{= a matrix/data frame of predictors}

\item{y}{= a matrix/data frame of total return indices}

\item{n}{= the number of days in the return window}

\item{w}{= the number of days the predictors are lagged}

\item{h}{= the number of days needed for the predictors to be known}

\item{u}{= T/F depending on whether returns or spread changes are needed}
}
\description{
returns a matrix/data frame of the same dimensions as <x>
}
\seealso{
Other bbk: \code{\link{bbk.bin.rets.prd.summ}},
  \code{\link{bbk.bin.rets.summ}},
  \code{\link{bbk.bin.xRet}}, \code{\link{bbk.data}},
  \code{\link{bbk.drawdown}}, \code{\link{bbk.fanChart}},
  \code{\link{bbk.histogram}}, \code{\link{bbk.holidays}},
  \code{\link{bbk.summ}}, \code{\link{bbk.turnover}},
  \code{\link{bbk}}
}
\keyword{bbk.fwdRet}
