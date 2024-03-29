% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/EPFR.r
\name{ftp.get}
\alias{ftp.get}
\title{ftp.get}
\usage{
ftp.get(x, y, n, w, h, u = "ftp", v)
}
\arguments{
\item{x}{= a remote file}

\item{y}{= local folder (e.g. "C:\\\\temp")}

\item{n}{= ftp site (can be missing)}

\item{w}{= user id (can be missing)}

\item{h}{= password (can be missing)}

\item{u}{= a string (ftp/sftp)}

\item{v}{= a boolean (ftp.use.epsv argument of getCurlHandle)}
}
\description{
file <x> from remote site
}
\seealso{
Other ftp: \code{\link{ftp.all.dir}},
  \code{\link{ftp.all.files.underlying}},
  \code{\link{ftp.all.files}},
  \code{\link{ftp.credential}}, \code{\link{ftp.del}},
  \code{\link{ftp.dir.parse.ftp}},
  \code{\link{ftp.dir.parse.sftp}}, \code{\link{ftp.dir}},
  \code{\link{ftp.download}}, \code{\link{ftp.exists}},
  \code{\link{ftp.file}}, \code{\link{ftp.info}},
  \code{\link{ftp.kill}}, \code{\link{ftp.list}},
  \code{\link{ftp.missing.underlying}},
  \code{\link{ftp.missing}}, \code{\link{ftp.parent}},
  \code{\link{ftp.put}}, \code{\link{ftp.record}},
  \code{\link{ftp.rmdir}}, \code{\link{ftp.sql.factor}},
  \code{\link{ftp.upload}}
}
\keyword{ftp.get}
