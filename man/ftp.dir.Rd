% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/EPFR.r
\name{ftp.dir}
\alias{ftp.dir}
\title{ftp.dir}
\usage{
ftp.dir(x, y, n, w, h = F, u = "ftp", v)
}
\arguments{
\item{x}{= a remote folder}

\item{y}{= ftp site (can be missing)}

\item{n}{= user id (can be missing)}

\item{w}{= password (can be missing)}

\item{h}{= a boolean (do/don't report time stamps)}

\item{u}{= a string (ftp/sftp)}

\item{v}{= a boolean (ftp.use.epsv argument of getURL)}
}
\description{
logical or YYYYMMDD vector indexed by remote file names
}
\seealso{
Other ftp: \code{\link{ftp.all.dir}},
  \code{\link{ftp.all.files.underlying}},
  \code{\link{ftp.all.files}},
  \code{\link{ftp.credential}}, \code{\link{ftp.del}},
  \code{\link{ftp.dir.parse.ftp}},
  \code{\link{ftp.dir.parse.sftp}},
  \code{\link{ftp.download}}, \code{\link{ftp.exists}},
  \code{\link{ftp.get}}, \code{\link{ftp.info}},
  \code{\link{ftp.kill}}, \code{\link{ftp.list}},
  \code{\link{ftp.missing.underlying}},
  \code{\link{ftp.missing}}, \code{\link{ftp.parent}},
  \code{\link{ftp.put}}, \code{\link{ftp.record}},
  \code{\link{ftp.rmdir}}, \code{\link{ftp.sql.factor}},
  \code{\link{ftp.upload}}
}
\keyword{ftp.dir}
