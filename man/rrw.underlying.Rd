% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/EPFR.r
\name{rrw.underlying}
\alias{rrw.underlying}
\title{rrw.underlying}
\usage{
rrw.underlying(x, y, n, w, h, u, v, g)
}
\arguments{
\item{x}{= a YYYYMM (first-return date)}

\item{y}{= a variable vector}

\item{n}{= a universe (e.g. "R1Mem"/c("EafeMem", 1, "CountryCode", "JP"))}

\item{w}{= a variable (neutrality group)}

\item{h}{= a variable (return)}

\item{u}{= a folder (has subfolders derived/data)}

\item{v}{= a variable (to orthogonalize against)}

\item{g}{= classif file}
}
\description{
Runs regressions
}
\seealso{
Other rrw: \code{\link{rrw.factors}}, \code{\link{rrw}}
}
\keyword{rrw.underlying}
