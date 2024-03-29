% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/EPFR.r
\name{refresh.predictors.daily}
\alias{refresh.predictors.daily}
\title{refresh.predictors.daily}
\usage{
refresh.predictors.daily(x, y, n, w, h = F)
}
\arguments{
\item{x}{= a file (predictors)}

\item{y}{= query needed to get full history}

\item{n}{= a string (last part of query after date restriction)}

\item{w}{= a connection string}

\item{h}{= a boolean (ignore/note data changes)}
}
\description{
refreshes the text file contains flows data from SQL
}
\seealso{
Other refresh: \code{\link{refresh.predictors.append}},
  \code{\link{refresh.predictors.monthly}},
  \code{\link{refresh.predictors.script}},
  \code{\link{refresh.predictors.weekly}},
  \code{\link{refresh.predictors}}
}
\keyword{refresh.predictors.daily}
