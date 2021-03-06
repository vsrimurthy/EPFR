% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/EPFR.r
\name{fop}
\alias{fop}
\title{fop}
\usage{
fop(x, y, delay, lags, floW, retW, nBins, grp.fcn, convert2df, reverse.vbl,
  prd.size, first.ret.date, findOptimalParametersFcn, sum.flows, sprds)
}
\arguments{
\item{x}{= a matrix/data frame of predictors}

\item{y}{= a matrix/data frame of total return indices}

\item{delay}{= the number of days needed for the predictors to be known}

\item{lags}{= a numeric vector of predictor lags}

\item{floW}{= a numeric vector of trailing flow windows}

\item{retW}{= a numeric vector of forward return windows}

\item{nBins}{= a numeric vector}

\item{grp.fcn}{= a function that maps yyyymmdd dates to groups of interest (e.g. day of the week)}

\item{convert2df}{= T/F depending on whether you want the output converted to a data frame}

\item{reverse.vbl}{= T/F depending on whether you want the variable reversed}

\item{prd.size}{= size of each compounding period in terms of days (days = 1, wks = 5, etc.)}

\item{first.ret.date}{= if F grp.fcn is applied to formation dates. Otherwise it is applied to the first day in forward the return window.}

\item{findOptimalParametersFcn}{= the function you are using to summarize your results}

\item{sum.flows}{= if T, flows get summed. Otherwise they get compounded}

\item{sprds}{= T/F depending on whether spread changes, rather than returns, are needed}
}
\description{
an array of summary statistics of each quantile, indexed by parameter
}
\seealso{
Other fop: \code{\link{fop.Bin.underlying}},
  \code{\link{fop.Bin}}, \code{\link{fop.IC.summ}},
  \code{\link{fop.IC}}, \code{\link{fop.correl}},
  \code{\link{fop.grp.map}}, \code{\link{fop.rank.xRet}},
  \code{\link{fop.wrapper}}
}
\keyword{fop}
