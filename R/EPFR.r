
#' mat.read
#' 
#' reads the file into data frame
#' @param x = a file
#' @param y = the separator (can be missing)
#' @param n = a column (contains row names, can be NULL)
#' @param w = a boolean (there is/isn't a header)
#' @param h = a string vector (quoting characters)
#' @keywords mat.read
#' @export
#' @family mat
#' @import utils

mat.read <- function (x = "C:\\temp\\write.csv", y, n = 1, w = T, h = "") 
{
    if (missing(y)) 
        y <- c("\t", ",")
    if (is.null(n)) 
        adj <- 0:1
    else adj <- rep(0, 2)
    if (!file.exists(x)) 
        stop("File ", x, " doesn't exist!\n")
    u <- length(y)
    z <- read.table(x, w, y[u], row.names = n, quote = h, as.is = T, 
        na.strings = txt.na(), comment.char = "", check.names = F)
    while (min(dim(z) - adj) == 0 & u > 1) {
        u <- u - 1
        z <- read.table(x, w, y[u], row.names = n, quote = h, 
            as.is = T, na.strings = txt.na(), comment.char = "", 
            check.names = F)
    }
    z
}

#' ret.outliers
#' 
#' Sets big ones to NA (a way to control for splits)
#' @param x = a numeric vector (returns)
#' @param y = outlier threshold
#' @keywords ret.outliers
#' @export
#' @family ret
#' @import stats

ret.outliers <- function (x, y = 1.5) 
{
    mdn <- median(x, na.rm = T)
    y <- c(1/y, y) * (100 + mdn) - 100
    z <- !is.na(x) & x > y[1] & x < y[2]
    z <- ifelse(z, x, NA)
    z
}

#' sql.query.underlying
#' 
#' opens a connection, executes sql query, then closes the connection
#' @param x = a SQL query vector
#' @param y = a connection, the output of odbcDriverConnect
#' @param n = a boolean (report/ignore record count)
#' @keywords sql.query.underlying
#' @export
#' @family sql
#' @import RODBC

sql.query.underlying <- function (x, y, n = T) 
{
    for (i in x) z <- sqlQuery(y, i, stringsAsFactors = F)
    if (n) 
        cat("Getting", txt.ex.int(dim(z)[1]), "new", ifelse(dim(z)[1] != 
            1, "rows", "row"), "of data ..\n")
    z
}

#' email
#' 
#' emails <x>
#' @param x = the email address(es) of the recipient(s)
#' @param y = subject of the email
#' @param n = text of the email
#' @param w = a file vector
#' @param h = a boolean (use html/text)
#' @param u = the email address(es) being CC'ed
#' @param v = the email address(es) being BCC'ed
#' @keywords email
#' @export
#' @family email
#' @import RDCOMClient

email <- function (x, y, n, w = "", h = F, u, v) 
{
    z <- COMCreate("Outlook.Application")
    z <- z$CreateItem(0)
    z[["To"]] <- x
    if (!missing(u)) 
        z[["Cc"]] <- u
    if (!missing(v)) 
        z[["Bcc"]] <- v
    z[["subject"]] <- y
    if (h) 
        z[["HTMLBody"]] <- n
    else z[["body"]] <- n
    for (j in w) if (file.exists(j)) 
        z[["Attachments"]]$Add(j)
    z$Send()
    invisible()
}

#' ftp.dir
#' 
#' logical or YYYYMMDD vector indexed by remote file names
#' @param x = a remote folder
#' @param y = ftp site (can be missing)
#' @param n = user id (can be missing)
#' @param w = password (can be missing)
#' @param h = a boolean (do/don't report time stamps)
#' @param u = a string (ftp/sftp)
#' @param v = a boolean (ftp.use.epsv argument of getURL)
#' @keywords ftp.dir
#' @export
#' @family ftp
#' @import RCurl

ftp.dir <- function (x, y, n, w, h = F, u = "ftp", v) 
{
    w <- ftp.missing(as.list(environment()), "ynwuv")
    z <- paste0(w[["ftp"]], x, "/")
    z <- getURL(z, userpwd = w[["userpwd"]], ftp.use.epsv = w[["epsv"]])
    if (z != "") {
        z <- txt.parse(z, ifelse(u == "ftp", "\r\n", "\n"))
        if (u == "ftp") 
            z <- ftp.dir.parse.ftp(z)
        else z <- ftp.dir.parse.sftp(z)
        z <- z[!z[, "is.file"] | z[, "size"] > 0, ]
        if (dim(z)[1] > 0) {
            h <- ifelse(h, "yyyymmdd", "is.file")
            z <- vec.named(z[, h], z[, "file"])
        }
        else {
            z <- NULL
        }
    }
    else {
        z <- NULL
    }
    z
}

#' acronymize
#' 
#' randomly acronymnizes
#' @param x = a string vector
#' @keywords acronymize
#' @export

acronymize <- function (x) 
{
    z <- x
    m <- int.random(10)
    n <- int.random(4)
    if (m + n - 1 <= length(z)) {
        x <- toupper(txt.left(z[m + 0:n], 1))
        z[m] <- paste0(paste(x, collapse = "."), ".")
        for (j in 1:n) z <- z[-(m + 1)]
        if (m < length(z)) 
            z <- c(z[1:m], acronymize(z[seq(m + 1, length(z))]))
    }
    z
}

#' acronymize.wrapper
#' 
#' randomly acronymnizes
#' @param x = a string
#' @keywords acronymize.wrapper
#' @export

acronymize.wrapper <- function (x) 
{
    z <- txt.trim(txt.parse(x, "."))
    for (j in seq_along(z)) {
        y <- txt.parse(z[j], " ")
        y <- acronymize(y)
        z[j] <- paste(y, collapse = " ")
    }
    z <- paste0(paste(z, collapse = ". "), ".")
    z
}

#' angle
#' 
#' angle ABC
#' @param x = number representing distance between points A & B
#' @param y = number representing distance between points B & C
#' @param n = number representing distance between points A & C
#' @keywords angle
#' @export

angle <- function (x, y, n) 
{
    n <- min(n, 0.99999 * (x + y))
    x <- min(x, 0.99999 * (n + y))
    y <- min(y, 0.99999 * (x + n))
    z <- 180 * (1 - acos((n^2 - x^2 - y^2)/(2 * x * y))/pi)
    z
}

#' args.canonical
#' 
#' relabels arguments
#' @param x = a boolean (standard/reverse order)
#' @keywords args.canonical
#' @export
#' @family args

args.canonical <- function (x = T) 
{
    z <- txt.to.char("xynwhuvgrsbpamdeofijklz")
    if (!x) 
        z <- rev(z)
    z
}

#' args.comment
#' 
#' functions, arguments and comments
#' @keywords args.comment
#' @export
#' @family args

args.comment <- function () 
{
    x <- vec.to.list(fcn.list(), T)
    x <- lapply(x, fcn.args.comment)
    x <- lapply(x, function(z) matrix(c(names(z), z), length(z), 
        2, F))
    x <- lapply(x, mat.ex.matrix)
    x <- mat.ex.list(x, "fcn")
    names(x)[1:2] <- c("arg", "comment")
    z <- x[, c("fcn", "arg", "comment")]
    z
}

#' args.missing
#' 
#' arguments that can be missing
#' @param x = a string (function name)
#' @keywords args.missing
#' @export
#' @family args

args.missing <- function (x) 
{
    x <- fcn.lines.code(x, F)
    z <- "^(.*if \\(missing\\()(.)(\\).*)$"
    x <- x[grepl(z, x)]
    z <- unique(gsub(z, "\\2", x))
    z
}

#' args.rename
#' 
#' relabels arguments
#' @param fcn = a function
#' @param x = a boolean (standard/reverse order)
#' @keywords args.rename
#' @export
#' @family args

args.rename <- function (fcn, x = T) 
{
    z <- fcn
    y <- fcn.args.actual(z)
    x <- args.canonical(x)
    x <- vec.named(x[seq_along(y)], y)
    body(z) <- args.rename.body(body(z), x)
    x <- vec.to.list(x, T, T)
    formals(z) <- lapply(x, function(z) bquote())
    z
}

#' args.rename.body
#' 
#' relabels arguments <y> by <n>
#' @param x = an expression
#' @param y = a string vector (new args indexed by old)
#' @keywords args.rename.body
#' @export
#' @family args

args.rename.body <- function (x, y) 
{
    if (!length(x)) 
        return()
    for (i in seq_along(x)) {
        if (is.call(x[[i]])) 
            x[[i]][-1L] <- Recall(x[[i]][-1L], y)
        if (is.name(x[[i]]) && deparse(x[[i]]) %in% names(y)) 
            x[[i]] <- as.name(y[[deparse(x[[i]])]])
    }
    z <- x
    z
}

#' array.bind
#' 
#' binds together along the dimension they differ on
#' @param ... = arrays
#' @keywords array.bind
#' @export
#' @family array

array.bind <- function (...) 
{
    x <- list(...)
    x <- lapply(x, array.unlist)
    x <- Reduce(rbind, x)
    x <- mat.sort(x, dim(x)[2]:2 - 1, rep(F, dim(x)[2] - 1))
    z <- lapply(x[, -dim(x)[2]], unique)
    z <- array(x[, dim(x)[2]], sapply(z, length), z)
    z
}

#' array.ex.list
#' 
#' array
#' @param x = a numeric vector/matrix/data frame list
#' @param y = a boolean (row union/intersection)
#' @param n = a boolean (column union/intersection)
#' @keywords array.ex.list
#' @export
#' @family array

array.ex.list <- function (x, y, n) 
{
    w <- !is.null(dim(x[[1]]))
    if (y) 
        y <- union
    else y <- intersect
    if (w) 
        fcn <- rownames
    else fcn <- names
    y <- Reduce(y, lapply(x, fcn))
    x <- lapply(x, function(z) map.rname(z, y))
    if (w) {
        if (n) 
            n <- union
        else n <- intersect
        n <- Reduce(n, lapply(x, colnames))
        x <- lapply(x, function(z) t(map.rname(t(z), n)))
    }
    z <- simplify2array(x)
    z
}

#' array.unlist
#' 
#' unlists the contents of an array
#' @param x = an array
#' @param y = a string vector (output column names, can be missing)
#' @keywords array.unlist
#' @export
#' @family array

array.unlist <- function (x, y) 
{
    n <- length(dim(x))
    if (missing(y)) 
        y <- col.ex.int(0:n + 1)
    if (length(y) != n + 1) 
        stop("Problem")
    z <- expand.grid(dimnames(x), stringsAsFactors = F)
    names(z) <- y[1:n]
    z[, y[n + 1]] <- as.vector(x)
    z
}

#' ascending
#' 
#' T/F depending on whether <x> is ascending
#' @param x = a numeric vector
#' @keywords ascending
#' @export

ascending <- function (x) 
{
    all(!is.na(x) & x == x[order(x)])
}

#' avail
#' 
#' For each row, returns leftmost entry with data
#' @param x = a matrix/data frame
#' @keywords avail
#' @export

avail <- function (x) 
{
    Reduce(zav, mat.ex.matrix(x))
}

#' avg.model
#' 
#' constant-only (zero-variable) regression model
#' @param x = a numeric vector (results)
#' @keywords avg.model
#' @export
#' @family avg

avg.model <- function (x) 
{
    x <- x[!is.na(x)]
    z <- vec.named(mean(x), "Estimate")
    z["Std. Error"] <- sd(x)/sqrt(length(x))
    z["t value"] <- z["Estimate"]/nonneg(z["Std. Error"])
    z
}

#' avg.winsorized
#' 
#' mean is computed over the quantiles 2 through <y> - 1
#' @param x = a numeric vector
#' @param y = an integer (number of bins)
#' @keywords avg.winsorized
#' @export
#' @family avg

avg.winsorized <- function (x, y = 100) 
{
    x <- x[!is.na(x)]
    w <- qtl(x, y)
    w <- is.element(w, 3:y - 1)
    z <- x[w]
    z <- mean(z)
    z
}

#' avg.wtd
#' 
#' returns the weighted mean of <x> given weights <n>
#' @param x = a numeric vector
#' @param y = a numeric vector (weights)
#' @keywords avg.wtd
#' @export
#' @family avg

avg.wtd <- function (x, y) 
{
    fcn.num.nonNA(weighted.mean, x, y, F)
}

#' base.ex.int
#' 
#' Expresses <x> in base <y>
#' @param x = a non-negative integer vector
#' @param y = a positive integer
#' @param n = a non-negative integer (max digits, 0 = no limit)
#' @keywords base.ex.int
#' @export
#' @family base

base.ex.int <- function (x, y = 26, n = 0) 
{
    if (n == 0) 
        n <- floor(log(vec.max(max(x), 1))/log(y)) + 1
    z <- matrix(0, length(x), n)
    w <- x > 0
    if (n > 1) 
        for (j in n:2) {
            z[w, j] <- x[w]%%y
            x[w] <- (x[w] - z[w, j])/y
            w <- x > 0
        }
    z[, 1] <- x
    if (dim(z)[1] == 1) 
        z <- t(z)[, 1]
    z
}

#' base.to.int
#' 
#' Evaluates the base <y> number <x>
#' @param x = a positive integer vector
#' @param y = a positive integer
#' @keywords base.to.int
#' @export
#' @family base

base.to.int <- function (x, y = 26) 
{
    sum(x * y^(rev(seq_along(x)) - 1))
}

#' bbk
#' 
#' standard model output
#' @param x = a matrix/data frame (predictors)
#' @param y = a matrix/data frame (total return indices)
#' @param n = a positive integer (flow window in days/months)
#' @param w = a positive integer (return window in days/months)
#' @param h = a positive integer (number of bins)
#' @param u = a non-negative integer (0 = Sun, 1 = Mon, etc., the day you trade)
#' @param v = a boolean (sum/compound)
#' @param g = a non-negative integer (lag in days/months)
#' @param r = a non-negative integer (delay in days/months)
#' @param s = a string (index within which you trade)
#' @param b = a boolean (spread changes/returns)
#' @keywords bbk
#' @export
#' @family bbk

bbk <- function (x, y, n = 1, w = 5, h = 5, u = NULL, v = F, g = 0, 
    r = 2, s = NULL, b = F) 
{
    x <- bbk.data(x, y, n, v, g, r, u, w, s, b)
    z <- lapply(bbk.bin.xRet(x$x, x$fwdRet, h, T, T), mat.reverse)
    z <- c(z, bbk.summ(z$rets, z$bins, w, ifelse(is.null(u), 
        1, 5)))
    z
}

#' bbk.bin.rets.prd.summ
#' 
#' Summarizes bin excess returns by sub-periods of interest (as defined by <y>)
#' @param fcn = a function (summary)
#' @param x = a matrix/data frame (rows indexed by time and columns indexed by bins)
#' @param y = a numeric vector (corresponds to rows of <x>, maps each row to sub-period like calendar year)
#' @param n = a positive integer (number of rows covering a full year)
#' @keywords bbk.bin.rets.prd.summ
#' @export
#' @family bbk

bbk.bin.rets.prd.summ <- function (fcn, x, y, n) 
{
    w <- !is.na(y)
    y <- y[w]
    x <- x[w, ]
    x <- mat.ex.matrix(x)
    fcn.loc <- function(z) fcn(z, n, T)
    z <- split(x, y)
    z <- sapply(z, fcn.loc, simplify = "array")
    z
}

#' bbk.bin.rets.summ
#' 
#' Summarizes bin excess returns arithmetically
#' @param x = a matrix/data frame (rows indexed by time and columns indexed by bins)
#' @param y = a positive integer (number of rows covering a full year)
#' @param n = a boolean (report/ignore period count)
#' @keywords bbk.bin.rets.summ
#' @export
#' @family bbk

bbk.bin.rets.summ <- function (x, y, n = F) 
{
    z <- c("AnnMn", "AnnSd", "Sharpe", "HitRate", "Beta", "Alpha", 
        "DrawDn", "DDnBeg", "DDnN")
    if (n) 
        z <- c(z, "nPrds")
    z <- matrix(NA, length(z), dim(x)[2], F, list(z, colnames(x)))
    if (n) 
        z["nPrds", ] <- sum(!is.na(x[, 1]))
    z["AnnMn", ] <- apply(x, 2, mean, na.rm = T) * y
    z["AnnSd", ] <- apply(x, 2, sd, na.rm = T) * sqrt(y)
    z["Sharpe", ] <- 100 * z["AnnMn", ]/z["AnnSd", ]
    z["HitRate", ] <- apply(sign(x), 2, mean, na.rm = T) * 50
    w <- colnames(x) == "uRet"
    if (any(w)) {
        z[c("Alpha", "Beta"), "uRet"] <- 0:1
        h <- !is.na(x[, "uRet"])
        m <- sum(h)
        if (m > 1) {
            vec <- c(rep(1, m), x[h, "uRet"])
            vec <- matrix(vec, m, 2, F, list(1:m, c("Alpha", 
                "Beta")))
            vec <- run.cs.reg(t(x[h, !w]), vec)
            vec[, "Alpha"] <- vec[, "Alpha"] * y
            z[colnames(vec), rownames(vec)] <- t(vec)
        }
    }
    if (dim(x)[1] > 1) {
        x <- x[order(rownames(x)), ]
        w <- fcn.mat.vec(bbk.drawdown, x, , T)
        z["DDnN", ] <- colSums(w)
        z["DrawDn", ] <- colSums(w * zav(x))
        y <- fcn.mat.num(which.max, w, , T)
        y <- rownames(x)[y]
        if (any(substring(y, 5, 5) == "Q")) 
            y <- yyyymm.ex.qtr(y)
        z["DDnBeg", ] <- char.to.num(y)
    }
    z
}

#' bbk.bin.xRet
#' 
#' Returns equal weight bin returns through time
#' @param x = a matrix/data frame (predictors)
#' @param y = a matrix/data frame (forward returns)
#' @param n = an integer (number of bins)
#' @param w = a boolean (report/ignore universe return)
#' @param h = a boolean (do/don't provide detail)
#' @param u = a string vector (binning groups, can be missing)
#' @keywords bbk.bin.xRet
#' @export
#' @family bbk

bbk.bin.xRet <- function (x, y, n = 5, w = F, h = F, u) 
{
    if (missing(u)) 
        u <- rep(1, dim(x)[2])
    if (h) 
        rslt <- list(raw.fwd.rets = y, raw = x)
    x <- bbk.holidays(x, y)
    x <- fcn.mat.vec(function(z) qtl(z, n, , u), x, , F)
    if (h) 
        rslt[["bins"]] <- x
    uRetVec <- rowMeans(y, na.rm = T)
    y <- mat.ex.matrix(y) - uRetVec
    z <- array.unlist(x, c("date", "security", "bin"))
    z$ret <- unlist(y)
    z <- pivot(mean, z$ret, z$date, z$bin)
    z <- map.rname(z, rownames(x))
    colnames(z) <- paste0("Q", colnames(z))
    z <- mat.ex.matrix(z)
    z$TxB <- z[, 1] - z[, dim(z)[2]]
    if (w) 
        z$uRet <- uRetVec
    if (h) {
        rslt[["rets"]] <- z
        z <- rslt
    }
    z
}

#' bbk.data
#' 
#' fetches data required to compute standard model output
#' @param x = a matrix/data frame (predictors)
#' @param y = a matrix/data frame (total return indices)
#' @param n = a positive integer (flow window in days/months)
#' @param w = a boolean (sum/compound)
#' @param h = a non-negative integer (lag in days/months)
#' @param u = a non-negative integer (delay in days/months)
#' @param v = a non-negative integer (0 = Sun, 1 = Mon, etc., the day you trade)
#' @param g = a positive integer (return window in days/months)
#' @param r = a string (index within which you trade)
#' @param s = a boolean (spread changes/returns)
#' @keywords bbk.data
#' @export
#' @family bbk

bbk.data <- function (x, y, n, w, h, u, v, g, r, s) 
{
    x <- x[!is.na(avail(x)), ]
    if (!ascending(rownames(x))) 
        stop("Flows are crap")
    if (any(yyyymm.lag(rownames(x)[dim(x)[1]], dim(x)[1]:1 - 
        1, F) != rownames(x))) 
        stop("Missing flow dates")
    if (!ascending(rownames(y))) 
        stop("Returns are crap")
    if (any(yyyymm.lag(rownames(y)[dim(y)[1]], dim(y)[1]:1 - 
        1) != rownames(y))) 
        stop("Missing return dates")
    if (n > 1) 
        x <- compound.flows(x, n, w)
    x <- mat.lag(x, h + u)
    if (!is.null(v)) 
        x <- mat.daily.to.weekly(vec.last, x, v)
    y <- bbk.fwdRet(x, y, g, !s)
    if (!is.null(r)) 
        y <- Ctry.msci.index.changes(y, r)
    z <- list(x = x, fwdRet = y)
    z
}

#' bbk.drawdown
#' 
#' contiguous periods corresponding to max drawdown
#' @param x = a numeric vector
#' @keywords bbk.drawdown
#' @export
#' @family bbk

bbk.drawdown <- function (x) 
{
    z <- cumsum(zav(x))
    z <- cummax(z) - rev(cummin(rev(z)))
    z <- z == max(z)
    z <- z & duplicated(z)
    z
}

#' bbk.fwdRet
#' 
#' returns a matrix/data frame of the same dimensions as <x>
#' @param x = a matrix/data frame (predictors)
#' @param y = a matrix/data frame (total return indices)
#' @param n = a positive integer (return window in days)
#' @param w = a boolean (returns/spread changes)
#' @keywords bbk.fwdRet
#' @export
#' @family bbk

bbk.fwdRet <- function (x, y, n, w) 
{
    if (dim(x)[2] != dim(y)[2]) 
        stop("Problem 1")
    if (any(colnames(x) != colnames(y))) 
        stop("Problem 2")
    y <- ret.ex.idx(y, n, T, w)
    z <- map.rname(y, rownames(x))
    z <- excise.zeroes(z)
    z
}

#' bbk.holidays
#' 
#' Sets <x> to NA whenever <y> is NA
#' @param x = a matrix/data frame (predictors)
#' @param y = a matrix/data frame (forward returns)
#' @keywords bbk.holidays
#' @export
#' @family bbk

bbk.holidays <- function (x, y) 
{
    x * nonneg(mat.to.obs(y))
}

#' bbk.matrix
#' 
#' standard model output summary value of <item> for "TxB" for various argument combinations
#' @param x = a matrix/data frame (predictors)
#' @param y = a matrix/data frame (total return indices)
#' @param n = a positive integer (flow window in days/months)
#' @param w = a positive integer (return window in days/months)
#' @param h = an integer (number of bins)
#' @param u = an integer (0 = Sun, 1 = Mon, etc., the day you trade)
#' @param v = a boolean (sum/compound)
#' @param g = a non-negative integer (lag in days/months)
#' @param r = a non-negative integer (delay in days/months)
#' @param s = a string (index within which you trade)
#' @param b = a boolean (spread changes/returns)
#' @param p = a string (e.g. AnnMn, Sharpe)
#' @keywords bbk.matrix
#' @export
#' @family bbk

bbk.matrix <- function (x, y, n, w = 5, h = 5, u = 5, v = F, g = 0, r = 2, 
    s = NULL, b = F, p = "AnnMn") 
{
    z <- x <- as.list(environment())
    z <- z[!is.element(names(z), c("x", "y", "p"))]
    z <- z[sapply(z, function(z) length(z) > 1)]
    x <- x[!is.element(names(x), c(names(z), "p"))]
    z <- expand.grid(z)
    z[, p] <- rep(NA, dim(z)[1])
    for (j in 1:dim(z)[1]) {
        y <- lapply(z[, -dim(z)[2]], function(z) z[j])
        cat("\t", paste(paste(names(y), "=", unlist(y)), collapse = ", "), 
            "..\n")
        z[j, p] <- do.call(bbk, c(y, x))[["summ"]][p, "TxB"]
    }
    z <- reshape.wide(z)
    z
}

#' bbk.summ
#' 
#' summarizes by year and overall
#' @param x = a matrix/data frame (bin returns)
#' @param y = a matrix/data frame (bin memberships)
#' @param n = a positive integer (return window in days/months)
#' @param w = a positive integer
#' @keywords bbk.summ
#' @export
#' @family bbk

bbk.summ <- function (x, y, n, w) 
{
    if (n%%w != 0) 
        stop("Quantum size is wrong!")
    prdsPerYr <- yyyy.periods.count(rownames(x))
    fcn <- function(z) bbk.bin.rets.summ(z, prdsPerYr/n)
    z <- mat.ex.matrix(summ.multi(fcn, x, n/w))
    fcn <- function(z) bbk.turnover(z) * prdsPerYr/n
    y <- summ.multi(fcn, mat.ex.matrix(y), n/w)
    z <- map.rname(z, c(rownames(z), "AnnTo"))
    z["AnnTo", ] <- map.rname(y, colnames(z))
    z <- list(summ = z)
    if (n == w) {
        z.ann <- yyyy.ex.period(rownames(x), n)
        z.ann <- bbk.bin.rets.prd.summ(bbk.bin.rets.summ, x, 
            z.ann, prdsPerYr/n)
        z.ann <- rbind(z.ann["AnnMn", , ], z.ann["nPrds", "uRet", 
            ])
        z.ann <- t(z.ann)
        colnames(z.ann)[dim(z.ann)[2]] <- "nPrds"
        z[["annSumm"]] <- z.ann
    }
    z
}

#' bbk.turnover
#' 
#' returns average name turnover per bin
#' @param x = a matrix/data frame (positive integers)
#' @keywords bbk.turnover
#' @export
#' @family bbk

bbk.turnover <- function (x) 
{
    z <- vec.unique(x)
    x <- zav(x)
    new <- x[-1, ]
    old <- x[-dim(x)[1], ]
    z <- vec.named(rep(NA, length(z)), z)
    for (i in names(z)) z[i] <- mean(nameTo(old == i, new == 
        i), na.rm = T)
    names(z) <- paste0("Q", names(z))
    z["TxB"] <- z["Q1"] + z["Q5"]
    z["uRet"] <- 0
    z
}

#' bear
#' 
#' T/F depending on whether period fell in a bear market
#' @param x = a numeric vector (log returns)
#' @keywords bear
#' @export

bear <- function (x) 
{
    n <- length(x)
    z <- rep(F, n)
    y <- c(1, n)
    while (length(y) > 0) {
        h <- bbk.drawdown(x[y[1]:y[2]])
        if (100 * exp(sum(x[y[1]:y[2]][h])) < 80) {
            z[y[1]:y[2]] <- h
            v <- min((y[1]:y[2])[h])
            if (v > y[1] + 1) 
                y <- c(y, y[1], v - 1)
            v <- max((y[1]:y[2])[h])
            if (v < y[2] - 1) 
                y <- c(y, v + 1, y[2])
        }
        y <- tail(y, -2)
    }
    z
}

#' best.linear.strategy.blend
#' 
#' Returns optimal weights to put on <x> and <y>
#' @param x = a numeric vector (return)
#' @param y = a numeric vector (return)
#' @keywords best.linear.strategy.blend
#' @export

best.linear.strategy.blend <- function (x, y) 
{
    x <- as.list(environment())
    w <- Reduce("&", lapply(x, function(z) !is.na(z)))
    x <- lapply(x, function(z) z[w])
    avg <- sapply(x, mean)
    std <- sapply(x, sd)
    gm <- Reduce(correl, x)
    V <- c(std["x"]^2, rep(std["x"] * std["y"] * gm, 2), std["y"]^2)
    V <- matrix(V, 2, 2)
    V <- solve(V)
    z <- V %*% avg
    z <- renorm(z[, 1])
    z
}

#' binomial.trial
#' 
#' returns the likelihood of getting <n> or more/fewer heads depending on whether <w> is T/F
#' @param x = probability of success in a 1/0 Bernoulli trial
#' @param y = number of coin flips
#' @param n = number of heads
#' @param w = a boolean (upper/lower tail)
#' @keywords binomial.trial
#' @export

binomial.trial <- function (x, y, n, w) 
{
    if (w) 
        pbinom(y - n, y, 1 - x)
    else pbinom(n, y, x)
}

#' bond.curve.expand
#' 
#' full yield curve
#' @param x = a numeric vector (interest rates)
#' @keywords bond.curve.expand
#' @export
#' @family bond

bond.curve.expand <- function (x) 
{
    approx(char.to.num(names(x)), char.to.num(x), 1:char.to.num(names(x)[length(x)]), 
        method = "constant", f = 1, rule = 2)$y
}

#' bond.price
#' 
#' bond prices
#' @param x = a numeric vector (annual coupon rates)
#' @param y = an integer vector (years to maturity)
#' @param n = a numeric vector (interest rates)
#' @keywords bond.price
#' @export
#' @family bond

bond.price <- function (x, y, n) 
{
    w <- length(x) == length(n)
    if (!w) 
        n <- bond.curve.expand(n)
    z <- rep(0, length(x))
    if (w) 
        discount <- rep(1, length(x))
    else discount <- 1
    for (j in seq_along(n)) {
        if (w) {
            discount <- discount/(1 + n/100)
        }
        else {
            discount <- discount/(1 + n[j]/100)
        }
        z <- z + ifelse(y >= j, x * discount, 0)
        z <- z + ifelse(y == j, 100 * discount, 0)
    }
    z
}

#' brinson
#' 
#' performs a Brinson attribution
#' @param x = a numeric vector (benchmark weights)
#' @param y = a numeric vector (active weights)
#' @param n = a numeric vector (returns)
#' @param w = a numeric vector (groups)
#' @keywords brinson
#' @export

brinson <- function (x, y, n, w) 
{
    z <- list()
    z[["BmkWgt"]] <- pivot.1d(sum, w, x)
    z[["ActWgt"]] <- pivot.1d(sum, w, y)
    z[["BmkRet"]] <- pivot.1d(sum, w, x * n)
    z[["PorRet"]] <- pivot.1d(sum, w, (x + y) * n)
    w <- unique(w)
    w <- sapply(z, function(z) map.rname(z, w))
    w[, "BmkRet"] <- w[, "BmkRet"]/nonneg(w[, "BmkWgt"])
    w[, "PorRet"] <- w[, "PorRet"]/nonneg(rowSums(w[, c("BmkWgt", 
        "ActWgt")]))
    w[, "PorRet"] <- zav(w[, "PorRet"], w[, "BmkRet"])
    w[, "PorRet"] <- w[, "PorRet"] - w[, "BmkRet"]
    z <- list()
    z[["Selec"]] <- sum(w[, "PorRet"] * w[, "BmkWgt"])
    z[["Alloc"]] <- sum(w[, "BmkRet"] * w[, "ActWgt"])
    z[["Intcn"]] <- sum(w[, "PorRet"] * w[, "ActWgt"])
    z <- unlist(z)/100
    z
}

#' britten.jones
#' 
#' transforms the design matrix as set out in Britten-Jones, M., Neuberger  , A., & Nolte, I. (2011). Improved inference in regression with overlapping  observations. Journal of Business Finance & Accounting, 38(5-6), 657-683.
#' @param x = a matrix
#' @param y = constitutent lagged returns that go into the first period
#' @keywords britten.jones
#' @export
#' @family britten

britten.jones <- function (x, y) 
{
    m <- length(y)
    n <- dim(x)[1]
    orig.nms <- colnames(x)
    for (i in 1:n) y <- c(y, x[i, 1] - sum(y[i - 1 + 1:m]))
    x <- as.matrix(x[, -1])
    z <- matrix(0, n + m, dim(x)[2], F, list(seq(1, m + n), colnames(x)))
    for (i in 0:m) z[1:n + i, ] <- z[1:n + i, ] + x
    if (det(crossprod(z)) > 0) {
        z <- z %*% solve(crossprod(z)) %*% crossprod(x)
        z <- data.frame(y, z)
        names(z) <- orig.nms
    }
    else z <- NULL
    z
}

#' britten.jones.data
#' 
#' returns data needed for a Britten-Jones analysis
#' @param x = a matrix/data frame (predictors)
#' @param y = a matrix/data frame (total return indices)
#' @param n = a positive integer (return window)
#' @param w = a string (index within which you trade)
#' @keywords britten.jones.data
#' @export
#' @family britten

britten.jones.data <- function (x, y, n, w = NULL) 
{
    if (any(dim(x) != dim(y))) 
        stop("x/y are mismatched!")
    prd.ret <- 100 * mat.lag(y, -1)/nonneg(y) - 100
    prd.ret <- list(prd1 = prd.ret)
    if (n > 1) 
        for (i in 2:n) prd.ret[[paste0("prd", i)]] <- mat.lag(prd.ret[["prd1"]], 
            1 - i)
    y <- ret.ex.idx(y, n, T, T)
    vec <- char.to.num(unlist(y))
    w1 <- !is.na(vec) & abs(vec) < 1e-06
    if (any(w1)) {
        for (i in names(prd.ret)) {
            w2 <- char.to.num(unlist(prd.ret[[i]]))
            w2 <- is.na(w2) | abs(w2) < 1e-06
            w1 <- w1 & w2
        }
    }
    if (any(w1)) {
        vec <- ifelse(w1, NA, vec)
        y <- matrix(vec, dim(y)[1], dim(y)[2], F, dimnames(y))
    }
    if (!is.null(w)) 
        y <- Ctry.msci.index.changes(y, w)
    x <- bbk.bin.xRet(x, y, 5, F, T)
    y <- ret.to.log(y)
    prd.ret <- lapply(prd.ret, ret.to.log)
    w1 <- !is.na(unlist(y))
    for (i in names(prd.ret)) {
        vec <- char.to.num(unlist(prd.ret[[i]]))
        vec <- ifelse(w1, vec, NA)
        prd.ret[[i]] <- matrix(vec, dim(y)[1], dim(y)[2], F, 
            dimnames(y))
    }
    fcn <- function(z) z - rowMeans(z, na.rm = T)
    y <- fcn(y)
    prd.ret <- lapply(prd.ret, fcn)
    z <- NULL
    for (i in colnames(x$bins)) {
        if (sum(!is.na(x$bins[, i]) & !duplicated(x$bins[, i])) > 
            1) {
            df <- char.to.num(x$bins[, i])
            w1 <- !is.na(df)
            n.beg <- find.data(w1, T)
            n.end <- find.data(w1, F)
            if (n > 1 & n.end - n.beg + 1 > sum(w1)) {
                vec <- find.gaps(w1)
                if (any(vec < n - 1)) {
                  vec <- vec[vec < n - 1]
                  for (j in names(vec)) df[char.to.num(j) + 1:char.to.num(vec[j]) - 
                    1] <- 3
                }
            }
            df <- mat.ex.vec(df)
            w1 <- rowSums(df) == 1
            if (all(is.element(c("Q1", "Q5"), names(df)))) {
                df$TxB <- (df$Q1 - df$Q5)/2
            }
            else if (any(names(df) == "Q1")) {
                df$TxB <- df$Q1/2
            }
            else if (any(names(df) == "Q5")) {
                df$TxB <- -df$Q5/2
            }
            df <- df[, !is.element(names(df), c("Q1", "Q5"))]
            df$ActRet <- y[, i]
            df <- mat.last.to.first(df)
            w1 <- !is.na(prd.ret[["prd1"]][, i]) & w1
            n.beg <- find.data(w1, T)
            n.end <- find.data(w1, F)
            if (n == 1 | n.end - n.beg + 1 == sum(w1)) {
                z <- britten.jones.data.stack(df[n.beg:n.end, 
                  ], n, prd.ret, n.beg, i)
            }
            else {
                vec <- find.gaps(w1)
                if (any(vec < n - 1)) 
                  stop("Small return gap detected: i = ", i, 
                    ", retHz =", n, "..\n")
                if (any(vec >= n - 1)) {
                  vec <- vec[vec >= n - 1]
                  n.beg <- c(n.beg, char.to.num(names(vec)) + 
                    char.to.num(vec))
                  n.end <- c(char.to.num(names(vec)) - 1, n.end)
                  for (j in seq_along(n.beg)) z <- britten.jones.data.stack(df[n.beg[j]:n.end[j], 
                    ], n, prd.ret, n.beg[j], i)
                }
            }
        }
    }
    z
}

#' britten.jones.data.stack
#' 
#' applies the Britten-Jones transformation to a subset and then stacks
#' @param x = a matrix/data frame
#' @param y = a positive integer (return window)
#' @param n =
#' @param w = an integer
#' @param h =
#' @keywords britten.jones.data.stack
#' @export
#' @family britten

britten.jones.data.stack <- function (x, y, n, w, h) 
{
    u <- colSums(x[, -1] == 0) == dim(x)[1]
    if (any(u)) {
        u <- !is.element(colnames(x), colnames(x)[-1][u])
        x <- x[, u]
    }
    if (y > 1) {
        vec <- NULL
        for (j in names(n)[-y]) vec <- c(vec, n[[j]][w, h])
        n <- dim(x)[1]
        x <- britten.jones(x, vec)
        if (is.null(x)) 
            cat("Discarding", n, "observations for", h, "due to Britten-Jones singularity ..\n")
    }
    if (!is.null(x)) 
        x <- mat.ex.matrix(zav(t(map.rname(t(x), c("ActRet", 
            paste0("Q", 2:4), "TxB")))))
    if (!is.null(x)) {
        if (is.null(z)) {
            rownames(x) <- 1:dim(x)[1]
            z <- x
        }
        else {
            rownames(x) <- 1:dim(x)[1] + dim(z)[1]
            z <- rbind(z, x)
        }
    }
    z
}

#' char.to.num
#' 
#' coerces to numeric without generating warnings
#' @param x = a string vector
#' @keywords char.to.num
#' @export

char.to.num <- function (x) 
{
    suppressWarnings(as.numeric(x))
}

#' classification.threshold
#' 
#' threshold value that causes fewest classification errors
#' @param x = a 1/0 vector
#' @param y = a numeric vector (predictors)
#' @keywords classification.threshold
#' @export

classification.threshold <- function (x, y) 
{
    n <- length(x)
    x <- x[order(y)]
    y <- y[order(y)]
    z <- c(n + 1, y[1] - 1)
    for (j in 2:n) {
        v <- mean(y[j - 1:0])
        w <- y > v
        h <- min(sum(w) + sum(x[!w]) - sum(x[w]), sum(!w) + sum(x[w]) - 
            sum(x[!w]))
        if (h < z[1]) 
            z <- c(h, v)
    }
    z
}

#' col.ex.int
#' 
#' Returns the relevant excel column (1 = "A", 2 = "B", etc.)
#' @param x = a positive integer vector
#' @keywords col.ex.int
#' @export
#' @family col

col.ex.int <- function (x) 
{
    z <- rep("", length(x))
    w <- x > 0
    while (any(w)) {
        h <- x[w]%%26
        h <- ifelse(h == 0, 26, h)
        x[w] <- (x[w] - h)/26
        z[w] <- paste0(LETTERS[h], z[w])
        w <- x > 0
    }
    z
}

#' col.lag
#' 
#' Lags <x> by <y> columns
#' @param x = a string (excel column)
#' @param y = an integer vector
#' @keywords col.lag
#' @export
#' @family col

col.lag <- function (x, y) 
{
    obj.lag(x, y, col.to.int, col.ex.int)
}

#' col.to.int
#' 
#' Returns the relevant associated integer (1 = "A", 2 = "B", etc.)
#' @param x = a string vector (representation of excel column)
#' @keywords col.to.int
#' @export
#' @family col

col.to.int <- function (x) 
{
    z <- lapply(vec.to.list(x), txt.to.char)
    z <- lapply(z, function(z) match(z, LETTERS))
    z <- char.to.num(sapply(z, base.to.int))
    z
}

#' combinations
#' 
#' returns all possible combinations of <y> values of <x>
#' @param x = a numeric vector
#' @param y = an integer between 1 and <length(x)>
#' @keywords combinations
#' @export
#' @family combinations

combinations <- function (x, y) 
{
    w <- rep(F, length(x))
    if (y > 0) 
        w[1:y] <- T
    if (all(w)) {
        z <- paste(x, collapse = " ")
    }
    else if (all(!w)) {
        z <- ""
    }
    else {
        z <- NULL
        while (any(w)) {
            z <- c(z, paste(x[w], collapse = " "))
            w <- combinations.next(w)
        }
    }
    z
}

#' combinations.ex.int
#' 
#' inverse of combinations.to.int; returns a logical vector #		:	of length <n>, <y> of which elements are T
#' @param x = a positive integer
#' @param y = a positive integer
#' @param n = a positive integer
#' @keywords combinations.ex.int
#' @export
#' @family combinations

combinations.ex.int <- function (x, y, n) 
{
    z <- x <= choose(n - 1, y - 1)
    if (n > 1 & z) {
        z <- c(z, combinations.ex.int(x, y - 1, n - 1))
    }
    else if (n > 1 & !z) {
        z <- c(z, combinations.ex.int(x - choose(n - 1, y - 1), 
            y, n - 1))
    }
    z
}

#' combinations.next
#' 
#' returns the next combination in dictionary order
#' @param x = a logical vector
#' @keywords combinations.next
#' @export
#' @family combinations

combinations.next <- function (x) 
{
    m <- length(x)
    n <- find.data(!x, F)
    if (any(x[1:n])) {
        n <- find.data(x[1:n], F)
        nT <- sum(x) - sum(x[1:n])
        x[n:m] <- F
        x[n + 1 + 0:nT] <- T
        z <- x
    }
    else {
        z <- rep(F, m)
    }
    z
}

#' combinations.to.int
#' 
#' maps each particular way to choose <sum(x)> things #		:	amongst <length(x)> things to the number line
#' @param x = a logical vector
#' @keywords combinations.to.int
#' @export
#' @family combinations

combinations.to.int <- function (x) 
{
    n <- length(x)
    m <- sum(x)
    if (m == 0 | n == 1) {
        z <- 1
    }
    else if (x[1]) {
        z <- combinations.to.int(x[-1])
    }
    else {
        z <- choose(n - 1, m - 1) + combinations.to.int(x[-1])
    }
    z
}

#' common.fund.flow.shock
#' 
#' common fund flow shock of Dou, Kogan & Wu (2022)
#' @param x = a YYYYMM
#' @param y = a connection string
#' @param n = number of months
#' @keywords common.fund.flow.shock
#' @export

common.fund.flow.shock <- function (x, y, n) 
{
    z <- c(sql.declare("@begPrd", "datetime", yyyymm.to.day(yyyymm.lag(x, 
        n + 1))))
    x <- c(z, sql.declare("@endPrd", "datetime", yyyymm.to.day(yyyymm.lag(x, 
        -1))), "")
    z <- c("Flow", "PortfolioChange", "AssetsStart")
    z <- paste0(z, " = sum(", z, ")")
    z <- c("FundId", sql.yyyymmdd("MonthEnding"), z)
    w <- paste("MonthEnding", c("<", ">"), c("@endPrd", "@begPrd"))
    w <- split(w, c("End", "Beg"))
    z <- sql.Flow(z, w, c("Act", "E", "UI"), , "M", "FundId, MonthEnding")
    z <- paste(c(x, sql.unbracket(z)), collapse = "\n")
    z <- sql.query(z, y, F)
    z <- z[!is.na(z[, "AssetsStart"]) & z[, "AssetsStart"] > 
        0, ]
    z[, "MonthEnding"] <- yyyymmdd.to.yyyymm(z[, "MonthEnding"])
    x <- vec.count(z[, "FundId"])
    x <- map.rname(x, z[, "FundId"])
    z <- z[is.element(x, n + 1), ]
    x <- pivot.1d(sum, z[, "MonthEnding"], z[, c("PortfolioChange", 
        "Flow", "AssetsStart")])
    x <- as.matrix(x)
    x <- x[order(rownames(x)), ]
    y <- (100 * x[, "Flow"]/x[, "AssetsStart"])[-1]
    x <- 100 * x[, "PortfolioChange"]/x[, "AssetsStart"]
    for (w in c("Flow", "PortfolioChange")) z[, w] <- 100 * z[, 
        w]/z[, "AssetsStart"]
    z[, "PortfolioChange"] <- z[, "PortfolioChange"] - map.rname(x, 
        z[, "MonthEnding"])
    x <- z[, colnames(z) != "AssetsStart"]
    x[, "MonthEnding"] <- yyyymm.lag(x[, "MonthEnding"], -1)
    colnames(x)[3:4] <- paste0(colnames(x)[3:4], ".m1")
    x <- merge(z, x)
    z <- x[, colnames(x) != "AssetsStart"]
    x <- reshape.wide(x[, c("MonthEnding", "FundId", "AssetsStart")])
    x <- x[order(rownames(x)), order(colnames(x))]
    x <- as.matrix(x)
    z <- split(z[, colnames(z) != "FundId"], z[, "FundId"])
    z <- lapply(z, mat.index)
    z <- lapply(z, function(z) summary(lm(txt.regr(colnames(z)), 
        z))[["residuals"]])
    z <- simplify2array(z)
    z <- z[rownames(x), colnames(x)]
    w <- qtl.eq(x)
    n <- list()
    for (j in rownames(z)) {
        r <- data.frame(z[j, ], x[j, ], stringsAsFactors = F)
        r[, 1] <- r[, 1] * r[, 2]
        r <- pivot.1d(sum, w[j, ], r)
        r <- as.matrix(r)[as.character(1:5), ]
        n[[j]] <- r[, 1]/r[, 2]
    }
    n <- simplify2array(n)
    z <- svd(n)[["v"]][, 1]
    z <- sign(correl(z, y)) * z
    z
}

#' compound
#' 
#' Outputs the compounded return
#' @param x = a numeric vector (percentage returns)
#' @keywords compound
#' @export
#' @family compound

compound <- function (x) 
{
    z <- !is.na(x)
    if (any(z)) 
        z <- 100 * product(1 + x[z]/100) - 100
    else z <- NA
    z
}

#' compound.flows
#' 
#' compounded flows over <n> trailing periods indexed by last day in the flow window
#' @param x = a matrix/data frame
#' @param y = a positive integer (number of rows to compound/sum)
#' @param n = a boolean (sum/compound)
#' @keywords compound.flows
#' @export
#' @family compound

compound.flows <- function (x, y, n = F) 
{
    h <- nonneg(mat.to.obs(x))
    z <- zav(x)
    if (!n) 
        z <- log(1 + z/100)
    z <- mat.rollsum(z, y)
    if (!n) 
        z <- 100 * exp(z) - 100
    z <- z * h
    z
}

#' compound.sf
#' 
#' compounds flows
#' @param x = a matrix/data frame
#' @param y = a boolean (sum/compound)
#' @keywords compound.sf
#' @export
#' @family compound

compound.sf <- function (x, y) 
{
    if (y) 
        fcn <- sum
    else fcn <- compound
    w <- is.na(x[, dim(x)[2]])
    z <- fcn.mat.num(fcn, zav(x), , F)
    z[w] <- NA
    z
}

#' correl
#' 
#' the estimated correlation between <x> and <y> or the columns of <x>
#' @param x = a numeric vector/matrix/data frame
#' @param y = a numeric vector (can be missing)
#' @param n = a boolean (rank/regular correlations)
#' @keywords correl
#' @export

correl <- function (x, y, n = T) 
{
    if (missing(y)) 
        fcn.mat.col(cor, x, , n)
    else fcn.mat.col(cor, x, y, n)
}

#' covar
#' 
#' efficient estimated covariance between the columns of <x>
#' @param x = a matrix
#' @keywords covar
#' @export

covar <- function (x) 
{
    cov(x, use = "pairwise.complete.obs")
}

#' cpt.RgnSec
#' 
#' makes Region-Sector groupings
#' @param x = an integer vector (sectors)
#' @param y = a country code vector
#' @keywords cpt.RgnSec
#' @export
#' @family cpt

cpt.RgnSec <- function (x, y) 
{
    y <- Ctry.to.CtryGrp(y)
    z <- GSec.to.GSgrp(x)
    z <- ifelse(is.element(z, "Cyc"), x, z)
    vec <- c(seq(15, 25, 5), "Def", "Fin")
    vec <- txt.expand(vec, c("Pac", "Oth"), , T)
    vec <- vec.named(c(seq(1, 9, 2), 1 + seq(1, 9, 2)), vec)
    vec["45-Pac"] <- vec["45-Oth"] <- 11
    z <- paste(z, y, sep = "-")
    z <- map.rname(vec, z)
    z <- char.to.num(z)
    z
}

#' cpt.RgnSecJP
#' 
#' makes Region-Sector groupings
#' @param x = an integer vector (sectors)
#' @param y = a country code vector
#' @keywords cpt.RgnSecJP
#' @export
#' @family cpt

cpt.RgnSecJP <- function (x, y) 
{
    y <- ifelse(is.element(y, c("US", "CA")), "NoAm", Ctry.to.CtryGrp(y))
    z <- GSec.to.GSgrp(x)
    z <- ifelse(is.element(z, "Cyc"), x, z)
    vec <- c(seq(15, 25, 5), "Def", "Fin")
    vec <- txt.expand(vec, c("Pac", "NoAm", "Oth"), , T)
    x <- NULL
    for (j in 1:3) x <- c(x, seq(j, by = 3, length.out = 5))
    vec <- vec.named(x, vec)
    vec[paste("45", c("Pac", "NoAm", "Oth"), sep = "-")] <- length(vec) + 
        1
    z <- paste(z, y, sep = "-")
    z <- map.rname(vec, z)
    z <- char.to.num(z)
    z
}

#' Ctry.info
#' 
#' handles the addition and removal of countries from an index
#' @param x = a country code vector
#' @param y = a string (column in classif-Ctry)
#' @keywords Ctry.info
#' @export
#' @family Ctry
#' @examples
#' Ctry.info("PK", "CtryNm")

Ctry.info <- function (x, y) 
{
    z <- mat.read(parameters("classif-ctry"), ",")
    z <- map.rname(z, x)[, y]
    z
}

#' Ctry.msci
#' 
#' Countries added or removed from the index in ascending order
#' @param x = a string (index like ACWI/EAFE/EM)
#' @keywords Ctry.msci
#' @export
#' @family Ctry

Ctry.msci <- function (x) 
{
    z <- c("Developed", "Emerging", "Frontier")
    names(z) <- c("EAFE", "EM", "Frontier")
    if (x == "ACWI") 
        x <- c("EAFE", "EM")
    if (any(!is.element(x, names(z)))) 
        stop("Bad Index")
    x <- z[x]
    z <- parameters("MsciCtryClassification")
    z <- mat.sort(mat.read(z, "\t", NULL), "yyyymm", F)
    fcn <- function(z) is.element(z, x)
    z[, c("From", "To")] <- apply(z[, c("From", "To")], 2, fcn)
    z <- z[z$From != z$To, c("CCode", "To", "yyyymm")]
    colnames(z) <- c("CCODE", "ACTION", "YYYYMM")
    z
}

#' Ctry.msci.index.changes
#' 
#' handles the addition and removal of countries from an index
#' @param x = a matrix/data frame (total return indices indexed by trade date)
#' @param y = a string (MSCI index like ACWI/EAFE/EM)
#' @keywords Ctry.msci.index.changes
#' @export
#' @family Ctry

Ctry.msci.index.changes <- function (x, y) 
{
    h <- Ctry.msci.members.rng(y, rownames(x)[1], tail(rownames(x), 
        1))
    z <- Ctry.msci(y)
    if (nchar(rownames(x)[1]) == 8) 
        z$YYYYMM <- yyyymmdd.ex.yyyymm(z$YYYYMM)
    if (nchar(colnames(x)[1]) == 3) {
        z$CCODE <- Ctry.info(z$CCODE, "Curr")
        h <- Ctry.info(h, "Curr")
        z <- z[!is.element(z$CCODE, c("USD", "EUR")), ]
    }
    w <- !is.element(z$CCODE, colnames(x))
    if (any(w)) {
        w2 <- is.element(h, z$CCODE[w])
        z <- z[!w, ]
        if (any(w2)) 
            err.raise(h[w2], F, "Warning: No data for the following")
    }
    u.Ctry <- z$CCODE[!duplicated(z$CCODE)]
    z <- z[order(z$YYYYMM), ]
    for (i in u.Ctry) {
        vec <- z$CCODE == i
        if (!z[vec, "ACTION"][1]) 
            vec <- c("19720809", z[vec, "YYYYMM"])
        else vec <- z[vec, "YYYYMM"]
        if (length(vec)%%2 == 0) 
            vec <- c(vec, "30720809")
        w <- rownames(x) < vec[1]
        vec <- vec[-1]
        while (length(vec) > 0) {
            w <- w | (rownames(x) >= vec[1] & rownames(x) < vec[2])
            vec <- tail(vec, -2)
        }
        x[w, i] <- NA
    }
    z <- x
    z
}

#' Ctry.msci.members
#' 
#' lists countries in an index at <y>
#' @param x = a string (index like ACWI/EAFE/EM)
#' @param y = a YYYYMM/YYYYMMDD ("" for static series)
#' @keywords Ctry.msci.members
#' @export
#' @family Ctry

Ctry.msci.members <- function (x, y) 
{
    fcn <- function(z, l, k) if (l) 
        union(z, k)
    else setdiff(z, k)
    z <- mat.read(parameters("MsciCtry2016"), ",")
    z <- rownames(z)[is.element(z[, x], 1)]
    if (nchar(y) == 8) 
        u <- "20160331"
    else u <- "201603"
    if (y != "") 
        x <- Ctry.msci(x)
    if (nchar(y) == 8) 
        x$YYYYMM <- yyyymmdd.ex.yyyymm(x$YYYYMM)
    if (y != "" & y > u) {
        w <- x$YYYYMM >= u & x$YYYYMM <= y
        for (i in which(w)) z <- fcn(z, x[i, "ACTION"], x[i, 
            "CCODE"])
    }
    if (y != "" & y < u) {
        w <- x$YYYYMM <= u & x$YYYYMM > y
        if (any(w)) {
            x <- mat.reverse(x)
            w <- rev(w)
            x[, "ACTION"] <- !x[, "ACTION"]
            for (i in which(w)) z <- fcn(z, x[i, "ACTION"], x[i, 
                "CCODE"])
        }
    }
    z
}

#' Ctry.msci.members.rng
#' 
#' lists countries that were ever in an index between <y> and <n>
#' @param x = a string (index like ACWI/EAFE/EM)
#' @param y = a YYYYMM/YYYYMMDD
#' @param n = after <y> and of the same date type
#' @keywords Ctry.msci.members.rng
#' @export
#' @family Ctry

Ctry.msci.members.rng <- function (x, y, n) 
{
    if (nchar(y) != nchar(n) | y >= n) 
        stop("Problem")
    z <- Ctry.msci.members(x, y)
    x <- Ctry.msci(x)
    if (nchar(y) == 8) 
        x$YYYYMM <- yyyymmdd.ex.yyyymm(x$YYYYMM)
    z <- union(z, x[x$YYYYMM >= y & x$YYYYMM <= n & x$ACTION, 
        "CCODE"])
    z
}

#' Ctry.to.CtryGrp
#' 
#' makes Country groups
#' @param x = a country code vector
#' @keywords Ctry.to.CtryGrp
#' @export
#' @family Ctry

Ctry.to.CtryGrp <- function (x) 
{
    z <- c("JP", "AU", "NZ", "HK", "SG", "CN", "KR", "TW", "PH", 
        "ID", "TH", "MY", "KY", "BM")
    z <- ifelse(is.element(x, z), "Pac", "Oth")
    z
}

#' day.ex.date
#' 
#' calendar dates
#' @param x = an R date vector
#' @keywords day.ex.date
#' @export
#' @family day

day.ex.date <- function (x) 
{
    format(x, "%Y%m%d")
}

#' day.ex.int
#' 
#' the <x>th day after Thursday, January 1, 1970
#' @param x = an integer vector
#' @keywords day.ex.int
#' @export
#' @family day

day.ex.int <- function (x) 
{
    format(as.Date(x, origin = "1970-01-01"), "%Y%m%d")
}

#' day.lag
#' 
#' lags <x> by <y> days.
#' @param x = a calendar date vector
#' @param y = an integer vector
#' @keywords day.lag
#' @export
#' @family day

day.lag <- function (x, y) 
{
    obj.lag(x, y, day.to.int, day.ex.int)
}

#' day.seq
#' 
#' returns a sequence of calendar dates between (and including) x and y
#' @param x = a calendar date
#' @param y = a calendar date
#' @param n = a positive integer
#' @keywords day.seq
#' @export
#' @family day

day.seq <- function (x, y, n = 1) 
{
    obj.seq(x, y, day.to.int, day.ex.int, n)
}

#' day.to.date
#' 
#' converts to an R date
#' @param x = a string vector
#' @keywords day.to.date
#' @export
#' @family day

day.to.date <- function (x) 
{
    as.Date(x, "%Y%m%d")
}

#' day.to.int
#' 
#' number of days after Thursday, January 1, 1970
#' @param x = a calendar date vector
#' @keywords day.to.int
#' @export
#' @family day

day.to.int <- function (x) 
{
    unclass(day.to.date(x))
}

#' day.to.week
#' 
#' maps days to weeks
#' @param x = a calendar date vector
#' @param y = an integer (0 = Sun, 1 = Mon, etc., the day each week ends)
#' @keywords day.to.week
#' @export
#' @family day

day.to.week <- function (x, y) 
{
    x <- day.to.int(x)
    z <- day.ex.int(x + (y + 3 - x%%7)%%7)
    z
}

#' day.to.weekday
#' 
#' Converts to 0 = Sun, 1 = Mon, .., 6 = Sat
#' @param x = a string vector
#' @keywords day.to.weekday
#' @export
#' @family day

day.to.weekday <- function (x) 
{
    as.character(as.POSIXlt(day.to.date(x))$wday)
}

#' decimal.format
#' 
#' rounds <x> to <y> decimals and renders as nice character vector
#' @param x = a numeric vector
#' @param y = a positive integer
#' @keywords decimal.format
#' @export

decimal.format <- function (x, y) 
{
    formatC(x, y, format = "f")
}

#' dir.all.files
#' 
#' Returns all files in the folder including sub-directories
#' @param x = a folder
#' @param y = a string (regular expression)
#' @keywords dir.all.files
#' @export
#' @family dir

dir.all.files <- function (x, y) 
{
    z <- dir(x, y, recursive = T)
    if (length(z) > 0) {
        z <- paste(x, z, sep = "\\")
        z <- txt.replace(z, "/", "\\")
    }
    z
}

#' dir.clear
#' 
#' rids <x> of files of type <y>
#' @param x = a file
#' @param y = a string (regular expression)
#' @keywords dir.clear
#' @export
#' @family dir

dir.clear <- function (x, y) 
{
    cat("Ridding folder", x, "of", y, "files ..\n")
    z <- dir(x, y)
    if (length(x) > 0) 
        file.kill(paste(x, z, sep = "\\"))
    invisible()
}

#' dir.ensure
#' 
#' Creates necessary folders so files can be copied to <x>
#' @param x = a file vector
#' @keywords dir.ensure
#' @export
#' @family dir

dir.ensure <- function (x) 
{
    x <- dirname(x)
    x <- x[!duplicated(x)]
    x <- x[!dir.exists(x)]
    z <- x
    while (length(z) > 0) {
        z <- dirname(z)
        z <- z[!dir.exists(z)]
        x <- union(z, x)
    }
    if (length(x) > 0) 
        dir.make(x)
    invisible()
}

#' dir.kill
#' 
#' removes <x>
#' @param x = a folder vector
#' @keywords dir.kill
#' @export
#' @family dir

dir.kill <- function (x) 
{
    w <- dir.exists(x)
    if (any(w)) 
        unlink(x[w], recursive = T)
    invisible()
}

#' dir.make
#' 
#' creates folders <x>
#' @param x = a folder vector
#' @keywords dir.make
#' @export
#' @family dir

dir.make <- function (x) 
{
    for (z in x) dir.create(z)
    invisible()
}

#' dir.parameters
#' 
#' returns full path to relevant parameters sub-folder
#' @param x = desired sub-folder
#' @keywords dir.parameters
#' @export
#' @family dir

dir.parameters <- function (x) 
{
    paste(fcn.dir(), "New Model Concept\\General", x, sep = "\\")
}

#' dir.parent
#' 
#' returns paths to the parent directory
#' @param x = a file vector
#' @keywords dir.parent
#' @export
#' @family dir

dir.parent <- function (x) 
{
    z <- dirname(x)
    z <- ifelse(z == ".", "", z)
    z <- txt.replace(z, "/", "\\")
    z
}

#' dir.publications
#' 
#' desired output directory for relevant publication
#' @param x = a string
#' @keywords dir.publications
#' @export
#' @family dir

dir.publications <- function (x) 
{
    dir.parameters(paste0("Publications\\", x))
}

#' dir.size
#' 
#' size of directory <x> in KB
#' @param x = a folder
#' @keywords dir.size
#' @export
#' @family dir

dir.size <- function (x) 
{
    z <- dir.all.files(x, "\\.")
    if (length(z) == 0) {
        z <- 0
    }
    else {
        z <- file.size(z)
        z <- sum(z, na.rm = T)/2^10
    }
    z
}

#' dtw
#' 
#' Dynamic time-warped distance between <x> and <y>
#' @param x = a numeric vector
#' @param y = a numeric vector
#' @keywords dtw
#' @export

dtw <- function (x, y) 
{
    n <- length(x)
    m <- length(y)
    z <- matrix(NA, n + 1, m + 1, F, list(c(0, x), c(0, y)))
    z[1, ] <- z[, 1] <- Inf
    z[1, 1] <- 0
    for (i in 1:m + 1) for (j in 1:n + 1) {
        z[j, i] <- min(z[j - 1, i], min(z[j, i - 1], z[j - 1, 
            i - 1])) + abs(x[j - 1] - y[i - 1])
    }
    w <- list(x = n, y = m)
    i <- m + 1
    j <- n + 1
    while (max(i, j) > 2) {
        if (z[j - 1, i - 1] < min(z[j - 1, i], z[j, i - 1])) {
            i <- i - 1
            j <- j - 1
        }
        else if (z[j - 1, i] < z[j, i - 1]) {
            j <- j - 1
        }
        else {
            i <- i - 1
        }
        w[["x"]] <- c(j - 1, w[["x"]])
        w[["y"]] <- c(i - 1, w[["y"]])
    }
    z <- mat.ex.matrix(w)
    z
}

#' dup.code
#' 
#' T/F depending on whether code is duplicated
#' @param x = a string vector
#' @param y = a string vector
#' @keywords dup.code
#' @export

dup.code <- function (x, y) 
{
    z <- list(A = x, B = y)
    z <- lapply(z, function(z) tryCatch(parse(text = z), error = function(z) {
        NULL
    }))
    halt <- all(!sapply(z, is.null))
    if (halt) {
        v <- lapply(z, all.vars)
        halt <- length(unique(sapply(v, length))) == 1
    }
    if (halt) {
        z <- lapply(z, all.names)
        halt <- lapply(z, vec.count)
        halt <- length(unique(sapply(halt, length))) == 1
    }
    if (halt) 
        halt <- length(unique(sapply(z, length))) == 1
    if (halt) {
        for (s in names(z)) {
            v[[s]] <- vec.count(z[[s]][is.element(z[[s]], v[[s]])])
            z[[s]] <- z[[s]][!is.element(z[[s]], names(v[[s]]))]
        }
        halt <- length(unique(sapply(z, length))) == 1
    }
    if (halt) 
        halt <- all(z[[1]] == z[[2]])
    if (halt) {
        v <- lapply(v, sort)
        halt <- all(v[["A"]] == v[["B"]])
    }
    z <- halt
    z
}

#' EHD
#' 
#' named vector of item between <w> and <h> sorted ascending
#' @param x = a connection string/connection
#' @param y = a string (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param n = a frequency (T/F for daily/weekly or D/W/M)
#' @param w = a YYYYMMDD (begin date)
#' @param h = a YYYYMMDD (end date)
#' @param u = a filter vector
#' @keywords EHD
#' @export

EHD <- function (x, y, n, w, h, u = NULL) 
{
    z <- sql.Flow.tbl(n, T)
    n <- sql.Flow.tbl(n, F)
    u <- split(u, ifelse(grepl("InstOrRetail", u), "ShareClass", 
        "Fund"))
    if (any(names(u) == "ShareClass")) 
        u[["ShareClass"]] <- sql.in("SCId", sql.tbl("SCId", "ShareClass", 
            u[["ShareClass"]]))
    if (any(names(u) == "Fund")) 
        u[["Fund"]] <- sql.in("HFundId", sql.FundHistory(u[["Fund"]], 
            F))
    u[["Beg"]] <- paste(n, ">=", wrap(w))
    u[["End"]] <- paste(n, "<=", wrap(h))
    if (grepl("%$", y)) {
        y <- paste0("[", y, "] ", sql.Mo(gsub(".$", "", y), "AssetsStart", 
            NULL, T))
    }
    else {
        y <- paste0(y, " = sum(", y, ")")
    }
    y <- c(sql.yyyymmdd(n), y)
    z <- paste(sql.unbracket(sql.tbl(y, z, sql.and(u), n)), collapse = "\n")
    z <- sql.query(z, x, F)
    z <- mat.index(z)
    z <- z[order(names(z))]
    z
}

#' email.exists
#' 
#' T/F depending on whether email already went out
#' @param x = a string (report name)
#' @param y = date for which you want to send the report
#' @keywords email.exists
#' @export
#' @family email

email.exists <- function (x, y) 
{
    record.exists(x, y, "emails.txt")
}

#' email.kill
#' 
#' deletes entry <x> in the email record. Returns nothing.
#' @param x = a string (report name)
#' @keywords email.kill
#' @export
#' @family email

email.kill <- function (x) 
{
    record.kill(x, "emails.txt")
}

#' email.list
#' 
#' named vector of emails and sent dates
#' @keywords email.list
#' @export
#' @family email

email.list <- function () 
{
    record.read("emails.txt")
}

#' email.record
#' 
#' updates the email record. Returns nothing.
#' @param x = a string (report name)
#' @param y = date for which you sent the report
#' @keywords email.record
#' @export
#' @family email

email.record <- function (x, y) 
{
    record.write(x, y, "emails.txt")
}

#' err.raise
#' 
#' error message
#' @param x = a string vector
#' @param y = a boolean (output many lines/one line)
#' @param n = a string (main line of error message)
#' @keywords err.raise
#' @export
#' @family err

err.raise <- function (x, y, n) 
{
    cat(err.raise.txt(x, y, n), "\n")
    invisible()
}

#' err.raise.txt
#' 
#' error message
#' @param x = a string vector
#' @param y = a boolean (output many lines/one line)
#' @param n = a string (main line of error message)
#' @keywords err.raise.txt
#' @export
#' @family err

err.raise.txt <- function (x, y, n) 
{
    n <- paste0(n, ":")
    if (y) {
        z <- paste(c(n, paste0("\t", x)), collapse = "\n")
    }
    else {
        z <- paste0(n, "\n\t", paste(x, collapse = " "))
    }
    z <- paste0(z, "\n")
    z
}

#' event.read
#' 
#' data frame with events sorted and numbered
#' @param x = a file of dates in dd/mm/yyyy format
#' @keywords event.read
#' @export

event.read <- function (x) 
{
    z <- readLines(x)
    z <- yyyymmdd.ex.txt(z, "/", "DMY")
    z <- z[order(z)]
    x <- seq_along(z)
    z <- data.frame(z, x, row.names = x, stringsAsFactors = F)
    colnames(z) <- c("Date", "EventNo")
    z
}

#' excise.zeroes
#' 
#' Coverts zeroes to NA
#' @param x = a numeric vector/matrix/data frame
#' @keywords excise.zeroes
#' @export

excise.zeroes <- function (x) 
{
    fcn <- function(z) ifelse(!is.na(z) & abs(z) < 1e-06, NA, 
        z)
    z <- fcn.mat.vec(fcn, x, , T)
    z
}

#' extract.AnnMn.sf
#' 
#' Subsets to "AnnMn" and re-labels columns
#' @param x = array (3D items/bins/parameters)
#' @param y = an item (AnnMn/AnnSd/Sharp/HitRate)
#' @keywords extract.AnnMn.sf
#' @export
#' @family extract

extract.AnnMn.sf <- function (x, y) 
{
    mat.last.to.first(mat.ex.matrix(t(x[y, dimnames(x)[[2]] != 
        "uRet", ])))
}

#' extract.AnnMn.sf.wrapper
#' 
#' Subsets to "AnnMn" and re-labels columns
#' @param x = a list (each element a 3D array, items/bins/parameters)
#' @param y = an item (AnnMn/AnnSd/Sharp/HitRate)
#' @keywords extract.AnnMn.sf.wrapper
#' @export
#' @family extract

extract.AnnMn.sf.wrapper <- function (x, y = "AnnMn") 
{
    fcn <- function(z) extract.AnnMn.sf(z, y)
    if (dim(x[[1]])[3] == 1) 
        z <- t(sapply(x, fcn))
    else z <- mat.ex.matrix(lapply(x, fcn))
    z
}

#' farben
#' 
#' vector of R colours
#' @param x = number of colours needed
#' @param y = a boolean (fill/border)
#' @keywords farben
#' @export

farben <- function (x, y) 
{
    h <- mat.read(parameters("classif-colours"))
    if (!y) {
        v <- rownames(h)
        h <- map.rname(h, h$border)
        rownames(h) <- v
    }
    h <- h[, c("R", "G", "B")]
    h <- mat.ex.matrix(t(h))
    if (x > dim(h)[2]) {
        stop("farben: Can't handle this!")
    }
    else {
        z <- colnames(h)[1:x]
    }
    if (length(z) == 1) 
        z <- list(One = h[, z])
    else z <- h[, z]
    z <- lapply(z, function(z) paste(txt.right(paste0("0", as.hexmode(z)), 
        2), collapse = ""))
    z <- paste0("#", toupper(as.character(unlist(z))))
    z
}

#' fcn.all.canonical
#' 
#' Checks all functions are in standard form
#' @keywords fcn.all.canonical
#' @export
#' @family fcn

fcn.all.canonical <- function () 
{
    x <- fcn.list()
    w <- sapply(vec.to.list(x), fcn.canonical)
    if (all(w)) 
        cat("All functions are canonical ..\n")
    if (any(!w)) 
        err.raise(x[!w], F, "The following functions are non-canonical")
    invisible()
}

#' fcn.all.roxygenize
#' 
#' roxygenizes all functions
#' @param x = the output file
#' @keywords fcn.all.roxygenize
#' @export
#' @family fcn

fcn.all.roxygenize <- function (x) 
{
    n <- fcn.list()
    n <- txt.parse(n, ".")
    n <- n[n[, 2] != "", 1]
    n <- vec.count(n)
    n <- names(n)[n > 1]
    y <- vec.named("mat.read", "utils")
    y["stats"] <- "ret.outliers"
    y["RODBC"] <- "sql.query.underlying"
    y["RDCOMClient"] <- "email"
    y["RCurl"] <- "ftp.dir"
    z <- NULL
    for (w in names(y)) z <- c(z, "", fcn.roxygenize(y[w], w, 
        n))
    y <- setdiff(fcn.list(), y)
    for (w in y) z <- c(z, "", fcn.roxygenize(w, , n))
    writeLines(z, x)
    invisible()
}

#' fcn.all.sub
#' 
#' strings of names of all sub-functions
#' @param x = a string vector (function names)
#' @keywords fcn.all.sub
#' @export
#' @family fcn

fcn.all.sub <- function (x) 
{
    fcn.all.super(x, T, F)
}

#' fcn.all.super
#' 
#' all functions depending on <x>
#' @param x = a string vector (function names)
#' @param y = a boolean (all/direct)
#' @param n = a boolean (super/sub)
#' @keywords fcn.all.super
#' @export
#' @family fcn

fcn.all.super <- function (x, y = T, n = T) 
{
    z <- fcn.direct.map()
    if (y) 
        z <- txt.subclass.bulk(z)
    if (n) 
        n <- c("sub", "fcn")
    else n <- c("fcn", "sub")
    z <- unique(z[is.element(z[, n[1]], x), n[2]])
    z
}

#' fcn.args.actual
#' 
#' list of actual arguments
#' @param x = a string (function name)
#' @keywords fcn.args.actual
#' @export
#' @family fcn

fcn.args.actual <- function (x) 
{
    names(formals(x))
}

#' fcn.args.comment
#' 
#' named vector of commented arguments
#' @param x = a string (function name)
#' @keywords fcn.args.comment
#' @export
#' @family fcn

fcn.args.comment <- function (x) 
{
    z <- fcn.comments.parse(fcn.to.comments(x))[["detl.args"]]
    z <- vec.named(gsub("^[^(]+ =", "", z), substring(z, 1, txt.first(z, 
        " =") - 1))
    z
}

#' fcn.canonical
#' 
#' T/F depending on whether <x> is in standard form
#' @param x = a string (function name)
#' @keywords fcn.canonical
#' @export
#' @family fcn

fcn.canonical <- function (x) 
{
    y <- fcn.to.comments(x)
    z <- fcn.comments.parse(y)
    if (z$canonical) 
        if (z$name != x) {
            cat(x, "has a problem with NAME!\n")
            z$canonical <- F
        }
    if (z$canonical) 
        if (!ascending(fcn.dates.parse(z$date))) {
            cat(x, "has a problem with DATE!\n")
            z$canonical <- F
        }
    if (z$canonical) {
        actual.args <- fcn.args.actual(x)
        if (length(z$args) != length(actual.args)) {
            cat(x, "has a problem with NUMBER of COMMENTED ARGUMENTS!\n")
            z$canonical <- F
        }
    }
    if (z$canonical) 
        if (any(z$args != actual.args)) {
            cat(x, "has a problem with COMMENTED ARGUMENTS NOT MATCHING ACTUAL!\n")
            z$canonical <- F
        }
    canon <- c("fcn", args.canonical())
    if (z$canonical) 
        if (length(z$args) < length(canon)) {
            n <- length(z$args)
            z$canonical <- all(z$args == canon[1:n]) | all(z$args == 
                canon[1:n + 1])
            if (!z$canonical & n == 1) 
                z$canonical <- z$args == "..."
            if (!z$canonical) 
                cat(x, "has NON-CANONICAL ARGUMENTS!\n")
        }
    if (z$canonical) {
        n <- setdiff(args.missing(x), z$args[z$missing])
        z$canonical <- length(n) == 0
        if (!z$canonical) 
            cat(x, "has ARGUMENTS THAT CAN BE MISSING THAT ARE NOT DECLARED AS SUCH!\n")
    }
    if (z$canonical) 
        z <- fcn.indent.proper(x)
    else z <- F
    z
}

#' fcn.comments.parse
#' 
#' extracts information from the comments
#' @param x = a string vector (comments section of a function)
#' @keywords fcn.comments.parse
#' @export
#' @family fcn

fcn.comments.parse <- function (x) 
{
    z <- list(canonical = !is.null(x))
    if (z$canonical) {
        if (!grepl("^# Name\t\t: ", x[1])) {
            cat("Problem with NAME!\n")
            z$canonical <- F
        }
        else {
            z$name <- gsub("^.{10}", "", x[1])
            x <- x[-1]
        }
    }
    if (z$canonical) {
        if (!grepl("^# Author\t: ", x[1])) {
            cat("Problem with AUTHOR!\n")
            z$canonical <- F
        }
        else {
            z$author <- gsub("^.{11}", "", x[1])
            x <- x[-1]
        }
    }
    if (z$canonical) {
        if (!grepl("^# Date\t\t: ", x[1])) {
            cat("Problem with DATE!\n")
            z$canonical <- F
        }
        else {
            z$date <- gsub("^.{10}", "", x[1])
            x <- x[-1]
            while (length(x) > 0 & grepl("^#\t\t: ", x[1])) {
                z$date <- paste0(z$date, gsub("^.{5}", "", x[1]))
                x <- x[-1]
            }
        }
    }
    if (z$canonical) {
        if (!grepl("^# Args\t\t: ", x[1])) {
            cat("Problem with ARGS!\n")
            z$canonical <- F
        }
        else {
            z$detl.args <- x[1]
            x <- x[-1]
            while (length(x) > 0 & grepl("^(#\t\t:\t|#\t\t: )", 
                x[1])) {
                z$detl.args <- c(z$detl.args, x[1])
                x <- x[-1]
            }
            z$detl.args <- fcn.extract.args(z$detl.args)
            if (length(z$detl.args) == 1 & z$detl.args[1] != 
                "none") {
                z$args <- txt.parse(z$detl.args, " =")[1]
            }
            else if (length(z$detl.args) > 1) 
                z$args <- txt.parse(z$detl.args, " =")[, 1]
        }
    }
    z$missing <- grepl("[ (]can be missing)", z$detl.args)
    if (z$canonical) {
        if (!grepl("^# Output\t: ", x[1])) {
            cat("Problem with OUTPUT!\n")
            z$canonical <- F
        }
        else {
            z$out <- x[1]
            x <- x[-1]
            while (length(x) > 0 & grepl("^(#\t\t:\t|#\t\t: )", 
                x[1])) {
                z$out <- c(z$out, x[1])
                x <- x[-1]
            }
            z$out <- fcn.extract.out(z$out)
        }
    }
    if (z$canonical & length(x) > 0) {
        if (grepl("^# Notes\t\t: ", x[1])) {
            x <- x[-1]
            while (length(x) > 0 & grepl("^(#\t\t:\t|#\t\t: )", 
                x[1])) x <- x[-1]
        }
    }
    if (z$canonical & length(x) > 0) {
        if (grepl("^# Example\t: ", x[1])) {
            z$example <- gsub("^.{12}", "", x[1])
            x <- x[-1]
        }
    }
    if (z$canonical & length(x) > 0) {
        if (grepl("^# Import\t: ", x[1])) {
            z$import <- gsub("^.{11}", "", x[1])
            x <- x[-1]
        }
    }
    if (z$canonical & length(x) > 0) {
        cat("Other bizarre problem!\n")
        z$canonical <- F
    }
    z
}

#' fcn.date
#' 
#' date of last modification
#' @param x = a string (function name)
#' @keywords fcn.date
#' @export
#' @family fcn

fcn.date <- function (x) 
{
    max(fcn.dates.parse(fcn.comments.parse(fcn.to.comments(x))$date))
}

#' fcn.dates.parse
#' 
#' dates a function was modified
#' @param x = a string (date element from fcn.comments.parse)
#' @keywords fcn.dates.parse
#' @export
#' @family fcn

fcn.dates.parse <- function (x) 
{
    z <- txt.parse(x, ",")
    if (length(z) == 1) 
        z <- yyyymmdd.ex.txt(z)
    if (length(z) > 1) {
        z <- txt.parse(z, "/")[, 1:3]
        z[, 3] <- fix.gaps(char.to.num(z[, 3]))
        z[, 3] <- yyyy.ex.yy(z[, 3])
        z <- apply(z, 2, char.to.num)
        z <- as.character((z %*% 100^c(1, 0, 2))[, 1])
    }
    z
}

#' fcn.dir
#' 
#' folder of function source file
#' @keywords fcn.dir
#' @export
#' @family fcn

fcn.dir <- function () 
{
    z <- "C:\\temp\\Automation"
    if (Sys.info()[["nodename"]] == "OpsServerDev") 
        z <- "C:\\Users\\vik\\Documents"
    z <- paste0(z, "\\root.txt")
    if (file.exists(z)) 
        z <- readLines(z)
    else z <- "<EXTERNAL>"
    z
}

#' fcn.direct.map
#' 
#' map from sub to calling functions
#' @keywords fcn.direct.map
#' @export
#' @family fcn

fcn.direct.map <- function () 
{
    z <- vec.to.list(fcn.list(), T)
    z <- lapply(z, fcn.direct.sub)
    z <- mat.ex.list(z, c("sub", "fcn"))
    z
}

#' fcn.direct.sub
#' 
#' all direct sub-functions
#' @param x = a string (function name)
#' @keywords fcn.direct.sub
#' @export
#' @family fcn

fcn.direct.sub <- function (x) 
{
    x <- parse(text = deparse(get(x)))
    z <- setdiff(all.vars(x), fcn.list())
    z <- setdiff(all.vars(x, functions = T), z)
    z
}

#' fcn.direct.super
#' 
#' all functions directly depending on <x>
#' @param x = a string vector (function names)
#' @keywords fcn.direct.super
#' @export
#' @family fcn

fcn.direct.super <- function (x) 
{
    fcn.all.super(x, F)
}

#' fcn.expressions.count
#' 
#' number of expressions
#' @param x = a string (function name)
#' @keywords fcn.expressions.count
#' @export
#' @family fcn

fcn.expressions.count <- function (x) 
{
    length(body(get(x))) - 1
}

#' fcn.expressions.to.txt
#' 
#' constituent expressions expressed as a string vector
#' @param x = a string (function name)
#' @keywords fcn.expressions.to.txt
#' @export
#' @family fcn

fcn.expressions.to.txt <- function (x) 
{
    x <- body(get(x))
    z <- NULL
    for (j in seq_along(x)) {
        u <- deparse(x[j], width.cutoff = 500)
        u <- paste(u, collapse = " ")
        z <- c(z, txt.itrim(u))
    }
    u <- "^(.*)(\\(\\))$"
    z <- z[grepl(u, z)]
    z <- gsub(u, "\\1", z)
    z <- gsub("^(\\()(.*)(\\))$", "\\2", z)
    z
}

#' fcn.extract.args
#' 
#' vector of arguments with explanations
#' @param x = a string vector (argument section of comments)
#' @keywords fcn.extract.args
#' @export
#' @family fcn

fcn.extract.args <- function (x) 
{
    n <- length(x)
    x <- gsub("^(# Args\t\t: |#\t\t: )", "", x)
    if (n > 1) {
        w <- grepl("=", x)
        while (any(w[-n] & !w[-1])) {
            i <- 2:n - 1
            i <- i[w[-n] & !w[-1]][1]
            j <- i:n + 1
            j <- j[c(w, T)[j]][1] - 1
            x[i] <- paste(txt.trim(x[i:j], "\t"), collapse = " ")
            while (j > i) {
                x <- x[-j]
                w <- w[-j]
                j <- j - 1
                n <- n - 1
            }
        }
    }
    z <- x
    z
}

#' fcn.extract.out
#' 
#' extracts output
#' @param x = a string vector (output section of comments)
#' @keywords fcn.extract.out
#' @export
#' @family fcn

fcn.extract.out <- function (x) 
{
    paste(gsub("^(# Output\t: |#\t\t: )", "", x), collapse = " ")
}

#' fcn.has
#' 
#' Checks all functions are in standard form
#' @param x = a string (regular expression)
#' @keywords fcn.has
#' @export
#' @family fcn

fcn.has <- function (x) 
{
    fcn <- function(z) grepl(x, fcn.to.txt(z, F))
    z <- fcn.list()
    z <- z[sapply(vec.to.list(z), fcn)]
    z
}

#' fcn.indent.proper
#' 
#' T/F depending on whether the function is indented properly
#' @param x = a string (function name)
#' @keywords fcn.indent.proper
#' @export
#' @family fcn

fcn.indent.proper <- function (x) 
{
    n <- c(LETTERS, 1:9)
    y <- toupper(fcn.lines.code(x, T))
    z <- txt.trim.left(y, "\t")
    w <- nchar(y) - nchar(z)
    r <- grepl(" <- FUNCTION\\(", z)
    for (j in c("^FOR \\(", "^WHILE \\(", "^IF \\(")) r <- r | 
        grepl(j, z)
    r <- ifelse(r & grepl("\\{$", z), 1, NA)
    r <- ifelse(grepl("^#", z), 0, r)
    r <- ifelse(grepl("^}", z), -1, r)
    r <- ifelse(grepl("^} ELSE .*\\{$", z), 0, r)
    n <- nchar(y) > w & is.element(substring(y, w + 1, w + 1), 
        n)
    n <- !is.na(r) | n
    r <- 1 + cumsum(zav(r)) - zav(r) - as.numeric(grepl("^}", 
        z)) - w
    z <- (grepl("^#", z) & r == 1) | r == 0
    z <- all(z & n)
    z
}

#' fcn.lines.code
#' 
#' lines of actual code
#' @param x = a string (function name)
#' @param y = a boolean (count/ignore comments)
#' @keywords fcn.lines.code
#' @export
#' @family fcn

fcn.lines.code <- function (x, y) 
{
    z <- length(fcn.to.comments(x))
    x <- fcn.to.txt(x, T)
    x <- txt.parse(x, "\n")
    z <- x[seq(z + 4, length(x) - 1)]
    if (!y) 
        z <- z[!grepl("^#", txt.trim.left(z, "\t"))]
    z
}

#' fcn.lines.count
#' 
#' number of lines of code
#' @param x = a string (function name)
#' @param y = a boolean (count/ignore comments)
#' @keywords fcn.lines.count
#' @export
#' @family fcn

fcn.lines.count <- function (x, y = T) 
{
    length(fcn.lines.code(x, y))
}

#' fcn.list
#' 
#' Returns the names of objects that are or are not functions
#' @param x = a string (regular expression)
#' @keywords fcn.list
#' @export
#' @family fcn

fcn.list <- function (x = "*") 
{
    w <- globalenv()
    while (!is.element("fcn.list", ls(envir = w))) w <- parent.env(w)
    z <- ls(envir = w, all.names = T, pattern = x)
    w <- is.element(z, as.character(lsf.str(envir = w, all.names = T)))
    z <- z[w]
    z
}

#' fcn.lite
#' 
#' functions in alphabetical order ex RODBC/RDCOMClient
#' @keywords fcn.lite
#' @export
#' @family fcn

fcn.lite <- function () 
{
    x <- c("COMCreate", "odbcDriverConnect")
    x <- setdiff(fcn.list(), fcn.all.super(x))
    x <- vec.to.list(x, T)
    fcn <- function(z) paste(z, "<-", fcn.to.txt(z, T, F))
    x <- sapply(x, fcn)
    y <- paste0(gsub("..$", "", fcn.path()), "-lite.r")
    writeLines(x, y)
    invisible()
}

#' fcn.mat.col
#' 
#' applies <fcn> to the columns of <x> pairwise
#' @param fcn = a function (maps two vectors to a single value)
#' @param x = a numeric vector/matrix/data frame
#' @param y = a numeric vector (can be missing)
#' @param n = a boolean (do/don't rank)
#' @keywords fcn.mat.col
#' @export
#' @family fcn

fcn.mat.col <- function (fcn, x, y, n) 
{
    if (missing(y)) {
        z <- matrix(NA, dim(x)[2], dim(x)[2], F, list(colnames(x), 
            colnames(x)))
        for (i in 1:dim(x)[2]) for (j in 1:dim(x)[2]) z[i, j] <- fcn.num.nonNA(fcn, 
            x[, i], x[, j], n)
    }
    else if (is.null(dim(x))) {
        z <- fcn.num.nonNA(fcn, x, y, n)
    }
    else {
        z <- rep(NA, dim(x)[2])
        for (i in 1:dim(x)[2]) z[i] <- fcn.num.nonNA(fcn, x[, 
            i], y, n)
    }
    z
}

#' fcn.mat.num
#' 
#' applies <fcn> to <x> if a numeric vector or the columns/rows of <x> otherwise
#' @param fcn = a function (vector to value)
#' @param x = a numeric vector/matrix/data frame
#' @param y = a numeric vector/matrix/data frame (can be missing)
#' @param n = a boolean (apply to columns/rows)
#' @keywords fcn.mat.num
#' @export
#' @family fcn

fcn.mat.num <- function (fcn, x, y, n) 
{
    if (is.null(dim(x)) & missing(y)) {
        z <- fcn(x)
    }
    else if (is.null(dim(x)) & !missing(y)) {
        z <- fcn(x, y)
    }
    else if (missing(y)) {
        z <- apply(x, char.to.num(n) + 1, fcn)
    }
    else if (is.null(dim(y))) {
        z <- apply(x, char.to.num(n) + 1, fcn, y)
    }
    else {
        w <- dim(x)[2 - char.to.num(n)]
        fcn.loc <- function(z) fcn(z[1:w], z[1:w + w])
        if (n) 
            x <- rbind(x, y)
        else x <- cbind(x, y)
        z <- apply(x, char.to.num(n) + 1, fcn.loc)
    }
    z
}

#' fcn.mat.vec
#' 
#' applies <fcn> to <x> if a numeric vector or the columns/rows of <x> otherwise
#' @param fcn = a function (vector to vector)
#' @param x = a numeric vector/matrix/data frame
#' @param y = a string vector/matrix/data frame
#' @param n = a boolean (apply to columns/rows)
#' @keywords fcn.mat.vec
#' @export
#' @family fcn

fcn.mat.vec <- function (fcn, x, y, n) 
{
    if (is.null(dim(x)) & missing(y)) {
        z <- fcn(x)
    }
    else if (is.null(dim(x)) & !missing(y)) {
        z <- fcn(x, y)
    }
    else if (n & missing(y)) {
        z <- sapply(mat.ex.matrix(x), fcn)
    }
    else if (!n & missing(y)) {
        z <- t(sapply(mat.ex.matrix(t(x)), fcn))
    }
    else if (n & is.null(dim(y))) {
        z <- sapply(mat.ex.matrix(x), fcn, y)
    }
    else if (!n & is.null(dim(y))) {
        z <- t(sapply(mat.ex.matrix(t(x)), fcn, y))
    }
    else if (n) {
        w <- dim(x)[1]
        fcn.loc <- function(z) fcn(z[1:w], z[1:w + w])
        y <- rbind(x, y)
        z <- sapply(mat.ex.matrix(y), fcn.loc)
    }
    else {
        w <- dim(x)[2]
        fcn.loc <- function(z) fcn(z[1:w], z[1:w + w])
        y <- cbind(x, y)
        z <- t(sapply(mat.ex.matrix(t(y)), fcn.loc))
    }
    if (!is.null(dim(x))) 
        dimnames(z) <- dimnames(x)
    z
}

#' fcn.nonNA
#' 
#' applies <fcn> to the non-NA values of <x>
#' @param fcn = a function (vector to vector)
#' @param x = a numeric vector
#' @keywords fcn.nonNA
#' @export
#' @family fcn

fcn.nonNA <- function (fcn, x) 
{
    w <- !is.na(x)
    z <- rep(NA, length(x))
    if (any(w)) 
        z[w] <- fcn(x[w])
    z
}

#' fcn.num.nonNA
#' 
#' applies <fcn> to the non-NA values of <x> and <y>
#' @param fcn = a function (vector to value)
#' @param x = a numeric vector
#' @param y = a numeric vector (can be missing)
#' @param n = a boolean (do/don't rank)
#' @keywords fcn.num.nonNA
#' @export
#' @family fcn

fcn.num.nonNA <- function (fcn, x, y, n) 
{
    if (missing(y)) 
        w <- !is.na(x)
    else w <- !is.na(x) & !is.na(y)
    if (all(!w)) {
        z <- NA
    }
    else if (missing(y) & !n) {
        z <- fcn(x[w])
    }
    else if (missing(y) & n) {
        z <- fcn(rank(x[w]))
    }
    else if (!n) {
        z <- fcn(x[w], y[w])
    }
    else if (n) {
        z <- fcn(rank(x[w]), rank(y[w]))
    }
    z
}

#' fcn.order
#' 
#' functions in alphabetical order
#' @keywords fcn.order
#' @export
#' @family fcn

fcn.order <- function () 
{
    x <- vec.to.list(fcn.list(), T)
    fcn <- function(z) paste(z, "<-", fcn.to.txt(z, T, F))
    x <- sapply(x, fcn)
    writeLines(x, fcn.path())
    invisible()
}

#' fcn.pair.comment
#' 
#' comment consitency check
#' @param x = a string (function name, higher)
#' @param y = a string (function name, lower)
#' @param n = a data frame (function name/arg/comment)
#' @param w = a data frame (sub classes)
#' @keywords fcn.pair.comment
#' @export
#' @family fcn

fcn.pair.comment <- function (x, y, n, w) 
{
    v <- fcn.expressions.to.txt(x)
    u <- grepl(paste0(y, "\\("), v)
    if (any(u)) 
        for (r in which(u)) if (txt.left(v[r], 4) != "if (") {
            z <- txt.bracket(v[r], y)
            z <- txt.trim(txt.parse.delimit(z))
            h <- is.element(z, n[n[, 1] == x, "arg"])
            if (any(h)) 
                for (foo in which(h)) {
                  h[foo] <- !any(grepl(paste0("([ \t]|^)", z[foo], 
                    " <- "), v[2:r - 1]))
                  h[foo] <- h[foo] & !grepl(paste0("([ \t]|^)", 
                    z[foo], " <- .*", y, "\\("), v[r])
                }
            if (any(h)) {
                hi <- mat.index(n[n[, 1] == x, 2:3])
                lo <- n[n[, 1] == y, 3][seq_along(z)]
                foo <- rep(NA, sum(h))
                for (m in seq_along(foo)) foo[m] <- txt.subclass(hi[z[h]][m], 
                  lo[h][m], w)
                h[h] <- foo
            }
            if (any(h)) 
                for (l in 1:sum(h)) {
                  cat("\n", x, " --> ", y, ":\n")
                  cat("\t", hi[z[h]][l], "\n")
                  cat("\t", lo[h][l], "\n")
                }
        }
    invisible()
}

#' fcn.pair.comment.wrapper
#' 
#' comment consitency check
#' @keywords fcn.pair.comment.wrapper
#' @export
#' @family fcn

fcn.pair.comment.wrapper <- function () 
{
    x <- args.comment()
    x[, "comment"] <- gsub("^([^(]*)( \\(.*)", "\\1", x[, "comment"])
    y <- txt.subclass.wrapper()
    w <- nchar(x[, "arg"]) > 1 & x[, "arg"] != "fcn"
    x <- x[!is.element(x[, "fcn"], x[w, "fcn"]), ]
    z <- fcn.direct.map()[, c("fcn", "sub")]
    z <- z[z[, "sub"] != z[, "fcn"], ]
    w <- lapply(z, function(z) is.element(z, x[, "fcn"]))
    z <- z[Reduce("&", w), ]
    for (j in 1:dim(z)[1]) {
        fcn.pair.comment(z[j, "fcn"], z[j, "sub"], x, y)
    }
    invisible()
}

#' fcn.path
#' 
#' path to function source file
#' @keywords fcn.path
#' @export
#' @family fcn

fcn.path <- function () 
{
    parameters.ex.file(fcn.dir(), "functionsVKS.r")
}

#' fcn.roxygenize
#' 
#' roxygenized function format
#' @param x = a string (function name)
#' @param y = a string (library to import)
#' @param n = vector of function families
#' @keywords fcn.roxygenize
#' @export
#' @family fcn

fcn.roxygenize <- function (x, y, n) 
{
    w <- fcn.to.comments(x)
    w <- txt.replace(w, "\\", "\\\\")
    w <- txt.replace(w, "%", "\\%")
    w <- txt.replace(w, "@", "@@")
    w <- fcn.comments.parse(w)
    z <- c(w$name, "", w$out)
    if (any(names(w) == "args")) 
        z <- c(z, paste("@param", w$detl.args))
    z <- c(z, paste("@keywords", w$name), "@export")
    if (!missing(n)) {
        if (any(x == n) | any(txt.left(x, nchar(n) + 1) == paste0(n, 
            "."))) {
            z <- c(z, paste("@family", txt.parse(x, ".")[1]))
        }
    }
    if (!missing(y)) {
        z <- c(z, paste("@import", y))
    }
    else if (any(names(w) == "import")) 
        z <- c(z, w$import)
    if (any(names(w) == "example")) 
        z <- c(z, "@examples", w$example)
    z <- c(paste("#'", z), "")
    x <- fcn.to.txt(x, F, T)
    x[1] <- paste(w$name, "<-", x[1])
    z <- c(z, x)
    z
}

#' fcn.sho
#' 
#' cats <x> to the screen
#' @param x = a string (function name)
#' @keywords fcn.sho
#' @export
#' @family fcn

fcn.sho <- function (x) 
{
    x <- fcn.to.txt(x, T)
    cat(x, "\n")
    invisible()
}

#' fcn.simple
#' 
#' T/F depending on whether <x> has multi-line expressions
#' @param x = a string (function name)
#' @keywords fcn.simple
#' @export
#' @family fcn

fcn.simple <- function (x) 
{
    fcn.lines.count(x, F) == fcn.expressions.count(x)
}

#' fcn.to.comments
#' 
#' returns the comment section
#' @param x = a string (function name)
#' @keywords fcn.to.comments
#' @export
#' @family fcn

fcn.to.comments <- function (x) 
{
    y <- fcn.to.txt(x, T, T)
    z <- all(!is.element(txt.right(y, 1), c(" ", "\t")))
    if (!z) 
        cat(x, "has lines with trailing whitespace!\n")
    if (z & !grepl("^function\\(", y[1])) {
        cat(x, "has a first line with non-canonical leading characters!\n")
        z <- F
    }
    if (z & any(!is.element(txt.left(y[-1], 1), c("#", "\t", 
        "}")))) {
        cat(x, "has lines with non-canonical leading characters!\n")
        z <- F
    }
    comment.delimiter <- paste("#", txt.space(65, "-"))
    w <- y == comment.delimiter
    if (z & sum(w) != 2) {
        cat(x, "does not have precisely two comment delimiters!\n")
        z <- F
    }
    w <- seq(1, length(y))[w]
    if (z & w[1] != 2) {
        cat(x, "does not have a proper beginning comment delimiter!\n")
        z <- F
    }
    if (z & w[2] - w[1] < 5) {
        cat(x, "has an ending too close to the beginning comment delimiter!\n")
        z <- F
    }
    if (z & length(y) - w[2] > 2) {
        z <- is.element(y[length(y) - 1], c("\tz", "\tinvisible()"))
        if (!z) 
            cat(x, "returns a non-canonical variable!\n")
    }
    if (z) 
        z <- y[seq(w[1] + 1, w[2] - 1)]
    else z <- NULL
    z
}

#' fcn.to.txt
#' 
#' represents <x> as a string or string vector
#' @param x = a string (function name)
#' @param y = a boolean (do/don't return comments)
#' @param n = a boolean (return string/vector)
#' @keywords fcn.to.txt
#' @export
#' @family fcn

fcn.to.txt <- function (x, y = F, n = F) 
{
    x <- get(x)
    if (y) 
        z <- deparse(x, control = "useSource")
    else z <- deparse(x)
    if (!n) 
        z <- paste(z, collapse = "\n")
    z
}

#' fcn.vec.grp
#' 
#' applies <fcn> to <x> within groups <y>
#' @param fcn = a function (to be apply within groups)
#' @param x = a numeric vector/matrix/data frame
#' @param y = a numeric vector (groups)
#' @keywords fcn.vec.grp
#' @export
#' @family fcn

fcn.vec.grp <- function (fcn, x, y) 
{
    x <- split(x, y)
    z <- lapply(x, fcn)
    z <- unsplit(z, y)
    z
}

#' fcn.vec.num
#' 
#' applies <fcn> to <x>
#' @param fcn = a function (vector to vector)
#' @param x = a string vector
#' @param y = a string vector
#' @keywords fcn.vec.num
#' @export
#' @family fcn

fcn.vec.num <- function (fcn, x, y) 
{
    n <- length(x)
    if (n == 1 & missing(y)) {
        z <- fcn(x)
    }
    else if (n == 1 & !missing(y)) {
        z <- fcn(x, y)
    }
    else if (n > 1 & missing(y)) {
        z <- rep(NA, n)
        for (i in 1:n) z[i] <- fcn(x[i])
    }
    else if (n > 1 & length(y) == 1) {
        z <- rep(NA, n)
        for (i in 1:n) z[i] <- fcn(x[i], y)
    }
    else {
        z <- rep(NA, n)
        for (i in 1:n) z[i] <- fcn(x[i], y[i])
    }
    z
}

#' fetch
#' 
#' fetches <x> for the trailing <n> periods ending at <y>
#' @param x = a variable vector
#' @param y = a YYYYMM/flowdate
#' @param n = an integer (lookback)
#' @param w = R-object folder
#' @param h = classif file
#' @keywords fetch
#' @export

fetch <- function (x, y, n, w, h) 
{
    daily <- nchar(y) == 8
    if (daily) {
        yyyy <- yyyymmdd.to.yyyymm(y)
        mm <- txt.right(y, 2)
    }
    else {
        yyyy <- yyyymm.to.yyyy(y)
        mm <- char.to.num(txt.right(y, 2))
    }
    if (n > 1 & length(x) > 1) {
        stop("Can't handle this!\n")
    }
    else if (n > 1) {
        z <- paste0(w, "\\", x, ".", yyyy, ".r")
        lCol <- paste(x, mm, sep = ".")
        z <- readRDS(z)
        m <- 1:dim(z)[2]
        m <- m[colnames(z) == lCol]
        colnames(z) <- paste(colnames(z), yyyy, sep = ".")
        while (m < n) {
            if (daily) 
                yyyy <- yyyymm.lag(yyyy, 1)
            else yyyy <- yyyy - 1
            df <- paste0(w, "\\", x, ".", yyyy, ".r")
            df <- readRDS(df)
            colnames(df) <- paste(colnames(df), yyyy, sep = ".")
            z <- data.frame(df, z)
            m <- m + dim(df)[2]
        }
        z <- z[, seq(m - n + 1, m)]
    }
    else if (length(x) > 1) {
        z <- matrix(NA, dim(h)[1], length(x), F, list(rownames(h), 
            x))
        z <- mat.ex.matrix(z)
        for (i in colnames(z)) {
            df <- paste0(w, "\\", i, ".", yyyy, ".r")
            lCol <- paste(i, mm, sep = ".")
            if (file.exists(df)) {
                z[, i] <- readRDS(df)[, lCol]
            }
            else {
                cat("Warning:", df, "does not exist. Proceeding regardless ..\n")
            }
        }
    }
    else {
        z <- paste0(w, "\\", x, ".", yyyy, ".r")
        lCol <- paste(x, mm, sep = ".")
        if (file.exists(z)) {
            z <- readRDS(z)[, lCol]
        }
        else {
            cat("Warning:", z, "does not exist. Proceeding regardless ..\n")
            z <- rep(NA, dim(h)[1])
        }
    }
    z
}

#' file.bkp
#' 
#' Copies <x> to <y>
#' @param x = a file vector
#' @param y = a file vector
#' @keywords file.bkp
#' @export
#' @family file

file.bkp <- function (x, y) 
{
    w <- file.exists(x)
    if (any(!w)) 
        err.raise(x[!w], T, "Warning: The following files to be copied do not exist")
    if (any(w)) {
        x <- x[w]
        y <- y[w]
        file.kill(y)
        dir.ensure(y)
        file.copy(x, y)
    }
    invisible()
}

#' file.date
#' 
#' Returns the last modified date in yyyymmdd format
#' @param x = a file vector
#' @keywords file.date
#' @export
#' @family file

file.date <- function (x) 
{
    z <- file.mtime(x)
    z <- day.ex.date(z)
    z
}

#' file.kill
#' 
#' Deletes designated files
#' @param x = a file vector
#' @keywords file.kill
#' @export
#' @family file

file.kill <- function (x) 
{
    unlink(x)
    invisible()
}

#' file.mtime.to.time
#' 
#' Converts to HHMMSS times
#' @param x = time stamp on a file
#' @keywords file.mtime.to.time
#' @export
#' @family file

file.mtime.to.time <- function (x) 
{
    format(x, "%H%M%S")
}

#' file.time
#' 
#' Returns the last modified date in yyyymmdd format
#' @param x = a file vector
#' @keywords file.time
#' @export
#' @family file

file.time <- function (x) 
{
    z <- file.mtime(x)
    z <- file.mtime.to.time(z)
    z
}

#' file.to.last
#' 
#' the last YYYYMMDD or the last day of the YYYYMM for which we have data
#' @param x = a file (predictors)
#' @keywords file.to.last
#' @export
#' @family file

file.to.last <- function (x) 
{
    z <- mat.read(x, ",")
    z <- mat.to.last.Idx(z)
    if (nchar(z) == 6) 
        z <- yyyymm.to.day(z)
    z
}

#' find.data
#' 
#' returns the position of the first/last true value of x
#' @param x = a logical vector
#' @param y = a boolean (position of first/last true value)
#' @keywords find.data
#' @export
#' @family find

find.data <- function (x, y = T) 
{
    z <- seq_along(x)
    if (!y) {
        x <- rev(x)
        z <- rev(z)
    }
    z <- z[x & !duplicated(x)]
    z
}

#' find.gaps
#' 
#' returns the position of the first and last true value of x #		:	together with the first positions of all gaps
#' @param x = a logical vector
#' @keywords find.gaps
#' @export
#' @family find

find.gaps <- function (x) 
{
    w <- cumsum(c(1, diff(x) != 0))
    z <- vec.named(w[!duplicated(w)], seq_along(x)[!duplicated(w)])
    z <- vec.named(map.rname(vec.count(w), z), names(z))
    w <- x[as.numeric(names(z))]
    w[1] <- w[length(w)] <- T
    z <- z[!w]
    z
}

#' fix.gaps
#' 
#' replaces NA's by previous value
#' @param x = a numeric or character vector
#' @keywords fix.gaps
#' @export

fix.gaps <- function (x) 
{
    z <- which(!is.na(x))
    z <- approx(z, z, seq_along(x), method = "constant", rule = 1:2)[["y"]]
    z <- x[z]
    z
}

#' flowdate.diff
#' 
#' returns <x - y> in terms of flowdates
#' @param x = a flowdate vector
#' @param y = a flowdate vector
#' @keywords flowdate.diff
#' @export
#' @family flowdate

flowdate.diff <- function (x, y) 
{
    obj.diff(flowdate.to.int, x, y)
}

#' flowdate.ex.AllocMo
#' 
#' Returns the flowdates corresponding to <x> (inverse of yyyymmdd.to.AllocMo)
#' @param x = a YYYYMM
#' @param y = calendar day allocations are known the next month
#' @keywords flowdate.ex.AllocMo
#' @export
#' @family flowdate

flowdate.ex.AllocMo <- function (x, y = 23) 
{
    x <- yyyymm.lag(x, -1)
    z <- flowdate.ex.yyyymm(x, F)
    z <- z[char.to.num(txt.right(z, 2)) >= y]
    x <- yyyymm.lag(x, -1)
    z <- c(z, flowdate.ex.yyyymm(x, F))
    z <- z[char.to.num(txt.right(z, 2)) < y | yyyymmdd.to.yyyymm(z) < 
        x]
    z
}

#' flowdate.ex.int
#' 
#' the <x>th daily flow-publication date after Thursday, January 1, 1970
#' @param x = an integer vector
#' @keywords flowdate.ex.int
#' @export
#' @family flowdate

flowdate.ex.int <- function (x) 
{
    z <- c(0, x)
    z <- y <- seq(min(z), max(z))
    w <- !flowdate.exists(yyyymmdd.ex.int(z)) & z <= 0
    while (any(w)) {
        h <- z[1] - sum(w):1
        z <- c(h, z[!w])
        w <- c(!flowdate.exists(yyyymmdd.ex.int(h)), rep(F, sum(!w)))
    }
    w <- !flowdate.exists(yyyymmdd.ex.int(z)) & z > 0
    while (any(w)) {
        h <- z[length(z)] + 1:sum(w)
        z <- c(z[!w], h)
        w <- c(rep(F, sum(!w)), !flowdate.exists(yyyymmdd.ex.int(h)))
    }
    z <- yyyymmdd.ex.int(z[x - y[1] + 1])
    z
}

#' flowdate.ex.yyyymm
#' 
#' last/all trading days daily flow-publication dates in <x>
#' @param x = a YYYYMM vector
#' @param y = a boolean (return last/all flowdates)
#' @keywords flowdate.ex.yyyymm
#' @export
#' @family flowdate

flowdate.ex.yyyymm <- function (x, y = T) 
{
    z <- yyyymmdd.ex.yyyymm(x, y)
    if (!y) 
        z <- z[flowdate.exists(z)]
    z
}

#' flowdate.exists
#' 
#' returns T if <x> is a daily flow-publication date
#' @param x = a string vector
#' @keywords flowdate.exists
#' @export
#' @family flowdate

flowdate.exists <- function (x) 
{
    yyyymmdd.exists(x) & !is.element(txt.right(x, 4), c("0101", 
        "1225"))
}

#' flowdate.lag
#' 
#' lags <x> by <y> daily flow-publication dates
#' @param x = a flowdate vector
#' @param y = an integer vector
#' @keywords flowdate.lag
#' @export
#' @family flowdate

flowdate.lag <- function (x, y) 
{
    obj.lag(x, y, flowdate.to.int, flowdate.ex.int)
}

#' flowdate.seq
#' 
#' a sequence of dly flow-pub dates starting at <x> and, if possible, ending at <y>
#' @param x = a flowdate
#' @param y = a flowdate
#' @param n = a positive integer
#' @keywords flowdate.seq
#' @export
#' @family flowdate

flowdate.seq <- function (x, y, n = 1) 
{
    if (any(!flowdate.exists(c(x, y)))) 
        stop("Inputs are not daily flow-publication dates")
    z <- obj.seq(x, y, flowdate.to.int, flowdate.ex.int, n)
    z
}

#' flowdate.to.int
#' 
#' number of daily flow-publication dates after Thursday, January 1, 1970
#' @param x = a flowdate vector
#' @keywords flowdate.to.int
#' @export
#' @family flowdate

flowdate.to.int <- function (x) 
{
    z <- unique(c("1970", yyyymm.to.yyyy(yyyymmdd.to.yyyymm(x))))
    z <- char.to.num(z)[order(z)]
    z <- seq(z[1], z[length(z)])
    z <- txt.expand(z, c("0101", "1225"), "")
    z <- z[yyyymmdd.exists(z)]
    z <- vec.named(seq_along(z), z)
    z <- z - z["19700101"]
    x <- yyyymmdd.to.int(x)
    y <- floor(approx(yyyymmdd.to.int(names(z)), z, x, rule = 1:2)$y)
    z <- x - zav(y, z[1] - 1)
    z
}

#' ftp.all.dir
#' 
#' remote-site directory listing of all sub-folders
#' @param x = a remote folder
#' @param y = ftp site (can be missing)
#' @param n = user id (can be missing)
#' @param w = password (can be missing)
#' @param h = a string (ftp/sftp)
#' @param u = a boolean (ftp.use.epsv argument of getCurlHandle)
#' @keywords ftp.all.dir
#' @export
#' @family ftp

ftp.all.dir <- function (x, y, n, w, h, u) 
{
    z <- as.list(environment())
    z <- z[!sapply(z, is.symbol)]
    z[["v"]] <- F
    z <- do.call(ftp.all.files.underlying, z)
    z <- gsub(paste0("^", x, "."), "", z)
    z
}

#' ftp.all.files
#' 
#' remote-site directory listing of files (incl. sub-folders)
#' @param x = a remote folder
#' @param y = ftp site (can be missing)
#' @param n = user id (can be missing)
#' @param w = password (can be missing)
#' @param h = a string (ftp/sftp)
#' @param u = a boolean (ftp.use.epsv argument of getCurlHandle)
#' @keywords ftp.all.files
#' @export
#' @family ftp

ftp.all.files <- function (x, y, n, w, h, u) 
{
    z <- as.list(environment())
    z <- z[!sapply(z, is.symbol)]
    z[["v"]] <- T
    z <- do.call(ftp.all.files.underlying, z)
    if (x == "/") 
        x <- ""
    z <- gsub(paste0("^", x, "."), "", z)
    z
}

#' ftp.all.files.underlying
#' 
#' remote-site directory listing of files or folders
#' @param x = a remote folder
#' @param y = ftp site (can be missing)
#' @param n = user id (can be missing)
#' @param w = password (can be missing)
#' @param h = a string (ftp/sftp)
#' @param u = a boolean (ftp.use.epsv argument of getCurlHandle)
#' @param v = a boolean (files/folders)
#' @keywords ftp.all.files.underlying
#' @export
#' @family ftp

ftp.all.files.underlying <- function (x, y, n, w, h = "ftp", u, v) 
{
    w <- as.list(environment())
    w <- w[!sapply(w, is.symbol)]
    w <- list.rename(w, c("y", "n", "w", "h", "u"), c("y", "n", 
        "w", "u", "v"))
    w[["h"]] <- F
    z <- NULL
    while (length(x) > 0) {
        cat(x[1], "..\n")
        m <- do.call(ftp.dir, c(list(x = x[1]), w))
        if (!is.null(m)) {
            j <- names(m)
            if (x[1] != "/" & x[1] != "") 
                j <- paste(x[1], j, sep = "/")
            else j <- paste0("/", j)
            if (any(m == v)) 
                z <- c(z, j[m == v])
            if (any(!m)) 
                x <- c(x, j[!m])
        }
        x <- x[-1]
    }
    z
}

#' ftp.credential
#' 
#' relevant ftp credential
#' @param x = a string (ftp/user/pwd)
#' @param y = a string (ftp/sftp)
#' @param n = a boolean (ftp.use.epsv argument of getCurlHandle)
#' @keywords ftp.credential
#' @export
#' @family ftp

ftp.credential <- function (x, y = "ftp", n = F) 
{
    z <- ifelse(n & y == "ftp", "-credential-T", "-credential")
    z <- as.character(map.rname(vec.read(parameters(paste0(y, 
        z))), x))
    z
}

#' ftp.del
#' 
#' deletes file <x> or file <y> on remote folder <x>
#' @param x = a remote folder/file
#' @param y = a SINGLE file (e.g. "foo.txt") or missing if <x> is a file
#' @param n = ftp site (can be missing)
#' @param w = user id (can be missing)
#' @param h = password (can be missing)
#' @param u = a string (ftp/sftp)
#' @keywords ftp.del
#' @export
#' @family ftp

ftp.del <- function (x, y, n, w, h, u = "ftp") 
{
    if (!missing(y)) 
        x <- paste0(x, "/", y)
    w <- ftp.missing(as.list(environment()), "nwhuv")
    z <- paste0(w[["ftp"]], x)
    u <- ifelse(w[["protocol"]] == "ftp", "DELE", "RM")
    tryCatch(curlPerform(url = z, quote = paste(u, x), userpwd = w[["userpwd"]]), 
        error = function(z) {
            NULL
        })
    invisible()
}

#' ftp.dir.parse.ftp
#' 
#' data frame with ftp information
#' @param x = a string vector (raw output of ftp)
#' @keywords ftp.dir.parse.ftp
#' @export
#' @family ftp

ftp.dir.parse.ftp <- function (x) 
{
    z <- data.frame(substring(x, 1, 8), substring(x, 18, 39), 
        substring(x, 40, nchar(x)), stringsAsFactors = F)
    names(z) <- c("yyyymmdd", "size", "file")
    z[, "is.file"] <- !grepl(" <DIR> ", x)
    z[, "size"] <- ifelse(z[, "is.file"], z[, "size"], 0)
    z[, "size"] <- char.to.num(z[, "size"])/2^10
    z[, "yyyymmdd"] <- paste0("20", substring(z[, "yyyymmdd"], 
        7, 8), substring(z[, "yyyymmdd"], 4, 5), substring(z[, 
        "yyyymmdd"], 1, 2))
    z <- z[, c("size", "is.file", "yyyymmdd", "file")]
    z
}

#' ftp.dir.parse.sftp
#' 
#' data frame with ftp information
#' @param x = a string vector (raw output of ftp)
#' @keywords ftp.dir.parse.sftp
#' @export
#' @family ftp

ftp.dir.parse.sftp <- function (x) 
{
    n <- paste0("(", paste(month.abb, collapse = "|"), ")")
    n <- paste0("^((?<! ", n, " ).)* (?=", n, " )")
    z <- gsub(n, "", x, perl = T)
    y <- txt.left(x, nchar(x) - nchar(z))
    z <- data.frame(substring(z, 1, 3), char.to.num(substring(z, 
        5, 6)), substring(z, 7, 12), substring(z, 13, nchar(z)), 
        stringsAsFactors = F)
    names(z) <- c("mm", "dd", "yyyy", "file")
    z[, "is.file"] <- grepl("^-", y)
    if (dim(z)[1] == 1) {
        z[, "size"] <- char.to.num(txt.parse(txt.itrim(y), txt.space(1))[5])/2^10
    }
    else {
        z[, "size"] <- char.to.num(txt.parse(txt.itrim(y), txt.space(1))[, 
            5])/2^10
    }
    z$mm <- match(z$mm, month.abb)
    z$yyyy <- ifelse(grepl(":", z$yyyy), yyyymm.to.yyyy(yyyymmdd.to.yyyymm(today())), 
        z$yyyy)
    z$yyyy <- char.to.num(z$yyyy)
    z[, "yyyymmdd"] <- as.character(10000 * z$yyyy + 100 * z$mm + 
        z$dd)
    z <- z[, c("size", "is.file", "yyyymmdd", "file")]
    z[, "file"] <- txt.trim(z[, "file"])
    z
}

#' ftp.download
#' 
#' replicates <x> in folder <y>
#' @param x = a remote folder
#' @param y = local folder (e.g. "C:\\\\temp\\\\mystuff")
#' @param n = ftp site (can be missing)
#' @param w = user id (can be missing)
#' @param h = password (can be missing)
#' @param u = a string (ftp/sftp)
#' @param v = a boolean (ftp.use.epsv argument of getCurlHandle)
#' @keywords ftp.download
#' @export
#' @family ftp

ftp.download <- function (x, y, n, w, h, u = "ftp", v) 
{
    w <- as.list(environment())
    w <- w[!sapply(w, is.symbol)]
    z <- list.rename(w, c("x", "n", "w", "h", "u", "v"))
    z <- do.call(ftp.all.files, z)
    w <- w[!is.element(names(w), c("x", "y"))]
    y <- paste0(y, "\\", dir.parent(z))
    y <- ifelse(grepl("\\\\$", y), gsub(".$", "", y), y)
    dir.ensure(paste0(unique(y), "\\foo.txt"))
    z <- paste0(x, "/", z)
    for (j in seq_along(z)) {
        cat(gsub(paste0("^", x), "", z[j]), "..\n")
        do.call(ftp.get, c(list(x = z[j], y = y[j]), w))
    }
    invisible()
}

#' ftp.exists
#' 
#' T/F depending on whether upload already happened
#' @param x = a string (report name)
#' @param y = date for which you want to send the report
#' @keywords ftp.exists
#' @export
#' @family ftp

ftp.exists <- function (x, y) 
{
    record.exists(x, y, "upload.txt")
}

#' ftp.file
#' 
#' strips out parent directory, returning just the file name
#' @param x = a file vector
#' @keywords ftp.file
#' @export
#' @family ftp

ftp.file <- function (x) 
{
    txt.right(x, nchar(x) - nchar(ftp.parent(x)) - 1)
}

#' ftp.get
#' 
#' file <x> from remote site
#' @param x = a remote file
#' @param y = local folder (e.g. "C:\\\\temp")
#' @param n = ftp site (can be missing)
#' @param w = user id (can be missing)
#' @param h = password (can be missing)
#' @param u = a string (ftp/sftp)
#' @param v = a boolean (ftp.use.epsv argument of getCurlHandle)
#' @keywords ftp.get
#' @export
#' @family ftp

ftp.get <- function (x, y, n, w, h, u = "ftp", v) 
{
    w <- ftp.missing(as.list(environment()), "nwhuv")
    z <- getCurlHandle(ftp.use.epsv = w[["epsv"]], userpwd = w[["userpwd"]])
    z <- getBinaryURL(paste0(w[["ftp"]], x), curl = z)
    writeBin(z, con = paste0(y, "\\", ftp.file(x)))
    invisible()
}

#' ftp.info
#' 
#' parameter <n> associated with <x> flows at the <y> level with the <w> filter
#' @param x = a frequency (D/W/M)
#' @param y = a boolean (Fund/ShareClass)
#' @param n = one of sql.table/date.field/ftp.path
#' @param w = a filter (e.g. Aggregate/Active/Passive/ETF/Mutual)
#' @keywords ftp.info
#' @export
#' @family ftp

ftp.info <- function (x, y, n, w) 
{
    z <- mat.read(parameters("classif-ftp"), "\t", NULL)
    z <- z[z[, "Type"] == x & z[, "FundLvl"] == y & z[, "filter"] == 
        w, n]
    z
}

#' ftp.kill
#' 
#' deletes entry <x> in the ftp record. Returns nothing.
#' @param x = a string (report name)
#' @keywords ftp.kill
#' @export
#' @family ftp

ftp.kill <- function (x) 
{
    record.kill(x, "upload.txt")
}

#' ftp.list
#' 
#' named vector of emails and sent dates
#' @keywords ftp.list
#' @export
#' @family ftp

ftp.list <- function () 
{
    record.read("upload.txt")
}

#' ftp.missing
#' 
#' supplies missing arguments
#' @param x = a list (arguments from higher function)
#' @param y = a string (argument names)
#' @keywords ftp.missing
#' @export
#' @family ftp

ftp.missing <- function (x, y) 
{
    y <- strsplit(y, "")[[1]]
    x <- x[!sapply(x, is.symbol)]
    x <- list.rename(x, y)
    z <- do.call(ftp.missing.underlying, x)
    z
}

#' ftp.missing.underlying
#' 
#' logical or YYYYMMDD vector indexed by remote file names
#' @param x = ftp site (can be missing)
#' @param y = user id (can be missing)
#' @param n = password (can be missing)
#' @param w = a string (ftp/sftp)
#' @param h = a boolean (ftp.use.epsv argument of getURL, can be missing)
#' @keywords ftp.missing.underlying
#' @export
#' @family ftp
#' @@importFrom RCurl getURL

ftp.missing.underlying <- function (x, y, n, w, h) 
{
    if (missing(h)) 
        h <- w == "ftp"
    if (missing(x)) 
        x <- ftp.credential("ftp", w, h)
    if (missing(y)) 
        y <- ftp.credential("user", w, h)
    if (missing(n)) 
        n <- ftp.credential("pwd", w, h)
    z <- list(ftp = paste0(w, "://", x), userpwd = paste0(y, 
        ":", n), protocol = w, epsv = h)
    z
}

#' ftp.parent
#' 
#' returns paths to the parent directory
#' @param x = a file vector
#' @keywords ftp.parent
#' @export
#' @family ftp

ftp.parent <- function (x) 
{
    z <- dirname(x)
    z <- ifelse(z == ".", "", z)
    z
}

#' ftp.put
#' 
#' puts file <y> to remote site <x>, creating folders as needed
#' @param x = a remote folder
#' @param y = a file vector
#' @param n = ftp site (can be missing)
#' @param w = user id (can be missing)
#' @param h = password (can be missing)
#' @param u = a string (ftp/sftp)
#' @param v = a boolean (ftp.use.epsv argument of getCurlHandle)
#' @keywords ftp.put
#' @export
#' @family ftp

ftp.put <- function (x, y, n, w, h, u = "ftp", v) 
{
    w <- ftp.missing(as.list(environment()), "nwhuv")
    ctr <- 5
    z <- NULL
    while (is.null(z) & ctr > 0) {
        if (ctr < 5) 
            cat("Trying to upload to", x, "again ..\n")
        z <- getCurlHandle(ftp.use.epsv = w[["epsv"]], userpwd = w[["userpwd"]])
        z <- tryCatch(ftpUpload(y, paste0(w[["ftp"]], x, "/", 
            ftp.file(y)), curl = z, ftp.create.missing.dirs = T), 
            error = function(z) {
                NULL
            })
        ctr <- ctr - 1
    }
    z <- !is.null(z)
    z
}

#' ftp.record
#' 
#' updates the email record. Returns nothing.
#' @param x = a string (report name)
#' @param y = date for which you sent the report
#' @keywords ftp.record
#' @export
#' @family ftp

ftp.record <- function (x, y) 
{
    record.write(x, y, "upload.txt")
}

#' ftp.rmdir
#' 
#' removes directory <x> (e.g. "mystuff")
#' @param x = a remote folder
#' @param y = ftp site (can be missing)
#' @param n = user id (can be missing)
#' @param w = password (can be missing)
#' @param h = a string (ftp/sftp)
#' @keywords ftp.rmdir
#' @export
#' @family ftp

ftp.rmdir <- function (x, y, n, w, h = "ftp") 
{
    w <- ftp.missing(as.list(environment()), "ynwhu")
    z <- paste0(w[["ftp"]], x, "/")
    tryCatch(curlPerform(url = z, quote = paste0("RMD ", x, "/"), 
        userpwd = w[["userpwd"]]), error = function(z) {
        NULL
    })
    invisible()
}

#' ftp.sql.factor
#' 
#' SQL code to validate <x> flows at the <y> level
#' @param x = a variable
#' @param y = a flowdate
#' @param n = a filter (e.g. Aggregate/Active/Passive/ETF/Mutual)
#' @param w = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @param h = a breakdown filter (All/GeoId/DomicileId, can be missing)
#' @param u = a boolean (chuck/keep securities held by just one fund)
#' @keywords ftp.sql.factor
#' @export
#' @family ftp

ftp.sql.factor <- function (x, y, n, w, h, u = F) 
{
    if (missing(h)) {
        if (any(grepl("^(StockM|StockD|FwtdEx0|FwtdIn0|SwtdEx0|SwtdIn0|FundCtM|HoldSum|SharesHeld|FundCt)$", 
            x))) {
            h <- "GeoId"
        }
        else {
            h <- "All"
        }
    }
    if (all(grepl("^(Flo)(Trend|Diff|Diff2)$", x))) {
        z <- sql.1mAllocD(y, c(x, qa.filter.map(n)), w, T, F, 
            "Flow", u, "All", F)
    }
    else if (all(grepl("^(Alloc)(Trend|Diff|Mo)$", x))) {
        z <- sql.1mAllocD(yyyymmdd.to.yyyymm(y), c(x, qa.filter.map(n)), 
            w, T, F, "AssetsStart", u, "All", F)
    }
    else if (all(x == "AllocD")) {
        z <- sql.1mAllocD(yyyymmdd.to.yyyymm(y), c("AllocDA", 
            "AllocDInc", "AllocDDec", "AllocDAdd", "AllocDRem", 
            qa.filter.map(n)), w, T, F, NULL, u)
    }
    else if (all(x == "FloMo")) {
        z <- sql.1dFloMo(y, c(x, qa.filter.map(n)), w, T, h, 
            "All", u)
    }
    else if (all(x == "StockD")) {
        z <- sql.1dFloMo(y, c("FloDollar", qa.filter.map(n)), 
            w, T, h, "All", u)
    }
    else if (all(x == "AssetsStartDollarD")) {
        z <- sql.1dFloMo(y, c("AssetsStartDollar", qa.filter.map(n)), 
            w, T, h, "All", u)
    }
    else if (all(x == "IOND")) {
        z <- sql.1dFloMo(y, c("Inflow", "Outflow", qa.filter.map(n)), 
            w, T, h, "All", u)
    }
    else if (all(x == "FundCtD")) {
        z <- sql.1dFundCt(y, c("FundCt", qa.filter.map(n)), w, 
            T, "GeoId", u)
    }
    else if (all(x == "FundCtM")) {
        z <- sql.1mFundCt(yyyymmdd.to.yyyymm(y), c("FundCt", 
            qa.filter.map(n)), w, T, h, 0, "All", u)
    }
    else if (all(grepl("^(FundCt|Herfindahl|HoldSum|SharesHeld)$", 
        x))) {
        z <- sql.1mFundCt(yyyymmdd.to.yyyymm(y), c(x, qa.filter.map(n)), 
            w, T, h, 0, "All", u)
    }
    else if (all(x == "HoldSumTopV")) {
        z <- sql.1mFundCt(yyyymmdd.to.yyyymm(y), c("HoldSum", 
            qa.filter.map(n)), w, T, h, 5, "All", u)
    }
    else if (all(x == "HoldSumTopX")) {
        z <- sql.1mFundCt(yyyymmdd.to.yyyymm(y), c("HoldSum", 
            qa.filter.map(n)), w, T, h, 10, "All", u)
    }
    else if (all(x == "Dispersion")) {
        if (u) 
            stop("Can't handle this!")
        z <- sql.Dispersion(yyyymmdd.to.yyyymm(y), c(x, qa.filter.map(n)), 
            w, T)
    }
    else if (all(x == "HoldAum")) {
        z <- sql.1mHoldAum(yyyymmdd.to.yyyymm(y), c("HoldAum", 
            qa.filter.map(n)), w, T, h, u)
    }
    else if (all(x == "StockM")) {
        z <- sql.1mHoldAum(yyyymmdd.to.yyyymm(y), c("FloDollar", 
            qa.filter.map(n)), w, T, h, u)
    }
    else if (all(x == "FloMoM")) {
        z <- sql.1mHoldAum(yyyymmdd.to.yyyymm(y), c("FloMo", 
            qa.filter.map(n)), w, T, h, u)
    }
    else if (all(x == "IONM")) {
        z <- sql.1mHoldAum(yyyymmdd.to.yyyymm(y), c("Inflow", 
            "Outflow", qa.filter.map(n)), w, T, h, u)
    }
    else if (all(x == "AllocSkew")) {
        z <- sql.1mAllocSkew(yyyymmdd.to.yyyymm(y), c(x, qa.filter.map(n)), 
            w, T, "All", u)
    }
    else if (all(grepl("^(ActWt)(Trend|Diff|Diff2)$", x))) {
        z <- sql.1mAllocSkew(y, c(x, qa.filter.map(n)), w, T, 
            "All", u)
    }
    else if (all(grepl("^[FS]wtd(In|Ex)0$", x))) {
        z <- sql.TopDownAllocs(yyyymmdd.to.yyyymm(y), c(x, qa.filter.map(n)), 
            w, T, h, u)
    }
    else {
        stop("Bad factor")
    }
    z
}

#' ftp.upload
#' 
#' Copies up files from the local machine
#' @param x = empty a remote folder
#' @param y = a folder (e.g. "C:\\\\temp\\\\mystuff")
#' @param n = ftp site (can be missing)
#' @param w = user id (can be missing)
#' @param h = password (can be missing)
#' @param u = a string (ftp/sftp)
#' @param v = a boolean (ftp.use.epsv argument of getCurlHandle)
#' @keywords ftp.upload
#' @export
#' @family ftp

ftp.upload <- function (x, y, n, w, h, u = "ftp", v) 
{
    w <- as.list(environment())
    w <- w[!sapply(w, is.symbol)]
    z <- dir.all.files(y, "\\.")
    s <- ftp.parent(z)
    s <- txt.right(s, nchar(s) - nchar(y))
    s <- paste0(x, s)
    x <- rep(F, length(z))
    for (j in seq_along(z)) {
        cat(ftp.file(z[j]), "")
        w[["x"]] <- s[j]
        w[["y"]] <- z[j]
        x[j] <- do.call(ftp.put, w)
        cat(substring(Sys.time(), 12, 16), "\n")
    }
    if (all(x)) {
        cat("All files successfully uploaded.\n")
    }
    else {
        err.raise(z[!x], T, "Following files were not uploaded")
    }
    invisible()
}

#' fwd.probs
#' 
#' probability that forward return is positive given predictor is positive
#' @param x = a matrix/data frame (predictors)
#' @param y = a matrix/data frame (total return indices)
#' @param n = a positive integer (flow window in days/months)
#' @param w = a boolean (sum/compound)
#' @param h = a non-negative integer (lag in days/months)
#' @param u = a non-negative integer (delay in days/months)
#' @param v = a non-negative integer (0 = Sun, 1 = Mon, etc., the day you trade)
#' @param g = a positive integer (return window in days/months)
#' @param r = a string (index within which you trade)
#' @keywords fwd.probs
#' @export
#' @family fwd

fwd.probs <- function (x, y, n, w, h, u, v, g, r) 
{
    x <- bbk.data(x, y, n, w, h, u, v, g, r, F)
    y <- x$fwdRet
    x <- x$x
    z <- c("All", "Pos", "Exc", "Last")
    z <- matrix(NA, dim(x)[2], length(z), F, list(colnames(x), 
        z))
    z[, "Last"] <- unlist(x[dim(x)[1], ])
    for (j in colnames(x)) {
        w1 <- x[, j]
        w2 <- y[, j]
        z[j, "All"] <- sum(!is.na(w2) & w2 > 0)/sum(!is.na(w2))
        z[j, "Pos"] <- sum(!is.na(w1) & !is.na(w2) & w2 > 0 & 
            w1 > 0)/sum(!is.na(w1) & !is.na(w2) & w1 > 0)
    }
    z[, "Exc"] <- z[, "Pos"] - z[, "All"]
    z
}

#' fwd.probs.wrapper
#' 
#' probability that forward return is positive given predictor is positive
#' @param x = a matrix/data frame (predictors)
#' @param y = a matrix/data frame (total return indices)
#' @param n = a positive integer (flow window in days/months)
#' @param w = a boolean (sum/compound)
#' @param h = a non-negative integer (lag in days/months)
#' @param u = a non-negative integer (delay in days/months)
#' @param v = a non-negative integer (0 = Sun, 1 = Mon, etc., the day you trade)
#' @param g = a positive integer (return window in days/months)
#' @param r = a string (index within which you trade)
#' @keywords fwd.probs.wrapper
#' @export
#' @family fwd

fwd.probs.wrapper <- function (x, y, n, w, h, u, v, g, r) 
{
    fcn2 <- function(l) {
        fcn <- function(z) fwd.probs(x, y, n, w, z, u, v, l, 
            r)
        simplify2array(lapply(vec.to.list(h, T), fcn))
    }
    z <- simplify2array(lapply(vec.to.list(g, T), fcn2))
    z
}

#' glome.ex.R3
#' 
#' maps unit cube to the glome (sphere in 4D)
#' @param x = a number or numeric vector between 0 and 1
#' @param y = a number or numeric vector between 0 and 1
#' @param n = a number or numeric vector between 0 and 1
#' @keywords glome.ex.R3
#' @export

glome.ex.R3 <- function (x, y, n) 
{
    w <- length(x)
    z <- sqrt(1 - x^2) * sin(2 * pi * y)
    z <- c(z, sqrt(1 - x^2) * cos(2 * pi * y))
    z <- c(z, x * sin(2 * pi * n))
    z <- c(z, x * cos(2 * pi * n))
    if (w > 1) 
        z <- matrix(z, w, 4, F, list(1:w, LETTERS[1:4]))
    z
}

#' gram.schmidt
#' 
#' Gram-Schmidt orthogonalization of <x> to <y>
#' @param x = a numeric vector/matrix/data frame
#' @param y = a numeric vector
#' @keywords gram.schmidt
#' @export

gram.schmidt <- function (x, y) 
{
    x - tcrossprod(y, crossprod(x, y)/sum(y^2))
}

#' GSec.to.GSgrp
#' 
#' makes Sector groups
#' @param x = an integer vector (sectors)
#' @keywords GSec.to.GSgrp
#' @export

GSec.to.GSgrp <- function (x) 
{
    z <- rep("", length(x))
    z <- ifelse(is.element(x, c(15, 20, 25, 45)), "Cyc", z)
    z <- ifelse(is.element(x, c(10, 30, 35, 50, 55)), "Def", 
        z)
    z <- ifelse(is.element(x, 40), "Fin", z)
    z
}

#' html.and
#' 
#' <x> stated in a grammatical phrase
#' @param x = a string vector
#' @keywords html.and
#' @export
#' @family html

html.and <- function (x) 
{
    n <- length(x)
    if (n > 1) {
        z <- paste(paste(x[-n], collapse = ", "), x[n], sep = " and ")
    }
    else z <- x
    z
}

#' html.email
#' 
#' writes outgoing email report for <x>
#' @param x = a flowdate (can be missing)
#' @param y = a boolean (regular/Asia process)
#' @keywords html.email
#' @export
#' @family html

html.email <- function (x, y = T) 
{
    if (missing(x)) 
        x <- today()
    u <- ifelse(y, "morning", "evening")
    u <- paste("This", u, "the following emails did not go out:")
    u <- c("The QC process certified", "reports were successfully emailed.", 
        u)
    u <- c(u, "The QC process was unable to check delivery of the following:")
    h <- record.track(x, "emails", y)
    h <- h[h$yyyymmdd != h$target | h$today, ]
    z <- html.problem.underlying(paste0("<b>", rownames(h), "</b>"), 
        u, h$yyyymmdd != h$target)
    u <- ifelse(y, "morning", "evening")
    u <- paste("This", u, "the following ftp uploads did not happen:")
    u <- c("The QC process certified", "successful uploads.", 
        u)
    u <- c(u, "The QC process was unable to check uploads of the following:")
    h <- record.track(x, "upload", y)
    h <- h[h$yyyymmdd != h$target | h$today, ]
    z <- c(z, html.problem.underlying(paste0("<b>", rownames(h), 
        "</b>"), u, h$yyyymmdd != h$target))
    z <- txt.replace(z, " one reports were ", " one report was ")
    z <- txt.replace(z, " one successful uploads.", " one successful upload.")
    z <- paste(c("Dear All,", z, html.signature()), collapse = "\n")
    y <- ifelse(y, "ReportDeliveryList", "ReportDeliveryAsiaList")
    email(recipient.read(y), "Report Delivery", z, , T)
    invisible()
}

#' html.ex.utf8
#' 
#' code to represent <x> in html
#' @param x = a string
#' @keywords html.ex.utf8
#' @export
#' @family html

html.ex.utf8 <- function (x) 
{
    z <- txt.to.char(x)
    w <- !grepl("[[:alnum:]\n\t\\ ><=/%%$:.,;?!]", z)
    for (j in seq_along(z[w])) z[w][j] <- paste0("&#x", as.hexmode(utf8ToInt(z[w][j])), 
        ";")
    z <- paste(z, collapse = "")
    z
}

#' html.flow.breakdown
#' 
#' html breaking down flows into constituents
#' @param x = a named numeric vector
#' @param y = a string
#' @param n = a number representing miscellaneous flows
#' @keywords html.flow.breakdown
#' @export
#' @family html

html.flow.breakdown <- function (x, y, n = 0) 
{
    if (y != "") 
        y <- paste0(" ", y)
    x <- x[order(abs(x), decreasing = T)]
    x <- x[order(x > 0, decreasing = sum(x) + n > 0)]
    u <- char.to.num(sign(sum(x) + n))
    x <- x * u
    h <- sum(x > 0)
    m <- length(x) - h
    x <- paste0(names(x), " ($", int.format(round(abs(x))), " million)")
    if (h == 0) {
        z <- paste("This week's", ifelse(u > 0, "inflows", "outflows"), 
            "were driven by sundry small contributions which overwhelmed", 
            ifelse(u > 0, "outflows from", "inflows into"), html.and(x))
    }
    else if (m == 0) {
        if (u > 0) {
            z <- paste0("inflows ", ifelse(abs(n) > 0, "primarily ", 
                ""), "went into")
        }
        else {
            z <- paste0("outflows ", ifelse(abs(n) > 0, "primarily ", 
                ""), "came from")
        }
        z <- paste("This week's", z, html.and(x))
    }
    else {
        z <- paste("This week's", ifelse(u > 0, "inflows", "outflows"), 
            ifelse(abs(n) > 0, "were primarily", "were"), "driven by", 
            html.and(x[1:h]))
        z <- paste0(z, y, ", but offset by")
        z <- paste(z, ifelse(u > 0, "outflows from", "inflows into"), 
            html.and(x[h + 1:m]))
    }
    z <- paste0(z, y)
    z
}

#' html.flow.english
#' 
#' writes a flow report in English
#' @param x = an integer vector
#' @param y = a string vector
#' @param n = line number(s) at which to insert a statement
#' @param w = statement(s) to be inserted
#' @keywords html.flow.english
#' @export
#' @family html

html.flow.english <- function (x, y, n, w) 
{
    z <- format(day.to.date(y["date"]), "%B %d %Y")
    z <- paste("For the week ended", z, "fund flow data from EPFR for", 
        y["AssetClass"], "($")
    z <- paste0(z, int.format(x["AUM"]), " million in total assets) reported net")
    z <- paste(z, ifelse(x["last"] > 0, "INFLOWS", "OUTFLOWS"), 
        "of $")
    z <- paste0(z, int.format(abs(x["last"])), " million vs an")
    z <- paste(z, ifelse(x["prior"] > 0, "inflow", "outflow"), 
        "of $")
    z <- paste0(z, int.format(abs(x["prior"])), " million the prior week")
    if (x["straight"] > 0) {
        u <- paste("This is the", txt.ex.int(x["straight"], T), 
            ifelse(x["straight"] > 4, "straight", "consecutive"))
        u <- paste(u, "week of", ifelse(x["last"] > 0, "inflows", 
            "outflows"))
    }
    else if (x["straight"] == -1) {
        u <- paste("This is the first week of", ifelse(x["last"] > 
            0, "inflows,", "outflows,"))
        u <- paste(u, "the prior one seeing", ifelse(x["last"] > 
            0, "outflows", "inflows"))
    }
    else {
        u <- paste("This is the first week of", ifelse(x["last"] > 
            0, "inflows,", "outflows,"))
        u <- paste(u, "the prior", txt.ex.int(-x["straight"]), 
            "seeing", ifelse(x["last"] > 0, "outflows", "inflows"))
    }
    z <- c(z, u)
    u <- paste(txt.left(y["date"], 4), "YTD has seen")
    if (x["YtdCountOutWks"] > x["YtdCountInWks"]) {
        u <- paste(u, txt.ex.int(x["YtdCountOutWks"]), "weeks of outflows and")
        if (x["YtdCountInWks"] > 0) {
            u <- paste(u, txt.ex.int(x["YtdCountInWks"]), "of inflows")
        }
        else u <- paste(u, "none of inflows")
    }
    else {
        u <- paste(u, txt.ex.int(x["YtdCountInWks"]), "weeks of inflows and")
        if (x["YtdCountOutWks"] > 0) {
            u <- paste(u, txt.ex.int(x["YtdCountOutWks"]), "of outflows")
        }
        else u <- paste(u, "none of outflows")
    }
    if (x["YtdCountInWks"] > 0 & x["YtdCountOutWks"] > 0) {
        u <- paste0(u, " (largest inflow $", int.format(x["YtdBigIn"]), 
            " million; largest outflow $", int.format(x["YtdBigOut"]), 
            " million)")
    }
    else if (x["YtdCountInWks"] > 0) {
        u <- paste0(u, " (largest inflow $", int.format(x["YtdBigIn"]), 
            " million)")
    }
    else {
        u <- paste0(u, " (largest outflow $", int.format(x["YtdBigOut"]), 
            " million)")
    }
    z <- c(z, u)
    u <- paste("For", txt.left(y["PriorYrWeek"], 4), "there were")
    if (x["PriorYrCountOutWks"] > x["PriorYrCountInWks"]) {
        u <- paste(u, txt.ex.int(x["PriorYrCountOutWks"]), "weeks of outflows and")
        if (x["PriorYrCountInWks"] > 0) {
            u <- paste(u, txt.ex.int(x["PriorYrCountInWks"]), 
                "of inflows")
        }
        else u <- paste(u, "none of inflows")
    }
    else {
        u <- paste(u, txt.ex.int(x["PriorYrCountInWks"]), "weeks of inflows and")
        if (x["PriorYrCountOutWks"] > 0) {
            u <- paste(u, txt.ex.int(x["PriorYrCountOutWks"]), 
                "of outflows")
        }
        else u <- paste(u, "none of outflows")
    }
    if (x["PriorYrCountInWks"] > 0 & x["PriorYrCountOutWks"] > 
        0) {
        u <- paste0(u, " (largest inflow $", int.format(x["PriorYrBigIn"]), 
            " million; largest outflow $", int.format(x["PriorYrBigOut"]), 
            " million)")
    }
    else if (x["PriorYrCountInWks"] > 0) {
        u <- paste0(u, " (largest inflow $", int.format(x["PriorYrBigIn"]), 
            " million)")
    }
    else {
        u <- paste0(u, " (largest outflow $", int.format(x["PriorYrBigOut"]), 
            " million)")
    }
    z <- c(z, u)
    if (x["FourWeekAvg"] > 0) {
        u <- paste0("four-week moving average: $", int.format(x["FourWeekAvg"]), 
            " million inflow (four-week cumulative: $", int.format(x["FourWeekSum"]), 
            " million inflow)")
    }
    else {
        u <- paste0("four-week moving average: $", int.format(-x["FourWeekAvg"]), 
            " million outflow (four-week cumulative: $", int.format(-x["FourWeekSum"]), 
            " million outflow)")
    }
    z <- c(z, u)
    u <- paste(txt.left(y["date"], 4), "flow data (through", 
        format(day.to.date(y["date"]), "%B %d"))
    if (x["YtdCumSum"] > 0) {
        u <- paste0(u, "): $", int.format(x["YtdCumSum"]), " million cumulative INFLOW, or a weekly average inflow of $", 
            int.format(x["YtdCumAvg"]), " million")
    }
    else {
        u <- paste0(u, "): $", int.format(-x["YtdCumSum"]), " million cumulative OUTFLOW, or a weekly average outflow of $", 
            int.format(-x["YtdCumAvg"]), " million")
    }
    z <- c(z, u)
    u <- paste(txt.left(y["PriorYrWeek"], 4), "flow data (through", 
        format(day.to.date(y["PriorYrWeek"]), "%B %d"))
    if (x["PriorYrCumSum"] > 0) {
        u <- paste0(u, "): $", int.format(x["PriorYrCumSum"]), 
            " million cumulative INFLOW, or a weekly average inflow of $", 
            int.format(x["PriorYrCumAvg"]), " million")
    }
    else {
        u <- paste0(u, "): $", int.format(-x["PriorYrCumSum"]), 
            " million cumulative OUTFLOW, or a weekly average outflow of $", 
            int.format(-x["PriorYrCumAvg"]), " million")
    }
    z <- c(z, u)
    if (!missing(n) & !missing(w)) {
        while (length(n) > 0) {
            z <- c(z[1:n[1]], w[1], z[seq(n[1] + 1, length(z))])
            n <- n[-1]
            w <- w[-1]
        }
    }
    z <- paste(c(paste0("<br>", z[1]), html.list(z[-1]), "</p>"), 
        collapse = "\n")
    z
}

#' html.flow.underlying
#' 
#' list object containing the following items: #		:	a) text - dates and text information about flows #		:	b) numbers - numeric summary of the flows
#' @param x = a numeric vector (indexed by YYYYMMDD)
#' @keywords html.flow.underlying
#' @export
#' @family html

html.flow.underlying <- function (x) 
{
    x <- x[order(names(x), decreasing = T)]
    z <- vec.named(x[1:2], c("last", "prior"))
    n <- vec.named(names(x)[1], "date")
    z["FourWeekAvg"] <- mean(x[1:4])
    z["FourWeekSum"] <- sum(x[1:4])
    y <- x > 0
    z["straight"] <- straight(y)
    if (z["straight"] == 1) 
        z["straight"] <- -straight(y[-1])
    y <- x[txt.left(names(x), 4) == txt.left(names(x)[1], 4)]
    z["YtdCountInWks"] <- sum(y > 0)
    z["YtdCountOutWks"] <- sum(y < 0)
    z["YtdBigIn"] <- max(y)
    z["YtdBigOut"] <- -min(y)
    y <- x[txt.left(names(x), 4) != txt.left(names(x)[1], 4)]
    y <- y[txt.left(names(y), 4) == txt.left(names(y)[1], 4)]
    z["PriorYrCountInWks"] <- sum(y > 0)
    z["PriorYrCountOutWks"] <- sum(y < 0)
    z["PriorYrBigIn"] <- max(y)
    z["PriorYrBigOut"] <- -min(y)
    y <- x[txt.left(names(x), 4) == txt.left(names(x)[1], 4)]
    z["YtdCumAvg"] <- mean(y)
    z["YtdCumSum"] <- sum(y)
    y <- x[txt.left(names(x), 4) != txt.left(names(x)[1], 4)]
    y <- y[txt.left(names(y), 4) == txt.left(names(y)[1], 4)]
    y <- y[order(names(y))]
    y <- y[1:min(sum(txt.left(names(x), 4) == txt.left(names(x)[1], 
        4)), length(y))]
    y <- y[order(names(y), decreasing = T)]
    n["PriorYrWeek"] <- names(y)[1]
    z["PriorYrCumAvg"] <- mean(y)
    z["PriorYrCumSum"] <- sum(y)
    z <- list(numbers = z, text = n)
    z
}

#' html.image
#' 
#' html to attach an image
#' @param x = a file (image)
#' @param y = an integer (percentage magnification)
#' @keywords html.image
#' @export
#' @family html

html.image <- function (x, y) 
{
    paste0("<br><img src='cid:", ftp.file(x), "' width= ", y, 
        "% height= ", y, "%>")
}

#' html.list
#' 
#' <x> expressed as an html list
#' @param x = a string vector
#' @keywords html.list
#' @export
#' @family html

html.list <- function (x) 
{
    c("<ul>", paste0("<li>", x, "</li>"), "</ul>")
}

#' html.positioning
#' 
#' writes a positioning report
#' @param x = a matrix (predictors)
#' @param y = security names (correspond to columns of <x>, can be missing)
#' @keywords html.positioning
#' @export
#' @family html

html.positioning <- function (x, y) 
{
    if (missing(y)) {
        y <- colnames(x)
    }
    else {
        y <- paste0(y, " (", colnames(x), ")")
    }
    x <- x[order(rownames(x), decreasing = T), ]
    y <- y[order(x[1, ], decreasing = T)]
    x <- x[, order(x[1, ], decreasing = T)]
    n <- qtl.eq(x)
    w1.new <- is.element(n[1, ], 1) & !is.na(n[2, ]) & n[2, ] > 
        1
    w5.new <- is.element(n[1, ], 5) & !is.na(n[2, ]) & n[2, ] < 
        5
    w1.old <- is.element(n[2, ], 1) & !is.element(n[1, ], 1)
    w5.old <- is.element(n[2, ], 5) & !is.element(n[1, ], 5)
    z <- paste("<p>The week ended", format(day.to.date(rownames(n)[1]), 
        "%B %d %Y"), "saw")
    if (sum(w1.new) == 0 & sum(w5.new) == 0) {
        z <- c(z, "no new entrants into either the top or bottom quintile.")
    }
    else if (sum(w1.new) > 0) {
        z <- c(z, html.and(y[w1.new]))
        if (sum(w1.old) == 0) {
            z <- c(z, "rise to the top quintile.")
        }
        else {
            z <- c(z, "rise to the top quintile, displacing")
            z <- c(z, paste0(html.and(y[w1.old]), "."))
        }
        if (sum(w5.new) == 0) {
            z <- c(z, "There were no new entrants into the bottom quintile.")
        }
        else {
            z <- c(z, "Over the same week,")
            z <- c(z, html.and(y[w5.new]))
            if (sum(w5.old) == 0) {
                z <- c(z, "fell to the bottom quintile.")
            }
            else {
                z <- c(z, "fell to the bottom quintile, displacing")
                z <- c(z, paste0(html.and(y[w5.old]), "."))
            }
        }
    }
    else {
        z <- c(z, html.and(y[w5.new]))
        if (sum(w5.old) == 0) {
            z <- c(z, "fall to the bottom quintile.")
        }
        else {
            z <- c(z, "fall to the bottom quintile, displacing")
            z <- c(z, paste0(html.and(y[w5.old]), "."))
        }
        z <- c(z, "There were no new entrants into the top quintile.")
    }
    z <- c(z, "</p>")
    h <- sapply(mat.ex.matrix(n == matrix(n[1, ], dim(n)[1], 
        dim(n)[2], T)), straight)
    w <- is.element(n[1, ], c(1, 5)) & h > 1
    if (any(w)) {
        h <- (ifelse(is.element(n[1, ], 5), -1, 1) * h)[w]
        names(h) <- y[w]
        z <- c(z, html.tenure(h, c("week of top-quintile rating for", 
            "for"), c("week of bottom-bucket status for", "for")))
    }
    z <- list(html = z, indicator = t(x)[, 1], quintiles = t(n)[, 
        1])
    z
}

#' html.problem
#' 
#' problem report
#' @param x = a string (report name)s
#' @param y = a string vector
#' @param n = a boolean vector (error/no error, NA = no check)
#' @keywords html.problem
#' @export
#' @family html

html.problem <- function (x, y, n) 
{
    paste(c("Dear All,", html.problem.underlying(x, y, n), html.signature()), 
        collapse = "\n")
}

#' html.problem.underlying
#' 
#' problem report
#' @param x = a string vector (report names)
#' @param y = a string vector
#' @param n = a boolean vector (error/no error, NA = no check)
#' @keywords html.problem.underlying
#' @export
#' @family html

html.problem.underlying <- function (x, y, n) 
{
    w <- !is.na(n) & n
    z <- NULL
    if (sum(w) == 0) {
        z <- c(z, "<p>", paste(y[1], txt.ex.int(sum(!is.na(n))), 
            y[2], "</p>"))
    }
    else {
        z <- c(z, "<p>", y[3], html.list(x[w]), "</p>")
    }
    w <- is.na(n)
    if (any(w)) {
        z <- c(z, "<p>", y[4])
        z <- c(z, html.list(x[w]), "</p>")
    }
    z
}

#' html.signature
#' 
#' signature at the end of an email
#' @keywords html.signature
#' @export
#' @family html

html.signature <- function () 
{
    z <- paste0("<p>", sample(readLines(parameters("letterClosings")), 
        1), "</p><p>")
    z <- paste0(z, quant.info(machine.info("Quant"), "Name"), 
        "<br>Quantitative Team, EPFR</p>")
    z <- paste0(z, "<p><i>", sample(readLines(parameters("letterSayings")), 
        1), "</i></p>")
    z
}

#' html.tbl
#' 
#' renders <x> in html
#' @param x = a matrix/data frame
#' @param y = a boolean (do/don't format integers)
#' @keywords html.tbl
#' @export
#' @family html

html.tbl <- function (x, y) 
{
    if (y) {
        x <- round(x)
        x <- mat.ex.matrix(lapply(x, int.format), rownames(x))
    }
    z <- "<TABLE border=\"0\""
    z <- c(z, paste0("<TR><TH><TH>", paste(colnames(x), collapse = "<TH>")))
    y <- rownames(x)
    x <- mat.ex.matrix(x)
    x$sep <- "</TD><TD align=\"right\">"
    z <- c(z, paste0("<TR><TH>", y, "<TD align=\"right\">", do.call(paste, 
        x)))
    z <- paste(c(z, "</TABLE>"), collapse = "\n")
    z
}

#' html.tenure
#' 
#' describes how long securities/factors have belonged to a group
#' @param x = an integer vector
#' @param y = a numeric vector (length two, for positive descriptions)
#' @param n = a numeric vector (length two, for negative descriptions)
#' @keywords html.tenure
#' @export
#' @family html

html.tenure <- function (x, y, n) 
{
    x <- x[order(abs(x), decreasing = T)]
    x <- x[order(sign(x), decreasing = T)]
    z <- NULL
    pos <- neg <- T
    for (j in unique(x)) {
        if (j > 0) {
            phrase <- ifelse(pos, y[1], y[2])
            pos <- F
        }
        else {
            phrase <- ifelse(neg, n[1], n[2])
            neg <- F
        }
        z <- c(z, paste("the", txt.ex.int(abs(j), T), phrase, 
            html.and(names(x)[x == j])))
    }
    x <- unique(x)
    if (all(x > 0)) {
        z <- paste0("This is ", html.and(z[x > 0]), ".")
    }
    else if (all(x < 0)) {
        z <- paste0("This is ", html.and(z[x < 0]), ".")
    }
    else {
        z <- paste0("This is not only ", html.and(z[x > 0]), 
            " but also ", html.and(z[x < 0]), ".")
    }
    z
}

#' int.format
#' 
#' adds commas "1,234,567"
#' @param x = an integer vector
#' @keywords int.format
#' @export
#' @family int

int.format <- function (x) 
{
    txt.trim(prettyNum(as.character(x), big.mark = ","))
}

#' int.random
#' 
#' random integer between 1 and <x>
#' @param x = a positive integer
#' @keywords int.random
#' @export
#' @family int

int.random <- function (x = 5) 
{
    order(rnorm(x))[1]
}

#' int.to.prime
#' 
#' prime factors of <x>
#' @param x = an integer
#' @keywords int.to.prime
#' @export
#' @family int

int.to.prime <- function (x) 
{
    n <- floor(sqrt(x))
    while (n > 1 & x%%n > 0) n <- n - 1
    if (n == 1) 
        z <- x
    else z <- z <- c(int.to.prime(n), int.to.prime(x/n))
    z <- z[order(z)]
    z
}

#' isin.exists
#' 
#' T/F depending on whether each element is an isin
#' @param x = a string vector
#' @keywords isin.exists
#' @export

isin.exists <- function (x) 
{
    charset <- vec.named(0:35, c(0:9, LETTERS))
    x <- toupper(txt.trim(x))
    z <- grepl("^[A-Z]{2}[0-9A-Z]{9}\\d{1}$", x)
    y <- x[z]
    y <- y[!duplicated(y)]
    y <- matrix(NA, length(y), 11, F, list(y, LETTERS[1:11]))
    for (j in 1:dim(y)[2]) y[, j] <- char.to.num(map.rname(charset, 
        substring(rownames(y), j, j)))
    y <- mat.ex.matrix(y)
    y <- vec.named(do.call(paste0, y), rownames(y))
    y <- split(y, names(y))
    fcn <- function(z) {
        z <- char.to.num(txt.to.char(z))
        l <- seq_along(z)%%2 == length(z)%%2
        z[l] <- 2 * z[l]
        z <- txt.to.char(paste(z, collapse = ""))
        z <- sum(char.to.num(z))
        z <- 10 * ceiling(z/10) - z
    }
    y <- sapply(y, fcn)
    y <- txt.right(names(y), 1) == y
    z[z] <- as.logical(y[x[z]])
    z
}

#' knapsack.count
#' 
#' number of ways to subdivide <x> things amongst <y> people
#' @param x = a non-negative integer
#' @param y = a positive integer
#' @keywords knapsack.count
#' @export
#' @family knapsack

knapsack.count <- function (x, y) 
{
    z <- matrix(1, x + 1, y, F, list(0:x, 1:y))
    if (x > 0 & y > 1) 
        for (i in 1:x) for (j in 2:y) z[i + 1, j] <- z[i, j] + 
            z[i + 1, j - 1]
    z <- z[x + 1, y]
    z
}

#' knapsack.ex.int
#' 
#' inverse of knapsack.to.int; returns a vector of length <n>, #		:	the elements of which sum to <y>
#' @param x = a positive integer
#' @param y = a positive integer
#' @param n = a positive integer
#' @keywords knapsack.ex.int
#' @export
#' @family knapsack

knapsack.ex.int <- function (x, y, n) 
{
    z <- NULL
    while (x != 1) {
        x <- x - 1
        i <- 0
        while (x > 0) {
            i <- i + 1
            h <- knapsack.count(i, n - 1)
            x <- x - h
        }
        z <- c(y - i, z)
        x <- x + h
        y <- y - z[1]
        n <- n - 1
    }
    z <- c(rep(0, n - 1), y, z)
    z
}

#' knapsack.next
#' 
#' next way to subdivide <sum(x)> things amongst <length(x)> people
#' @param x = an integer vector (non-negative!)
#' @keywords knapsack.next
#' @export
#' @family knapsack

knapsack.next <- function (x) 
{
    m <- length(x)
    w <- x > 0
    w <- w & !duplicated(w)
    if (w[1]) {
        n <- x[1]
        x[1] <- 0
        w <- x > 0
        w <- w & !duplicated(w)
        x[(1:m)[w] - 1:0] <- x[(1:m)[w] - 1:0] + c(1 + n, -1)
    }
    else {
        x[(1:m)[w] - 1:0] <- x[(1:m)[w] - 1:0] + c(1, -1)
    }
    z <- x
    z
}

#' knapsack.prev
#' 
#' inverse of knapsack.next
#' @param x = an integer vector (non-negative!)
#' @keywords knapsack.prev
#' @export
#' @family knapsack

knapsack.prev <- function (x) 
{
    m <- length(x)
    w <- x > 0
    w <- w & !duplicated(w)
    w <- (1:m)[w]
    if (x[w] == 1 | w == 1) {
        x[w + 0:1] <- x[w + 0:1] + c(-1, 1)
    }
    else {
        x[c(1, w + 0:1)] <- x[c(1, w + 0:1)] + c(x[w] - 1, -x[w], 
            1)
    }
    z <- x
    z
}

#' knapsack.to.int
#' 
#' maps each particular way to subdivide <sum(x)> things #		:	amongst <length(x)> people to the number line
#' @param x = an integer vector (non-negative!)
#' @keywords knapsack.to.int
#' @export
#' @family knapsack

knapsack.to.int <- function (x) 
{
    n <- sum(x)
    z <- 1
    m <- length(x) - 1
    while (m > 0) {
        i <- sum(x[1:m])
        while (i > 0) {
            z <- z + knapsack.count(i - 1, m)
            i <- i - 1
        }
        m <- m - 1
    }
    z
}

#' latin.ex.arabic
#' 
#' lower-case latin representation of <x>
#' @param x = a numeric vector
#' @keywords latin.ex.arabic
#' @export
#' @family latin

latin.ex.arabic <- function (x) 
{
    tolower(as.roman(x))
}

#' latin.to.arabic
#' 
#' <x> expressed as an arabic integer
#' @param x = a character vector
#' @keywords latin.to.arabic
#' @export
#' @family latin

latin.to.arabic <- function (x) 
{
    char.to.num(as.roman(x))
}

#' list.rename
#' 
#' renamed list
#' @param x = list
#' @param y = a string vector (old names)
#' @param n = a string vector (new names, can be missing)
#' @keywords list.rename
#' @export

list.rename <- function (x, y, n) 
{
    if (missing(n)) 
        n <- args.canonical()[seq_along(y)]
    z <- x[is.element(names(x), y)]
    names(z) <- vec.named(n, y)[names(z)]
    z
}

#' load.dy.vbl
#' 
#' Loads a daily variable
#' @param fcn = a function
#' @param x = a YYYYMMDD
#' @param y = a YYYYMMDD
#' @param n = a string vector (passed down to <fcn>)
#' @param w = a string (name to store variable under)
#' @param h = R-object folder
#' @param u = a StockFlows environment
#' @keywords load.dy.vbl
#' @export
#' @family load

load.dy.vbl <- function (fcn, x, y, n, w, h, u) 
{
    load.vbl.underlying(fcn, x, y, n, w, h, u, T)
}

#' load.dy.vbl.1obj
#' 
#' Loads a daily variable
#' @param fcn = a function
#' @param x = a YYYYMMDD
#' @param y = a YYYYMMDD
#' @param n = passed down to <mk.fcn>
#' @param w = a string (name to store variable under)
#' @param h = a YYYYMM
#' @param u = a StockFlows environment
#' @keywords load.dy.vbl.1obj
#' @export
#' @family load

load.dy.vbl.1obj <- function (fcn, x, y, n, w, h, u) 
{
    z <- flowdate.ex.yyyymm(h, F)
    z <- paste(w, txt.right(z, 2), sep = ".")
    z <- matrix(NA, dim(u$classif)[1], length(z), F, list(rownames(u$classif), 
        z))
    dd <- txt.right(colnames(z), 2)
    dd <- dd[char.to.num(paste0(h, dd)) >= char.to.num(x)]
    dd <- dd[char.to.num(paste0(h, dd)) <= char.to.num(y)]
    for (i in dd) {
        cat(i, "")
        z[, paste(w, i, sep = ".")] <- fcn(paste0(h, i), n, u)
    }
    z <- mat.ex.matrix(z)
    z
}

#' load.mo.vbl
#' 
#' Loads a monthly variable
#' @param fcn = a function
#' @param x = a YYYYMM
#' @param y = a YYYYMM
#' @param n = a string vector (passed down to <fcn>)
#' @param w = a string (name to store variable under)
#' @param h = R-object folder
#' @param u = a StockFlows environment
#' @keywords load.mo.vbl
#' @export
#' @family load

load.mo.vbl <- function (fcn, x, y, n, w, h, u) 
{
    load.vbl.underlying(fcn, x, y, n, w, h, u, F)
}

#' load.mo.vbl.1obj
#' 
#' Loads a monthly variable
#' @param fcn = a function
#' @param x = a YYYYMM
#' @param y = a YYYYMM
#' @param n = passed down to <mk.fcn>
#' @param w = a string (name to store variable under)
#' @param h = the period for which the object is to be made
#' @param u = a StockFlows environment
#' @keywords load.mo.vbl.1obj
#' @export
#' @family load

load.mo.vbl.1obj <- function (fcn, x, y, n, w, h, u) 
{
    z <- paste(w, 1:12, sep = ".")
    z <- matrix(NA, dim(u$classif)[1], length(z), F, list(rownames(u$classif), 
        z))
    mm <- 1:12
    mm <- mm[100 * h + mm >= x]
    mm <- mm[100 * h + mm <= y]
    for (i in mm) {
        cat(i, "")
        z[, paste(w, i, sep = ".")] <- fcn(as.character(100 * 
            h + i), n, u)
    }
    z <- mat.ex.matrix(z)
    z
}

#' load.vbl.underlying
#' 
#' Loads a variable
#' @param fcn = a function
#' @param x = a YYYYMM/YYYYMMDD
#' @param y = a YYYYMM/YYYYMMDD
#' @param n = a string vector (passed down to <fcn>)
#' @param w = a string (name to store variable under)
#' @param h = R-object folder
#' @param u = a StockFlows environment
#' @param v = a boolean (daily/monthly)
#' @keywords load.vbl.underlying
#' @export
#' @family load

load.vbl.underlying <- function (fcn, x, y, n, w, h, u, v) 
{
    if (v) {
        fcn.conv <- yyyymmdd.to.yyyymm
        fcn.load <- load.dy.vbl.1obj
    }
    else {
        fcn.conv <- yyyymm.to.yyyy
        fcn.load <- load.mo.vbl.1obj
    }
    for (v in yyyymm.seq(fcn.conv(x), fcn.conv(y))) {
        cat(v, ":")
        z <- fcn.load(fcn, x, y, n, w, v, u)
        saveRDS(z, file = paste(h, paste(w, v, "r", sep = "."), 
            sep = "\\"), ascii = T)
        cat("\n")
    }
    invisible()
}

#' machine.info
#' 
#' folder of function source file
#' @param x = a string (column in classif-Machines)
#' @keywords machine.info
#' @export

machine.info <- function (x) 
{
    mat.read(parameters("classif-Machines"), "\t")[Sys.info()[["nodename"]], 
        x]
}

#' map.classif
#' 
#' Maps data to the row space of <y>
#' @param x = a numeric vector
#' @param y = <classif>
#' @param n = something like "isin" or "HSId"
#' @keywords map.classif
#' @export
#' @family map

map.classif <- function (x, y, n) 
{
    z <- vec.to.list(txt.has(colnames(y), paste0("^", n, "\\d+")))
    fcn <- function(z) char.to.num(map.rname(x, y[, z]))
    z <- avail(sapply(z, fcn))
    z
}

#' map.rname
#' 
#' returns a matrix/data frame, the row names of which match up with <y>
#' @param x = a string vector/matrix/data frame
#' @param y = a string vector
#' @keywords map.rname
#' @export
#' @family map

map.rname <- function (x, y) 
{
    if (is.null(dim(x))) {
        z <- vec.named(, y)
        w <- is.element(y, names(x))
        if (any(w)) 
            z[w] <- x[names(z)[w]]
    }
    else {
        w <- !is.element(y, rownames(x))
        if (any(w)) {
            y.loc <- matrix(NA, sum(w), dim(x)[2], F, list(y[w], 
                colnames(x)))
            x <- rbind(x, y.loc)
        }
        if (dim(x)[2] == 1) {
            z <- matrix(x[as.character(y), 1], length(y), 1, 
                F, list(y, colnames(x)))
        }
        else z <- x[as.character(y), ]
    }
    z
}

#' mat.compound
#' 
#' Compounds across the rows
#' @param x = a matrix/data frame (percentage returns)
#' @keywords mat.compound
#' @export
#' @family mat

mat.compound <- function (x) 
{
    fcn.mat.num(compound, x, , F)
}

#' mat.correl
#' 
#' Returns the correlation of <x> & <y> if <x> is a numeric vector or those between the rows of <x> and <y> otherwise
#' @param x = a numeric vector/matrix/data frame
#' @param y = a numeric vector/matrix/data frame
#' @keywords mat.correl
#' @export
#' @family mat

mat.correl <- function (x, y) 
{
    fcn.mat.num(correl, x, y, F)
}

#' mat.count
#' 
#' counts observations of the columns of <x>
#' @param x = a matrix/data frame
#' @keywords mat.count
#' @export
#' @family mat

mat.count <- function (x) 
{
    z <- colSums(mat.to.obs(x))
    z <- c(z, round(100 * z/dim(x)[1], 1))
    z <- matrix(z, dim(x)[2], 2, F, list(colnames(x), c("obs", 
        "pct")))
    z
}

#' mat.daily.to.monthly
#' 
#' returns latest data in each month indexed by <yyyymm> ascending
#' @param x = a matrix/data frame (daily data)
#' @param y = a boolean (is/isn't month-end data)
#' @keywords mat.daily.to.monthly
#' @export
#' @family mat

mat.daily.to.monthly <- function (x, y = F) 
{
    z <- x[order(rownames(x), decreasing = T), ]
    z <- z[!duplicated(yyyymmdd.to.yyyymm(rownames(z))), ]
    if (y) {
        w <- yyyymmdd.to.yyyymm(rownames(z))
        w <- yyyymmdd.ex.yyyymm(w)
        w <- w == rownames(z)
        z <- z[w, ]
    }
    rownames(z) <- yyyymmdd.to.yyyymm(rownames(z))
    z <- mat.reverse(z)
    z
}

#' mat.daily.to.weekly
#' 
#' returns weekly data
#' @param fcn = a function (converts vector to a number)
#' @param x = a matrix/data frame (daily data)
#' @param y = an integer (0 = Sun, 1 = Mon, etc., the day each week ends)
#' @keywords mat.daily.to.weekly
#' @export
#' @family mat

mat.daily.to.weekly <- function (fcn, x, y) 
{
    pivot.1d(fcn, day.to.week(rownames(x), y), x)
}

#' mat.diff
#' 
#' difference between <x> and itself lagged <y>
#' @param x = a matrix/data frame
#' @param y = a non-negative integer
#' @keywords mat.diff
#' @export
#' @family mat

mat.diff <- function (x, y) 
{
    fcn.mat.vec(function(z) vec.diff(z, y), x, , T)
}

#' mat.ex.array
#' 
#' a data frame with the first dimension forming the column space
#' @param x = an array
#' @keywords mat.ex.array
#' @export
#' @family mat

mat.ex.array <- function (x) 
{
    apply(x, 1, function(z) mat.index(array.unlist(z), length(dim(z)):1))
}

#' mat.ex.list
#' 
#' rbinds elements of <x> with added column <y>
#' @param x = a string vector/matrix/data frame list
#' @param y = a string vector (additional columns, can be missing)
#' @keywords mat.ex.list
#' @export
#' @family mat

mat.ex.list <- function (x, y) 
{
    h <- is.null(dim(x[[1]]))
    if (missing(y)) 
        if (h) 
            y <- c("x", "y")
        else y <- "yyyymmdd"
    if (h) {
        z <- sapply(x, length)
        x <- Reduce(c, x)
        z <- rep(names(z), z)
        z <- data.frame(x, z, stringsAsFactors = F)
        names(z) <- y
    }
    else {
        z <- sapply(x, function(z) dim(z)[1])
        x <- Reduce(rbind, x)
        x[, y] <- rep(names(z), z)
        z <- x
    }
    z
}

#' mat.ex.matrix
#' 
#' converts into a data frame
#' @param x = a matrix/data frame
#' @param y = a string vector
#' @keywords mat.ex.matrix
#' @export
#' @family mat

mat.ex.matrix <- function (x, y = NULL) 
{
    as.data.frame(x, row.names = y, stringsAsFactors = F)
}

#' mat.ex.vec
#' 
#' transforms into a 1/0 matrix of bin memberships if <y> is missing or the values of <y> otherwise
#' @param x = a numeric vector
#' @param y = a string vector
#' @param n = a boolean (do/don't append "Q" to column headers)
#' @keywords mat.ex.vec
#' @export
#' @family mat

mat.ex.vec <- function (x, y, n = T) 
{
    if (!is.null(names(x))) 
        w <- names(x)
    else w <- seq_along(x)
    if (n) 
        x <- paste0("Q", x)
    z <- data.frame(w, x, y, stringsAsFactors = F)
    z <- reshape.wide(z)
    z
}

#' mat.index
#' 
#' indexes <x> by, and, if <n>, removes, columns <y>
#' @param x = a matrix/data frame
#' @param y = a string vector (columns)
#' @param n = a boolean (do/don't remove indexing columns)
#' @keywords mat.index
#' @export
#' @family mat

mat.index <- function (x, y = 1, n = T) 
{
    if (all(is.element(y, 1:dim(x)[2]))) {
        w <- is.element(1:dim(x)[2], y)
    }
    else {
        w <- is.element(colnames(x), y)
    }
    if (sum(w) > 1) 
        z <- do.call(paste, mat.ex.matrix(x)[, y])
    else z <- x[, w]
    if (any(is.na(z))) 
        stop("NA's in row indices ..")
    if (any(duplicated(z))) 
        stop("Duplicated row indices ..")
    if (!n) {
        rownames(x) <- z
        z <- x
    }
    else if (sum(!w) > 1) {
        rownames(x) <- z
        z <- x[, !w]
    }
    else {
        z <- vec.named(x[, !w], z)
    }
    z
}

#' mat.lag
#' 
#' Returns data lagged <y> periods with the same row space as <x>
#' @param x = a matrix/data frame
#' @param y = an integer
#' @keywords mat.lag
#' @export
#' @family mat

mat.lag <- function (x, y) 
{
    if (is.null(dim(x))) 
        vec.lag(x, y)
    else fcn.mat.vec(vec.lag, x, y, T)
}

#' mat.last.to.first
#' 
#' Re-orders so the last <y> columns come first
#' @param x = a matrix/data frame
#' @param y = a non-negative integer
#' @keywords mat.last.to.first
#' @export
#' @family mat

mat.last.to.first <- function (x, y = 1) 
{
    x[, order((1:dim(x)[2] + y - 1)%%dim(x)[2])]
}

#' mat.rank
#' 
#' ranks <x> if <x> is a numeric vector or the rows of <x> otherwise
#' @param x = a numeric vector/matrix/data frame
#' @keywords mat.rank
#' @export
#' @family mat

mat.rank <- function (x) 
{
    fcn <- function(z) fcn.nonNA(rank, -z)
    z <- fcn.mat.vec(fcn, x, , F)
    z
}

#' mat.reverse
#' 
#' reverses row order
#' @param x = a matrix/data frame
#' @keywords mat.reverse
#' @export
#' @family mat

mat.reverse <- function (x) 
{
    x[dim(x)[1]:1, ]
}

#' mat.rollsum
#' 
#' rolling sum of <n> rows
#' @param x = a matrix/data frame
#' @param y = a non-negative integer
#' @keywords mat.rollsum
#' @export
#' @family mat

mat.rollsum <- function (x, y) 
{
    fcn <- function(z) as.numeric(filter(z, rep(1, y), sides = 1))
    z <- fcn.mat.vec(fcn, x, , T)
    z
}

#' mat.sort
#' 
#' sorts <x> by <y> in decreasing order if <n> is T
#' @param x = a matrix/data frame
#' @param y = a string vector (column names of <x>)
#' @param n = a boolean vector (same length as <y>)
#' @keywords mat.sort
#' @export
#' @family mat

mat.sort <- function (x, y, n) 
{
    x[do.call(order, c(mat.ex.matrix(x)[y], list(decreasing = n))), 
        ]
}

#' mat.subset
#' 
#' <x> subset to <y>
#' @param x = a matrix/data frame
#' @param y = a string vector
#' @keywords mat.subset
#' @export
#' @family mat

mat.subset <- function (x, y) 
{
    w <- is.element(y, colnames(x))
    if (any(!w)) {
        err.raise(y[!w], F, "Warning: The following columns are missing")
        z <- t(map.rname(t(x), y))
    }
    else if (length(y) == 1) {
        z <- vec.named(x[, y], rownames(x))
    }
    else {
        z <- x[, y]
    }
    z
}

#' mat.to.last.Idx
#' 
#' the last row index for which we have data
#' @param x = a matrix/data frame
#' @keywords mat.to.last.Idx
#' @export
#' @family mat

mat.to.last.Idx <- function (x) 
{
    z <- rownames(x)[dim(x)[1]]
    cat("Original data had", dim(x)[1], "rows ending at", z, 
        "..\n")
    z
}

#' mat.to.obs
#' 
#' Returns 0 if <x> is NA or 1 otherwise.
#' @param x = a numeric vector/matrix/data frame
#' @keywords mat.to.obs
#' @export
#' @family mat

mat.to.obs <- function (x) 
{
    fcn.mat.vec(function(z) char.to.num(!is.na(z)), x, , T)
}

#' mat.to.xlModel
#' 
#' prepends the trade open and close dates and re-indexes by data date (as needed)
#' @param x = a data frame (indexed by trade open date)
#' @param y = a non-negative integer (delay in days)
#' @param n = a positive integer (return window in weekdays)
#' @param w = a boolean (index by data/trade-open date)
#' @keywords mat.to.xlModel
#' @export
#' @family mat

mat.to.xlModel <- function (x, y = 2, n = 5, w = F) 
{
    z <- c("Open", "Close")
    z <- matrix(NA, dim(x)[1], length(z), F, list(rownames(x), 
        z))
    if (w) 
        z[, "Open"] <- yyyymm.lag(rownames(z), -y)
    if (!w) {
        z[, "Open"] <- rownames(z)
        rownames(z) <- yyyymm.lag(z[, "Open"], y)
    }
    z[, "Close"] <- yyyymm.lag(z[, "Open"], -n)
    if (all(nchar(rownames(x)) == 8)) {
        if (any(day.to.weekday(z[, "Open"]) != "5") | any(day.to.weekday(z[, 
            "Close"]) != "5")) {
            cat("WARNING: YOU ARE NOT TRADING FRIDAY TO FRIDAY!\n")
        }
    }
    z <- cbind(z, x)
    z <- z[order(rownames(z), decreasing = T), ]
    z
}

#' mat.weekly.to.daily
#' 
#' daily file having latest weekly data known by each flow date
#' @param x = a matrix/data frame (weekly data)
#' @keywords mat.weekly.to.daily
#' @export
#' @family mat

mat.weekly.to.daily <- function (x) 
{
    w <- flowdate.exists(rownames(x))
    if (any(!w)) 
        rownames(x)[!w] <- yyyymmdd.lag(rownames(x)[!w], 1)
    y <- flowdate.seq(min(rownames(x)), max(rownames(x)))
    z <- fix.gaps(ifelse(is.element(y, rownames(x)), y, NA))
    z <- map.rname(x, z)
    rownames(z) <- y
    z
}

#' mat.write
#' 
#' Writes <x> as a <n>-separated file to <y>
#' @param x = a numeric vector/matrix/data frame
#' @param y = a file (output, can be missing)
#' @param n = the separator
#' @param w = a boolean (do/don't write row names)
#' @keywords mat.write
#' @export
#' @family mat

mat.write <- function (x, y, n = ",", w = T) 
{
    if (missing(y)) 
        y <- paste(machine.info("temp"), "write.csv", sep = "\\")
    if (is.null(dim(x))) {
        write.table(x, y, sep = n, quote = F, col.names = F, 
            row.names = w)
    }
    else if (dim(x)[1] == 0) {
        cat("No records. Write to", y, "failed ..\n")
    }
    else if (w) {
        write.table(x, y, sep = n, quote = F, col.names = NA)
    }
    else {
        write.table(x, y, sep = n, quote = F, col.names = T, 
            row.names = F)
    }
    invisible()
}

#' mat.zScore
#' 
#' zScores <x> within groups <n> using weights <y>
#' @param x = a numeric vector/matrix/data frame
#' @param y = a membership vector (can be missing)
#' @param n = a numeric vector (groups, can be missing)
#' @keywords mat.zScore
#' @export
#' @family mat

mat.zScore <- function (x, y, n) 
{
    h <- is.null(dim(x))
    if (h) {
        m <- length(x)
        z <- rep(NA, m)
    }
    else {
        m <- dim(x)[1]
        z <- matrix(NA, m, dim(x)[2], F, dimnames(x))
    }
    if (missing(y)) 
        y <- rep(1, m)
    if (missing(n)) 
        n <- rep(1, m)
    y <- is.element(y, 1)
    w <- !is.na(n)
    x <- data.frame(x, y, stringsAsFactors = F)
    x <- fcn.vec.grp(zScore.underlying, x[w, ], n[w])
    if (any(w) & h) 
        z[w] <- x
    else z[w, ] <- unlist(x)
    z
}

#' maturity.bucket
#' 
#' where clauses for SQL case statement
#' @param x = named numeric vector
#' @keywords maturity.bucket
#' @export

maturity.bucket <- function (x) 
{
    x <- x[order(x)]
    x <- vec.named(paste("v >=", x, "and v <", c(x[-1], "?")), 
        names(x))
    x[length(x)] <- gsub(".{10}$", "", x[length(x)])
    z <- txt.replace(x, "v", "datediff(day, @date, BondMaturity)")
    z
}

#' mk.1dActWtTrend.Ctry
#' 
#' SQL query for daily ActWtTrend
#' @param x = a flowdate
#' @param y = factor (one of ActWtTrend/ActWtDiff/ActWtDiff2)
#' @param n = a string (one of Ctry/FX)
#' @param w = a connection string/connection
#' @param h = a filter vector
#' @keywords mk.1dActWtTrend.Ctry
#' @export
#' @family mk

mk.1dActWtTrend.Ctry <- function (x, y, n, w, h = "E") 
{
    s <- yyyymmdd.to.AllocMo.unique(x, 23, F)
    n <- sql.1dFloMo.CountryId.List(n, x)
    x <- sql.1dActWtTrend.Flow(x, h)
    z <- c(sql.drop("#FLO"), sql.1dActWtTrend.Alloc(s, "#CTRY", 
        "CountryId", names(n)))
    z <- paste(c(z, "", x), collapse = "\n")
    z <- c(z, sql.1dActWtTrend.Final("#CTRY", y, "CountryId"))
    z <- sql.1dFloTrend.Alloc.data(z, n, w)
    z
}

#' mk.1dActWtTrend.Sec
#' 
#' SQL query for daily ActWtTrend
#' @param x = a flowdate
#' @param y = factor (one of ActWtTrend/ActWtDiff/ActWtDiff2)
#' @param n = a connection string/connection
#' @param w = a filter vector
#' @keywords mk.1dActWtTrend.Sec
#' @export
#' @family mk

mk.1dActWtTrend.Sec <- function (x, y, n, w = "E") 
{
    s <- yyyymmdd.to.AllocMo.unique(x, 23, F)
    x <- sql.1dActWtTrend.Flow(x, w)
    z <- c(sql.drop("#FLO"), sql.1dActWtTrend.Alloc(s, "#SEC", 
        "SectorId"))
    s <- sql.unbracket(sql.1dActWtTrend.Alloc(s, , "IndustryId", 
        20))
    z <- c(z, "", "insert into", "\t#SEC (FundId, SectorId, Allocation, AUM)", 
        s)
    z <- c(z, "", sql.Allocation.Sec.FinsExREst(c("FundId", "SectorId", 
        "Allocation", "AUM")))
    z <- paste(c(z, "", x), collapse = "\n")
    z <- c(z, sql.1dActWtTrend.Final("#SEC", y, "SectorId"))
    z <- sql.1dFloTrend.Alloc.data(z, sql.1dFloMo.CountryId.List("Sector"), 
        n)
    z
}

#' mk.1dFloMo.Ctry
#' 
#' SQL query for daily/weekly CBE flow momentum
#' @param x = a flowdate/YYYYMMDD (depending on whether daily/weekly)
#' @param y = a string (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param n = a string (one of Ctry/FX/Sector)
#' @param w = a connection string/connection
#' @param h = a frequency (T/F for daily/weekly or D/W/M)
#' @param u = a filter vector
#' @param v = a boolean (foreign/all allocations)
#' @param g = a boolean (institutional/all share classes)
#' @keywords mk.1dFloMo.Ctry
#' @export
#' @family mk

mk.1dFloMo.Ctry <- function (x, y, n, w, h, u = "E", v = F, g = F) 
{
    s <- yyyymmdd.to.AllocMo.unique(x, 23, F)
    n <- sql.1dFloMo.CountryId.List(n, x)
    if (v) 
        v <- sql.extra.domicile(n, "CountryId", "CountryId")
    else v <- NULL
    if (is.null(v)) {
        s <- list(A = paste0("ReportDate = '", yyyymm.to.day(s), 
            "'"))
    }
    else {
        v[["A"]] <- paste0("ReportDate = '", yyyymm.to.day(s), 
            "'")
        s <- v
    }
    s[["B"]] <- paste0("CountryId in (", paste(names(n), collapse = ", "), 
        ")")
    s <- sql.Allocation(c("FundId", "CountryId", "Allocation"), 
        "Country", "Domicile", , sql.and(s))
    if (g) {
        g <- list(A = wrap(x))
        g[["B"]] <- sql.in("SCID", sql.tbl("SCID", "ShareClass", 
            "InstOrRetail = 'Inst'"))
    }
    else g <- list(A = wrap(x))
    r <- c(sql.Flow.tbl(h, F), "FundId", y)
    z <- sql.Flow(r, g, c("CB", u, "UI"), , h)
    z <- c(sql.label(z, "t1"), "inner join", sql.label(s, "t2"), 
        "\ton t2.FundId = t1.FundId")
    z <- mk.1dFloMo.Ctry.data(z, y, r, w)
    if (length(n) > 1) 
        z <- mk.1dFloMo.Ctry.rslt(y, z, n)
    z
}

#' mk.1dFloMo.Ctry.data
#' 
#' formats flow momentum output
#' @param x = a from clause
#' @param y = a string (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param n = a string vector (select items)
#' @param w = a connection string/connection
#' @keywords mk.1dFloMo.Ctry.data
#' @export
#' @family mk

mk.1dFloMo.Ctry.data <- function (x, y, n, w) 
{
    s <- c(sql.yyyymmdd(n[1]), "CountryId", paste0(y, " = 0.01 * sum(Allocation * ", 
        y, ")"))
    z <- sql.unbracket(sql.tbl(s, x, , paste0(n[1], ", ", s[2])))
    z <- sql.query(paste(z, collapse = "\n"), w, F)
    z
}

#' mk.1dFloMo.Ctry.rslt
#' 
#' formats flow momentum output
#' @param x = a string (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param y = flow momentum output
#' @param n = a country code vector (indexed by CountryId)
#' @keywords mk.1dFloMo.Ctry.rslt
#' @export
#' @family mk

mk.1dFloMo.Ctry.rslt <- function (x, y, n) 
{
    y[, 2] <- map.rname(n, y[, 2])
    y <- aggregate(x = y[x], by = y[2:1], FUN = sum)
    if (length(x) > 1) 
        y <- reshape.long(y, x, "item")
    z <- reshape.wide(y)
    z
}

#' mk.1dFloMo.CtrySG
#' 
#' SQL query for daily/weekly regional flow momentum
#' @param x = a flowdate/YYYYMMDD (backtest start)
#' @param y = a string (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param n = a string (one of Ctry/FX)
#' @param w = a connection string/connection
#' @param h = a frequency (T/F for daily/weekly)
#' @param u = a filter vector
#' @param v = a boolean (institutional/all share classes)
#' @keywords mk.1dFloMo.CtrySG
#' @export
#' @family mk

mk.1dFloMo.CtrySG <- function (x, y, n, w, h, u = "E", v = F) 
{
    if (n == "Ctry") {
        z <- as.character(sql.1dFloMo.CountryId.List(n, x))
        z <- z[!is.na(Ctry.info(z, "GeoId"))]
        z <- vec.named(z, Ctry.info(z, "GeoId"))
    }
    else if (n == "FX") {
        z <- sql.1dFloMo.CountryId.List(n, x)
        n <- mat.read(parameters("classif-Ctry"))[, c("CountryId", 
            "GeoId")]
        n <- n[is.element(n[, "CountryId"], names(z)) & !is.na(n[, 
            "GeoId"]), ]
        z <- z[as.character(n[, "CountryId"])]
        names(z) <- n[, "GeoId"]
    }
    else {
        stop("Can't handle this ..\n")
    }
    z <- split(names(z), z)
    z <- sapply(z, function(z) if (length(z) == 1) 
        paste("GeographicFocus =", z)
    else paste0("GeographicFocus in (", paste(z, collapse = ", "), 
        ")"))
    z <- sql.1dFloMo.CtrySG(x, y, z, h, u, v)
    z <- sql.query(z, w)
    z
}

#' mk.1dFloMo.FI
#' 
#' SQL query for daily/weekly regional flow momentum
#' @param x = a flowdate/YYYYMMDD (backtest start)
#' @param y = a string (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param n = a connection string/connection
#' @param w = a frequency (T/F for daily/weekly)
#' @param h = a filter vector
#' @param u = a boolean (institutional/all share classes)
#' @keywords mk.1dFloMo.FI
#' @export
#' @family mk

mk.1dFloMo.FI <- function (x, y, n, w, h = "All", u = F) 
{
    h <- c("FundType in ('B', 'M')", h)
    z <- sql.1dFloMo.FI.grp()
    z <- sql.1dFloMo.CtrySG(x, y, z, w, h, u)
    z <- sql.query(z, n)
    z
}

#' mk.1dFloMo.Indy
#' 
#' SQL query for daily/weekly CBE flow momentum
#' @param x = a flowdate/YYYYMMDD (depending on whether daily/weekly)
#' @param y = a string (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param n = a connection string/connection
#' @param w = a frequency (T/F for daily/weekly or D/W/M)
#' @param h = one of US/UK/JP/EM/Eurozone/All (full global)
#' @keywords mk.1dFloMo.Indy
#' @export
#' @family mk

mk.1dFloMo.Indy <- function (x, y, n, w, h) 
{
    u <- yyyymmdd.to.AllocMo.unique(x, 23, F)
    s <- sql.1dFloMo.CountryId.List("Industry", x)
    if (h == "UK") {
        h <- "GB"
    }
    else if (h == "Eurozone") {
        h <- c("AT", "BE", "DE", "FI", "FR", "IE", "IT", "NL", 
            "PT", "ES")
    }
    else if (h == "EM") {
        h <- c("AE", "BR", "CL", "CN", "CO", "CZ", "EG", "GR", 
            "HU", "ID", "IN", "KR", "MX", "MY", "PE", "PH", "PL", 
            "QA", "RU", "TH", "TR", "TW", "ZA")
    }
    else if (h == "All") {
        h <- mat.read(parameters("classif-Ctry"))
        h <- rownames(h)[!is.na(h$CountryId)]
    }
    else if (all(h != c("US", "JP"))) {
        stop("Can't handle yet!")
    }
    h <- vec.named(Ctry.info(h, "CountryId"), h)
    v <- list(A = paste0("CountryId in (", paste(h, collapse = ", "), 
        ")"))
    v[["B"]] <- paste0("ReportDate = '", yyyymm.to.day(u), "'")
    z <- c("FundId", "GeographicFocus", "Universe = sum(Allocation)")
    z <- sql.Allocation(z, "Country", "GeographicFocus", "E", 
        sql.and(v), paste(z[-length(z)], collapse = ", "))
    z <- c("insert into", "\t#CTRY (FundId, GeographicFocus, Universe)", 
        sql.unbracket(z))
    z <- c(sql.index("#CTRY", "FundId"), z)
    z <- c("create table #CTRY (FundId int not null, GeographicFocus int, Universe float)", 
        z)
    v <- paste0("ReportDate = '", yyyymm.to.day(u), "'")
    r <- c("FundId", "IndustryId", "GeographicFocus", "Allocation")
    v <- sql.unbracket(sql.Allocation(r, "Industry", "GeographicFocus", 
        "All", v))
    v <- c("insert into", paste0("\t#INDY (", paste(r, collapse = ", "), 
        ")"), v)
    v <- c(sql.index("#INDY", "FundId, IndustryId"), v)
    v <- c("create table #INDY (FundId int not null, IndustryId int not null, GeographicFocus int, Allocation float)", 
        v)
    z <- c(z, "", v)
    v <- c("GeographicFocus", "StyleSector")
    r <- c(sql.Flow.tbl(w, F), "FundId")
    v <- c(r, paste0(v, " = max(", v, ")"), paste0(y, " = sum(", 
        y, ")"))
    v <- sql.Flow(v, list(A = wrap(x)), c("CB", "E"), c("GeographicFocus", 
        "StyleSector"), w, paste(r, collapse = ", "))
    v <- c("insert into", paste0("\t#FLO (", paste(r, collapse = ", "), 
        ", GeographicFocus, StyleSector, ", paste(y, collapse = ", "), 
        ")"), sql.unbracket(v))
    v <- c(sql.index("#FLO", paste(r, collapse = ", ")), v)
    v <- c(paste0("create table #FLO (", r[1], " datetime not null, FundId int not null, GeographicFocus int, StyleSector int, ", 
        paste(paste(y, "float"), collapse = ", "), ")"), v)
    z <- c(z, "", v)
    v <- paste(Ctry.info(names(h), "GeoId"), collapse = ", ")
    z <- c(z, "", sql.delete("#CTRY", sql.in("FundId", sql.tbl("FundId", 
        "#FLO", sql.in("GeographicFocus", paste0("(", v, ")"))))))
    z <- c(z, "", sql.Allocations.bulk.Single("Universe", NULL, 
        "#CTRY", "GeographicFocus", c("GeographicFocus", v)))
    z <- c(z, "", sql.Allocations.bulk.EqWtAvg("Universe", NULL, 
        "#CTRY", "GeographicFocus"))
    z <- c(z, "", sql.Allocations.bulk.EqWtAvg("Allocation", 
        "IndustryId", "#INDY", "GeographicFocus"))
    foo <- mk.1wFloMo.IndyFlow.map(T, F)
    v <- paste0("(", paste(foo[, "StyleSector"], collapse = ", "), 
        ")")
    z <- c(z, "", sql.delete("#INDY", sql.in("FundId", sql.tbl("FundId", 
        "#FLO", sql.in("StyleSector", v)))))
    for (j in rownames(foo)) {
        v <- c("StyleSector", foo[j, "StyleSector"])
        r <- c("IndustryId", foo[j, "IndustryId"])
        z <- c(z, "", sql.Allocations.bulk.Single("Allocation", 
            r, "#INDY", "GeographicFocus", v))
    }
    z <- mk.1dFloMo.Sec.rslt(y, z, s, w, "IndustryId", n)
    z
}

#' mk.1dFloMo.Rgn
#' 
#' SQL query for daily/weekly regional flow momentum
#' @param x = a flowdate/YYYYMMDD (backtest start)
#' @param y = a string (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param n = a connection string/connection
#' @param w = a frequency (T/F for daily/weekly)
#' @param h = a filter vector
#' @param u = a boolean (institutional/all share classes)
#' @keywords mk.1dFloMo.Rgn
#' @export
#' @family mk

mk.1dFloMo.Rgn <- function (x, y, n, w, h = "E", u = F) 
{
    z <- c("AsiaXJP", "EurXGB", "JP", "LatAm", "UK", "US", "PacxJP")
    z <- map.rname(vec.ex.filters("macro"), z)
    names(z) <- c("AsiaXJP", "EurXGB", "Japan", "LatAm", "UK", 
        "USA", "PacXJP")
    z <- sql.1dFloMo.CtrySG(x, y, z, w, h, u)
    z <- sql.query(z, n)
    z
}

#' mk.1dFloMo.Sec
#' 
#' SQL query for daily/weekly CBE flow momentum
#' @param x = a flowdate/YYYYMMDD (depending on whether daily/weekly)
#' @param y = a string (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param n = a connection string/connection
#' @param w = a frequency (T/F for daily/weekly or D/W/M)
#' @param h = a list (elements Region/Filter/Group)
#' @param u = a boolean (foreign/all allocations)
#' @param v = a boolean (institutional/all share classes)
#' @keywords mk.1dFloMo.Sec
#' @export
#' @family mk

mk.1dFloMo.Sec <- function (x, y, n, w, h, u = F, v = F) 
{
    g <- yyyymmdd.to.AllocMo.unique(x, 23, F)
    s <- sql.1dFloMo.CountryId.List("Sector", x)
    r <- vec.ex.filters("sector")
    if (any(h$Region == names(r))) {
        h$Region <- txt.parse(r[h$Region], ",")
    }
    else if (h$Region == "All") {
        h$Region <- mat.read(parameters("classif-Ctry"))
        h$Region <- rownames(h$Region)[!is.na(h$Region$CountryId)]
    }
    else {
        stop("Can't handle yet!")
    }
    h$Region <- vec.named(Ctry.info(h$Region, "CountryId"), h$Region)
    r <- list(A = paste0("CountryId in (", paste(h$Region, collapse = ", "), 
        ")"))
    r[["B"]] <- paste0("ReportDate = '", yyyymm.to.day(g), "'")
    z <- c("FundId", h$Group, "Universe = sum(Allocation)")
    z <- sql.Allocation(z, "Country", h$Group, "E", sql.and(r), 
        paste(z[-length(z)], collapse = ", "))
    z <- c("insert into", paste0("\t#CTRY (FundId, ", h$Group, 
        ", Universe)"), sql.unbracket(z))
    z <- c(sql.index("#CTRY", "FundId"), z)
    z <- c(paste0("create table #CTRY (FundId int not null, ", 
        h$Group, " int, Universe float)"), z)
    g <- paste0("ReportDate = '", yyyymm.to.day(g), "'")
    g <- sql.Allocation.Sec(g, h$Group)
    g <- c(sql.index("#SEC", "FundId, SectorId"), g)
    g <- c(paste0("create table #SEC (FundId int not null, SectorId int not null, ", 
        h$Group, " int, Allocation float)"), g)
    z <- c(z, "", g)
    g <- mat.read(parameters("classif-GeoId"), "\t")
    g <- paste(rownames(g)[is.element(g[, "xBord"], 1)], collapse = ", ")
    g <- paste0("GeographicFocus not in (", g, ")")
    g <- sql.delete("#CTRY", g)
    z <- c(z, "", g)
    if (v) {
        x <- list(A = wrap(x))
        x[["B"]] <- sql.in("SCID", sql.tbl("SCID", "ShareClass", 
            "InstOrRetail = 'Inst'"))
    }
    else x <- list(A = wrap(x))
    if (u) {
        u <- paste(names(h$Region), collapse = "', '")
        u <- paste0("Domicile not in ('", u, "')")
        u <- c(h$Filter, u)
    }
    else u <- h$Filter
    g <- c(h$Group, "StyleSector")
    r <- c(sql.Flow.tbl(w, F), "FundId")
    g <- c(r, paste0(g, " = max(", g, ")"), paste0(y, " = sum(", 
        y, ")"))
    g <- sql.Flow(g, x, u, c(h$Group, "StyleSector"), w, paste(r, 
        collapse = ", "))
    g <- c("insert into", paste0("\t#FLO (", paste(c(r, h$Group, 
        "StyleSector", y), collapse = ", "), ")"), sql.unbracket(g))
    g <- c(sql.index("#FLO", paste(r, collapse = ", ")), g)
    g <- c(paste0("create table #FLO (", r[1], " datetime not null, FundId int not null, ", 
        h$Group, " int, StyleSector int, ", paste(paste(y, "float"), 
            collapse = ", "), ")"), g)
    z <- c(z, "", g)
    g <- paste(Ctry.info(names(h$Region), "GeoId"), collapse = ", ")
    z <- c(z, "", sql.delete("#CTRY", sql.in("FundId", sql.tbl("FundId", 
        "#FLO", sql.in("GeographicFocus", paste0("(", g, ")"))))))
    z <- c(z, "", sql.Allocations.bulk.Single("Universe", NULL, 
        "#CTRY", h$Group, c("GeographicFocus", g)))
    z <- c(z, "", sql.Allocations.bulk.EqWtAvg("Universe", NULL, 
        "#CTRY", h$Group))
    z <- c(z, "", sql.Allocations.bulk.EqWtAvg("Allocation", 
        "SectorId", "#SEC", h$Group))
    foo <- mk.1wFloMo.IndyFlow.map(F, F)
    g <- paste0("(", paste(foo[, "StyleSector"], collapse = ", "), 
        ")")
    z <- c(z, "", sql.delete("#SEC", sql.in("FundId", sql.tbl("FundId", 
        "#FLO", sql.in("StyleSector", g)))))
    foo <- map.rname(foo, c(rownames(foo), "FinsExREst"))
    foo["FinsExREst", "SectorId"] <- 30
    foo["FinsExREst", "StyleSector"] <- foo["Fins", "StyleSector"]
    foo["Fins", "StyleSector"] <- paste(foo[c("Fins", "REst"), 
        "StyleSector"], collapse = ", ")
    for (j in rownames(foo)) {
        g <- c("StyleSector", foo[j, "StyleSector"])
        r <- c("SectorId", foo[j, "SectorId"])
        z <- c(z, "", sql.Allocations.bulk.Single("Allocation", 
            r, "#SEC", h$Group, g))
    }
    z <- mk.1dFloMo.Sec.rslt(y, z, s, w, "SectorId", n)
    z
}

#' mk.1dFloMo.Sec.rslt
#' 
#' gets, and formats, flow momentum output
#' @param x = a string (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param y = flow momentum output
#' @param n = a numeric vector (sector codes indexed by SectorId)
#' @param w = a frequency (T/F for daily/weekly or D/W/M)
#' @param h = a string (IndustryId/SectorId)
#' @param u = a connection string/connection
#' @keywords mk.1dFloMo.Sec.rslt
#' @export
#' @family mk

mk.1dFloMo.Sec.rslt <- function (x, y, n, w, h, u) 
{
    if (h == "SectorId") 
        z <- "#SEC"
    else z <- "#INDY"
    y <- paste(c(sql.drop(c("#FLO", "#CTRY", z)), "", y), collapse = "\n")
    g <- sql.1dFloMo.Sec.topline(h, x, z, w)
    y <- sql.query(c(y, g), u, F)
    w <- sql.Flow.tbl(w, F)
    y[, h] <- map.rname(n, y[, h])
    y <- y[!is.na(y[, h]), c(h, w, x)]
    if (length(x) > 1) 
        y <- reshape.long(y, x, "item")
    z <- reshape.wide(y)
    z
}

#' mk.1dFloTrend.Ctry
#' 
#' SQL query for daily/weekly FloTrend
#' @param x = a flowdate/YYYYMMDD (depending on whether daily/weekly)
#' @param y = factor (one of FloTrend/FloDiff/FloDiff2)
#' @param n = a string (one of Ctry/FX/Sector)
#' @param w = a connection string/connection
#' @param h = a frequency (T/F for daily/weekly)
#' @param u = a filter vector
#' @keywords mk.1dFloTrend.Ctry
#' @export
#' @family mk

mk.1dFloTrend.Ctry <- function (x, y, n, w, h, u = "E") 
{
    s <- yyyymmdd.to.AllocMo.unique(x, 23, F)
    n <- sql.1dFloMo.CountryId.List(n, x)
    v <- sql.1dFloTrend.Alloc(s, "#CTRY", "CountryId", names(n))
    v <- c(v, "", sql.1dFloTrend.Alloc.purge("#CTRY", "CountryId"))
    v <- paste(v, collapse = "\n")
    z <- sql.1dFloTrend.Alloc.from(x, "#CTRY", "CountryId", h, 
        u)
    z <- c(v, sql.1dFloTrend.Alloc.final(z, y, "CountryId", h))
    z <- sql.1dFloTrend.Alloc.data(z, n, w)
    z
}

#' mk.1dFloTrend.Sec
#' 
#' SQL query for daily/weekly FloTrend
#' @param x = a flowdate/YYYYMMDD (depending on whether daily/weekly)
#' @param y = factor (one of FloTrend/FloDiff/FloDiff2)
#' @param n = a connection string/connection
#' @param w = a frequency (T/F for daily/weekly)
#' @param h = a filter vector
#' @keywords mk.1dFloTrend.Sec
#' @export
#' @family mk

mk.1dFloTrend.Sec <- function (x, y, n, w, h) 
{
    s <- yyyymmdd.to.AllocMo.unique(x, 23, F)
    v <- sql.1dFloTrend.Alloc(s, "#SEC", "SectorId")
    v <- c(v, "", "insert into", paste0("\t#SEC (FundId, SectorId, Allocation)"), 
        sql.1dFloTrend.Alloc.fetch(s, "IndustryId", 20, F, T))
    v <- c(v, "", "insert into", paste0("\t#SEC (FundId, SectorId, Allocation)"), 
        sql.1dFloTrend.Alloc.fetch(yyyymm.lag(s), "IndustryId", 
            20, T, T))
    v <- c(v, "", sql.1dFloTrend.Alloc.purge("#SEC", "SectorId"))
    z <- "Allocation = sum(case when SectorId = 20 then -Allocation else Allocation end)"
    z <- c("FundId", "SectorId = 30", z)
    z <- sql.tbl(z, "#SEC", "SectorId in (7, 20)", "FundId")
    v <- c(v, "", "insert into", paste0("\t#SEC (FundId, SectorId, Allocation)"), 
        sql.unbracket(z))
    v <- paste(v, collapse = "\n")
    z <- sql.1dFloTrend.Alloc.from(x, "#SEC", "SectorId", w, 
        h)
    z <- c(v, sql.1dFloTrend.Alloc.final(z, y, "SectorId", w))
    z <- sql.1dFloTrend.Alloc.data(z, sql.1dFloMo.CountryId.List("Sector"), 
        n)
    z
}

#' mk.1mActPas.Ctry
#' 
#' Generates the SQL query to get monthly AIS for countries
#' @param x = a YYYYMM
#' @param y = a connection string/connection
#' @keywords mk.1mActPas.Ctry
#' @export
#' @family mk

mk.1mActPas.Ctry <- function (x, y) 
{
    w <- c("LK", "VE")
    w <- vec.named(w, Ctry.info(w, "CountryId"))
    w <- c(sql.1dFloMo.CountryId.List("Ctry"), w)
    v <- c("CountryId", "Idx", "Allocation = avg(Allocation)")
    z <- list(A = paste0("CountryId in (", paste(names(w), collapse = ", "), 
        ")"))
    z[["B"]] <- paste0("ReportDate = @floDt")
    z <- sql.Allocation(v, "Country", "Idx = isnull(Idx, 'N')", 
        c("CB", "E", "UI"), sql.and(z), paste(v[-length(v)], 
            collapse = ", "))
    z <- sql.declare.wrapper("@floDt", yyyymm.to.day(x), z)
    z <- sql.query(z, y, F)
    z <- map.rname(reshape.wide(z), names(w))
    z <- vec.named(z[, "N"]/nonneg(z[, "Y"]) - 1, w)
    z
}

#' mk.1mActPas.Sec
#' 
#' SQL query for monthly Bullish sector indicator
#' @param x = a YYYYMM
#' @param y = a connection string/connection
#' @param n = one of US/UK/JP/EM/Eurozone
#' @keywords mk.1mActPas.Sec
#' @export
#' @family mk

mk.1mActPas.Sec <- function (x, y, n) 
{
    u <- sql.1dFloMo.CountryId.List("Sector", x)
    z <- list(A = paste0("ReportDate = '", yyyymm.to.day(x), 
        "'"))
    z <- sql.Allocation.Sec(z, "Idx", c("E", n))
    z <- c(sql.index("#SEC", "FundId, SectorId"), z)
    z <- c("create table #SEC (FundId int not null, SectorId int not null, Idx char(1), Allocation float)", 
        z)
    z <- c(z, "", sql.update("#SEC", "Idx = 'N'", , "Idx is NULL"))
    z <- paste(c(sql.drop("#SEC"), "", z), collapse = "\n")
    v <- c("SectorId", "Idx", "Allocation = avg(Allocation)")
    v <- sql.tbl(v, "#SEC", , paste(v[-length(v)], collapse = ", "))
    v <- paste(sql.unbracket(v), collapse = "\n")
    z <- sql.query(c(z, v), y, F)
    z <- map.rname(reshape.wide(z), names(u))
    z <- vec.named(z[, "N"]/nonneg(z[, "Y"]) - 1, u)
    z
}

#' mk.1mAllocMo
#' 
#' Returns a flow variable with the same row space as <n>
#' @param x = a YYYYMM
#' @param y = factors and filters
#' @param n = a StockFlows environment
#' @keywords mk.1mAllocMo
#' @export
#' @family mk

mk.1mAllocMo <- function (x, y, n) 
{
    x <- yyyymm.lag(x, 1)
    w <- is.element(y, c("Inst", "Retail"))
    if (any(w)) {
        w <- y[w][1]
        y <- setdiff(y, w)
    }
    else w <- "All"
    if (y[1] == "AllocSkew") {
        z <- sql.1mAllocSkew(x, y, n$DB, F, w)
    }
    else if (y[1] == "ShsSurp") {
        if (w != "All") 
            stop("Bad share-class!")
        z <- sql.ShsSurp(x, y, n$DB, F)
    }
    else if (y[1] == "SRIAdvisorPct") {
        if (w != "All") 
            stop("Bad share-class!")
        z <- sql.1mSRIAdvisorPct(x, y, n$DB, F)
    }
    else if (grepl("^Flo(Dollar|Mo)$", y[1])) {
        if (w != "All") 
            stop("Bad share-class!")
        z <- sql.1mHoldAum(x, y, n$DB, F, "All")
    }
    else if (y[1] == "Bullish") {
        if (w != "All") 
            stop("Bad share-class!")
        z <- sql.Bullish(x, y, n$DB, F)
    }
    else if (y[1] == "Dispersion") {
        if (w != "All") 
            stop("Bad share-class!")
        z <- sql.Dispersion(x, y, n$DB, F)
    }
    else if (grepl("^(FundCt|Herfindahl|HoldSum|SharesHeld)$", 
        y[1])) {
        z <- sql.1mFundCt(x, y, n$DB, F, "All", 0, w)
    }
    else if (grepl("^AllocD(Inc|Dec|Add|Rem)$", y[1])) {
        if (w != "All") 
            stop("Bad share-class!")
        z <- sql.1mAllocD(x, y, n$DB, F, F)
    }
    else if (grepl("^Alloc(Diff|Trend|Mo)$", y[1])) {
        if (w != "All") 
            stop("Bad share-class!")
        z <- sql.1mAllocD(x, y, n$DB, F, F, "AssetsStart", F, 
            "All", F)
    }
    else if (grepl("^[FS]wtd(In|Ex)0$", y[1])) {
        if (w != "All") 
            stop("Bad share-class!")
        z <- sql.TopDownAllocs(x, y, n$DB, F, "All")
    }
    else {
        stop("Bad Factor")
    }
    z <- sql.map.classif(z, n$conn, n$classif)
    z
}

#' mk.1mBullish.Ctry
#' 
#' SQL query for monthly Bullish country indicator
#' @param x = a YYYYMM
#' @param y = a connection string/connection
#' @keywords mk.1mBullish.Ctry
#' @export
#' @family mk

mk.1mBullish.Ctry <- function (x, y) 
{
    u <- c("LK", "VE")
    u <- vec.named(u, Ctry.info(u, "CountryId"))
    u <- c(sql.1dFloMo.CountryId.List("Ctry"), u)
    z <- list(A = paste0("ReportDate = '", yyyymm.to.day(x), 
        "'"))
    z[["B"]] <- paste0("CountryId in (", paste(names(u), collapse = ", "), 
        ")")
    v <- c("FundId", "CountryId", "BenchIndex", "Idx", "Allocation")
    z <- sql.unbracket(sql.Allocation(v, "Country", c("BenchIndex", 
        "Idx"), "E", sql.and(z)))
    z <- c("insert into", paste0("\t#CTRY (", paste(v, collapse = ", "), 
        ")"), z)
    z <- sql.1mBullish.Alloc(z, "CountryId", "#CTRY")
    v <- sql.1mBullish.Final("CountryId", "#CTRY")
    z <- mk.1mBullish.rslt(c(z, v), y, u)
    z
}

#' mk.1mBullish.rslt
#' 
#' final result for monthly Bullish indicator
#' @param x = a SQL query
#' @param y = a connection string/connection
#' @param n = map of sector code to name
#' @keywords mk.1mBullish.rslt
#' @export
#' @family mk

mk.1mBullish.rslt <- function (x, y, n) 
{
    z <- sql.query(x, y, F)
    z <- mat.index(z)
    z <- map.rname(z, names(n))
    names(z) <- n
    z
}

#' mk.1mBullish.Sec
#' 
#' SQL query for monthly Bullish sector indicator
#' @param x = a YYYYMM
#' @param y = a connection string/connection
#' @param n = one of US/UK/JP/EM/Eurozone
#' @keywords mk.1mBullish.Sec
#' @export
#' @family mk

mk.1mBullish.Sec <- function (x, y, n) 
{
    u <- sql.1dFloMo.CountryId.List("Sector", x)
    z <- list(A = paste0("ReportDate = '", yyyymm.to.day(x), 
        "'"))
    z <- sql.Allocation.Sec(z, c("BenchIndex", "Idx"), c("E", 
        n))
    z <- sql.1mBullish.Alloc(z, "SectorId", "#SEC")
    v <- sql.1mBullish.Final("SectorId", "#SEC")
    z <- mk.1mBullish.rslt(c(z, v), y, u)
    z
}

#' mk.1mFloMo.Ctry
#' 
#' SQL query for monthly CBE flow momentum
#' @param x = a YYYYMM
#' @param y = a string (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param n = a string (one of Ctry/FX/Sector)
#' @param w = a connection string/connection
#' @param h = a filter vector
#' @keywords mk.1mFloMo.Ctry
#' @export
#' @family mk

mk.1mFloMo.Ctry <- function (x, y, n, w, h = "E") 
{
    n <- sql.1dFloMo.CountryId.List(n)
    v <- list(A = paste0("ReportDate = '", yyyymm.to.day(yyyymm.lag(x)), 
        "'"))
    v[["B"]] <- paste0("CountryId in (", paste(names(n), collapse = ", "), 
        ")")
    v <- sql.Allocation(c("FundId", "CountryId", "Allocation"), 
        "Country", , , sql.and(v))
    r <- c("MonthEnding", "FundId", y)
    z <- sql.Flow(r, wrap(yyyymm.to.day(x)), c("CB", h, "UI"), 
        , "M")
    z <- c(sql.label(z, "t1"), "inner join", sql.label(v, "t2"), 
        "\ton t2.FundId = t1.FundId")
    z <- mk.1dFloMo.Ctry.data(z, y, r, w)
    z <- mk.1dFloMo.Ctry.rslt(y, z, n)
    z
}

#' mk.1wFloMo.CtryFlow
#' 
#' Country flows using all funds
#' @param x = a flowdate/month end
#' @param y = a filter vector (first element MUST BE FundType)
#' @param n = a string vector (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param w = a string (one of Ctry/LatAm)
#' @param h = a connection string/connection
#' @param u = a frequency (T/F for daily/weekly or D/W/M)
#' @keywords mk.1wFloMo.CtryFlow
#' @export
#' @family mk

mk.1wFloMo.CtryFlow <- function (x, y, n, w, h, u = "W") 
{
    w <- sql.1dFloMo.CountryId.List(w)
    w <- Ctry.info(w, c("GeoId", "CountryId"))
    colnames(w)[1] <- "GeographicFocus"
    z <- list(MAP = w)
    z <- mk.1wFloMo.CtryFlow.data(x, y, n, z, h, u, "CB")
    z <- mk.1wFloMo.CtryFlow.rslt(z)
    z
}

#' mk.1wFloMo.CtryFlow.data
#' 
#' data for country-flow computation
#' @param x = a month end/flowdate/YYYYMMDD
#' @param y = a filter vector (first element MUST BE FundType)
#' @param n = a string vector (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param w = result object with element MAP
#' @param h = a connection string/connection
#' @param u = a frequency (T/F for daily/weekly or D/W/M)
#' @param v = a filter (to define cross-border funds)
#' @keywords mk.1wFloMo.CtryFlow.data
#' @export
#' @family mk

mk.1wFloMo.CtryFlow.data <- function (x, y, n, w, h, u, v) 
{
    h <- sql.connect.wrapper(h)
    if (u == "M") 
        s <- x
    else s <- yyyymmdd.to.AllocMo.unique(x, 23, T)
    w[["SCF"]] <- vec.to.list(x, T)
    z <- paste(w$MAP[!is.na(w$MAP[, 1]), 1], collapse = ", ")
    z <- c(y, paste0(colnames(w$MAP)[1], " in (", z, ")"), "UI")
    w[["SCF"]] <- lapply(w[["SCF"]], function(l) sql.CtryFlow.Flow(l, 
        n, colnames(w$MAP)[1], u, z))
    w[["SCF"]] <- lapply(w[["SCF"]], function(z) sql.query.underlying(z, 
        h$conn, F))
    w[["CBF"]] <- vec.to.list(x, T)
    z <- c(y, v, "UI")
    w[["CBF"]] <- lapply(w[["CBF"]], function(l) sql.CtryFlow.Flow(l, 
        n, "GeographicFocus", u, z))
    w[["CBF"]] <- lapply(w[["CBF"]], function(z) sql.query.underlying(z, 
        h$conn, F))
    n <- gsub("..$", "", colnames(w$MAP)[2])
    z <- sql.CtryFlow.Alloc(w$MAP[, 2], y[1], s, n, v)
    z <- sql.query.underlying(z, h$conn, F)
    sql.close(h)
    w[["CBA"]] <- reshape.wide(z)
    z <- w
    z
}

#' mk.1wFloMo.CtryFlow.local
#' 
#' Country flows using locally-domiciled funds only
#' @param x = a YYYYMMDD
#' @param y = a filter vector (first element MUST BE FundType)
#' @param n = a string vector (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param w = a string (one of Ctry/LatAm)
#' @param h = a connection string/connection
#' @param u = a boolean (weekly/daily)
#' @keywords mk.1wFloMo.CtryFlow.local
#' @export
#' @family mk

mk.1wFloMo.CtryFlow.local <- function (x, y, n, w, h, u = T) 
{
    s <- yyyymm.to.day(yyyymmdd.to.AllocMo.unique(x, 23, F))
    h <- sql.connect.wrapper(h)
    w <- sql.1dFloMo.CountryId.List(w)
    w <- Ctry.info(w, c("GeoId", "CountryId"))
    rslt <- list(MAP = w)
    rslt[["SCF"]] <- list()
    r <- c("GeographicFocus", paste0(n, " = sum(", n, ")"))
    for (j in x) {
        z <- !is.na(w$GeoId)
        z <- vec.named(w[z, "GeoId"], rownames(w)[z])
        names(z) <- ifelse(names(z) == "CL", "CI", names(z))
        z <- paste0("(GeographicFocus = ", z, " and Domicile = '", 
            names(z), "')")
        z <- c("(", paste0("\t\t", c(sql.and(vec.to.list(z), 
            "or"), ")")))
        z <- paste(z, collapse = "\n")
        z <- sql.Flow(r, list(A = "@floDt"), c(y, z, "UI"), "GeographicFocus", 
            !u, "GeographicFocus")
        z <- sql.declare.wrapper("@floDt", j, z)
        rslt[["SCF"]][[j]] <- sql.query.underlying(z, h$conn, 
            F)
    }
    rslt[["CBF"]] <- list()
    v <- c("Domicile", "GeographicFocus")
    r <- c(v, paste0(n, " = sum(", n, ")"))
    for (j in x) {
        z <- sql.Flow(r, list(A = "@floDt"), c(y, "CB", "UI"), 
            v, !u, paste(v, collapse = ", "))
        z <- sql.declare.wrapper("@floDt", j, z)
        rslt[["CBF"]][[j]] <- sql.query.underlying(z, h$conn, 
            F)
    }
    z <- sql.CtryFlow.Alloc(w$CountryId, y[1], s, "Country", 
        "CB")
    rslt[["CBA"]] <- sql.query.underlying(z, h$conn, F)
    sql.close(h)
    v <- vec.named(rownames(w), w[, "CountryId"])
    rslt[["CBA"]][, "CountryId"] <- map.rname(v, rslt[["CBA"]][, 
        "CountryId"])
    rslt[["CBA"]] <- mat.index(rslt[["CBA"]], c("CountryId", 
        "GeographicFocus"))
    for (j in names(rslt[["CBF"]])) {
        v <- rslt[["CBF"]][[j]][, "Domicile"]
        rslt[["CBF"]][[j]][, "Domicile"] <- ifelse(is.element(v, 
            "CI"), "CL", v)
    }
    for (j in names(rslt[["CBF"]])) {
        v <- do.call(paste, rslt[["CBF"]][[j]][, c("Domicile", 
            "GeographicFocus")])
        v <- zav(char.to.num(map.rname(rslt[["CBA"]], v)))/100
        for (k in n) rslt[["CBF"]][[j]][, k] <- rslt[["CBF"]][[j]][, 
            k] * v
    }
    for (j in names(rslt[["CBF"]])) {
        rslt[["CBF"]][[j]][, "ReportDate"] <- rep(j, dim(rslt[["CBF"]][[j]])[1])
        rslt[["CBF"]][[j]] <- rslt[["CBF"]][[j]][, c("ReportDate", 
            "Domicile", n)]
    }
    rslt[["CBF"]] <- Reduce(rbind, rslt[["CBF"]])
    v <- !is.na(w[, "GeoId"])
    w <- vec.named(rownames(w)[v], w[v, "GeoId"])
    for (j in names(rslt[["SCF"]])) {
        rslt[["SCF"]][[j]][, "Domicile"] <- map.rname(w, rslt[["SCF"]][[j]][, 
            "GeographicFocus"])
        rslt[["SCF"]][[j]][, "ReportDate"] <- rep(j, dim(rslt[["SCF"]][[j]])[1])
        rslt[["SCF"]][[j]] <- rslt[["SCF"]][[j]][, c("ReportDate", 
            "Domicile", n)]
    }
    rslt[["SCF"]] <- Reduce(rbind, rslt[["SCF"]])
    rslt <- rbind(rslt[["SCF"]], rslt[["CBF"]])
    z <- aggregate(x = rslt[, n], by = rslt[, c("ReportDate", 
        "Domicile")], FUN = sum)
    if (length(n) == 1) 
        colnames(z) <- ifelse(colnames(z) == "x", n, colnames(z))
    z
}

#' mk.1wFloMo.CtryFlow.rslt
#' 
#' Country flows using all funds
#' @param x = result object with names MAP, CBF, SCF & CBA
#' @keywords mk.1wFloMo.CtryFlow.rslt
#' @export
#' @family mk

mk.1wFloMo.CtryFlow.rslt <- function (x) 
{
    fcn <- function(z) {
        z <- zav(map.rname(mat.index(z), colnames(x[["CBA"]])))
        z <- 0.01 * as.matrix(x[["CBA"]]) %*% as.matrix(z)
        z <- map.rname(z, x[["MAP"]][, 2])
        z
    }
    x[["CBF"]] <- lapply(x[["CBF"]], fcn)
    fcn <- function(z) map.rname(mat.index(z), x[["MAP"]][, 1])
    x[["SCF"]] <- lapply(x[["SCF"]], fcn)
    z <- list()
    for (j in names(x[["CBF"]])) {
        z[[j]] <- zav(x[["SCF"]][[j]]) + zav(x[["CBF"]][[j]])
        rownames(z[[j]]) <- rownames(x[["MAP"]])
        if (dim(x[["CBF"]][[1]])[2] == 1) 
            z[[j]] <- as.matrix(z[[j]])[, 1]
        else z[[j]] <- mat.ex.matrix(z[[j]])
    }
    if (length(x[["CBF"]]) == 1) 
        z <- z[[1]]
    z
}

#' mk.1wFloMo.IndyFlow
#' 
#' Industry/Sector flows
#' @param x = a YYYYMMDD
#' @param y = a string vector (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param n = a connection string/connection
#' @param w = a frequency (T/F for daily/weekly or D/W/M)
#' @param h = a boolean (Industry/Sector flows)
#' @keywords mk.1wFloMo.IndyFlow
#' @export
#' @family mk

mk.1wFloMo.IndyFlow <- function (x, y, n, w, h = T) 
{
    z <- list(MAP = mk.1wFloMo.IndyFlow.map(h, T))
    v <- paste(z$MAP[!is.na(z$MAP[, 1]), 1], collapse = ", ")
    v <- paste0(colnames(z$MAP)[1], " not in (", v, ")")
    z <- mk.1wFloMo.CtryFlow.data(x, "E", y, z, n, w, v)
    z <- mk.1wFloMo.CtryFlow.rslt(z)
    z
}

#' mk.1wFloMo.IndyFlow.map
#' 
#' Industry/Sector flows
#' @param x = a boolean (Industry/Sector flows)
#' @param y = a boolean (forward/reverse map)
#' @keywords mk.1wFloMo.IndyFlow.map
#' @export
#' @family mk

mk.1wFloMo.IndyFlow.map <- function (x, y) 
{
    if (x) 
        x <- c("GIgrp", "IndustryId")
    else x <- c("GSec", "SectorId")
    z <- mat.read(parameters(paste0("classif-", x[1])))[, c("StyleSector", 
        x[2])]
    if (!y) 
        z <- z[!is.na(z[, "StyleSector"]), 2:1]
    z
}

#' mk.ActWt
#' 
#' Active weight
#' @param x = a YYYYMM
#' @param y = a string vector (portfolio and benchmark names)
#' @param n = a StockFlows environment
#' @keywords mk.ActWt
#' @export
#' @family mk

mk.ActWt <- function (x, y, n) 
{
    z <- fetch(y[1], x, 1, paste(n$fldr, "data", sep = "\\"), 
        n$classif)
    w <- fetch(y[2], yyyymm.lag(x), 1, paste(n$fldr, "data", 
        sep = "\\"), n$classif)
    z <- z - w
    z
}

#' mk.Alpha
#' 
#' makes Alpha
#' @param x = a YYYYMM
#' @param y = a string vector (universe, group, variables and weights)
#' @param n = a StockFlows environment
#' @keywords mk.Alpha
#' @export
#' @family mk

mk.Alpha <- function (x, y, n) 
{
    m <- length(y)
    if (m%%2 != 0) 
        stop("Bad Arguments")
    univ <- y[1]
    grp.nm <- y[2]
    vbls <- y[seq(3, m/2 + 1)]
    wts <- renorm(char.to.num(y[seq(m/2 + 2, m)]))/100
    z <- fetch(vbls, x, 1, paste(n$fldr, "derived", sep = "\\"), 
        n$classif)
    grp <- n$classif[, grp.nm]
    mem <- fetch(univ, x, 1, paste0(n$fldr, "\\data"), n$classif)
    z <- mat.zScore(z, mem, grp)
    z <- zav(z)
    z <- as.matrix(z)
    z <- z %*% wts
    z <- char.to.num(z)
    z
}

#' mk.Alpha.daily
#' 
#' makes Alpha
#' @param x = a YYYYMMDD
#' @param y = a string vector (universe, group, variables, weights and T/F for daily)
#' @param n = a StockFlows environment
#' @keywords mk.Alpha.daily
#' @export
#' @family mk

mk.Alpha.daily <- function (x, y, n) 
{
    m <- length(y)
    if ((m - 2)%%3 != 0) 
        stop("Bad Arguments")
    univ <- y[1]
    grp.nm <- y[2]
    wts <- renorm(char.to.num(y[seq((m + 7)/3, (2 * m + 2)/3)]))/100
    vbls <- vec.named(as.logical(y[seq((2 * m + 5)/3, m)]), y[seq(3, 
        (m + 4)/3)])
    vbls[univ] <- F
    z <- matrix(NA, dim(n$classif)[1], length(vbls), F, list(rownames(n$classif), 
        names(vbls)))
    for (i in names(vbls)) {
        if (vbls[i]) 
            x.loc <- x
        else x.loc <- yyyymm.lag(yyyymmdd.to.yyyymm(x))
        if (i == univ) 
            sub.fldr <- "data"
        else sub.fldr <- "derived"
        z[, i] <- fetch(i, x.loc, 1, paste(n$fldr, sub.fldr, 
            sep = "\\"), n$classif)
    }
    z <- mat.ex.matrix(z)
    z$grp <- n$classif[, grp.nm]
    vbls <- setdiff(names(vbls), univ)
    z <- mat.zScore(z[, vbls], z[, univ], z$grp)
    z <- zav(z)
    z <- as.matrix(z)
    z <- z %*% wts
    z <- char.to.num(z)
    z
}

#' mk.avail
#' 
#' Returns leftmost non-NA variable
#' @param x = a YYYYMM/YYYYMMDD
#' @param y = a string vector (elements are: #		:	1) folder to fetch data from #		:	2) first variable to fetch 3) 2nd variable or number of trailing periods #		:	4+) remaining vbls assuming y[3] is not an integer)
#' @param n = a StockFlows environment
#' @keywords mk.avail
#' @export
#' @family mk

mk.avail <- function (x, y, n) 
{
    x <- list(y = x, n = 1, w = paste(n$fldr, y[1], sep = "\\"), 
        h = n$classif)
    if (is.element(y[3], 2:10000)) 
        x[["n"]] <- char.to.num(y[3])
    if (x[["n"]] == 1) 
        x[["x"]] <- y[-1]
    else x[["x"]] <- y[2]
    z <- avail(do.call(fetch, x))
    z
}

#' mk.beta
#' 
#' Computes monthly beta versus relevant benchmark
#' @param x = a YYYYMM
#' @param y = a string vector (benchmark and lookback, e.g. c("Eafe", 12))
#' @param n = a StockFlows environment
#' @keywords mk.beta
#' @export
#' @family mk

mk.beta <- function (x, y, n) 
{
    m <- char.to.num(y[2])
    univ <- y[1]
    w <- parameters.ex.file(dir.parameters("csv"), "IndexReturns-Monthly.csv")
    w <- mat.read(w, ",")
    z <- fetch("Ret", x, m, paste(n$fldr, "data", sep = "\\"), 
        n$classif)
    vec <- map.rname(w, yyyymm.lag(x, m:1 - 1))[, univ]
    vec <- matrix(c(rep(1, m), vec), m, 2, F, list(1:m, c("Intercept", 
        univ)))
    z <- run.cs.reg(z, vec)
    z <- char.to.num(z[, univ])
    z
}

#' mk.EigenCentrality
#' 
#' Returns EigenCentrality with the same row space as <n>
#' @param x = a YYYYMM
#' @param y = factors and filters
#' @param n = a StockFlows environment
#' @keywords mk.EigenCentrality
#' @export
#' @family mk

mk.EigenCentrality <- function (x, y, n) 
{
    x <- yyyymm.lag(x, 1)
    z <- sql.and(list(A = "ReportDate = @floDt", B = sql.in("t1.HSecurityId", 
        sql.RDSuniv(n[["DB"]]))))
    h <- c("Holdings t1", "inner join", "SecurityHistory id on id.HSecurityId = t1.HSecurityId")
    z <- sql.tbl(c("HFundId", "SecurityId"), h, z, "HFundId, SecurityId")
    z <- sql.declare.wrapper("@floDt", yyyymm.to.day(x), z)
    x <- sql.query.underlying(z, n$conn, F)
    x <- x[is.element(x[, "SecurityId"], rownames(n$classif)), 
        ]
    x <- split(x[, "HFundId"], x[, "SecurityId"])
    w <- Reduce(union, x)
    x <- sapply(x, function(z) is.element(w, z))
    rownames(x) <- w
    x <- crossprod(x)
    w <- diag(x) > 9
    x <- x[w, w]
    w <- order(diag(x))
    x <- x[w, w]
    w <- floor(dim(x)[2]/50)
    w <- qtl.fast(diag(x), w)
    diag(x) <- NA
    z <- matrix(F, dim(x)[1], dim(x)[2], F, dimnames(x))
    for (j in 1:max(w)) {
        for (k in 1:max(w)) {
            y <- x[w == j, w == k]
            y <- char.to.num(unlist(y))
            y[!is.na(y)] <- is.element(qtl.fast(y[!is.na(y)], 
                20), 1)
            y[is.na(y)] <- F
            z[w == j, w == k] <- as.logical(y)
        }
    }
    x <- rep(1, dim(z)[1])
    x <- x/sqrt(sum(x^2))
    y <- z %*% x
    y <- y/sqrt(sum(y^2))
    while (sqrt(sum((y - x)^2)) > 1e-06) {
        x <- y
        y <- z %*% x
        y <- y/sqrt(sum(y^2))
    }
    z <- dim(z)[1] * y
    z <- char.to.num(map.rname(z, rownames(n[["classif"]])))
    z
}

#' mk.FloBeta
#' 
#' Computes monthly beta versus common fund flow shock
#' @param x = a YYYYMM
#' @param y = a string vector (connection string and lookback)
#' @param n = a StockFlows environment
#' @keywords mk.FloBeta
#' @export
#' @family mk

mk.FloBeta <- function (x, y, n) 
{
    x <- yyyymm.lag(x, 1)
    m <- char.to.num(y[2])
    y <- y[1]
    w <- common.fund.flow.shock(x, y, m)
    z <- fetch("Ret", x, m, paste(n$fldr, "data", sep = "\\"), 
        n$classif)
    w <- matrix(c(rep(1, m), w), m, 2, F, list(1:m, c("Intercept", 
        "FloBeta")))
    z <- run.cs.reg(z, w)
    z <- char.to.num(z[, "FloBeta"])
    z
}

#' mk.Fragility
#' 
#' Generates the fragility measure set forth in #		:	Greenwood & Thesmar (2011) "Stock Price Fragility"
#' @param x = a YYYYMM
#' @param y = a string vector (length 3, folder/lookback/num. eigenvectors)
#' @param n = a StockFlows environment
#' @keywords mk.Fragility
#' @export
#' @family mk

mk.Fragility <- function (x, y, n) 
{
    trail <- char.to.num(y[2])
    eigen <- char.to.num(y[3])
    y <- y[1]
    x <- yyyymm.lag(x)
    h <- readRDS(paste(y, "FlowPct.r", sep = "\\"))
    h <- t(h[, yyyymm.lag(x, trail:1 - 1)])
    x <- readRDS(paste0(y, "\\HoldingValue-", x, ".r"))
    h <- h[, mat.count(h)[, 1] == trail & is.element(colnames(h), 
        colnames(x))]
    h <- principal.components.covar(h, eigen)
    x <- x[is.element(rownames(x), rownames(n$classif)), is.element(colnames(x), 
        rownames(h))]
    h <- h[is.element(rownames(h), colnames(x)), ]
    h <- h[, rownames(h)]
    h <- tcrossprod(h, x)
    z <- colSums(t(x) * h)
    x <- rowSums(x)^2
    z <- z/nonneg(x)
    z <- char.to.num(map.rname(z, rownames(n$classif)))
    z
}

#' mk.isin
#' 
#' Looks up date from external file and maps on <y[2]>
#' @param x = a YYYYMM/YYYYMMDD
#' @param y = a string vector (object name/file and identifier)
#' @param n = a StockFlows environment
#' @keywords mk.isin
#' @export
#' @family mk

mk.isin <- function (x, y, n) 
{
    if (length(y) == 1) 
        y <- c(y, "isin")
    z <- read.prcRet(y[1])
    z <- vec.named(z[, x], rownames(z))
    z <- map.classif(z, n[["classif"]], y[2])
    z
}

#' mk.Mem
#' 
#' Returns a 1/0 membership vector
#' @param x = a YYYYMM
#' @param y = a numeric vector (FundId)
#' @param n = a StockFlows environment
#' @keywords mk.Mem
#' @export
#' @family mk

mk.Mem <- function (x, y, n) 
{
    y <- sql.in("FundId", paste0("(", paste(y, collapse = ", "), 
        ")"))
    y <- sql.and(list(A = y, B = "ReportDate = @mo"))
    z <- c("Holdings t1", "inner join", "SecurityHistory t2 on t1.HSecurityId = t2.HSecurityId")
    z <- sql.tbl("SecurityId, Mem = sign(max(HoldingValue))", 
        z, y, "SecurityId")
    z <- sql.declare.wrapper("@mo", yyyymm.to.day(x), z)
    z <- zav(sql.map.classif(z, n$conn, n$classif))
    z
}

#' mk.SatoMem
#' 
#' Returns a 1/0 membership vector
#' @param x = a YYYYMM (never used)
#' @param y = a file (containing isin's)
#' @param n = a StockFlows environment
#' @keywords mk.SatoMem
#' @export
#' @family mk

mk.SatoMem <- function (x, y, n) 
{
    n <- n[["classif"]]
    y <- readLines(y)
    z <- vec.to.list(txt.has(colnames(n), "^isin\\d+"))
    fcn <- function(z) is.element(n[, z], y)
    z <- sapply(z, fcn)
    z <- char.to.num(apply(z, 1, max))
    z
}

#' mk.sf.daily
#' 
#' gets data using query generated by <fcn>
#' @param fcn = a fetch function
#' @param x = a flowdate vector list
#' @param y = a connection string
#' @param n = an integer (max queries using same connection)
#' @param w = argument passed down to <fcn>
#' @keywords mk.sf.daily
#' @export
#' @family mk

mk.sf.daily <- function (fcn, x, y, n, w) 
{
    sql.get(function(z, l, k) sql.query(fcn(z, l), k, F), x, 
        y, n, w)
}

#' mk.sqlDump
#' 
#' Returns variable with the same row space as <n>
#' @param x = a YYYYMM
#' @param y = a string vector (file, variable and lag)
#' @param n = a StockFlows environment
#' @keywords mk.sqlDump
#' @export
#' @family mk

mk.sqlDump <- function (x, y, n) 
{
    if (length(y) > 2) 
        x <- yyyymm.lag(x, char.to.num(y[3]))
    z <- paste0(n$fldr, "\\sqlDump\\", y[1], ".", x, ".r")
    z <- readRDS(z)
    z <- z[, y[2]]
    z
}

#' mk.SRIMem
#' 
#' 1/0 depending on whether <y> or more SRI funds own the stock
#' @param x = a YYYYMM
#' @param y = a positive integer
#' @param n = a StockFlows environment
#' @keywords mk.SRIMem
#' @export
#' @family mk

mk.SRIMem <- function (x, y, n) 
{
    x <- yyyymm.lag(x)
    x <- sql.SRI(x, n$DB)
    z <- sql.map.classif(x, n$conn, n$classif)
    z <- char.to.num(!is.na(z) & z >= y)
    z
}

#' mk.vbl.chg
#' 
#' Makes the MoM change in the variable
#' @param x = a YYYYMM
#' @param y = a variable
#' @param n = a StockFlows environment
#' @keywords mk.vbl.chg
#' @export
#' @family mk

mk.vbl.chg <- function (x, y, n) 
{
    z <- fetch(y, x, 2, paste(n$fldr, "data", sep = "\\"), n$classif)
    z <- z[, 2] - z[, 1]
    z
}

#' mk.vbl.diff
#' 
#' Computes the difference of the two variables
#' @param x = a YYYYMM
#' @param y = a variable vector (minuend and subtrahend)
#' @param n = a StockFlows environment
#' @keywords mk.vbl.diff
#' @export
#' @family mk

mk.vbl.diff <- function (x, y, n) 
{
    z <- fetch(y, x, 1, paste(n$fldr, "data", sep = "\\"), n$classif)
    z <- z[, 1] - z[, 2]
    z
}

#' mk.vbl.lag
#' 
#' Lags the variable
#' @param x = a YYYYMM
#' @param y = a string vector (variable, lag, sub-folder)
#' @param n = a StockFlows environment
#' @keywords mk.vbl.lag
#' @export
#' @family mk

mk.vbl.lag <- function (x, y, n) 
{
    x <- yyyymm.lag(x, char.to.num(y[2]))
    z <- fetch(y[1], x, 1, paste(n$fldr, y[3], sep = "\\"), n$classif)
    z
}

#' mk.vbl.max
#' 
#' Computes the maximum of the two variables
#' @param x = a YYYYMM
#' @param y = a variable vector (length 2)
#' @param n = a StockFlows environment
#' @keywords mk.vbl.max
#' @export
#' @family mk

mk.vbl.max <- function (x, y, n) 
{
    z <- fetch(y, x, 1, paste(n$fldr, "data", sep = "\\"), n$classif)
    z <- vec.max(z[, 1], z[, 2])
    z
}

#' mk.vbl.ratio
#' 
#' Computes the ratio of the two variables
#' @param x = a YYYYMM
#' @param y = a variable vector (numerator and denominator)
#' @param n = a StockFlows environment
#' @keywords mk.vbl.ratio
#' @export
#' @family mk

mk.vbl.ratio <- function (x, y, n) 
{
    z <- fetch(y, x, 1, paste(n$fldr, "data", sep = "\\"), n$classif)
    z <- zav(z[, 1])/nonneg(z[, 2])
    z
}

#' mk.vbl.scale
#' 
#' Linearly scales the first variable based on percentiles of the second. #		:	Top decile goes to scaling factor. Bot decile is fixed.
#' @param x = a YYYYMM
#' @param y = a string vector (elements are: #		:	1) the variable to be scaled #		:	2) the secondary variable #		:	3) the universe within which to scale #		:	4) the grouping within which to scale #		:	5) scaling factor on top decile)
#' @param n = a StockFlows environment
#' @keywords mk.vbl.scale
#' @export
#' @family mk

mk.vbl.scale <- function (x, y, n) 
{
    w <- is.element(fetch(y[3], x, 1, paste(n$fldr, "data", sep = "\\"), 
        n$classif), 1)
    h <- n$classif[, y[4]]
    x <- fetch(y[1:2], x, 1, paste(n$fldr, "derived", sep = "\\"), 
        n$classif)
    y <- char.to.num(y[5])
    x[w, 2] <- 1 - fcn.vec.grp(ptile, x[w, 2], h[w])/100
    x[w, 2] <- zav(x[w, 2], 0.5)
    z <- rep(NA, dim(x)[1])
    z[w] <- (x[w, 2] * 5 * (1 - y)/4 + (9 * y - 1)/8) * x[w, 
        1]
    z
}

#' mk.vbl.sum
#' 
#' Computes the sum of the two variables
#' @param x = a YYYYMM
#' @param y = a variable vector
#' @param n = a StockFlows environment
#' @keywords mk.vbl.sum
#' @export
#' @family mk

mk.vbl.sum <- function (x, y, n) 
{
    z <- fetch(y, x, 1, paste(n$fldr, "data", sep = "\\"), n$classif)
    z <- z[, 1] + z[, 2]
    z
}

#' mk.vbl.trail.fetch
#' 
#' compounded variable over some trailing window
#' @param x = a YYYYMM/YYYYMMDD
#' @param y = a string vector (elements are: #		:	1) variable to fetch (e.g. "AllocMo"/"AllocDiff"/"AllocTrend"/"Ret") #		:	2) number of trailing periods to use (e.g. "11") #		:	3) number of periods to lag (defaults to "0") #		:	4) sub-folder to fetch basic variable from (defaults to "derived") #		:	5) T/F depending on whether the compounded) variable is daily (defaults to F, matters only if <x> is monthly))
#' @param n = a StockFlows environment
#' @keywords mk.vbl.trail.fetch
#' @export
#' @family mk

mk.vbl.trail.fetch <- function (x, y, n) 
{
    if (length(y) == 2) 
        y <- c(y, 0, "derived", F)
    if (length(y) == 3) 
        y <- c(y, "derived", F)
    if (length(y) == 4) 
        y <- c(y, F)
    m <- char.to.num(y[2])
    trail <- m + char.to.num(y[3])
    if (nchar(x) == 6 & as.logical(y[5])) 
        x <- yyyymmdd.ex.yyyymm(x)
    z <- fetch(y[1], x, trail, paste(n$fldr, y[4], sep = "\\"), 
        n$classif)
    z <- z[, 1:m]
    z
}

#' mk.vbl.trail.sum
#' 
#' compounded variable over some trailing window
#' @param x = a YYYYMM/YYYYMMDD
#' @param y = a string vector (elements are: #		:	1) variable to fetch (e.g. "1mAllocMo"/"1dAllocDiff"/"1dAllocTrend"/"Ret") #		:	2) T to sum or F to compound (e.g. "T") #		:	3) number of trailing periods to use (e.g. "11") #		:	4) number of periods to lag (defaults to "0") #		:	5) sub-folder to fetch basic variable from (defaults to "derived")) #		:	6) T/F depending on whether the compounded variable is daily (defaults to F, matters only if <x> is monthly)
#' @param n = a StockFlows environment
#' @keywords mk.vbl.trail.sum
#' @export
#' @family mk

mk.vbl.trail.sum <- function (x, y, n) 
{
    z <- mk.vbl.trail.fetch(x, y[-2], n)
    z <- compound.sf(z, as.logical(y[2]))
    z <- char.to.num(z)
    z
}

#' mk.vbl.vol
#' 
#' volatility of variable over some trailing window
#' @param x = a YYYYMM/YYYYMMDD
#' @param y = a string vector (elements are: #		:	1) variable to fetch (e.g. "AllocMo"/"AllocDiff"/"AllocTrend"/"Ret") #		:	2) number of trailing periods to use (e.g. "11") #		:	3) number of periods to lag (defaults to "0") #		:	4) sub-folder to fetch basic variable from (defaults to "derived") #		:	5) T/F depending on whether the compounded variable is daily (defaults to F, matters only if <x> is monthly))
#' @param n = a StockFlows environment
#' @keywords mk.vbl.vol
#' @export
#' @family mk

mk.vbl.vol <- function (x, y, n) 
{
    z <- mk.vbl.trail.fetch(x, y, n)
    z <- apply(z, 1, sd)
    z <- char.to.num(z)
    z
}

#' mk.Wt
#' 
#' Generates the SQL query to get monthly index weight for individual stocks
#' @param x = a YYYYMM
#' @param y = FundId of the fund of interest
#' @param n = a StockFlows environment
#' @keywords mk.Wt
#' @export
#' @family mk

mk.Wt <- function (x, y, n) 
{
    y <- sql.and(list(A = sql.in("t1.HFundId", sql.tbl("HFundId", 
        "FundHistory", paste("FundId =", y))), B = "ReportDate = @mo"))
    z <- c("Holdings t1", "inner join", sql.label(sql.MonthlyAssetsEnd("@mo"), 
        "t3"), "\ton t1.HFundId = t3.HFundId")
    z <- c(z, "inner join", "SecurityHistory t2 on t1.HSecurityId = t2.HSecurityId")
    z <- sql.tbl("SecurityId, Wt = 100 * HoldingValue/AssetsEnd", 
        z, y)
    z <- sql.declare.wrapper("@mo", yyyymm.to.day(x), z)
    z <- zav(sql.map.classif(z, n$conn, n$classif))
    z
}

#' multi.asset
#' 
#' Reads in data relevant to the multi-asset strategy
#' @param x = a file vector
#' @keywords multi.asset
#' @export

multi.asset <- function (x) 
{
    x <- lapply(vec.to.list(x), mat.read)
    z <- Reduce(function(z, l) mat.index(merge(z, l, by = 0)), 
        x)
    z
}

#' nameTo
#' 
#' pct name turnover between <x> and <y> if <x> is a numeric vector or their rows otherwise
#' @param x = a numeric vector/matrix/data frame (no NA's)
#' @param y = a numeric vector/matrix/data frame (no NA's)
#' @keywords nameTo
#' @export

nameTo <- function (x, y) 
{
    fcn <- function(z, l) nameTo.underlying(sum(z), sum(l), sum(z & 
        l))
    z <- fcn.mat.num(fcn, x, y, F)
    z
}

#' nameTo.underlying
#' 
#' percent name turnover
#' @param x = an integer vector (counts over the current period)
#' @param y = an integer vector (counts over the prior period)
#' @param n = an integer vector (count of common names)
#' @keywords nameTo.underlying
#' @export

nameTo.underlying <- function (x, y, n) 
{
    100 - 100 * n/max(x, y)
}

#' nonneg
#' 
#' returns <x> if non-negative or NA otherwise
#' @param x = a numeric vector/matrix/data frame
#' @keywords nonneg
#' @export

nonneg <- function (x) 
{
    fcn <- function(z) ifelse(!is.na(z) & z > 0, z, NA)
    z <- fcn.mat.vec(fcn, x, , T)
    z
}

#' num.exists
#' 
#' T/F depending on whether <x> is a number of type <y>
#' @param x = a string vector
#' @param y = number type
#' @keywords num.exists
#' @export

num.exists <- function (x, y) 
{
    if (y == "N") {
        y <- "^([1-9]\\d*)$"
    }
    else if (y == "W") {
        y <- "^(0|[1-9]\\d*)$"
    }
    else if (y == "Z") {
        y <- "^(0|-?[1-9]\\d*)$"
    }
    else if (y == "Q") {
        y <- "^(0|-?[1-9]\\d*(\\.\\d+)?|-?0?\\.\\d+)$"
    }
    else {
        stop("Unknown number format!")
    }
    z <- grepl(y, x)
    z
}

#' nyse.holidays
#' 
#' returns full day NYSE holidays from the year 2000 and after
#' @param x = either "yyyymmdd" or "reason"
#' @keywords nyse.holidays
#' @export
#' @family nyse

nyse.holidays <- function (x = "yyyymmdd") 
{
    z <- parameters("NyseHolidays")
    z <- scan(z, what = list(yyyymmdd = "", reason = ""), sep = "\t", 
        quote = "", quiet = T)
    z <- z[[x]]
    z
}

#' nyse.lag
#' 
#' falls back one non-NYSE holidays
#' @param x = a flowdate
#' @keywords nyse.lag
#' @export
#' @family nyse

nyse.lag <- function (x) 
{
    z <- flowdate.lag(x, 1)
    x <- nyse.holidays()
    while (any(z == x)) z <- flowdate.lag(z, 1)
    z
}

#' obj.diff
#' 
#' returns <x - y>
#' @param fcn = a function (vector to integer vector)
#' @param x = an object vector
#' @param y = an object vector
#' @keywords obj.diff
#' @export
#' @family obj

obj.diff <- function (fcn, x, y) 
{
    fcn(x) - fcn(y)
}

#' obj.lag
#' 
#' lags <x> by <y>
#' @param x = an object vector
#' @param y = an integer vector
#' @param n = a function (object to value)
#' @param w = a function (bijective inverse of <n>)
#' @keywords obj.lag
#' @export
#' @family obj

obj.lag <- function (x, y, n, w) 
{
    w(n(x) - y)
}

#' obj.seq
#' 
#' returns a sequence of objects between (and including) <x> and <y>
#' @param x = an object
#' @param y = an object
#' @param n = a function (vector to integer vector)
#' @param w = a function (bijective inverse of <n>)
#' @param h = a positive integer
#' @keywords obj.seq
#' @export
#' @family obj

obj.seq <- function (x, y, n, w, h) 
{
    x <- n(x)
    y <- n(y)
    if (x > y) 
        z <- -h
    else z <- h
    z <- seq(x, y, z)
    z <- w(z)
    z
}

#' optimal
#' 
#' Performance statistics of the optimal zero-cost unit-variance portfolio
#' @param x = a matrix/data frame (indicators)
#' @param y = a matrix/data frame (forward returns)
#' @param n = a matrix/data frame (daily returns to train the risk model on)
#' @param w = a numeric vector  (the elements of which are: #		:	1) number of trailing days to train the risk model on #		:	2) number of principal components (when 0 raw return matrix is used) #		:	3) number of bins (when 0, indicator is ptiled) #		:	4) forward return window in days or months depending on the row space of <x>)
#' @keywords optimal
#' @export

optimal <- function (x, y, n, w) 
{
    period.count <- yyyy.periods.count(rownames(x))
    if (w[3] > 0) {
        x <- qtl.eq(x, w[3])
        x <- (1 + w[3] - 2 * x)/(w[3] - 1)
        x <- ifelse(!is.na(x) & abs(x) < 1, 0, x)
    }
    else x <- ptile(x)
    for (j in rownames(x)) {
        if (period.count == 260) 
            z <- j
        else z <- yyyymmdd.ex.yyyymm(j)
        z <- map.rname(n, flowdate.lag(z, w[1]:1 - 1))
        z <- z[, mat.count(z)[, 1] == w[1] & !is.na(x[j, ])]
        if (w[2] != 0) {
            z <- principal.components.covar(z, w[2])
        }
        else {
            z <- covar(z)/(1 - 1/w[1] + 1/w[1]^2)
        }
        opt <- solve(z) %*% map.rname(x[j, ], colnames(z))
        unity <- solve(z) %*% rep(1, dim(z)[1])
        opt <- opt - unity * char.to.num(crossprod(opt, z) %*% 
            unity)/char.to.num(crossprod(unity, z) %*% unity)
        opt <- opt[, 1]/sqrt(260 * (crossprod(opt, z) %*% opt)[1, 
            1])
        x[j, ] <- zav(map.rname(opt, colnames(x)))
    }
    x <- rowSums(x * zav(y))
    y <- period.count/w[4]
    z <- vec.named(, c("AnnMn", "AnnSd", "Sharpe", "HitRate"))
    z["AnnMn"] <- mean(x) * y
    z["AnnSd"] <- sd(x) * sqrt(y)
    z["Sharpe"] <- 100 * z["AnnMn"]/z["AnnSd"]
    z["HitRate"] <- mean(sign(x)) * 50
    z <- z/100
    z
}

#' parameters
#' 
#' returns full path to relevant parameters file
#' @param x = parameter type
#' @keywords parameters
#' @export

parameters <- function (x) 
{
    parameters.ex.file(dir.parameters("parameters"), paste0(x, 
        ".txt"))
}

#' parameters.ex.file
#' 
#' path to function source file
#' @param x = a folder vector
#' @param y = a string (file names)
#' @keywords parameters.ex.file
#' @export

parameters.ex.file <- function (x, y) 
{
    w <- grepl("^<EXTERNAL>", x)
    x <- ifelse(w, "C:\\EPFR", x)
    z <- paste0(x, "\\", y)
    w <- file.exists(z)
    if (any(!w)) 
        err.raise(z[!w], T, "WARNING: The following files do not exist")
    z
}

#' permutations
#' 
#' all possible permutations of <x>
#' @param x = a string vector without NA's
#' @keywords permutations
#' @export

permutations <- function (x) 
{
    h <- length(x)
    w <- 1:h
    z <- NULL
    while (!is.null(w)) {
        z <- c(z, paste(x[w], collapse = " "))
        w <- permutations.next(w)
    }
    z
}

#' permutations.next
#' 
#' returns the next permutation in dictionary order
#' @param x = an integer vector (seq_along(<x>) in some order)
#' @keywords permutations.next
#' @export

permutations.next <- function (x) 
{
    z <- x
    n <- length(z)
    j <- n - 1
    while (z[j] > z[j + 1] & j > 1) j <- j - 1
    if (z[j] > z[j + 1]) {
        z <- NULL
    }
    else {
        k <- n
        while (z[j] > z[k]) k <- k - 1
        z <- vec.swap(z, j, k)
        r <- n
        s <- j + 1
        while (r > s) {
            z <- vec.swap(z, r, s)
            r <- r - 1
            s <- s + 1
        }
    }
    z
}

#' pivot
#' 
#' returns a table, the rows and columns of which are unique members of rowIdx and colIdx The cells of the table are the <fcn> of <x> whenever <y> and <n> take on their respective values
#' @param fcn = a function (summary)
#' @param x = a numeric vector
#' @param y = a numeric vector (groups)
#' @param n = a numeric vector (groups)
#' @keywords pivot
#' @export

pivot <- function (fcn, x, y, n) 
{
    z <- aggregate(x = x, by = list(row = y, col = n), FUN = fcn)
    z <- reshape.wide(z)
    z
}

#' pivot.1d
#' 
#' returns a table, having the same column space of <x>, the rows of which are unique members of <grp> The cells of the table are the summ.fcn of <x> whenever <grp> takes on its respective value
#' @param fcn = a function (summary)
#' @param x = a string vector (groups)
#' @param y = a string vector/matrix/data frame
#' @keywords pivot.1d
#' @export

pivot.1d <- function (fcn, x, y) 
{
    z <- aggregate(x = y, by = list(grp = x), FUN = fcn)
    z <- mat.index(z)
    z
}

#' plurality.map
#' 
#' returns a map from <x> to <y>
#' @param x = a numeric vector
#' @param y = a numeric vector
#' @keywords plurality.map
#' @export

plurality.map <- function (x, y) 
{
    x <- list(x = x, y = y, obs = rep(1, length(x)), pct = rep(1, 
        length(x)))
    w <- Reduce("&", lapply(x, function(z) !is.na(z)))
    x <- lapply(x, function(z) z[w])
    z <- aggregate(obs ~ x + y, data = x, sum)
    x <- aggregate(pct ~ x, data = x, sum)
    z <- z[order(z[, "obs"], decreasing = T), ]
    z <- z[!duplicated(z[, "x"]), ]
    z <- merge(z, x)
    z[, "pct"] <- 100 * z[, "obs"]/z[, "pct"]
    z <- z[order(z[, "pct"], decreasing = T), ]
    z
}

#' portfolio.beta.wrapper
#' 
#' <n> day beta of columns of <x> with respect to benchmark <y>
#' @param x = a matrix/data frame (total return indices)
#' @param y = a string (benchmark like "ACWorld")
#' @param n = a positive integer (lookback in days)
#' @keywords portfolio.beta.wrapper
#' @export
#' @family portfolio

portfolio.beta.wrapper <- function (x, y, n) 
{
    y <- map.rname(mat.read(parameters.ex.file(dir.parameters("csv"), 
        "IndexReturns-Daily.csv")), rownames(x))[, y]
    x[, "Benchmark"] <- y
    z <- mat.ex.matrix(ret.ex.idx(x, 1, F, T))[-1, ]
    z <- list(x = z, xy = z * z[, "Benchmark"])
    z <- lapply(z, function(z) mat.rollsum(z, n))
    z <- z[["xy"]]/n - z[["x"]] * z[["x"]][, "Benchmark"]/n^2
    z <- z[, colnames(z) != "Benchmark"]/nonneg(z[, "Benchmark"])
    z
}

#' portfolio.residual
#' 
#' residual of <x> after factoring out <y> for each row
#' @param x = a matrix/data frame
#' @param y = a matrix/data frame
#' @keywords portfolio.residual
#' @export
#' @family portfolio

portfolio.residual <- function (x, y) 
{
    y <- bbk.holidays(y, x)
    x <- t(scale(t(x), scale = F))
    y <- t(scale(t(y), scale = F))
    z <- x - y * rowSums(x * y, na.rm = T)/nonneg(rowSums(y^2, 
        na.rm = T))
    z
}

#' position.floPct
#' 
#' Latest four-week flow percentage
#' @param x = a file (strategy)
#' @param y = a string vector (to subset to, can be missing)
#' @param n = last publication date
#' @keywords position.floPct
#' @export

position.floPct <- function (x, y, n) 
{
    x <- strat.path(x, "daily")
    x <- multi.asset(x)
    if (all(n != rownames(x))) {
        cat("Date", n, "not recognized! No output will be published ..\n")
        z <- NULL
    }
    else {
        if (rownames(x)[dim(x)[1]] != n) {
            cat("Warning: Latest data not being used! Proceeding regardless ..\n")
            x <- x[rownames(x) <= n, ]
        }
        if (missing(y)) 
            y <- colnames(x)
        else x <- mat.subset(x, y)
        z <- x[dim(x)[1] - 19:0, ]
        z <- vec.named(mat.compound(t(z)), y)
        z <- z[order(-z)]
        x <- x[dim(x)[1] - 19:0 - 5, ]
        x <- vec.named(mat.compound(t(x)), y)
        x <- map.rname(x, names(z))
        x <- rank(z) - rank(x)
        y <- vec.named(qtl.eq(z), names(z))
        y <- mat.ex.vec(y, z)
        z <- 0.01 * data.frame(z, 100 * x, y)
        colnames(z)[1:2] <- c("Current", "RankChg")
    }
    z
}

#' principal.components
#' 
#' first <y> principal components
#' @param x = a matrix/data frame
#' @param y = an integer (num. princ. comp. wanted)
#' @keywords principal.components
#' @export
#' @family principal

principal.components <- function (x, y = 2) 
{
    principal.components.underlying(x, y)$factor
}

#' principal.components.covar
#' 
#' covariance using first <y> components as factors
#' @param x = a matrix/data frame
#' @param y = an integer (num. important principal components)
#' @keywords principal.components.covar
#' @export
#' @family principal

principal.components.covar <- function (x, y) 
{
    z <- principal.components.underlying(x, y)
    if (is.null(dim(z$factor))) {
        z <- tcrossprod(as.matrix(z$factor), as.matrix(z$exposure))
    }
    else {
        z <- tcrossprod(z$factor, z$exposure)
    }
    x <- x - z
    z <- crossprod(z)/(dim(x)[1] - 1)
    diag(z) <- diag(z) + colSums(x^2)/(dim(x)[1] - 1)
    z
}

#' principal.components.underlying
#' 
#' first <y> principal components
#' @param x = a matrix/data frame
#' @param y = an integer (num. princ. comp. wanted)
#' @keywords principal.components.underlying
#' @export
#' @family principal

principal.components.underlying <- function (x, y) 
{
    x <- scale(x, scale = F)
    z <- svd(x)
    rownames(z$u) <- rownames(x)
    rownames(z$v) <- colnames(x)
    if (y < 1) 
        y <- scree(z$d)
    if (y == 1) {
        z <- list(factor = z$u[, 1] * z$d[1], exposure = z$v[, 
            1])
    }
    else {
        z <- list(factor = z$u[, 1:y] %*% diag(z$d[1:y]), exposure = z$v[, 
            1:y])
    }
    z
}

#' proc.count
#' 
#' returns top <x> processes by number running
#' @param x = number of records to return (0 = everything)
#' @keywords proc.count
#' @export
#' @family proc

proc.count <- function (x = 10) 
{
    z <- shell("tasklist /FO LIST", intern = T)
    z <- z[seq(2, length(z), by = 6)]
    z <- gsub("^.{11}", "", z)
    z <- txt.trim(z)
    z <- vec.count(z)
    z <- z[order(z, decreasing = T)]
    if (x > 0) 
        z <- z[1:x]
    z
}

#' proc.kill
#' 
#' kills off all processes <x>
#' @param x = process name (e.g. "ftp.exe")
#' @keywords proc.kill
#' @export
#' @family proc

proc.kill <- function (x) 
{
    shell(paste("TASKKILL /IM", x, "/F"), intern = T)
}

#' product
#' 
#' product of <x>
#' @param x = a numeric vector
#' @keywords product
#' @export

product <- function (x) 
{
    exp(sum(log(x)))
}

#' production.write
#' 
#' Writes production output if warranted
#' @param x = a matrix/data frame
#' @param y = a file (output)
#' @keywords production.write
#' @export

production.write <- function (x, y) 
{
    proceed <- !is.null(x)
    if (proceed) {
        w <- mat.read(y, ",")
        proceed <- dim(w)[2] == dim(x)[[2]]
    }
    if (proceed) 
        proceed <- all(colnames(w) == colnames(x))
    if (proceed) 
        proceed <- dim(x)[1] > dim(w)[1]
    if (proceed) 
        proceed <- all(is.element(rownames(w), rownames(x)))
    if (proceed) 
        proceed <- all(colSums(mat.to.obs(x[rownames(w), ])) == 
            colSums(mat.to.obs(w)))
    if (proceed) 
        proceed <- all(unlist(zav(x[rownames(w), ]) == zav(w)))
    if (proceed) {
        mat.write(x, y)
        cat("Writing to", y, "..\n")
    }
    invisible()
}

#' pstudent2
#' 
#' Returns cumulative t-distribution with df = 2
#' @param x = any real number
#' @keywords pstudent2
#' @export

pstudent2 <- function (x) 
{
    return(pt(x, 2))
}

#' ptile
#' 
#' Converts <x>, if a numeric vector, or the rows of <x> otherwise, to a ptile
#' @param x = a numeric vector/matrix/data frame
#' @keywords ptile
#' @export

ptile <- function (x) 
{
    fcn <- function(z) 100 * (rank(z) - 1)/(length(z) - 1)
    fcn2 <- function(z) fcn.nonNA(fcn, z)
    z <- fcn.mat.vec(fcn2, x, , F)
    z
}

#' publications.data
#' 
#' additional data is got and stale data removed
#' @param x = a flowdate vector
#' @param y = a SQL query/function
#' @param n = a folder
#' @param w = a connection string
#' @keywords publications.data
#' @export

publications.data <- function (x, y, n, w) 
{
    h <- dir(n, "\\.csv$")
    if (length(h) > 0) 
        h <- h[!is.element(h, paste0(x, ".csv"))]
    if (length(h) > 0) {
        err.raise(h, F, paste("Removing the following from", 
            n))
        file.kill(paste(n, h, sep = "\\"))
    }
    h <- dir(n, "\\.csv$")
    if (length(h) > 0) {
        h <- gsub(".{4}$", "", h)
        x <- x[!is.element(x, h)]
    }
    if (length(x) > 0) {
        cat("Updating", n, "for the following periods:\n")
        x <- vec.to.list(x, T)
        if (is.function(y)) {
            h <- function(z, l) y(z)
        }
        else {
            h <- function(z, l) txt.replace(y, "YYYYMMDD", z)
        }
        x <- mk.sf.daily(h, x, w, 12, "All")
        for (i in names(x)) mat.write(x[[i]], paste0(n, "\\", 
            i, ".csv"), ",")
    }
    invisible()
}

#' publish.daily.last
#' 
#' last daily flow-publication date
#' @param x = a YYYYMMDD (can be missing)
#' @keywords publish.daily.last
#' @export
#' @family publish

publish.daily.last <- function (x) 
{
    if (missing(x)) 
        x <- today()
    z <- flowdate.lag(x, 2)
    z
}

#' publish.monthly.last
#' 
#' date of last monthly publication
#' @param x = a YYYYMMDD (can be missing)
#' @param y = calendar day allocations are known the next month
#' @param n = an integer
#' @keywords publish.monthly.last
#' @export
#' @family publish

publish.monthly.last <- function (x, y = 23, n = 0) 
{
    if (missing(x)) 
        x <- today()
    z <- yyyymmdd.lag(x, 1)
    z <- yyyymmdd.to.AllocMo(z, y)
    z <- yyyymm.lag(z, n)
    z <- yyyymm.to.day(z)
    z
}

#' publish.weekly.last
#' 
#' date of last weekly publication
#' @param x = a YYYYMMDD (can be missing)
#' @keywords publish.weekly.last
#' @export
#' @family publish

publish.weekly.last <- function (x) 
{
    if (missing(x)) 
        x <- today()
    z <- char.to.num(day.to.weekday(x))
    if (any(z == 5:6)) 
        z <- z - 3
    else z <- z + 4
    z <- day.lag(x, z)
    z
}

#' qa.filter.map
#' 
#' maps to appropriate code on the R side
#' @param x = a filter (e.g. Aggregate/Active/Passive/ETF/Mutual)
#' @keywords qa.filter.map
#' @export
#' @family qa

qa.filter.map <- function (x) 
{
    zav(as.character(map.rname(vec.read(parameters("classif-filterNames")), 
        x)), x)
}

#' qa.mat.read
#' 
#' contents of <x> as a data frame
#' @param x = a remote file
#' @param y = local folder (e.g. "C:\\\\temp")
#' @param n = ftp site (can be missing)
#' @param w = user id (can be missing)
#' @param h = password (can be missing)
#' @param u = a string (ftp/sftp)
#' @param v = a boolean (ftp.use.epsv argument of getCurlHandle)
#' @keywords qa.mat.read
#' @export
#' @family qa

qa.mat.read <- function (x, y, n, w, h, u, v) 
{
    z <- as.list(environment())
    z <- z[!sapply(z, is.symbol)]
    do.call(ftp.get, z)
    x <- paste0(y, "\\", ftp.file(x))
    z <- NULL
    if (file.exists(x)) {
        z <- read.EPFR(x)
        Sys.sleep(1)
        file.kill(x)
    }
    z
}

#' qtl
#' 
#' <x> bucketed into <y> bins within groups <w> having equal weights <n>
#' @param x = a numeric vector
#' @param y = an integer (number of bins)
#' @param n = a numeric vector (weights, can be missing)
#' @param w = a string vector (binning groups, can be missing)
#' @keywords qtl
#' @export
#' @family qtl

qtl <- function (x, y, n, w) 
{
    if (missing(n)) 
        n <- rep(1, length(x))
    if (missing(w)) 
        w <- rep(1, length(x))
    h <- !is.na(x) & !is.na(w)
    x <- data.frame(x, n, stringsAsFactors = F)
    fcn <- function(z) qtl.single.grp(z, y)
    z <- rep(NA, length(h))
    if (any(h)) 
        z[h] <- fcn.vec.grp(fcn, x[h, ], w[h])
    z
}

#' qtl.eq
#' 
#' performs an equal-weight binning on <x> if <x> is a numeric vector or the rows of <x> otherwise
#' @param x = a numeric vector/matrix/data frame
#' @param y = an integer (number of bins)
#' @keywords qtl.eq
#' @export
#' @family qtl

qtl.eq <- function (x, y = 5) 
{
    fcn.mat.vec(qtl, x, y, F)
}

#' qtl.fast
#' 
#' performs a FAST equal-weight binning on <x>. Can't handle NAs.
#' @param x = a numeric vector
#' @param y = an integer (number of bins)
#' @keywords qtl.fast
#' @export
#' @family qtl

qtl.fast <- function (x, y = 5) 
{
    x <- order(-x)
    z <- ceiling((length(x)/y) * (0:y) + 0.5) - 1
    z <- z[-1] - z[-(y + 1)]
    z <- rep(1:y, z)[order(x)]
    z
}

#' qtl.single.grp
#' 
#' an equal-weight binning so that the first column of <x> is divided into <y> equal bins. Weights determined by the 2nd column
#' @param x = a data frame (2 columns, numeric, no NA's)
#' @param y = an integer (number of bins)
#' @keywords qtl.single.grp
#' @export
#' @family qtl

qtl.single.grp <- function (x, y) 
{
    if (any(x[, 2] < 0)) 
        stop("Can't handle negative weights!")
    if (sum(x[, 2]) > 0) {
        z <- aggregate(x[2], by = x[1], FUN = sum)
        z[, 2] <- z[, 2]/sum(z[, 2])
        z <- z[order(z[, 1], decreasing = T), ]
        z[, 2] <- cumsum(z[, 2]) - z[, 2]/2
        z[, 2] <- vec.max(ceiling(y * z[, 2]), 1)
        z <- approx(z[, 1], z[, 2], x[, 1], method = "constant", 
            rule = 1:2)[["y"]]
    }
    else z <- rep(NA, dim(x)[1])
    z
}

#' qtr.ex.int
#' 
#' returns = a YYYYMM vector
#' @param x = an integer vector
#' @keywords qtr.ex.int
#' @export
#' @family qtr

qtr.ex.int <- function (x) 
{
    z <- (x - 1)%/%4
    x <- x - 4 * z
    z <- paste(z, x, sep = "Q")
    z <- txt.prepend(z, 6, 0)
    z
}

#' qtr.lag
#' 
#' lags <x> by <y> quarters
#' @param x = a qtr vector
#' @param y = an integer vector
#' @keywords qtr.lag
#' @export
#' @family qtr

qtr.lag <- function (x, y) 
{
    obj.lag(x, y, qtr.to.int, qtr.ex.int)
}

#' qtr.seq
#' 
#' returns a sequence of QTR between (and including) x and y
#' @param x = a qtr
#' @param y = a qtr
#' @param n = a positive integer
#' @keywords qtr.seq
#' @export
#' @family qtr

qtr.seq <- function (x, y, n = 1) 
{
    obj.seq(x, y, qtr.to.int, qtr.ex.int, n)
}

#' qtr.to.int
#' 
#' returns integers
#' @param x = a qtr vector
#' @keywords qtr.to.int
#' @export
#' @family qtr

qtr.to.int <- function (x) 
{
    z <- char.to.num(substring(x, 1, 4))
    z <- 4 * z + char.to.num(substring(x, 6, 6))
    z
}

#' quant.info
#' 
#' folder of function source file
#' @param x = unique identifier of the quant
#' @param y = a string (column in classif-Quants)
#' @keywords quant.info
#' @export

quant.info <- function (x, y) 
{
    mat.read(parameters("classif-Quants"), "\t")[x, y]
}

#' read.EPFR
#' 
#' reads in the file
#' @param x = a file
#' @keywords read.EPFR
#' @export
#' @family read

read.EPFR <- function (x) 
{
    z <- mat.read(x, "\t", NULL)
    z[, 1] <- yyyymmdd.ex.txt(z[, 1])
    colnames(z)[1] <- "ReportDate"
    z
}

#' read.prcRet
#' 
#' returns the contents of the file
#' @param x = a string (object name preceded by # or a file)
#' @keywords read.prcRet
#' @export
#' @family read

read.prcRet <- function (x) 
{
    if (grepl("^#", x)) {
        z <- substring(x, 2, nchar(x))
        z <- get(z)
    }
    else z <- mat.read(x, ",")
    z
}

#' recipient.exists
#' 
#' T/F depending on whether recipient list exists
#' @param x = a string (report name)
#' @keywords recipient.exists
#' @export
#' @family recipient

recipient.exists <- function (x) 
{
    any(is.element(mat.read(parameters("classif-recipient"), 
        "\t", NULL)[, 1], x))
}

#' recipient.read
#' 
#' vector of recipient tranches
#' @param x = a string (report name)
#' @keywords recipient.read
#' @export
#' @family recipient

recipient.read <- function (x) 
{
    z <- mat.read(parameters("classif-recipient"), "\t", NULL)
    z <- z[is.element(z[, "email"], x), ]
    z <- split(z$recipient, z$tranche)
    w <- sapply(z, function(z) any(z == "ALLES"))
    for (j in names(z)[w]) {
        z[[j]] <- setdiff(z[[j]], "ALLES")
        z[[j]] <- c(z[[j]], recipient.read("ALLES"))
    }
    z <- sapply(z, function(z) paste(z, collapse = "; "))
    z
}

#' record.exists
#' 
#' T/F depending on whether action already taken
#' @param x = a string (report name)
#' @param y = date for which you want to send the report
#' @param n = a file
#' @keywords record.exists
#' @export
#' @family record

record.exists <- function (x, y, n) 
{
    z <- record.read(n)
    if (!is.null(z) & any(names(z) == x)) 
        z <- z[x] >= y
    else z <- F
    z
}

#' record.kill
#' 
#' deletes entry <x> in the record <y>. Returns nothing.
#' @param x = a string (report name)
#' @param y = a file
#' @keywords record.kill
#' @export
#' @family record

record.kill <- function (x, y) 
{
    n <- parameters.ex.file(dir.parameters("parameters"), y)
    if (file.exists(n)) {
        z <- vec.read(n)
        if (any(names(z) == x)) {
            z <- z[!is.element(names(z), x)]
            mat.write(z, n)
        }
    }
    invisible()
}

#' record.read
#' 
#' named vector of records and sent dates
#' @param x = a file
#' @keywords record.read
#' @export
#' @family record

record.read <- function (x) 
{
    z <- parameters.ex.file(dir.parameters("parameters"), x)
    if (file.exists(z)) 
        z <- vec.read(z)
    else z <- NULL
    z
}

#' record.track
#' 
#' writes report for date <x> and type <y>
#' @param x = a flowdate
#' @param y = a file
#' @param n = a boolean (regular/Asia process)
#' @keywords record.track
#' @export
#' @family record

record.track <- function (x, y, n) 
{
    z <- paste0(y, ifelse(n, "", "Asia"))
    z <- mat.read(parameters(paste0("classif-", z)), "\t")
    z <- z[is.element(z[, "day"], c(format(day.to.date(x), "%a"), 
        "All")), ]
    z$yyyymmdd <- map.rname(record.read(paste0(y, ".txt")), rownames(z))
    z$today <- z$target <- rep(NA, dim(z)[1])
    w <- z[, "entry"] == "date" & z[, "freq"] == "D"
    z[w, "target"] <- x
    z[w, "today"] <- T
    w <- z[, "entry"] == "flow" & z[, "freq"] == "D"
    z[w, "target"] <- publish.daily.last(flowdate.lag(x, -char.to.num(!n)))
    z[w, "today"] <- T
    w <- z[, "entry"] == "flow" & z[, "freq"] == "W"
    z[w, "target"] <- publish.weekly.last(flowdate.lag(x, -char.to.num(!n)))
    z[w, "today"] <- publish.weekly.last(flowdate.lag(x, -char.to.num(!n))) > 
        publish.weekly.last(flowdate.lag(x, 1 - char.to.num(!n)))
    w <- z[, "entry"] == "flow" & z[, "freq"] == "M"
    z[w, "target"] <- publish.monthly.last(x, 16)
    z[w, "today"] <- publish.monthly.last(x, 16) > publish.monthly.last(flowdate.lag(x, 
        1), 16)
    w <- z[, "entry"] == "hold" & z[, "freq"] == "M"
    z[w, "target"] <- publish.monthly.last(x, 26)
    z[w, "today"] <- publish.monthly.last(x, 26) > publish.monthly.last(flowdate.lag(x, 
        1), 26)
    w <- z[, "entry"] == "FXalloc" & z[, "freq"] == "M"
    z[w, "target"] <- publish.monthly.last(x, 9, 1)
    z[w, "today"] <- publish.monthly.last(x, 9, 1) > publish.monthly.last(flowdate.lag(x, 
        1), 9, 1)
    z
}

#' record.write
#' 
#' updates the record. Returns nothing.
#' @param x = a string (report name)
#' @param y = date for which you sent the report
#' @param n = a file
#' @keywords record.write
#' @export
#' @family record

record.write <- function (x, y, n) 
{
    n <- parameters.ex.file(dir.parameters("parameters"), n)
    if (file.exists(n)) {
        z <- vec.read(n)
        if (any(names(z) == x)) {
            z[x] <- max(z[x], y)
        }
        else {
            z[x] <- y
        }
        mat.write(z, n)
    }
    invisible()
}

#' refresh.predictors
#' 
#' refreshes the text file contains flows data from SQL
#' @param fcn = a function (last complete publication period)
#' @param x = a file (predictors)
#' @param y = query needed to get full history
#' @param n = a string (last part of query after date restriction)
#' @param w = a connection string
#' @param h = a boolean (ignore/note data changes)
#' @param u = a column (corresponds to date in relevant SQL table)
#' @keywords refresh.predictors
#' @export
#' @family refresh

refresh.predictors <- function (fcn, x, y, n, w, h, u) 
{
    v <- file.to.last(x)
    if (v < fcn()) {
        z <- refresh.predictors.script(y, n, u, v)
        z <- sql.query(z, w)
        x <- mat.read(x, ",")
        z <- refresh.predictors.append(x, z, h, F)
    }
    else {
        cat("There is no need to update the data ..\n")
        z <- NULL
    }
    z
}

#' refresh.predictors.append
#' 
#' Appends new to old data after performing checks
#' @param x = a matrix/data frame
#' @param y = a data frame
#' @param n = a boolean (ignore/note data changes)
#' @param w = a boolean (are/aren't row names)
#' @keywords refresh.predictors.append
#' @export
#' @family refresh

refresh.predictors.append <- function (x, y, n = F, w = F) 
{
    if (!w) 
        y <- mat.index(y)
    if (dim(y)[2] != dim(x)[2]) 
        stop("Problem 3")
    if (any(!is.element(colnames(y), colnames(x)))) 
        stop("Problem 4")
    z <- y[, colnames(x)]
    w <- is.element(rownames(z), rownames(x))
    if (sum(w) != 1) 
        stop("Problem 5")
    m <- data.frame(unlist(z[w, ]), unlist(x[rownames(z)[w], 
        ]), stringsAsFactors = F)
    m <- correl(m[, 1], m[, 2])
    m <- zav(m)
    if (!n & m < 0.9) 
        stop("Problem: Correlation between new and old data is", 
            round(100 * m), "!")
    z <- rbind(x, z[!w, ])
    z <- z[order(rownames(z)), ]
    last.date <- rownames(z)[dim(z)[1]]
    cat("Final data have", dim(z)[1], "rows ending at", last.date, 
        "..\n")
    z
}

#' refresh.predictors.daily
#' 
#' refreshes the text file contains flows data from SQL
#' @param x = a file (predictors)
#' @param y = query needed to get full history
#' @param n = a string (last part of query after date restriction)
#' @param w = a connection string
#' @param h = a boolean (ignore/note data changes)
#' @keywords refresh.predictors.daily
#' @export
#' @family refresh

refresh.predictors.daily <- function (x, y, n, w, h = F) 
{
    refresh.predictors(publish.daily.last, x, y, n, w, h, "DayEnding")
}

#' refresh.predictors.monthly
#' 
#' refreshes the text file contains flows data from SQL
#' @param x = a file (predictors)
#' @param y = query needed to get full history
#' @param n = a string (last part of query after date restriction)
#' @param w = a connection string
#' @param h = a boolean (ignore/report the fact last row has changed)
#' @keywords refresh.predictors.monthly
#' @export
#' @family refresh

refresh.predictors.monthly <- function (x, y, n, w, h) 
{
    refresh.predictors(publish.monthly.last, x, y, n, w, h, "WeightDate")
}

#' refresh.predictors.script
#' 
#' generates the SQL script to refresh predictors
#' @param x = query needed to get full history
#' @param y = a string (last part of query after date restriction)
#' @param n = a column (corresponds to date in relevant SQL table)
#' @param w = last date for which you already have data
#' @keywords refresh.predictors.script
#' @export
#' @family refresh

refresh.predictors.script <- function (x, y, n, w) 
{
    if (nchar(y) > 0) {
        z <- paste0(gsub(paste0(y, "$"), "", x), "where\n\t", 
            n, " >= '", w, "'\n", y)
    }
    else {
        z <- x
    }
    z
}

#' refresh.predictors.weekly
#' 
#' refreshes the text file contains flows data from SQL
#' @param x = a file (predictors)
#' @param y = query needed to get full history
#' @param n = a string (last part of query after date restriction)
#' @param w = a connection string
#' @param h = a boolean (ignore/note data changes)
#' @keywords refresh.predictors.weekly
#' @export
#' @family refresh

refresh.predictors.weekly <- function (x, y, n, w, h = F) 
{
    refresh.predictors(publish.weekly.last, x, y, n, w, h, "WeekEnding")
}

#' renorm
#' 
#' renormalizes, so the absolute weights sum to 100, <x>, if a numeric vector, or the rows of <x> otherwise
#' @param x = a numeric vector
#' @keywords renorm
#' @export

renorm <- function (x) 
{
    fcn <- function(z) 100 * z/excise.zeroes(sum(abs(z)))
    fcn2 <- function(z) fcn.nonNA(fcn, z)
    z <- fcn.mat.vec(fcn2, x, , F)
    z
}

#' reshape.long
#' 
#' <x> in long format
#' @param x = a data frame
#' @param y = a string vector (columns to be compressed)
#' @param n = a string (name for identifier column)
#' @param w = a string (name for values column)
#' @keywords reshape.long
#' @export
#' @family reshape

reshape.long <- function (x, y, n = "id", w = "val") 
{
    z <- reshape(x, direction = "long", varying = list(y), v.names = w, 
        idvar = setdiff(names(x), y), timevar = n, times = y)
    rownames(z) <- NULL
    z
}

#' reshape.wide
#' 
#' converts <x> to an array
#' @param x = a matrix/data frame (last columns correspond to array entries)
#' @keywords reshape.wide
#' @export
#' @family reshape

reshape.wide <- function (x) 
{
    z <- lapply(x[-dim(x)[2]], unique)
    x <- map.rname(mat.index(x, 2:dim(x)[2] - 1), do.call(paste, 
        expand.grid(z)))
    z <- array(x, sapply(z, length), z)
    z
}

#' ret.ex.idx
#' 
#' computes return
#' @param x = a matrix/data frame (total return indices)
#' @param y = a positive integer (return window)
#' @param n = a boolean (label returns by beginning/end of the period)
#' @param w = a boolean (returns/spread changes)
#' @keywords ret.ex.idx
#' @export
#' @family ret

ret.ex.idx <- function (x, y, n, w) 
{
    if (w) 
        x <- log(x)
    z <- mat.diff(x, y)
    if (w) 
        z <- z <- 100 * exp(z) - 100
    if (n) 
        z <- mat.lag(z, -y)
    z
}

#' ret.idx.gaps.fix
#' 
#' replaces NA's by latest available total return index (i.e. zero return over that period)
#' @param x = a matrix/data frame (indexed by YYYYMMDD)
#' @keywords ret.idx.gaps.fix
#' @export
#' @family ret

ret.idx.gaps.fix <- function (x) 
{
    fcn.mat.vec(fix.gaps, yyyymmdd.bulk(x), , T)
}

#' ret.to.idx
#' 
#' computes a total-return index
#' @param x = a file (percentage returns)
#' @keywords ret.to.idx
#' @export
#' @family ret

ret.to.idx <- function (x) 
{
    if (is.null(dim(x))) {
        z <- log(1 + x/100)
        w <- !is.na(z)
        n <- find.data(w, T)
        m <- find.data(w, F)
        if (n > 1) 
            n <- n - 1
        z[n] <- 100
        if (m > n) 
            z[seq(n + 1, m)] <- 100 * exp(cumsum(z[seq(n + 1, 
                m)]))
    }
    else {
        z <- fcn.mat.vec(ret.to.idx, x, , T)
    }
    z
}

#' ret.to.log
#' 
#' converts to logarithmic return
#' @param x = a numeric vector (returns)
#' @keywords ret.to.log
#' @export
#' @family ret

ret.to.log <- function (x) 
{
    log(1 + x/100)
}

#' rgb.diff
#' 
#' distance between RGB colours <x> and <y>
#' @param x = an integer vector (length three, elements between 0 and 256)
#' @param y = an integer vector (length three, elements between 0 and 256)
#' @keywords rgb.diff
#' @export

rgb.diff <- function (x, y) 
{
    z <- (x[1] + y[1])/2
    z <- c(z/256, 2, 1 - z/256) + 2
    z <- sqrt(sum(z * (x - y)^2))
    z
}

#' rpt.email
#' 
#' emails report
#' @param x = a folder
#' @param y = output type (".csv", ".pdf", etc.)
#' @param n = a boolean (do/don't check if latest)
#' @param w = a boolean (live/test)
#' @param h = a string (recipient email, can be missing)
#' @param u = a file (log, can be missing)
#' @param v = a string vector (report names, can be missing)
#' @keywords rpt.email
#' @export
#' @family rpt

rpt.email <- function (x, y, n, w, h, u, v) 
{
    if (missing(u)) 
        u <- paste0(x, "Email.log")
    if (missing(v)) 
        v <- x
    if (missing(h)) {
        if (recipient.exists(x)) {
            h <- recipient.read(x)
            if (length(v) > 1 & length(h) > 1) 
                v <- ifelse(is.element(names(h), v), names(h), 
                  x)
            h <- as.character(h)
        }
        else {
            h <- paste0(x, "List")
        }
    }
    fldr <- paste0("C:\\temp\\Automation\\R\\", x)
    u <- paste(fldr, u, sep = "\\")
    if (w) {
        file.kill(u)
        sink(file = u, append = FALSE, type = c("output", "message"), 
            split = FALSE)
    }
    flo.dt <- paste(fldr, "Exhibits", "FlowDate.txt", sep = "\\")
    proceed <- file.exists(flo.dt)
    if (proceed) {
        cat("Reading date from", flo.dt, "..\n")
        flo.dt <- readLines(flo.dt)[1]
    }
    else {
        cat("File", flo.dt, "does not exist ..\n")
    }
    if (proceed & n) {
        proceed <- flo.dt == publish.weekly.last()
        if (!proceed) 
            cat("Aborting. Data date", flo.dt, "does not correspond to latest publication week", 
                publish.weekly.last(), "..\n")
    }
    if (proceed) {
        out.files <- parameters.ex.file(dir.publications(x), 
            paste0(v, "-", flo.dt, y))
        proceed <- file.exists(out.files)
        if (any(!proceed)) {
            err.raise(out.files[!proceed], T, "Aborting: The following files do not exist")
        }
        proceed <- all(proceed)
    }
    u <- substring(u, nchar(fldr) + 2, nchar(u) - nchar("Email.log"))
    if (proceed & email.exists(u, flo.dt)) {
        cat("Aborting: The email for", u, "has already gone out .. \n")
        proceed <- F
    }
    if (proceed) {
        if (length(h) == length(v)) {
            for (i in seq_along(h)) rpt.email.send(v[i], h[i], 
                flo.dt, w, out.files[i])
        }
        else if (length(h) == 1) {
            rpt.email.send(x, h, flo.dt, w, out.files)
        }
        else if (length(v) == 1) {
            for (i in seq_along(h)) rpt.email.send(x, h[i], flo.dt, 
                w, out.files)
        }
        else {
            stop("Can't handle this yet ..\n")
        }
        email.record(u, flo.dt)
    }
    if (w) 
        sink()
    invisible()
}

#' rpt.email.send
#' 
#' emails report
#' @param x = a string (report name)
#' @param y = the email address(es) of the recipient(s)
#' @param n = a flowdate
#' @param w = a boolean (live/test)
#' @param h = a file vector
#' @keywords rpt.email.send
#' @export
#' @family rpt

rpt.email.send <- function (x, y, n, w, h) 
{
    err.raise(h, T, paste("Emailing the following to", y))
    if (grepl("\\.html$", h)) {
        z <- txt.ex.file(h)
        h <- ""
    }
    else {
        z <- paste0("reflecting flows to ", format(day.to.date(n), 
            "%A, %B %d, %Y"), ".")
        if (length(h) == 1) {
            z <- paste0("Please find below the latest copy of the ", 
                x, " report, ", z)
        }
        else {
            z <- paste0("Please find below the latest copies of the ", 
                x, " reports, ", z)
        }
        z <- paste0("Dear All,<p>", z, "</p>", html.signature())
    }
    y <- ifelse(w, y, quant.info(machine.info("Quant"), "email"))
    email(y, paste0("EPFR ", x, ": ", n), z, h, T)
    invisible()
}

#' rquaternion
#' 
#' n x 4 matrix of randomly generated number of unit size
#' @param x = number of quaternions desired
#' @keywords rquaternion
#' @export

rquaternion <- function (x) 
{
    z <- mat.ex.matrix(matrix(runif(3 * x), x, 3, F, list(1:x, 
        c("x", "y", "n"))))
    z <- do.call(glome.ex.R3, z)
    z
}

#' rrw
#' 
#' regression results
#' @param x = a YYYYMM (first-return date, backtest start)
#' @param y = a YYYYMM (first-return date, backtest end)
#' @param n = a variable vector (to regress return against)
#' @param w = a universe (e.g. "R1Mem", or c("EafeMem", 1, "CountryCode", "JP"))
#' @param h = a variable (neutrality group)
#' @param u = a variable (return)
#' @param v = a folder (must have sub-folders data/derived)
#' @param g = a variable (to orthogonalize against)
#' @param r = classif file
#' @keywords rrw
#' @export
#' @family rrw

rrw <- function (x, y, n, w, h, u, v, g = NULL, r) 
{
    dts <- yyyymm.seq(x, y)
    z <- NULL
    for (i in dts) {
        if (grepl("01$", i)) 
            cat("\n", i, "")
        else cat(txt.right(i, 2), "")
        x <- rrw.underlying(i, n, w, h, u, v, g, r)
        x <- mat.subset(x, c("ret", n))
        rownames(x) <- paste(i, rownames(x))
        if (is.null(z)) 
            z <- x
        else z <- rbind(z, x)
    }
    cat("\n")
    z <- list(value = map.rname(rrw.factors(z), n), corr = correl(z), 
        data = z)
    z
}

#' rrw.factors
#' 
#' Returns the t-values of factors that best predict return
#' @param x = a data frame (returns in the first column)
#' @keywords rrw.factors
#' @export
#' @family rrw

rrw.factors <- function (x) 
{
    y <- colnames(x)
    colnames(x) <- names(y) <- col.ex.int(1:dim(x)[2])
    z <- summary(lm(txt.regr(colnames(x)), x))$coeff[-1, "t value"]
    while (any(z < 0) & any(z > 0)) {
        x <- x[, !is.element(colnames(x), names(z)[order(z)][1])]
        z <- summary(lm(txt.regr(colnames(x)), x))$coeff[, "t value"][-1]
    }
    names(z) <- map.rname(y, names(z))
    z
}

#' rrw.underlying
#' 
#' Runs regressions
#' @param x = a YYYYMM (first-return date)
#' @param y = a variable vector
#' @param n = a universe (e.g. "R1Mem"/c("EafeMem", 1, "CountryCode", "JP"))
#' @param w = a variable (neutrality group)
#' @param h = a variable (return)
#' @param u = a folder (has subfolders derived/data)
#' @param v = a variable (to orthogonalize against)
#' @param g = classif file
#' @keywords rrw.underlying
#' @export
#' @family rrw

rrw.underlying <- function (x, y, n, w, h, u, v, g) 
{
    z <- fetch(c(y, v), yyyymm.lag(x), 1, paste0(u, "\\derived"), 
        g)
    grp <- g[, w]
    mem <- sf.subset(n, x, u, g)
    z <- mat.ex.matrix(mat.zScore(z, mem, grp))
    z$grp <- grp
    z$mem <- mem
    z$ret <- fetch(h, x, 1, paste0(u, "\\data"), g)
    z <- mat.last.to.first(z)
    z <- z[is.element(z$mem, 1) & !is.na(z$grp) & !is.na(z$ret), 
        ]
    if (!is.null(v)) {
        z[, v] <- zav(z[, v])
        for (j in y) {
            n <- !is.na(z[, j])
            z[n, j] <- char.to.num(summary(lm(txt.regr(c(j, v)), 
                z[n, ]))$residuals)
            z[, j] <- mat.zScore(z[, j], z$mem, z$grp)
        }
    }
    n <- apply(mat.to.obs(z[, c(y, "ret")]), 1, max) > 0
    z <- mat.ex.matrix(zav(z[n, ]))
    z$ret <- z$ret - mean(z$ret)
    z
}

#' run.cs.reg
#' 
#' regresses each row of <x> on design matrix <y>
#' @param x = a matrix (usually stocks go down and returns go across)
#' @param y = a matrix (whatever vectors you're regressing on)
#' @keywords run.cs.reg
#' @export

run.cs.reg <- function (x, y) 
{
    y <- as.matrix(y)
    z <- tcrossprod(as.matrix(x), tcrossprod(solve(crossprod(y)), 
        y))
    z
}

#' scree
#' 
#' number of eigenvectors to use (by looking at the "kink")
#' @param x = a numeric vector (desecending order)
#' @keywords scree
#' @export

scree <- function (x) 
{
    n <- length(x)
    y <- x[1]/n
    x <- x[-n] - x[-1]
    x <- 1.5 * pi - atan(x[1 - n]/y) - atan(y/x[-1])
    z <- (3:n - 1)[order(x)][1]
    z
}

#' seconds.sho
#' 
#' time elapsed since <x> in hh:mm:ss format
#' @param x = a number
#' @keywords seconds.sho
#' @export

seconds.sho <- function (x) 
{
    z <- round(proc.time()[["elapsed"]] - x)
    z <- tail(c(0, 0, base.ex.int(z, 60, 3)), 3)
    z <- paste(txt.right(100 + z, 2), collapse = ":")
    z
}

#' separating.hyperplane
#' 
#' number of errors and distance from origin for best separating hyperlane
#' @param x = a membership vector (length dim(<x>)[2] - 1)
#' @param y = a matrix (first column is a membership vector)
#' @keywords separating.hyperplane
#' @export

separating.hyperplane <- function (x, y) 
{
    classification.threshold(x[, 1], x[, -1] %*% y)
}

#' sf
#' 
#' runs a stock-flows simulation
#' @param fcn = a fetch function
#' @param x = a YYYYMM (first-return date, backtest start)
#' @param y = a YYYYMM (first-return date, backtest end)
#' @param n = a universe (e.g. "R1Mem", or c("EafeMem", 1, "CountryCode", "JP"))
#' @param w = a variable (neutrality group)
#' @param h = a variable (return)
#' @param u = a string (parameter)
#' @param v = a folder (must have sub-folders data/derived)
#' @param g = an integer (number of bins)
#' @param r = classif file
#' @param s = a positive integer (return window)
#' @param b = a boolean (geometric/artihmetic returns)
#' @keywords sf
#' @export
#' @family sf

sf <- function (fcn, x, y, n, w, h, u, v, g = 5, r, s = 1, b = F) 
{
    n.trail <- length(u)
    summ.fcn <- ifelse(b, "bbk.bin.rets.geom.summ", "bbk.bin.rets.summ")
    summ.fcn <- get(summ.fcn)
    fcn.loc <- function(z) summ.fcn(z, 12/s)
    z <- list()
    for (j in 1:n.trail) {
        cat(u[j], "")
        if (j%%10 == 0) 
            cat("\n")
        b <- sf.single.bsim(fcn, x, y, n, w, h, u[j], v, g, r, 
            s, T)$returns
        b <- t(map.rname(t(b), c(colnames(b), "TxB")))
        b[, "TxB"] <- b[, "Q1"] - b[, paste0("Q", g)]
        b <- mat.ex.matrix(b)
        z[[as.character(u[j])]] <- summ.multi(fcn.loc, b, s)
    }
    z <- simplify2array(z)
    cat("\n")
    z
}

#' sf.bin.nms
#' 
#' returns bin names
#' @param x = an integer (number of bins)
#' @param y = a boolean (report/ignore universe return)
#' @keywords sf.bin.nms
#' @export
#' @family sf

sf.bin.nms <- function (x, y) 
{
    z <- c(1:x, "na")
    z <- z[order(c(1:x, x/2 + 0.25))]
    z <- paste0("Q", z)
    if (y) 
        z <- c(z, "uRet")
    z
}

#' sf.daily
#' 
#' runs a daily stock-flows simulation FAST
#' @param x = a flowdate (first-return date, backtest start)
#' @param y = a flowdate (first-return date, backtest end)
#' @param n = a universe (e.g. "R1Mem", or c("EafeMem", 1, "CountryCode", "JP"))
#' @param w = a variable (neutrality group)
#' @param h = a variable (return)
#' @param u = variable & lookback (e.g. c("1dFloMo", 3))
#' @param v = a folder (data)
#' @param g = an integer (number of bins)
#' @param r = classif file
#' @param s = an integer (NULL for daily or the day you trade, 0 = Sun, 1 = Mon, etc.)
#' @param b = a positive integer (return window in days, can be missing)
#' @keywords sf.daily
#' @export
#' @family sf

sf.daily <- function (x, y, n, w, h, u, v, g = 5, r, s = NULL, b) 
{
    if (missing(b)) 
        b <- ifelse(is.null(s), 1, 5)
    if (is.null(s)) {
        if (!flowdate.exists(x)) 
            stop(x, " is not a flowdate!")
        if (!flowdate.exists(y)) 
            stop(y, " is not a flowdate!")
        z <- flowdate.seq(x, y)
        j <- sum(!is.element(z, nyse.holidays()))%%b
        if (j != 0) 
            stop("Lose ", j, " flowdates!")
        z <- length(z)
    }
    else {
        if (b%%5 != 0) 
            stop("<b> must be a multiple of 5!")
        b <- b/5
        if (!is.element(day.to.weekday(x), s)) 
            stop(x, " is not the end of the week!")
        if (!is.element(day.to.weekday(y), s)) 
            stop(y, " is not the end of the week!")
        z <- flowdate.seq(yyyymmdd.lag(x, 4), y)
        x <- vec.first(z)
        y <- vec.last(z)
        z <- flowdate.diff(y, x) + 1
    }
    z <- fetch(h, y, z, paste0(v, "\\data"), r)
    colnames(z) <- flowdate.seq(x, y)
    if (length(u) == 1) 
        u <- c(u, 1)
    x <- nyse.lag(colnames(z)[1])
    x <- flowdate.lag(x, as.numeric(u[2]) - 1)
    x <- flowdate.diff(y, x)
    x <- fetch(u[1], flowdate.lag(y, 1), x, paste0(v, "\\derived"), 
        r)
    colnames(x) <- flowdate.lag(y, dim(x)[2]:1)
    if (as.numeric(u[2]) > 1) {
        x <- t(compound.flows(t(x), as.numeric(u[2]), grepl("^1dFloMo", 
            u[1])))
    }
    y <- split(colnames(z), yyyymmdd.to.yyyymm(colnames(z)))
    names(y) <- yyyymm.lag(names(y))
    u <- fetch(n, max(names(y)), 1 + length(y), paste0(v, "\\data"), 
        r)
    colnames(u) <- yyyymm.lag(max(names(y)), length(y):0)
    for (j in names(y)) z[!is.element(u[, j], 1), y[[j]]] <- NA
    z <- z[, !is.element(colnames(z), nyse.holidays())]
    x <- x[, c(nyse.lag(colnames(z)[1]), colnames(z)[-dim(z)[2]])]
    colnames(x) <- colnames(z)
    x <- t(x)
    z <- t(z)
    if (!is.null(s)) {
        x <- mat.daily.to.weekly(vec.first, x, s)
        z <- mat.daily.to.weekly(compound, z, s)
    }
    if (b > 1) {
        z <- compound.flows(z, b, F)
        z <- z[b:dim(z)[1], ]
        x <- x[1:dim(z)[1], ]
        rownames(x) <- rownames(z)
    }
    x <- bbk.bin.xRet(x, z, g, T, F, r[, w])
    s <- ifelse(is.null(s), 250, 52)/b
    fcn <- function(z) bbk.bin.rets.summ(z, s)
    z <- summ.multi(fcn, x, b)
    z <- list(summ = z, rets = x)
    z
}

#' sf.detail
#' 
#' runs a stock-flows simulation
#' @param fcn = a fetch function
#' @param x = a YYYYMM (first-return date, backtest start)
#' @param y = a YYYYMM (first-return date, backtest end)
#' @param n = a universe (e.g. "R1Mem", or c("EafeMem", 1, "CountryCode", "JP"))
#' @param w = a variable (neutrality group)
#' @param h = a variable (return)
#' @param u = a string (parameter)
#' @param v = a folder (must have sub-folders data/derived)
#' @param g = an integer vector (if vector, last element T/F for dep/indep binning))
#' @param r = classif file
#' @param s = a variable (cap-weighting factor)
#' @keywords sf.detail
#' @export
#' @family sf

sf.detail <- function (fcn, x, y, n, w, h, u, v, g = 5, r, s = NULL) 
{
    x <- sf.single.bsim(fcn, x, y, n, w, h, u, v, g, r, 1, T, 
        s)
    x <- lapply(x, mat.ex.matrix)
    if (length(g) == 1) 
        x$returns$TxB <- x$returns$Q1 - x$returns[, paste0("Q", 
            g)]
    if (nchar(y) == 6) 
        y <- 12
    else y <- 250
    z <- bbk.bin.rets.summ(x$returns, y)
    z.ann <- t(bbk.bin.rets.prd.summ(bbk.bin.rets.summ, x$returns, 
        txt.left(rownames(x$returns), 4), y)["AnnMn", , ])
    z <- list(summ = z, annSumm = z.ann, counts = x$counts)
    z
}

#' sf.single.bsim
#' 
#' runs a single quintile simulation
#' @param fcn = a fetch function
#' @param x = a YYYYMM (first-return date, backtest start)
#' @param y = a YYYYMM (first-return date, backtest end) after <prdBeg>
#' @param n = a universe (e.g. "R1Mem", or c("EafeMem", 1, "CountryCode", "JP"))
#' @param w = a variable (neutrality group)
#' @param h = a variable (return)
#' @param u = a string (parameter)
#' @param v = a folder (must have sub-folders data/derived)
#' @param g = an integer vector (if vector, last element T/F for dep/indep binning))
#' @param r = classif file
#' @param s = a positive integer (return window)
#' @param b = a boolean (equal/cap-weight universe return)
#' @param p = a variable (cap-weighting factor)
#' @keywords sf.single.bsim
#' @export
#' @family sf

sf.single.bsim <- function (fcn, x, y, n, w, h, u, v, g = 5, r, s = 1, b = T, p = NULL) 
{
    w <- r[, w]
    z <- vec.to.list(yyyymm.seq(x, y), T)
    if (nchar(x) == 8) 
        z <- z[!is.element(names(z), nyse.holidays())]
    z <- lapply(z, function(z) sf.underlying.data(fcn, z, p, 
        n, w, h, u, v, g, r, s))
    fcn <- function(z) {
        l <- ifelse(is.na(z[, "ret"]), 0, z[, "mem"])
        z <- z[, "bin"]
        pivot.1d(sum, z[l > 0], l[l > 0])
    }
    h <- array.ex.list(lapply(z, fcn), T)
    if (length(g) == 1) 
        h <- map.rname(h, sf.bin.nms(g, b))
    h <- t(h)
    z <- lapply(z, function(z) sf.underlying.summ(z, b))
    z <- array.ex.list(z, T)
    if (length(g) == 1) 
        z <- map.rname(z, sf.bin.nms(g, b))
    z <- list(returns = t(z), counts = h)
    z
}

#' sf.subset
#' 
#' Returns a 1/0 mem vector
#' @param x = a universe (e.g. "R1Mem", or c("EafeMem", 1, "CountryCode", "JP"))
#' @param y = a YYYYMM/YYYYMMDD
#' @param n = a folder
#' @param w = classif file
#' @keywords sf.subset
#' @export
#' @family sf

sf.subset <- function (x, y, n, w) 
{
    m <- length(x)
    if (m == 1) 
        x <- c(x, 1)
    z <- y
    if (nchar(y) == 8) 
        z <- yyyymmdd.to.yyyymm(z)
    z <- yyyymm.lag(z, 1)
    z <- fetch(x[1], z, 1, paste(n, "data", sep = "\\"), w)
    z <- is.element(z, x[2])
    if (m > 2) 
        z <- z & is.element(w[, x[3]], x[4])
    z <- char.to.num(z)
    z
}

#' sf.underlying.data
#' 
#' Gets data needed to back-test a single period
#' @param fcn = a fetch function
#' @param x = a YYYYMM/flowdate (period for which you want returns)
#' @param y = a variable (factor for cap weighting)
#' @param n = a universe (e.g. "EafeMem" or c("GemMem", 1))
#' @param w = a string vector (neutrality group)
#' @param h = a variable (return)
#' @param u = a string (parameter)
#' @param v = a folder (data)
#' @param g = an integer vector (if vector, last element T/F for dep/indep binning))
#' @param r = classif file
#' @param s = a positive integer (return window)
#' @keywords sf.underlying.data
#' @export
#' @family sf

sf.underlying.data <- function (fcn, x, y, n, w, h, u, v, g, r, s) 
{
    mem <- sf.subset(n, x, v, r)
    vbl <- fcn(x, u, v, r)
    if (s == 1) {
        ret <- fetch(h, x, 1, paste0(v, "\\data"), r)
    }
    else {
        ret <- fetch(h, yyyymm.lag(x, 1 - s), s, paste0(v, "\\data"), 
            r)
        ret <- mat.compound(ret)
    }
    bin <- ifelse(is.na(ret), 0, mem)
    if (!is.null(y)) {
        y <- fetch(y, yyyymm.lag(x), 1, paste0(v, "\\derived"), 
            r)
        bin <- y <- vec.max(zav(y) * bin, bin)
    }
    bin <- sf.underlying.data.bin(vbl, g, bin, w)
    z <- data.frame(bin, ret, mem, w, row.names = rownames(r), 
        stringsAsFactors = F)
    if (!is.null(y)) 
        z$wgt <- y
    z
}

#' sf.underlying.data.bin
#' 
#' character vector of bin memberships
#' @param x = a numeric vector (or vector list)
#' @param y = an integer vector (if vector, last element T/F for dep/indep binning)
#' @param n = a numeric vector (weights)
#' @param w = a string vector (binning group)
#' @keywords sf.underlying.data.bin
#' @export
#' @family sf

sf.underlying.data.bin <- function (x, y, n, w) 
{
    fcn <- function(z, l, k, j, i) paste0(i, zav(qtl(z, l, k, 
        j), "na"))
    if (!is.list(x)) {
        z <- fcn(x, y, n, w, "Q")
    }
    else {
        h <- length(names(x))
        if (length(y) == h) 
            u <- T
        else u <- is.element(y[h + 1], 1)
        if (!u) {
            for (j in 1:h) x[[j]] <- fcn(x[[j]], y[j], n, w, 
                names(x)[j])
            z <- Reduce(paste, x)
        }
        else {
            z <- x[[1]] <- fcn(x[[1]], y[1], n, w, names(x)[1])
            for (j in 2:h) {
                x[[j]] <- fcn(x[[j]], y[j], n, paste(z, w), names(x)[j])
                z <- paste(z, x[[j]])
            }
        }
    }
    z
}

#' sf.underlying.summ
#' 
#' Returns a named vector of bin returns
#' @param x = a matrix/data frame (columns bin/ret/mem/wgt)
#' @param y = a boolean (report/ignore universe return)
#' @keywords sf.underlying.summ
#' @export
#' @family sf

sf.underlying.summ <- function (x, y) 
{
    if (all(colnames(x) != "wgt")) 
        x$wgt <- x$mem
    u <- is.element(x$mem, 1) & !is.na(x$ret) & !is.na(x$wgt) & 
        x$wgt > 0
    if (any(u)) {
        univ.ret <- sum(x$ret[u] * x$wgt[u])/sum(x$wgt[u])
        x$ret <- x$ret - univ.ret
        z <- pivot.1d(sum, x$bin[u], x$ret[u] * x$wgt[u])
        z <- z/map.rname(pivot.1d(sum, x$bin[u], x$wgt[u]), names(z))
        if (y) 
            z["uRet"] <- univ.ret
    }
    else {
        z <- NULL
    }
    z
}

#' sfpd.ActWtTrend
#' 
#' <h> factor
#' @param x = a matrix/data frame (flows)
#' @param y = a matrix/data frame (holdings)
#' @param n = a matrix/data frame (FundHistory)
#' @param w = a flowdate
#' @param h = a variable (ActWtTrend/ActWtDiff/ActWtDiff2)
#' @keywords sfpd.ActWtTrend
#' @export
#' @family sfpd

sfpd.ActWtTrend <- function (x, y, n, w, h) 
{
    g <- intersect(c("HFundId", "FundId"), names(x))[1]
    x <- aggregate(x["Flow"], by = x[g], FUN = sum)
    x <- merge(x, n)
    x <- x[, c("FundId", "Flow", "GeographicFocus")]
    y <- merge(x, y)
    x <- aggregate(y[, c("HoldingValue", "PortVal")], by = y[c("HSecurityId", 
        "GeographicFocus")], FUN = sum)
    x[, "FundWtdExcl0"] <- 100 * x[, "HoldingValue"]/nonneg(x[, 
        "PortVal"])
    x <- x[, !is.element(colnames(x), c("HoldingValue", "PortVal"))]
    y <- merge(y, x)
    y <- y[, !is.element(colnames(y), "GeographicFocus")]
    y <- sfpd.Wt(y)
    y[, "Wt"] <- y[, "Wt"] - y[, "FundWtdExcl0"]
    y <- y[!is.na(y[, "Wt"]), ]
    z <- sfpd.FloTrend.underlying(y, w, h)
    z
}

#' sfpd.AllocMo
#' 
#' <w> factor
#' @param x = a matrix/data frame (holdings)
#' @param y = a matrix/data frame (prior holdings)
#' @param n = a matrix/data frame (security history)
#' @param w = a variable (AllocMo/AllocTrend/AllocDiff)
#' @keywords sfpd.AllocMo
#' @export
#' @family sfpd

sfpd.AllocMo <- function (x, y, n, w) 
{
    z <- list(AssetsStart = y[, c("FundId", "PortVal")], AssetsEnd = x[, 
        c("FundId", "PortVal")])
    z <- lapply(z, function(z) z[!duplicated(z[, 1]), ])
    for (l in names(z)) colnames(z[[l]])[2] <- l
    z <- Reduce(merge, z)
    x <- sfpd.FloTrend.holdings(x, y, n)
    x <- merge(x, z)
    x[, "AssetsEnd"] <- rowMeans(x[, c("AssetsStart", "AssetsEnd")])
    if (w == "AllocMo") {
        x[, "Num"] <- x[, "AssetsEnd"] * (x[, "Wt"] - x[, "OldWt"])
        x[, "Den"] <- x[, "AssetsEnd"] * (x[, "Wt"] + x[, "OldWt"])/2
    }
    else if (w == "AllocTrend") {
        x[, "Num"] <- x[, "AssetsEnd"] * (x[, "Wt"] - x[, "OldWt"])
        x[, "Den"] <- abs(x[, "Num"])
    }
    else if (w == "AllocDiff") {
        x[, "Num"] <- x[, "AssetsEnd"] * sign(x[, "Wt"] - x[, 
            "OldWt"])
        x[, "Den"] <- x[, "AssetsEnd"]
    }
    else stop("Bad Factor!")
    x <- aggregate(x = x[, c("Num", "Den")], by = x["HSecurityId"], 
        FUN = sum)
    x[, "Num"] <- x[, "Num"]/nonneg(x[, "Den"])
    z <- x[, c("HSecurityId", "Num")]
    colnames(z)[2] <- w
    z <- z[!is.na(z[, w]), ]
    z
}

#' sfpd.AllocSkew
#' 
#' AllocSkew factor
#' @param x = a matrix/data frame (holdings)
#' @param y = a matrix/data frame (fund history)
#' @keywords sfpd.AllocSkew
#' @export
#' @family sfpd

sfpd.AllocSkew <- function (x, y) 
{
    z <- y[, c("FundId", "GeographicFocus")]
    z <- z[order(z[, "GeographicFocus"], decreasing = T), ]
    z <- z[!duplicated(z[, "FundId"]), ]
    x <- merge(x, z)
    z <- aggregate(x = x[c("HoldingValue", "PortVal")], by = x[c("HSecurityId", 
        "GeographicFocus")], FUN = sum)
    z[, "FundWtdExcl0"] <- z[, "HoldingValue"]/z[, "PortVal"]
    z <- z[, !is.element(colnames(z), c("HoldingValue", "PortVal"))]
    x <- merge(x, z)
    x[, "HoldingValue"] <- x[, "HoldingValue"]/x[, "PortVal"]
    x[, "FundWtdExcl0"] <- floor(1e+06 * x[, "FundWtdExcl0"])/1e+06
    x[, "HoldingValue"] <- x[, "FundWtdExcl0"] - x[, "HoldingValue"]
    x[, "HoldingValue"] <- round(1e+06 * x[, "HoldingValue"])/1e+06
    x[, "HoldingValue"] <- x[, "PortVal"] * sign(x[, "HoldingValue"])
    x <- aggregate(x = x[c("HoldingValue", "PortVal")], by = x["HSecurityId"], 
        FUN = sum)
    x[, "HoldingValue"] <- x[, "HoldingValue"]/x[, "PortVal"]
    z <- x[, colnames(x) != "PortVal"]
    z
}

#' sfpd.filter
#' 
#' T/F depending on whether records of <x> pass filter <y>
#' @param x = a matrix/data frame (FundHistory)
#' @param y = a filter (one of All/Act/Pas/Etf/Mutual)
#' @keywords sfpd.filter
#' @export
#' @family sfpd

sfpd.filter <- function (x, y) 
{
    if (y == "All") {
        z <- rep(T, dim(x)[1])
    }
    else if (y == "Act") {
        z <- !is.element(x[, "Idx"], "Y")
    }
    else if (y == "Pas") {
        z <- is.element(x[, "Idx"], "Y")
    }
    else if (y == "Etf") {
        z <- is.element(x[, "ETF"], "Y")
    }
    else if (y == "Mutual") {
        z <- !is.element(x[, "ETF"], "Y")
    }
    else {
        stop("Unknown filter!")
    }
    z
}

#' sfpd.FloDollar
#' 
#' FloMo factor
#' @param x = a matrix/data frame (flows)
#' @param y = a matrix/data frame (holdings)
#' @param n = a matrix/data frame (FundHistory)
#' @param w = a flowdate
#' @keywords sfpd.FloDollar
#' @export
#' @family sfpd

sfpd.FloDollar <- function (x, y, n, w) 
{
    y <- sfpd.FloMo.underlying(x, y, n, "Flow", "GeographicFocus")
    y[, "ReportDate"] <- yyyymmdd.to.txt(w)
    z <- y[, c("ReportDate", "GeographicFocus", "HSecurityId", 
        "Flow")]
    colnames(z) <- c("ReportDate", "GeoId", "HSecurityId", "CalculatedStockFlow")
    z
}

#' sfpd.FloMo
#' 
#' FloMo factor
#' @param x = a matrix/data frame (flows)
#' @param y = a matrix/data frame (holdings)
#' @param n = a matrix/data frame (FundHistory)
#' @param w = a flowdate
#' @keywords sfpd.FloMo
#' @export
#' @family sfpd

sfpd.FloMo <- function (x, y, n, w) 
{
    y <- sfpd.FloMo.underlying(x, y, n, c("Flow", "AssetsStart"))
    y[, "FloMo"] <- 100 * y[, "Flow"]/nonneg(y[, "AssetsStart"])
    y[, "ReportDate"] <- yyyymmdd.to.txt(w)
    z <- y[, c("ReportDate", "HSecurityId", "FloMo")]
    z
}

#' sfpd.FloMo.underlying
#' 
#' FloMo factor
#' @param x = a matrix/data frame (flows)
#' @param y = a matrix/data frame (holdings)
#' @param n = a matrix/data frame (FundHistory)
#' @param w = a string vector (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param h = a column vector (in FundHistory, can be NULL)
#' @keywords sfpd.FloMo.underlying
#' @export
#' @family sfpd

sfpd.FloMo.underlying <- function (x, y, n, w, h = NULL) 
{
    y <- sfpd.Wt(y)
    y <- y[!is.na(y[, "Wt"]), ]
    x <- merge(x, n)[, c("FundId", h, w)]
    y <- merge(x, y)
    for (j in w) y[, j] <- y[, j] * y[, "Wt"]/100
    z <- aggregate(y[w], by = y[c("HSecurityId", h)], FUN = sum)
    z
}

#' sfpd.FloTrend
#' 
#' <h> factor
#' @param x = a matrix/data frame (flows)
#' @param y = a matrix/data frame (holdings)
#' @param n = a matrix/data frame (FundHistory)
#' @param w = a flowdate
#' @param h = a variable (FloTrend/FloDiff/FloDiff2)
#' @param u = a matrix/data frame (prior holdings)
#' @param v = a matrix/data frame (security history)
#' @keywords sfpd.FloTrend
#' @export
#' @family sfpd

sfpd.FloTrend <- function (x, y, n, w, h, u, v) 
{
    g <- intersect(c("HFundId", "FundId"), names(x))[1]
    x <- aggregate(x["Flow"], by = x[g], FUN = sum)
    x <- merge(x, n)[, c("FundId", "Flow")]
    y <- sfpd.FloTrend.holdings(y, u, v)
    y[, "Wt"] <- y[, "Wt"] - y[, "OldWt"]
    y <- merge(y, x)
    z <- sfpd.FloTrend.underlying(y, w, h)
    z
}

#' sfpd.FloTrend.holdings
#' 
#' merges old and new holdings
#' @param x = a matrix/data frame (holdings)
#' @param y = a matrix/data frame (prior holdings)
#' @param n = a matrix/data frame (security history)
#' @keywords sfpd.FloTrend.holdings
#' @export
#' @family sfpd

sfpd.FloTrend.holdings <- function (x, y, n) 
{
    x <- x[is.element(x[, "FundId"], y[, "FundId"]), ]
    y <- y[is.element(y[, "FundId"], x[, "FundId"]), ]
    x <- merge(sfpd.Wt(x), n)
    y <- merge(sfpd.Wt(y), n)
    x <- x[is.element(x[, "SecurityId"], y[, "SecurityId"]), 
        ]
    y <- y[is.element(y[, "SecurityId"], x[, "SecurityId"]), 
        ]
    y <- y[, c("FundId", "SecurityId", "Wt")]
    colnames(y) <- c("FundId", "SecurityId", "OldWt")
    z <- merge(x, y)
    z
}

#' sfpd.FloTrend.parameterize
#' 
#' numerator and denominator to create variable
#' @param x = a matrix/data frame
#' @param y = a variable
#' @keywords sfpd.FloTrend.parameterize
#' @export
#' @family sfpd

sfpd.FloTrend.parameterize <- function (x, y) 
{
    z <- x
    if (grepl("Diff$", y)) {
        z[, "Num"] <- z[, "Flow"] * sign(z[, "Wt"])
        z[, "Den"] <- abs(z[, "Flow"])
    }
    else if (grepl("Diff2$", y)) {
        z[, "Num"] <- sign(z[, "Flow"]) * z[, "Wt"]
        z[, "Den"] <- abs(z[, "Wt"])
    }
    else if (grepl("Trend$", y)) {
        z[, "Num"] <- z[, "Flow"] * z[, "Wt"]
        z[, "Den"] <- abs(z[, "Flow"] * z[, "Wt"])
    }
    else stop("Bad factor!")
    z
}

#' sfpd.FloTrend.underlying
#' 
#' <n> factor
#' @param x = a matrix/data frame
#' @param y = a flowdate
#' @param n = a variable
#' @keywords sfpd.FloTrend.underlying
#' @export
#' @family sfpd

sfpd.FloTrend.underlying <- function (x, y, n) 
{
    x <- sfpd.FloTrend.parameterize(x, n)
    z <- aggregate(x[, c("Num", "Den")], by = x["HSecurityId"], 
        FUN = sum)
    z[, n] <- z[, "Num"]/nonneg(z[, "Den"])
    z[, "ReportDate"] <- yyyymmdd.to.txt(y)
    z <- z[, c("ReportDate", "HSecurityId", n)]
    z <- z[!is.na(z[, n]), ]
    z
}

#' sfpd.Flow
#' 
#' subsets <x> to latest information known before time <n>
#' @param x = premium daily file
#' @param y = a flowdate
#' @param n = cutoff time (New York) (e.g. "07:00:00")
#' @param w = 0 for same day, 1 for next day
#' @keywords sfpd.Flow
#' @export
#' @family sfpd

sfpd.Flow <- function (x, y, n, w = 1) 
{
    y <- paste(day.to.date(flowdate.lag(y, -w)), n)
    z <- x[order(x[, "PublishDate"], decreasing = T), ]
    z <- z[z[, "PublishDate"] < y, ]
    z <- z[!duplicated(z[, "SCID"]), ]
    z
}

#' sfpd.Holdings
#' 
#' Generates the SQL query to get weights for individual stocks
#' @param x = a YYYYMM
#' @param y = a connection string/connection
#' @keywords sfpd.Holdings
#' @export
#' @family sfpd

sfpd.Holdings <- function (x, y) 
{
    z <- c("Holdings t1", "inner join", "FundHistory t2 on t2.FundId = t1.FundId")
    z <- c(z, "inner join", sql.label(sql.MonthlyAssetsEnd("@mo"), 
        "t3"), "\ton t3.HFundId = t2.HFundId")
    n <- c("HSecurityId", "t1.FundId", "HoldingValue", "PortVal = AssetsEnd")
    z <- sql.tbl(n, z, "ReportDate = @mo")
    z <- sql.declare.wrapper("@mo", yyyymm.to.day(x), z)
    y <- sql.connect.wrapper(y)
    z <- sql.query.underlying(z, y$conn, T)
    sql.close(y)
    z
}

#' sfpd.ION
#' 
#' Inflow/Outflow factors
#' @param x = a matrix/data frame (flows)
#' @param y = a matrix/data frame (holdings)
#' @param n = a matrix/data frame (FundHistory)
#' @param w = a flowdate
#' @keywords sfpd.ION
#' @export
#' @family sfpd

sfpd.ION <- function (x, y, n, w) 
{
    x[, "Inflow"] <- vec.max(x[, "Flow"], 0)
    x[, "Outflow"] <- vec.min(x[, "Flow"], 0)
    y <- sfpd.FloMo.underlying(x, y, n, c("Inflow", "Outflow"))
    y[, "ReportDate"] <- yyyymmdd.to.txt(w)
    z <- y[, c("ReportDate", "HSecurityId", "Inflow", "Outflow")]
    z
}

#' sfpd.Wt
#' 
#' computes weight
#' @param x = a matrix/data frame (holdings)
#' @keywords sfpd.Wt
#' @export
#' @family sfpd

sfpd.Wt <- function (x) 
{
    x[, "Wt"] <- 100 * x[, "HoldingValue"]/nonneg(x[, "PortVal"])
    z <- x[, !is.element(colnames(x), c("HoldingValue", "PortVal"))]
    z
}

#' shell.wrapper
#' 
#' result of command <x>
#' @param x = a string to issue as command
#' @param y = timeout in seconds
#' @keywords shell.wrapper
#' @export

shell.wrapper <- function (x, y) 
{
    setTimeLimit(elapsed = y, transient = T)
    z <- tryCatch(shell(x, intern = T), error = function(z) {
        NULL
    })
    z
}

#' sim.direction
#' 
#' percentage needed to get worst group under control
#' @param x = a data frame
#' @param y = an integer vector (group limits, names correspond to columns in <x>)
#' @keywords sim.direction
#' @export
#' @family sim

sim.direction <- function (x, y) 
{
    z <- round(max(sim.direction.buy(x, y)), 4)
    y <- round(max(sim.direction.sell(x, y)), 4)
    z <- ifelse(z > y, z, -y)
    z
}

#' sim.direction.buy
#' 
#' percentage buy needed to get worst group under control
#' @param x = a data frame
#' @param y = an integer vector (group limits, names correspond to columns in <x>)
#' @keywords sim.direction.buy
#' @export
#' @family sim

sim.direction.buy <- function (x, y) 
{
    if (length(y) > 1) {
        z <- -apply(x[, paste0(names(y), "Wt")], 2, min)
    }
    else {
        z <- -min(x[, paste0(names(y), "Wt")])
    }
    z <- vec.max(z - y, 0)
    z
}

#' sim.direction.sell
#' 
#' percentage sell needed to get worst group under control
#' @param x = a data frame
#' @param y = an integer vector (group limits, names correspond to columns in <x>)
#' @keywords sim.direction.sell
#' @export
#' @family sim

sim.direction.sell <- function (x, y) 
{
    if (length(y) > 1) {
        z <- apply(x[, paste0(names(y), "Wt")], 2, max)
    }
    else {
        z <- min(x[, paste0(names(y), "Wt")])
    }
    z <- vec.max(z - y, 0)
    z
}

#' sim.fetch
#' 
#' data needed to run simulation
#' @param x = a YYYYMM
#' @param y = a variable
#' @param n = a string representing universe name
#' @param w = a StockFlows environment
#' @param h = a variable vector (risk factors)
#' @keywords sim.fetch
#' @export
#' @family sim

sim.fetch <- function (x, y, n, w, h = NULL) 
{
    z <- w$classif[, c("GSec", "CountryCode")]
    colnames(z) <- c("Sec", "Ctry")
    z$Alp <- fetch(y, yyyymm.lag(x), 1, paste(w$fldr, "derived", 
        sep = "\\"), w$classif)
    z$Bmk <- fetch(paste0(n, "Wt"), yyyymm.lag(x), 1, paste(w$fldr, 
        "data", sep = "\\"), w$classif)
    u <- fetch(paste0(n, "Mem"), yyyymm.lag(x), 1, paste(w$fldr, 
        "data", sep = "\\"), w$classif)
    z$Ret <- zav(fetch("Ret", x, 1, paste(w$fldr, "data", sep = "\\"), 
        w$classif))
    if (!is.null(h)) 
        z <- data.frame(z, fetch(h, yyyymm.lag(x), 1, paste(w$fldr, 
            "derived", sep = "\\"), w$classif), stringsAsFactors = F)
    h <- c("Alp", h)
    for (j in h) z[, j] <- zav(qtl(z[, j], 5, u, w$classif$RgnSec), 
        3)
    z <- z[is.element(u, 1), ]
    z$Bmk <- renorm(z$Bmk)
    z
}

#' sim.limits
#' 
#' returns group active-weight limits applying to each stock
#' @param x = a data frame
#' @param y = an integer vector (group limits, names correspond to columns in <x>)
#' @keywords sim.limits
#' @export
#' @family sim

sim.limits <- function (x, y) 
{
    for (j in names(y)) x[, paste0(j, "Wt")] <- zav(map.rname(pivot.1d(sum, 
        x[, j], x$Act), x[, j]))
    z <- x
    z
}

#' sim.optimal
#' 
#' returns named vector of optimal portfolio weights
#' @param x = a data frame (with columns Alp/Bmk/Sec/Ctry)
#' @param y = a numeric vector (initial weight)
#' @param n = an integer (name active limit)
#' @param w = an integer vector (group limits, names correspond to columns in <x>)
#' @param h = an integer (quintile to sell, stocks in bin <h> and higher are flushed)
#' @param u = an integer (between 0 and 100)
#' @keywords sim.optimal
#' @export
#' @family sim

sim.optimal <- function (x, y, n, w, h, u) 
{
    x$Act <- y - x$Bmk
    x$Act <- vec.max(vec.min(x$Act, n), -n)
    x$Act <- ifelse(is.element(x$Alp, h:5), -vec.min(x$Bmk, n), 
        x$Act)
    x <- sim.limits(x, w)
    h <- sim.direction(x, w)
    while (h != 0) {
        if (h > 0) 
            y <- sim.direction.buy(x, w)
        else y <- sim.direction.sell(x, w)
        y <- y[y > 0]
        y <- names(y)[order(y, decreasing = T)]
        x$Stk <- sim.trade.stk(x, h > 0, n, F)
        x$Grp <- sim.trade.grp(x, h > 0, w)
        x$Trd <- vec.min(x$Stk, x$Grp) > 0
        x <- mat.sort(x, c("Trd", y, "Alp", "Stk"), c(T, rep(h < 
            0, length(y) + 1), T))
        x$Act[1] <- x$Act[1] + sign(h) * min(x$Stk[1], x$Grp[1])
        x <- sim.limits(x, w)
        h <- sim.direction(x, w)
    }
    x <- sim.limits(x, w)
    h <- -round(sum(x$Act), 4)
    while (h != 0) {
        x$Stk <- sim.trade.stk(x, h > 0, n, T)
        x$Grp <- sim.trade.grp(x, h > 0, w)
        x$Trd <- vec.min(x$Stk, x$Grp) > 0
        if (u > 0) {
            vec <- list(A = apply(x[, c("Grp", "Stk")], 1, min), 
                B = sign(h) * x[, "Ret"])
            vec <- sapply(vec, function(z) z/sqrt(sum(z^2)), 
                simplify = "array")
            x <- x[order((vec %*% c(100 - u, u))[, 1], decreasing = T), 
                ]
            x <- mat.sort(x, c("Trd", "Alp"), c(T, h < 0))
        }
        else {
            x <- mat.sort(x, c("Trd", "Alp", "Grp", "Stk"), c(T, 
                h < 0, T, T))
        }
        x$Act[1] <- x$Act[1] + sign(h) * min(x$Stk[1], x$Grp[1])
        x <- sim.limits(x, w)
        h <- -round(sum(x$Act), 4)
    }
    z <- x[, c("Bmk", "Act", "Ret", names(w))]
    z
}

#' sim.overall
#' 
#' summarizes simulation
#' @param x = a list (output of <sim.optimal>)
#' @param y = a numeric vector (turnover)
#' @param n = an integer vector (names correspond to columns in elements of <x>)
#' @keywords sim.overall
#' @export
#' @family sim

sim.overall <- function (x, y, n) 
{
    x <- mat.ex.matrix(t(sapply(x, function(z) sim.summ(z, n))))
    x$to <- y
    z <- c("to", "Names", "Act", txt.expand(names(n), c("Selec", 
        "Alloc", "Intcn"), ""))
    z <- colMeans(x[, z])
    z[names(z) != "Names"] <- z[names(z) != "Names"] * 12
    z["Sharpe"] <- z["Act"]/nonneg(sd(x$Act) * sqrt(12))
    z <- c(z, apply(x[, paste0(c("Name", names(n)), "Max")], 
        2, max))
    n <- vec.named(seq_along(z), names(z))
    n["Sharpe"] <- n["Act"] + 0.5
    z <- z[order(n)]
    z
}

#' sim.seed
#' 
#' initial portfolio satisfying limits prioritizing earlier records of <x>
#' @param x = a data frame
#' @param y = an integer (name active limit)
#' @param n = an integer vector (group limits, names correspond to columns in <x>)
#' @keywords sim.seed
#' @export
#' @family sim

sim.seed <- function (x, y, n) 
{
    x <- x[order(x$Alp), ]
    x$Act <- -x$Bmk
    x$Act <- vec.max(vec.min(x$Act, y), -y)
    x <- sim.limits(x, n)
    x$Stk <- sim.trade.stk(x, T, y, T)
    x$Grp <- sim.trade.grp(x, T, n)
    x <- x[order(vec.min(x$Stk, x$Grp) > 0, decreasing = T), 
        ]
    while (sum(x$Act) < 1e-04 & min(x$Stk[1], x$Grp[1]) > 1e-04) {
        x$Act[1] <- x$Act[1] + min(x$Stk[1], x$Grp[1])
        x$Stk <- sim.trade.stk(x, T, y, T)
        x$Grp <- sim.trade.grp(x, T, n)
        x <- x[order(vec.min(x$Stk, x$Grp) > 0, decreasing = T), 
            ]
    }
    z <- rowSums(x[, c("Bmk", "Act")])
    z
}

#' sim.summ
#' 
#' summarizes simulation
#' @param x = a data frame
#' @param y = an integer vector (group limits, names correspond to columns in <x>)
#' @keywords sim.summ
#' @export
#' @family sim

sim.summ <- function (x, y) 
{
    z <- colSums(x[, c("Bmk", "Act")] * x$Ret)/100
    z["Names"] <- sum(rowSums(x[, c("Bmk", "Act")]) > 0)
    z["NameMax"] <- max(abs(x[, "Act"]))
    for (j in names(y)) {
        n <- brinson(x$Bmk, x$Act, x$Ret, x[, j])
        n["Max"] <- max(abs(pivot.1d(sum, x[, j], x$Act)))
        names(n) <- paste0(j, names(n))
        z <- c(z, n)
    }
    z
}

#' sim.trade.grp
#' 
#' max you can trade without breaching group limits
#' @param x = a data frame
#' @param y = a boolean (buy/sell)
#' @param n = an integer vector (group limits, names correspond to columns in <x>)
#' @keywords sim.trade.grp
#' @export
#' @family sim

sim.trade.grp <- function (x, y, n) 
{
    z <- matrix(n, dim(x)[1], length(n), T, list(rownames(x), 
        paste0(names(n), "Wt")))
    if (y) {
        z <- z - x[, colnames(z)]
    }
    else {
        z <- z + x[, colnames(z)]
    }
    z <- vec.max(apply(z, 1, min), 0)
    z
}

#' sim.trade.stk
#' 
#' max you can trade without breaching name limits
#' @param x = a data frame
#' @param y = a boolean (buy/sell)
#' @param n = an integer (name active limit)
#' @param w = a boolean (do/don't fully invest)
#' @keywords sim.trade.stk
#' @export
#' @family sim

sim.trade.stk <- function (x, y, n, w) 
{
    if (y) {
        z <- n - x$Act
    }
    else {
        z <- x$Act + x$Bmk
        z <- vec.min(z, n + x$Act)
    }
    z <- vec.max(z, 0)
    if (w) 
        z <- vec.min(z, max(ifelse(y, -1, 1) * sum(x$Act), 0))
    z
}

#' smear.Q1
#' 
#' Returns weights associated with ranks 1:x so that #		:	a) every position in the top quintile has an equal positive weight #		:	b) every position in the bottom 3 quintiles has an equal negative weight #		:	c) second quintile positions get a linear interpolation #		:	d) the weights sum to zero #		:	e) the positive weights sum to 100
#' @param x = any real number
#' @keywords smear.Q1
#' @export

smear.Q1 <- function (x) 
{
    bin <- qtl.eq(x:1)
    incr <- rep(NA, x)
    w <- bin == 2
    incr[w] <- sum(w):1
    incr[bin == 1] <- 1 + sum(w)
    incr[bin > 2] <- 0
    tot.incr <- sum(incr)
    m <- sum(bin < 3)
    pos.incr <- sum(incr[1:m])
    wt.incr <- 100/(pos.incr - m * tot.incr/x)
    neg.act <- tot.incr * wt.incr/x
    z <- incr * wt.incr - neg.act
    while (abs(sum(vec.max(z, 0)) - 100) > 1e-05) {
        m <- m - 1
        pos.incr <- sum(incr[1:m])
        wt.incr <- 100/(pos.incr - m * tot.incr/x)
        neg.act <- tot.incr * wt.incr/x
        z <- incr * wt.incr - neg.act
    }
    z
}

#' sql.1dActWtTrend.Alloc
#' 
#' SQL query for allocation table for FloTrend
#' @param x = a YYYYMM
#' @param y = a temp table
#' @param n = a column (SectorId/CountryId)
#' @param w = a string vector (identifiers)
#' @keywords sql.1dActWtTrend.Alloc
#' @export
#' @family sql

sql.1dActWtTrend.Alloc <- function (x, y, n, w = NULL) 
{
    z <- paste0("MonthEnding = '", yyyymm.to.day(x), "'")
    z <- sql.tbl(c("HFundId", "AUM = sum(AssetsEnd)"), "MonthlyData", 
        z, "HFundId")
    z <- c(sql.label(z, "t1"), "inner join", "FundHistory t2 on t2.HFundId = t1.HFundId")
    v <- sql.label(sql.1dFloTrend.Alloc.fetch(x, n, w, F, F), 
        "t3 on t3.FundId = t2.FundId")
    z <- c(z, "inner join", v)
    z <- sql.tbl(c("t2.FundId", n, "Allocation", "AUM"), z)
    if (!missing(y)) 
        z <- c(sql.drop(y), "", sql.into(z, y))
    z
}

#' sql.1dActWtTrend.Final
#' 
#' SQL query for daily ActWtTrend
#' @param x = a temp table (#CTRY/#SEC)
#' @param y = factor (one of ActWtTrend/ActWtDiff/ActWtDiff2)
#' @param n = a column (SectorId/CountryId)
#' @keywords sql.1dActWtTrend.Final
#' @export
#' @family sql

sql.1dActWtTrend.Final <- function (x, y, n) 
{
    r <- c("DayEnding", n, "GeographicFocus", "WtdAvg = sum(Allocation * AUM)/sum(AUM)")
    z <- c("#FLO t1", "inner join", sql.label(x, "t2 on t2.FundId = t1.FundId"))
    z <- sql.tbl(r, z, , paste(r[-length(r)], collapse = ", "), 
        "sum(AUM) > 0")
    z <- c(sql.label(z, "t1"), "inner join", "#FLO t2")
    z <- c(z, "\ton t2.GeographicFocus = t1.GeographicFocus and t2.DayEnding = t1.DayEnding")
    z <- c(z, "inner join", sql.label(x, "t3"))
    z <- c(z, paste0("\ton t3.FundId = t2.FundId and t3.", n, 
        " = t1.", n))
    if (y == "ActWtTrend") {
        y <- paste(y, sql.Trend("Flow * (Allocation - WtdAvg)", 
            ""))
    }
    else if (y == "ActWtDiff") {
        y <- paste(y, sql.Diff("Flow", "Allocation - WtdAvg", 
            ""))
    }
    else if (y == "ActWtDiff2") {
        y <- paste(y, sql.Diff("Allocation - WtdAvg", "Flow", 
            ""))
    }
    else stop("Bad Argument")
    y <- c(sql.yyyymmdd("t2.DayEnding", "DayEnding"), paste0("t3.", 
        n), y)
    z <- sql.tbl(y, z, , paste0("t2.DayEnding, t3.", n))
    z <- paste(sql.unbracket(z), collapse = "\n")
    z
}

#' sql.1dActWtTrend.Flow
#' 
#' SQL query for flows to compute ActWtTrend for Ctry/Sec
#' @param x = a flowdate
#' @param y = a filter vector
#' @keywords sql.1dActWtTrend.Flow
#' @export
#' @family sql

sql.1dActWtTrend.Flow <- function (x, y) 
{
    x <- list(A = wrap(x))
    z <- c("DayEnding", "FundId", "GeographicFocus = max(GeographicFocus)", 
        "Flow = sum(Flow)")
    x <- sql.Flow(z, x, c("CB", y, "UI"), "GeographicFocus", 
        T, paste(z[1:2], collapse = ", "))
    z <- sql.into(x, "#FLO")
    z
}

#' sql.1dActWtTrend.select
#' 
#' select statement to compute <x>
#' @param x = a variable
#' @keywords sql.1dActWtTrend.select
#' @export
#' @family sql

sql.1dActWtTrend.select <- function (x) 
{
    y <- ""
    if (grepl("(Num|Den)$", x)) {
        y <- txt.right(x, 3)
        x <- gsub(paste0(y, "$"), "", x)
    }
    if (x == "ActWtTrend") {
        z <- paste0(x, y, " ", sql.Trend("Flow * (t2.HoldingValue/PortVal - FundWtdExcl0)", 
            y))
    }
    else if (x == "ActWtDiff") {
        z <- paste0(x, y, " ", sql.Diff("Flow", "t2.HoldingValue/PortVal - FundWtdExcl0", 
            y))
    }
    else if (x == "ActWtDiff2") {
        z <- paste0(x, y, " ", sql.Diff("t2.HoldingValue/PortVal - FundWtdExcl0", 
            "Flow", y))
    }
    else if (x == "AllocSkew") {
        z <- "AllocSkew = sum(PortVal * sign(FundWtdExcl0 - t2.HoldingValue/PortVal))"
        z <- paste0(z, "/", sql.nonneg("sum(PortVal)"))
    }
    else stop("Bad Argument")
    z
}

#' sql.1dFloMo
#' 
#' SQL query for 1dFloMo for individual stocks
#' @param x = a flowdate vector
#' @param y = factors and filters
#' @param n = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @param w = a boolean (index by HSecurityId/SecurityId)
#' @param h = a breakdown filter vector (e.g. All/GeoId/DomicileId)
#' @param u = a ShareClass filter (All/Inst/Retail)
#' @param v = a boolean (chuck/keep securities held by just one fund)
#' @keywords sql.1dFloMo
#' @export
#' @family sql

sql.1dFloMo <- function (x, y, n, w, h, u = "All", v = F) 
{
    g <- yyyymmdd.to.AllocMo.unique(x, 26, T)
    z <- c(sql.drop("#AUM"), sql.1dFloMo.hld(g, ""), "")
    g <- c(z, sql.1dFloMo.aum(g, "AssetsEnd"))
    z <- sql.1dFloMo.select.wrapper(y, w, h, T)
    grp <- sql.1dFloMo.grp(w, h)
    if (v) {
        v <- ifelse(w, "HSecurityId", "SecurityId")
        v <- paste0("count(", v, ") > 1 and ")
    }
    else v <- NULL
    v <- paste0(v, "sum(HoldingValue/t3.AssetsEnd) > 0")
    x <- sql.DailyFlo(wrap(x), F, , u, h = T)
    y <- c(sql.label(sql.1dFloMo.filter(y, h), "t0"), "inner join", 
        "#HLD t1 on t1.FundId = t0.FundId")
    y <- c(y, "inner join", sql.label(x, "t2 on t2.HFundId = t0.HFundId"))
    y <- c(y, "inner join", "#AUM t3 on t3.FundId = t1.FundId")
    if (!w) 
        y <- c(y, "inner join", "SecurityHistory id on id.HSecurityId = t1.HSecurityId")
    if (n == "All") {
        z <- sql.tbl(z, y, , grp, v)
    }
    else {
        z <- sql.tbl(z, y, sql.in("t1.HSecurityId", sql.RDSuniv(n)), 
            grp, v)
    }
    z <- c(paste(g, collapse = "\n"), paste(sql.unbracket(z), 
        collapse = "\n"))
    z
}

#' sql.1dFloMo.aum
#' 
#' Underlying part of SQL query to get 1dFloMo for individual stocks
#' @param x = a month end
#' @param y = a column (name for AssetsEnd like "PortVal")
#' @param n = a boolean (introduce/correct rounding error)
#' @keywords sql.1dFloMo.aum
#' @export
#' @family sql

sql.1dFloMo.aum <- function (x, y, n = F) 
{
    z <- sql.MonthlyAssetsEnd(wrap(x), , T, , y)
    if (!n) {
        z <- sql.unbracket(z)
        z <- c("insert into", paste0("\t#AUM (FundId, ", y, ")"), 
            z)
        z <- c(sql.index("#AUM", "FundId"), z)
        z <- c(paste0("create table #AUM (FundId int not null, ", 
            y, " float not null)"), z)
    }
    else z <- sql.into(z, "#AUM")
    z
}

#' sql.1dFloMo.CountryId.List
#' 
#' map of security to CountryId
#' @param x = a string (Ctry/FX/Sector/EMDM/Aux)
#' @param y = a YYYYMM/YYYYMMDD
#' @keywords sql.1dFloMo.CountryId.List
#' @export
#' @family sql

sql.1dFloMo.CountryId.List <- function (x, y = "") 
{
    classif.type <- x
    sep <- ","
    if (x == "Ctry") {
        z <- Ctry.msci.members.rng("ACWI", "200704", "300012")
        classif.type <- "Ctry"
    }
    else if (x == "Aux") {
        z <- c("BG", "EE", "GH", "KE", "KZ", "LT", "UA", "NG", 
            "RO", "RS", "SI", "LK")
        classif.type <- "Ctry"
    }
    else if (x == "OtherFrontier") {
        z <- c("BH", "HR", "LB", "MU", "OM", "TN", "TT", "BD", 
            "CI", "IS")
        classif.type <- "Ctry"
    }
    else if (x == "APac") {
        z <- c("AU", "CN", "ID", "IN", "JP", "MY", "PH", "SG", 
            "TW", "NZ", "HK", "PK", "BD", "LK", "VN", "PG", "KH", 
            "MM", "MN", "KR", "TH")
        classif.type <- "Ctry"
    }
    else if (x == "LatAm") {
        z <- mat.read(parameters("classif-Ctry"))
        z <- rownames(z)[is.element(z$EpfrRgn, "Latin America")]
        classif.type <- "Ctry"
    }
    else if (x == "CountryFlow") {
        z <- mat.read(parameters("classif-Ctry"))
        z <- rownames(z)[!is.na(z$CountryId)]
        classif.type <- "Ctry"
    }
    else if (x == "EMDM") {
        z <- Ctry.msci.members("ACWI", y)
        classif.type <- "Ctry"
    }
    else if (x == "FX") {
        z <- Ctry.msci.members.rng("ACWI", "200704", "300012")
        z <- c(z, "CY", "EE", "LV", "LT", "SK", "SI")
        classif.type <- "Ctry"
    }
    else if (x == "Sector") {
        z <- rownames(mat.read(parameters("classif-GSec"), "\t"))
        classif.type <- "GSec"
        sep <- "\t"
    }
    else if (x == "Industry") {
        z <- rownames(mat.read(parameters("classif-GIgrp"), "\t"))
        classif.type <- "GIgrp"
        sep <- "\t"
    }
    else if (nchar(x) == 2) {
        z <- x
        classif.type <- "Ctry"
    }
    h <- parameters(paste("classif", classif.type, sep = "-"))
    h <- mat.read(h, sep)
    h <- map.rname(h, z)
    if (any(grepl("^(Ctry|CountryFlow|LatAm|APac|Aux|OtherFrontier)$", 
        x))) {
        z <- vec.named(z, h$CountryId)
    }
    else if (x == "EMDM") {
        w.dm <- is.element(z, c("US", "CA", Ctry.msci.members("EAFE", 
            y)))
        w.em <- is.element(z, Ctry.msci.members("EM", y))
        z <- c(vec.named(rep("DM", sum(w.dm)), h$CountryId[w.dm]), 
            vec.named(rep("EM", sum(w.em)), h$CountryId[w.em]))
    }
    else if (x == "FX") {
        z <- vec.named(h$Curr, h$CountryId)
    }
    else if (x == "Sector") {
        z <- vec.named(z, h$SectorId)
        z["30"] <- "FinsExREst"
    }
    else if (x == "Industry") {
        z <- vec.named(z, h$IndustryId)
    }
    else if (nchar(x) == 2) {
        z <- vec.named(z, h$CountryId)
    }
    z
}

#' sql.1dFloMo.CtrySG
#' 
#' SQL query for daily/weekly flow momentum by group
#' @param x = a flowdate/YYYYMMDD (backtest start)
#' @param y = a string (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param n = a string vector (group definitions)
#' @param w = a frequency (T/F for daily/weekly or D/W/M)
#' @param h = a filter vector
#' @param u = a boolean (institutional/all share classes)
#' @keywords sql.1dFloMo.CtrySG
#' @export
#' @family sql

sql.1dFloMo.CtrySG <- function (x, y, n, w, h, u) 
{
    y <- paste0(y, " = sum(", y, ")")
    y <- c("grp", sql.yyyymmdd(sql.Flow.tbl(w, F)), y)
    z <- sql.case("grp", n, c(names(n), "Other"), F)
    x <- list(A = paste0(sql.Flow.tbl(w, F), " >= '", x, "'"), 
        B = "not grp = 'Other'")
    if (u) 
        x[["C"]] <- sql.in("SCID", sql.tbl("SCID", "ShareClass", 
            "InstOrRetail = 'Inst'"))
    z <- sql.Flow(y, x, h, z, w, paste0(sql.Flow.tbl(w, F), ", grp"))
    z <- paste(sql.unbracket(z), collapse = "\n")
    z
}

#' sql.1dFloMo.FI
#' 
#' SQL query to get daily 1dFloMo for fixed income
#' @param x = a column (Flow/PortfolioChange)
#' @param y = a flowdate (can be missing)
#' @keywords sql.1dFloMo.FI
#' @export
#' @family sql

sql.1dFloMo.FI <- function (x = "Flow", y) 
{
    z <- list.rename(as.list(environment()), c("x", "y"), c("x", 
        "w"))
    z[["y"]] <- sql.1dFloMo.FI.grp()
    z[["n"]] <- "FundType in ('B', 'M')"
    z <- do.call(sql.1dFloMo.FI.underlying, z)
    z
}

#' sql.1dFloMo.FI.grp
#' 
#' named vector of fixed-income strategy groupings
#' @keywords sql.1dFloMo.FI.grp
#' @export
#' @family sql

sql.1dFloMo.FI.grp <- function () 
{
    z <- c("M", "FLOATS", "USTRIN", "USTRLT", "USTRST", "USMUNI", 
        "HYIELD", "WESEUR", "GLOBEM", "GLOFIX")
    z <- map.rname(vec.ex.filters("macro"), z)
    names(z)[1] <- "CASH"
    z
}

#' sql.1dFloMo.FI.underlying
#' 
#' SQL query to get daily 1dFloMo
#' @param x = a column (Flow/PortfolioChange)
#' @param y = a string vector (filters & names)
#' @param n = a filter vector
#' @param w = a flowdate (can be missing)
#' @keywords sql.1dFloMo.FI.underlying
#' @export
#' @family sql

sql.1dFloMo.FI.underlying <- function (x, y, n, w) 
{
    x <- vec.to.list(c(x, "AssetsStart"))
    x <- lapply(x, function(l) paste0("case when grp = '", names(y), 
        "' then ", l, " else NULL end"))
    x <- paste(names(y), sql.Mo(x[[1]], x[[2]], NULL, T))
    x <- c(sql.yyyymmdd("DayEnding"), x)
    z <- sql.case("grp", y, c(names(y), "OTHER"), F)
    if (missing(w)) {
        z <- sql.Flow(x, , n, z, "D", "DayEnding")
    }
    else {
        w <- paste("DayEnding >=", wrap(w))
        z <- sql.Flow(x, w, n, z, "D", "DayEnding")
    }
    z <- paste(sql.unbracket(z), collapse = "\n")
    z
}

#' sql.1dFloMo.filter
#' 
#' implements filters for 1dFloMo
#' @param x = factors and filters
#' @param y = a breakdown filter vector (e.g. All/GeoId/DomicileId)
#' @keywords sql.1dFloMo.filter
#' @export
#' @family sql

sql.1dFloMo.filter <- function (x, y) 
{
    sql.FundHistory(sql.arguments(x)$filter, T, c("FundId", sql.breakdown(y)))
}

#' sql.1dFloMo.grp
#' 
#' group by clause for 1dFloMo
#' @param x = a boolean (index by HSecurityId/SecurityId)
#' @param y = a breakdown filter vector (e.g. All/GeoId/DomicileId)
#' @keywords sql.1dFloMo.grp
#' @export
#' @family sql

sql.1dFloMo.grp <- function (x, y) 
{
    z <- c("ReportDate", ifelse(x, "HSecurityId", "SecurityId"), 
        sql.breakdown(y))
    z <- paste(z, collapse = ", ")
    z
}

#' sql.1dFloMo.hld
#' 
#' Query to insert <x> into flow table
#' @param x = a month end
#' @param y = a string ("" or SQL query)
#' @param n = a boolean (introduce/correct rounding error)
#' @keywords sql.1dFloMo.hld
#' @export
#' @family sql

sql.1dFloMo.hld <- function (x, y, n = F) 
{
    z <- sql.MonthlyAlloc(wrap(x))
    if (n) {
        z <- sql.into(z, "#HLD")
    }
    else {
        z <- c("insert into", "\t#HLD (FundId, HFundId, HSecurityId, HoldingValue)", 
            sql.unbracket(z))
        z <- c(sql.index("#HLD", "FundId, HSecurityId"), z)
        z <- c("create table #HLD (FundId int not null, HFundId int not null, HSecurityId int not null, HoldingValue float)", 
            z)
    }
    z <- c(sql.drop("#HLD"), "", z)
    if (y[1] != "") 
        z <- c(z, "", sql.delete("#HLD", sql.in("HSecurityId", 
            y, F)))
    z
}

#' sql.1dFloMo.Rgn
#' 
#' Generates the SQL query to get daily 1dFloMo for regions
#' @keywords sql.1dFloMo.Rgn
#' @export
#' @family sql

sql.1dFloMo.Rgn <- function () 
{
    z <- c("AsiaXJP", "EurXGB", "JP", "LatAm", "PacxJP", "UK", 
        "US")
    z <- map.rname(vec.ex.filters("macro"), z)
    names(z) <- c("AsiaXJP", "EurXGB", "Japan", "LatAm", "PacXJP", 
        "UK", "USA")
    z <- sql.1dFloMo.FI.underlying("Flow", z, c("E", "Act"))
    z
}

#' sql.1dFloMo.Sec.topline
#' 
#' top line SQL statement for daily/weekly CBE flow momentum
#' @param x = a string (SectorId/IndustryId)
#' @param y = a string (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param n = a temp table
#' @param w = a frequency (T/F for daily/weekly or D/W/M)
#' @keywords sql.1dFloMo.Sec.topline
#' @export
#' @family sql

sql.1dFloMo.Sec.topline <- function (x, y, n, w) 
{
    r <- sql.yyyymmdd(sql.Flow.tbl(w, F))
    r <- c(r, x, paste0(y, " = 0.0001 * sum(", y, " * Universe * Allocation)"))
    z <- c("#FLO t1", "inner join", "#CTRY t2 on t2.FundId = t1.FundId")
    z <- c(z, "inner join", paste(n, "t3 on t3.FundId = t1.FundId"))
    z <- sql.tbl(r, z, , paste0(sql.Flow.tbl(w, F), ", ", x))
    z <- paste(sql.unbracket(z), collapse = "\n")
    z
}

#' sql.1dFloMo.select
#' 
#' select statement to compute <x>
#' @param x = a variable
#' @keywords sql.1dFloMo.select
#' @export
#' @family sql

sql.1dFloMo.select <- function (x) 
{
    if (is.element(x, paste0("FloMo", c("", "CB", "PMA")))) {
        z <- paste(x, sql.Mo("Flow", "AssetsStart", "HoldingValue/t3.AssetsEnd", 
            T))
    }
    else if (x == "FloDollar") {
        z <- paste(x, "= sum(Flow * HoldingValue/t3.AssetsEnd)")
    }
    else if (x == "AssetsStartDollar") {
        z <- paste(x, "= sum(AssetsStart * HoldingValue/t3.AssetsEnd)")
    }
    else if (x == "AssetsEndDollar") {
        z <- paste(x, "= sum(t2.AssetsEnd * HoldingValue/t3.AssetsEnd)")
    }
    else if (x == "Inflow") {
        z <- paste(x, "= sum(case when Flow > 0 then Flow else 0 end * HoldingValue/t3.AssetsEnd)")
    }
    else if (x == "Outflow") {
        z <- paste(x, "= sum(case when Flow < 0 then Flow else 0 end * HoldingValue/t3.AssetsEnd)")
    }
    else if (x == "FloDollarGross") {
        z <- paste(x, "= sum(abs(Flow) * HoldingValue/t3.AssetsEnd)")
    }
    else stop("Bad Argument")
    z
}

#' sql.1dFloMo.select.wrapper
#' 
#' SQL query for 1mFloMo for individual stocks
#' @param x = factors and filters
#' @param y = a boolean (index by HSecurityId/SecurityId)
#' @param n = a breakdown filter vector (e.g. All/GeoId/DomicileId)
#' @param w = a boolean (ReportDate is/isn't a column)
#' @keywords sql.1dFloMo.select.wrapper
#' @export
#' @family sql

sql.1dFloMo.select.wrapper <- function (x, y, n, w = F) 
{
    x <- sql.arguments(x)$factor
    if (length(n) > 1) {
        z <- n
    }
    else if (n == "GeoId") {
        z <- "GeoId = GeographicFocus"
    }
    else {
        z <- sql.breakdown(n)
    }
    if (y | w) 
        z <- c(sql.yyyymmdd("ReportDate", , y), z)
    z <- c(z, ifelse(y, "HSecurityId", "SecurityId"))
    for (i in x) {
        if (y & i == "FloDollar") {
            z <- c(z, gsub(paste0("^", i), "CalculatedStockFlow", 
                sql.1dFloMo.select(i)))
        }
        else {
            z <- c(z, sql.1dFloMo.select(i))
        }
    }
    z
}

#' sql.1dFloTrend.Alloc
#' 
#' SQL query for allocation table for FloTrend
#' @param x = a YYYYMM
#' @param y = a temp table
#' @param n = a column (SectorId/CountryId)
#' @param w = a string vector (identifiers)
#' @keywords sql.1dFloTrend.Alloc
#' @export
#' @family sql

sql.1dFloTrend.Alloc <- function (x, y, n, w = NULL) 
{
    z <- sql.drop(y)
    z <- c(z, paste0("create table ", y, " (FundId int not null, ", 
        n, " int not null, Allocation float)"))
    z <- c(z, "", "insert into", paste0("\t", y, " (FundId, ", 
        n, ", Allocation)"), sql.1dFloTrend.Alloc.fetch(x, n, 
        w, F, T))
    z <- c(z, "", "insert into", paste0("\t", y, " (FundId, ", 
        n, ", Allocation)"), sql.1dFloTrend.Alloc.fetch(yyyymm.lag(x), 
        n, w, T, T))
    z
}

#' sql.1dFloTrend.Alloc.data
#' 
#' gets data for FloTrend
#' @param x = a SQL query
#' @param y = a country-code/sector-code vector (indexed by Id)
#' @param n = a connection string/connection
#' @keywords sql.1dFloTrend.Alloc.data
#' @export
#' @family sql

sql.1dFloTrend.Alloc.data <- function (x, y, n) 
{
    z <- sql.query(x, n, F)
    z <- reshape.wide(z)
    z <- map.rname(t(z), names(y))
    rownames(z) <- y
    z
}

#' sql.1dFloTrend.Alloc.fetch
#' 
#' SQL query for allocation table for FloTrend
#' @param x = a YYYYMM
#' @param y = a column (SectorId/CountryId)
#' @param n = a string vector (identifiers)
#' @param w = a boolean (reverse/leave alone sign)
#' @param h = a boolean (do/don't unbracket)
#' @keywords sql.1dFloTrend.Alloc.fetch
#' @export
#' @family sql

sql.1dFloTrend.Alloc.fetch <- function (x, y, n, w, h) 
{
    z <- paste0("ReportDate = '", yyyymm.to.day(x), "'")
    if (!is.null(n)) 
        z <- sql.and(list(A = z, B = paste0(y, " in (", paste(n, 
            collapse = ", "), ")")))
    w <- ifelse(w, "Allocation = -Allocation", "Allocation")
    z <- sql.Allocation(c("FundId", y, w), gsub("..$", "", y), 
        , , z)
    if (h) 
        z <- sql.unbracket(z)
    z
}

#' sql.1dFloTrend.Alloc.final
#' 
#' SQL query for daily/weekly FloTrend
#' @param x = a from clause
#' @param y = factor (one of FloTrend/FloDiff/FloDiff2)
#' @param n = a column (SectorId/CountryId)
#' @param w = a frequency (T/F for daily/weekly or D/W/M)
#' @keywords sql.1dFloTrend.Alloc.final
#' @export
#' @family sql

sql.1dFloTrend.Alloc.final <- function (x, y, n, w) 
{
    if (y == "FloTrend") {
        y <- paste(y, sql.Trend("Flow * Allocation", ""))
    }
    else if (y == "FloDiff") {
        y <- paste(y, sql.Diff("Flow", "Allocation", ""))
    }
    else if (y == "FloDiff2") {
        y <- paste(y, sql.Diff("Allocation", "Flow", ""))
    }
    else stop("Bad Argument")
    w <- sql.Flow.tbl(w, F)
    y <- c(sql.yyyymmdd(w), n, y)
    z <- sql.tbl(y, x, , paste0(w, ", ", n))
    z <- paste(sql.unbracket(z), collapse = "\n")
    z
}

#' sql.1dFloTrend.Alloc.from
#' 
#' SQL query for daily/weekly FloTrend
#' @param x = a flowdate/YYYYMMDD (depending on whether daily/weekly)
#' @param y = a temp table
#' @param n = a column (SectorId/CountryId)
#' @param w = a frequency (T/F for daily/weekly or D/W/M)
#' @param h = a filter vector
#' @keywords sql.1dFloTrend.Alloc.from
#' @export
#' @family sql

sql.1dFloTrend.Alloc.from <- function (x, y, n, w, h) 
{
    x <- list(A = wrap(x))
    z <- c(sql.Flow.tbl(w, F), "FundId", "Flow")
    z <- sql.label(sql.Flow(z, x, c("CB", h, "UI"), , w), "t1")
    r <- c("FundId", n, "Allocation = sum(Allocation)")
    r <- sql.tbl(r, y, , paste(r[1:2], collapse = ", "))
    z <- c(z, "inner join", sql.label(r, "t2"), "\ton t2.FundId = t1.FundId")
    z
}

#' sql.1dFloTrend.Alloc.purge
#' 
#' Ensures two sets of entries
#' @param x = a temp table
#' @param y = a column (SectorId/CountryId)
#' @keywords sql.1dFloTrend.Alloc.purge
#' @export
#' @family sql

sql.1dFloTrend.Alloc.purge <- function (x, y) 
{
    h <- c("FundId", y)
    z <- sql.tbl(h, x, , paste(h, collapse = ", "), "not count(Allocation) = 2")
    h <- lapply(split(h, h), function(z) paste0(x, ".", z, " = t.", 
        z))
    z <- sql.tbl(c("FundId", y), sql.label(z, "t"), sql.and(h))
    z <- sql.delete(x, sql.exists(z))
    z
}

#' sql.1dFundCt
#' 
#' Generates FundCt, the ownership breadth measure set forth in #		:	Chen, Hong & Stein (2001)"Breadth of ownership and stock returns"
#' @param x = a flowdate vector
#' @param y = factors and filters
#' @param n = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @param w = a boolean (index by HSecurityId/SecurityId)
#' @param h = a breakdown filter vector (e.g. All/GeoId/DomicileId)
#' @param u = a boolean (chuck/keep securities held by just one fund)
#' @keywords sql.1dFundCt
#' @export
#' @family sql

sql.1dFundCt <- function (x, y, n, w, h, u = F) 
{
    mo.end <- yyyymmdd.to.AllocMo.unique(x, 26, T)
    x <- wrap(x)
    if (length(x) == 1) 
        x <- paste("=", x)
    else x <- paste0("in (", paste(x, collapse = ", "), ")")
    x <- paste("flo.ReportDate", x)
    y <- sql.arguments(y)
    if (n != "All") 
        n <- list(A = sql.in("h.HSecurityId", sql.RDSuniv(n)))
    else n <- list()
    n[[LETTERS[length(n) + 1]]] <- paste0("h.ReportDate = '", 
        mo.end, "'")
    n[[LETTERS[length(n) + 1]]] <- x
    if (y$filter != "All") 
        n[[LETTERS[length(n) + 1]]] <- sql.FundHistory.sf(y$filter)
    if (length(n) == 1) 
        n <- n[[1]]
    else n <- sql.and(n)
    if (all(h == "GeoId")) 
        z <- "GeoId = GeographicFocus"
    else z <- setdiff(h, "All")
    if (w) 
        z <- c(z, "HSecurityId")
    else z <- c("SecurityId", z)
    if (w) 
        z <- c(sql.yyyymmdd("flo.ReportDate", "ReportDate", w), 
            z)
    for (j in y$factor) {
        if (j == "FundCt") {
            z <- c(z, paste(j, "count(distinct flo.HFundId)", 
                sep = " = "))
        }
        else {
            stop("Bad factor", j)
        }
    }
    v <- c("inner join", "Holdings h on h.FundId = his.FundId")
    v <- c("DailyData flo", "inner join", "FundHistory his on his.HFundId = flo.HFundId", 
        v)
    if (!w) 
        v <- c(v, "inner join", "SecurityHistory id on id.HSecurityId = h.HSecurityId")
    if (u) {
        u <- ifelse(w, "HSecurityId", "SecurityId")
        u <- paste0("count(", u, ") > 1")
    }
    else u <- ""
    if (w) 
        w <- c("flo.ReportDate", "HSecurityId")
    else w <- "SecurityId"
    w <- paste(c(w, sql.breakdown(h)), collapse = ", ")
    z <- paste(sql.unbracket(sql.tbl(z, v, n, w, u)), collapse = "\n")
    z
}

#' sql.1mActWt
#' 
#' SQL query to get the following active weights: #		:	a) EqlAct = equal weight average (incl 0) less the benchmark #		:	b) CapAct = fund weight average (incl 0) less the benchmark #		:	c) PosAct = fund weight average (incl 0) less the benchmark (positive flows only) #		:	d) NegAct = fund weight average (incl 0) less the benchmark (negative flows only)
#' @param x = a YYYYMM
#' @param y = a string vector (FundId and BenchIndexId)
#' @keywords sql.1mActWt
#' @export
#' @family sql

sql.1mActWt <- function (x, y) 
{
    w <- c("Eql", "Cap", "Pos", "Neg")
    w <- c("SecurityId", paste0(w, "Act = ", w, "Wt - BmkWt"))
    z <- c("SecurityId", "EqlWt = sum(HoldingValue/AssetsEnd)/count(AssetsEnd)", 
        "CapWt = sum(HoldingValue)/sum(AssetsEnd)", "BmkWt = avg(BmkWt)")
    z <- c(z, "PosWt = sum(case when Flow > 0 then HoldingValue else NULL end)/sum(case when Flow > 0 then AssetsEnd else NULL end)")
    z <- c(z, "NegWt = sum(case when Flow < 0 then HoldingValue else NULL end)/sum(case when Flow < 0 then AssetsEnd else NULL end)")
    z <- sql.unbracket(sql.tbl(w, sql.label(sql.tbl(z, sql.1mActWt.underlying(0, 
        "\t"), , "SecurityId"), "t")))
    z <- paste(c(sql.declare(c("@fundId", "@bmkId", "@allocDt"), 
        c("int", "int", "datetime"), c(y, yyyymm.to.day(x))), 
        z), collapse = "\n")
    z
}

#' sql.1mActWt.underlying
#' 
#' Generates tail end of a SQL query
#' @param x = the month for which you want data (0 = latest, 1 = lagged one month, etc.)
#' @param y = a string (prefix)
#' @keywords sql.1mActWt.underlying
#' @export
#' @family sql

sql.1mActWt.underlying <- function (x, y) 
{
    w <- list(A = paste("datediff(month, ReportDate, @allocDt) =", 
        x), B = sql.in("HFundId", sql.tbl("HFundId", "FundHistory", 
        "FundId = @fundId")))
    z <- c(sql.label(sql.tbl("HSecurityId, HoldingValue", "Holdings", 
        sql.and(w)), "t1"), "cross join")
    w <- list(A = paste("datediff(month, ReportDate, @allocDt) =", 
        x), B = sql.in("HFundId", sql.tbl("HFundId", "FundHistory", 
        "FundId = @fundId")))
    z <- c(z, sql.label(sql.tbl("AssetsEnd = sum(AssetsEnd)", 
        "MonthlyData", sql.and(w)), "t2"))
    z <- sql.label(paste0("\t", sql.tbl("HSecurityId, BmkWt = HoldingValue/AssetsEnd", 
        z)), "t0 -- Securities in the benchmark At Month End")
    w <- list(A = paste("datediff(month, ReportDate, @allocDt) =", 
        x))
    w[["B"]] <- sql.in("HFundId", sql.tbl("HFundId", "FundHistory", 
        "BenchIndexId = @bmkId"))
    w[["C"]] <- sql.in("HFundId", sql.Holdings(paste("datediff(month, ReportDate, @allocDt) =", 
        x), "HFundId"))
    w <- paste0("\t", sql.MonthlyAssetsEnd(w, "Flow"))
    z <- c(z, "cross join", sql.label(w, "t1 -- Funds Reporting Both Monthly Flows and Allocations with the right benchmark"))
    z <- c(z, "left join", paste0("\t", sql.Holdings(paste("datediff(month, ReportDate, @allocDt) =", 
        x), c("HSecurityId", "HFundId", "HoldingValue"))))
    z <- c(sql.label(z, "t2"), "\t\ton t2.HFundId = t1.HFundId and t2.HSecurityId = t0.HSecurityId", 
        "inner join")
    z <- c(z, "\tSecurityHistory id on id.HSecurityId = t0.HSecurityId")
    z <- paste0(y, z)
    z
}

#' sql.1mAllocD
#' 
#' SQL query for 1mAllocD
#' @param x = a YYYYMM/flowdate vector
#' @param y = factors and filters
#' @param n = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @param w = a boolean (index by HSecurityId/SecurityId)
#' @param h = a boolean (account for/ignore price action)
#' @param u = one of AssetsStart/Flow/NULL
#' @param v = a boolean (chuck/keep securities held by just one fund)
#' @param g = a ShareClass filter (All/Inst/Retail, x not monthly!)
#' @param r = a boolean (full outer/inner join)
#' @keywords sql.1mAllocD
#' @export
#' @family sql

sql.1mAllocD <- function (x, y, n, w, h, u = NULL, v = T, g = "All", r = T) 
{
    has.dt <- !yyyymm.exists(x[1])
    if (r) 
        r <- "full outer join"
    else r <- "inner join"
    y <- sql.arguments(y)
    z <- u
    if (has.dt) {
        u <- sql.DailyFlo(wrap(x), , , g)
        x <- yyyymmdd.to.AllocMo.unique(x, 26, F)
        l <- sql.FundHistory(y$filter, T, "FundId")
        l <- sql.label(l, "t2 on t2.HFundId = t1.HFundId")
        y$filter <- "All"
        u <- c(sql.label(u, "t1"), "inner join", l)
        l <- c("ReportDate", "FundId", "Flow")
        u <- sql.label(sql.tbl(l, u), "t3 on t3.FundId = isnull(t1.FundId, t2.FundId)")
        u <- c("inner join", u)
        z <- NULL
    }
    else if (!is.null(u)) {
        u <- c("inner join", "#NEWAUM t3 on t3.FundId = isnull(t1.FundId, t2.FundId)")
    }
    z <- sql.1mAllocD.data(x, y$filter, h, F, T, z)
    h <- paste(z, collapse = "\n")
    if (w) 
        z <- "HSecurityId"
    else z <- "SecurityId"
    l <- paste0("isnull(t1.", z, ", t2.", z, ")")
    z <- paste(z, "=", l)
    if (has.dt) {
        z <- c(sql.yyyymmdd("ReportDate", , w), z)
    }
    else if (w) {
        z <- c(sql.ReportDate(yyyymm.to.day(x)), z)
    }
    for (i in y$factor) z <- c(z, sql.1mAllocD.select(i))
    u <- c("#OLDHLD t2 on t2.FundId = t1.FundId and t2.SecurityId = t1.SecurityId", 
        u)
    u <- c("#NEWHLD t1", r, u)
    if (has.dt) 
        has.dt <- paste("ReportDate,", l)
    else has.dt <- l
    if (v) 
        v <- paste0("count(", l, ") > 1")
    else v <- ""
    if (n != "All") {
        n <- sql.RDSuniv(n)
        n <- sql.in("isnull(t1.HSecurityId, t2.HSecurityId)", 
            n)
    }
    else n <- ""
    z <- sql.tbl(z, u, n, has.dt, v)
    z <- c(h, paste(sql.unbracket(z), collapse = "\n"))
    z
}

#' sql.1mAllocD.data
#' 
#' SQL query to get the data for AllocD
#' @param x = a YYYYMM
#' @param y = a filter (one of All/Act/Pas/Etf/Mutual)
#' @param n = a boolean (account for/ignore price action)
#' @param w = a boolean (excise/leave leveraged funds)
#' @param h = a boolean (excise/leave in fake security -999)
#' @param u = a column vector (besides AssetsEnd)
#' @keywords sql.1mAllocD.data
#' @export
#' @family sql

sql.1mAllocD.data <- function (x, y, n, w, h, u = NULL) 
{
    fcn <- function(z) sql.1mAllocD.data.underlying(z, u)
    if (n) {
        z <- sql.currprior(fcn, x, c("#OLDHLD", "#NEWHLD"), c("#OLDAUM", 
            "#NEWAUM"), c("#OLDPRC", "#NEWPRC"))
        z <- c(sql.drop(c("#OLDHLD", "#NEWHLD", "#OLDAUM", "#NEWAUM", 
            "#OLDPRC", "#NEWPRC")), "", z)
    }
    else {
        z <- sql.currprior(fcn, x, c("#OLDHLD", "#NEWHLD"), c("#OLDAUM", 
            "#NEWAUM"))
        z <- c(sql.drop(c("#OLDHLD", "#NEWHLD", "#OLDAUM", "#NEWAUM")), 
            "", z)
    }
    fcnS <- function(z, l) {
        v <- "HoldingValue = HoldingValue + AUM, SharesHeld = SharesHeld + AUM, Allocation = Allocation + AUM"
        h <- sql.in("SecurityId", sql.tbl("SecurityId", l), F)
        h <- sql.tbl(c("FundId", "AUM = sum(HoldingValue)"), 
            z, h, "FundId")
        r <- sql.and(list(A = paste0("t.FundId = ", z, ".FundId"), 
            B = "SecurityId = -999"))
        sql.update(z, v, sql.label(h, "t"), r)
    }
    z <- c(z, "", fcnS("#OLDHLD", "#NEWHLD"))
    z <- c(z, "", fcnS("#NEWHLD", "#OLDHLD"))
    z <- c(z, "", sql.common(c("#NEWHLD", "#OLDHLD"), "SecurityId"))
    v <- c("SecurityId", "HSecurityId = max(HSecurityId)")
    v <- sql.label(sql.tbl(v, "#NEWHLD", , "SecurityId"), "t")
    v <- sql.update("#OLDHLD", "HSecurityId = t.HSecurityId", 
        v, "#OLDHLD.SecurityId = t.SecurityId")
    z <- c(z, "", v)
    if (any(y != "All")) {
        v <- sql.in("HFundId", sql.FundHistory(y, T), F)
        z <- c(z, "", sql.delete("#NEWHLD", v))
    }
    fcnW <- function(z) {
        h <- c("FundId", "AssetsEnd = sum(HoldingValue)")
        h <- sql.label(sql.tbl(h, z, , "FundId"), "t")
        sql.update(z, "Allocation = 100 * HoldingValue/AssetsEnd", 
            h, paste0("t.FundId = ", z, ".FundId"))
    }
    z <- c(z, "", fcnW("#OLDHLD"), "", fcnW("#NEWHLD"))
    fcnL <- function(z) {
        h <- list(A = "SecurityId = -999", B = "Allocation < -5")
        h <- sql.tbl("FundId", z, sql.and(h))
        sql.delete(z, sql.in("FundId", h))
    }
    if (w) 
        z <- c(z, "", fcnL("#OLDHLD"), "", fcnL("#NEWHLD"))
    z <- c(z, "", sql.common(c("#NEWHLD", "#OLDHLD"), "FundId"))
    if (n) {
        v <- c("#OLDPRC o", "inner join", "#NEWPRC n on n.SecurityId = o.SecurityId")
        y <- sql.and(list(A = "n.Stat > 0", B = "o.Stat > 0"))
        v <- sql.tbl(c("o.SecurityId", "Mult = n.Stat/o.Stat"), 
            v, y)
        z <- c(z, "", sql.update("#OLDHLD", "HoldingValue = HoldingValue * Mult", 
            sql.label(v, "t"), "t.SecurityId = #OLDHLD.SecurityId"))
        z <- c(z, "", fcnW("#OLDHLD"))
    }
    if (h) {
        z <- c(z, "", sql.delete("#OLDHLD", "SecurityId = -999"))
        z <- c(z, "", sql.delete("#NEWHLD", "SecurityId = -999"))
    }
    z
}

#' sql.1mAllocD.data.underlying
#' 
#' SQL query to get raw data for AllocD
#' @param x = a string vector (parameters)
#' @param y = a column vector (besides AssetsEnd)
#' @keywords sql.1mAllocD.data.underlying
#' @export
#' @family sql

sql.1mAllocD.data.underlying <- function (x, y) 
{
    z <- c("Holdings t", "inner join", "SecurityHistory id on id.HSecurityId = t.HSecurityId")
    v <- c("FundId", "HFundId", "t.HSecurityId", "SecurityId", 
        "HoldingValue", "SharesHeld", "Allocation = HoldingValue")
    z <- sql.tbl(v, z, paste("ReportDate =", wrap(x[1])))
    v <- paste("create table", x[2], "(FundId int not null, HFundId int not null, HSecurityId int not null, SecurityId int not null, HoldingValue float, SharesHeld float, Allocation float)")
    z <- c(v, "insert into", paste0("\t", x[2], " (FundId, HFundId, HSecurityId, SecurityId, HoldingValue, SharesHeld, Allocation)"), 
        sql.unbracket(z))
    z <- c(z, "", sql.into(sql.MonthlyAssetsEnd(wrap(x[1]), y, 
        T), x[3]))
    if (length(x) > 3) {
        h <- c("SecurityId", "FundId", "Price = 1000000 * HoldingValue/SharesHeld")
        h <- sql.tbl(h, x[2], "SharesHeld > 0")
        h <- sql.median("Price", "SecurityId", h)
        z <- c(z, "", sql.into(h, x[4]))
        z <- c(z, "", "insert into", paste0("\t", x[4], " (SecurityId, Stat)"), 
            "values (-999, 1000000)")
    }
    z <- c(z, "", sql.delete(x[2], sql.in("FundId", sql.tbl("FundId", 
        x[3]), F)))
    h <- c("FundId", "HFundId", "HoldingValue = sum(HoldingValue)")
    h <- sql.tbl(h, x[2], , "FundId, HFundId")
    h <- c(sql.label(h, "t1"), "inner join", sql.label(x[3], 
        "t2 on t2.FundId = t1.FundId"))
    v <- c("t1.FundId", "HFundId", "HSecurityId = -999", "SecurityId = -999", 
        "HoldingValue = AssetsEnd - HoldingValue", "SharesHeld = AssetsEnd - HoldingValue", 
        "Allocation = AssetsEnd - HoldingValue")
    h <- sql.tbl(v, h)
    z <- c(z, "", "insert into", paste0("\t", x[2], " (FundId, HFundId, HSecurityId, SecurityId, HoldingValue, SharesHeld, Allocation)"), 
        sql.unbracket(h))
    z
}

#' sql.1mAllocD.select
#' 
#' select term to compute <x>
#' @param x = the factor to be computed
#' @keywords sql.1mAllocD.select
#' @export
#' @family sql

sql.1mAllocD.select <- function (x) 
{
    z <- vec.read(parameters("classif-AllocD"), "\t")
    if (any(x == names(z))) 
        z <- as.character(z[x])
    else stop("Bad Argument")
    z <- paste0("[", x, "] = ", z)
    z
}

#' sql.1mAllocSkew
#' 
#' SQL query for AllocSkew
#' @param x = a YYYYMM
#' @param y = factors and filters
#' @param n = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @param w = a boolean (index by HSecurityId/SecurityId)
#' @param h = a ShareClass filter (All/Inst/Retail)
#' @param u = a boolean (chuck/keep securities held by just one fund)
#' @keywords sql.1mAllocSkew
#' @export
#' @family sql

sql.1mAllocSkew <- function (x, y, n, w, h = "All", u = F) 
{
    y <- sql.arguments(y)
    z <- sql.1mAllocSkew.underlying(x, y$filter, sql.RDSuniv(n), 
        h)
    z <- c(z, sql.1mAllocSkew.topline(y$factor, w, nchar(x[1]) == 
        8, u))
    z
}

#' sql.1mAllocSkew.topline
#' 
#' SQL query for 1mAllocSkew
#' @param x = a variable vector
#' @param y = a boolean (index by HSecurityId/SecurityId)
#' @param n = a boolean (ReportDate must/needn't be a column)
#' @param w = a boolean (chuck/keep securities held by just one fund)
#' @keywords sql.1mAllocSkew.topline
#' @export
#' @family sql

sql.1mAllocSkew.topline <- function (x, y, n, w) 
{
    if (n & any(x == "AllocSkew")) 
        stop("Can't run AllocSkew on daily data!")
    z <- h <- ifelse(y, "t2.HSecurityId", "SecurityId")
    if (w) 
        w <- paste0("count(", h, ") > 1")
    else w <- ""
    if (y | n) {
        z <- c(sql.yyyymmdd("t1.ReportDate", "ReportDate", y), 
            z)
        h <- paste0(h, ", t1.ReportDate")
    }
    z <- c(z, sapply(vec.to.list(x), sql.1dActWtTrend.select))
    x <- sql.1mAllocSkew.topline.from("#FLO", y)
    z <- paste(sql.unbracket(sql.tbl(z, x, , h, w)), collapse = "\n")
    z
}

#' sql.1mAllocSkew.topline.from
#' 
#' from part of the final select statement in 1mAllocTrend
#' @param x = a temp table
#' @param y = a boolean (index by HSecurityId/SecurityId)
#' @keywords sql.1mAllocSkew.topline.from
#' @export
#' @family sql

sql.1mAllocSkew.topline.from <- function (x, y) 
{
    w <- c("ReportDate", "HSecurityId", "GeographicFocus", "FundWtdExcl0 = sum(HoldingValue)/sum(PortVal)")
    z <- c(sql.label(x, "t1"), "inner join", "#HLD t2 on t2.FundId = t1.FundId", 
        "inner join", "#AUM t3 on t3.FundId = t1.FundId")
    w <- sql.label(sql.tbl(w, z, , paste(w[-length(w)], collapse = ", ")), 
        "mnW")
    z <- c(sql.label(x, "t1"), "inner join", "#HLD t2 on t2.FundId = t1.FundId", 
        "inner join", "#AUM t3 on t3.FundId = t1.FundId", "inner join")
    z <- c(z, w, "\ton mnW.ReportDate = t1.ReportDate and mnW.HSecurityId = t2.HSecurityId and mnW.GeographicFocus = t1.GeographicFocus")
    if (!y) 
        z <- c(z, "inner join", "SecurityHistory id on id.HSecurityId = t2.HSecurityId")
    z
}

#' sql.1mAllocSkew.underlying
#' 
#' the SQL query to get the data for 1dActWtTrend
#' @param x = a YYYYMM/flowdate vector
#' @param y = a filter vector
#' @param n = a string ("" or SQL query)
#' @param w = a ShareClass filter (All/Inst/Retail)
#' @param h = a boolean (introduce/correct rounding error, can be missing)
#' @keywords sql.1mAllocSkew.underlying
#' @export
#' @family sql

sql.1mAllocSkew.underlying <- function (x, y, n, w, h) 
{
    dly <- !yyyymm.exists(x[1])
    if (missing(h)) 
        h <- !dly
    if (dly) {
        mo.end <- yyyymmdd.to.AllocMo.unique(x, 26, T)
    }
    else {
        mo.end <- x <- yyyymm.to.day(x)
    }
    x <- wrap(x)
    if (length(x) == 1) 
        x <- paste("=", x)
    else x <- paste0("in (", paste(x, collapse = ", "), ")")
    x <- paste("ReportDate", x)
    x <- sql.ShareClass(x, w)
    z <- sql.drop(c("#FLO", "#AUM"))
    z <- c(z, sql.1dFloMo.hld(mo.end, n, h))
    z <- c(z, "", sql.1dFloMo.aum(mo.end, "PortVal", h))
    z <- c(z, "", sql.1mAllocSkew.underlying.basic(x, y, dly))
    z <- paste(z, collapse = "\n")
    z
}

#' sql.1mAllocSkew.underlying.basic
#' 
#' Query to insert <x> into flow table
#' @param x = a where clause (date restriction)
#' @param y = a filter vector
#' @param n = a boolean (daily/monthly)
#' @keywords sql.1mAllocSkew.underlying.basic
#' @export
#' @family sql

sql.1mAllocSkew.underlying.basic <- function (x, y, n) 
{
    if (n) 
        n <- "DailyData"
    else n <- "MonthlyData"
    z <- c(sql.label(n, "t1"), "inner join", sql.label(sql.FundHistory(y, 
        T, c("FundId", "GeographicFocus")), "t2"), "on t2.HFundId = t1.HFundId")
    z <- sql.tbl("ReportDate, FundId, GeographicFocus = max(GeographicFocus), Flow = sum(Flow), AssetsStart = sum(AssetsStart)", 
        z, x, "ReportDate, FundId")
    z <- c("insert into", "\t#FLO (ReportDate, FundId, GeographicFocus, Flow, AssetsStart)", 
        sql.unbracket(z))
    z <- c(sql.index("#FLO", "ReportDate, FundId"), z)
    z <- c("create table #FLO (ReportDate datetime not null, FundId int not null, GeographicFocus int, Flow float, AssetsStart float)", 
        z)
    z
}

#' sql.1mBullish.Alloc
#' 
#' SQL query for monthly Bullish sector indicator
#' @param x = a string (SQL statement)
#' @param y = SectorId/CountryId
#' @param n = a temp table
#' @keywords sql.1mBullish.Alloc
#' @export
#' @family sql

sql.1mBullish.Alloc <- function (x, y, n) 
{
    z <- paste("create table", n, "(FundId int not null,", y, 
        "int not null, BenchIndex int, Idx char(1), Allocation float)")
    z <- c(z, c(sql.index(n, paste("FundId,", y)), x))
    z <- c(z, "", sql.BenchIndex.duplication(n))
    z <- c(z, "", sql.update(n, "Idx = 'N'", , "Idx is NULL"))
    z <- paste(c(sql.drop(n), "", z), collapse = "\n")
    z
}

#' sql.1mBullish.Final
#' 
#' SQL query for monthly Bullish sector indicator
#' @param x = SectorId/CountryId
#' @param y = a temp table
#' @keywords sql.1mBullish.Final
#' @export
#' @family sql

sql.1mBullish.Final <- function (x, y) 
{
    r <- "Bullish = 100 * sum(case when t1.Allocation > t2.Allocation then 1.0 else 0.0 end)/count(t1.FundId)"
    r <- c(paste0("t1.", x), r)
    z <- paste0("BenchIndex, ", x, ", Allocation = avg(Allocation)")
    z <- sql.tbl(z, y, "Idx = 'Y'", paste("BenchIndex,", x))
    z <- sql.label(z, paste0("t2 on t2.BenchIndex = t1.BenchIndex and t2.", 
        x, " = t1.", x))
    z <- c(paste(y, "t1"), "inner join", z)
    z <- sql.unbracket(sql.tbl(r, z, "Idx = 'N'", paste0("t1.", 
        x)))
    z <- paste(z, collapse = "\n")
    z
}

#' sql.1mChActWt
#' 
#' SQL query to get the following active weights: #		:	a) EqlChAct = equal weight average change in active weight #		:	b) BegChAct = beginning-of-period-asset weighted change in active weight #		:	c) EndChAct = end-of-period-asset weighted change in active weight #		:	d) BegPosChAct = beginning-of-period-asset weighted change in active weight (positive flows only) #		:	e) EndPosChAct = end-of-period-asset weighted change in active weight (positive flows only) #		:	f) BegNegChAct = beginning-of-period-asset weighted change in active weight (negative flows only) #		:	g) EndNegChAct = end-of-period-asset weighted change in active weight (negative flows only)
#' @param x = a YYYYMM
#' @param y = a string vector (FundId and BenchIndexId)
#' @keywords sql.1mChActWt
#' @export
#' @family sql

sql.1mChActWt <- function (x, y) 
{
    x <- sql.declare(c("@fundId", "@bmkId", "@allocDt"), c("int", 
        "int", "datetime"), c(y, yyyymm.to.day(x)))
    w <- sql.tbl("SecurityId, t1.HFundId, ActWt = isnull(HoldingValue, 0)/AssetsEnd - BmkWt, AssetsEnd, Flow", 
        sql.1mActWt.underlying(0, ""))
    z <- c("FundHistory t1", "inner join", sql.label(w, "t2"), 
        "\ton t2.HFundId = t1.HFundId", "inner join", "FundHistory t3")
    w <- sql.tbl("SecurityId, t1.HFundId, ActWt = isnull(HoldingValue, 0)/AssetsEnd - BmkWt, AssetsEnd", 
        sql.1mActWt.underlying(1, ""))
    w <- c(z, "\ton t3.FundId = t1.FundId", "inner join", sql.label(w, 
        "t4"), "\ton t4.HFundId = t3.HFundId and t4.SecurityId = t2.SecurityId")
    z <- c("t2.SecurityId", "EqlChAct = avg(t2.ActWt - t4.ActWt)")
    z <- c(z, "BegChAct = sum(t4.AssetsEnd * (t2.ActWt - t4.ActWt))/sum(t4.AssetsEnd)")
    z <- c(z, "EndChAct = sum(t2.AssetsEnd * (t2.ActWt - t4.ActWt))/sum(t2.AssetsEnd)")
    z <- c(z, "BegPosChAct = sum(case when Flow > 0 then t4.AssetsEnd else NULL end * (t2.ActWt - t4.ActWt))/sum(case when Flow > 0 then t4.AssetsEnd else NULL end)")
    z <- c(z, "EndPosChAct = sum(case when Flow > 0 then t2.AssetsEnd else NULL end * (t2.ActWt - t4.ActWt))/sum(case when Flow > 0 then t2.AssetsEnd else NULL end)")
    z <- c(z, "BegNegChAct = sum(case when Flow < 0 then t4.AssetsEnd else NULL end * (t2.ActWt - t4.ActWt))/sum(case when Flow < 0 then t4.AssetsEnd else NULL end)")
    z <- c(z, "EndNegChAct = sum(case when Flow < 0 then t2.AssetsEnd else NULL end * (t2.ActWt - t4.ActWt))/sum(case when Flow < 0 then t2.AssetsEnd else NULL end)")
    z <- paste(c(x, "", sql.unbracket(sql.tbl(z, w, , "t2.SecurityId"))), 
        collapse = "\n")
    z
}

#' sql.1mFundCt
#' 
#' Generates FundCt, the ownership breadth measure set forth in #		:	Chen, Hong & Stein (2001)"Breadth of ownership and stock returns"
#' @param x = a YYYYMM
#' @param y = factors and filters
#' @param n = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @param w = a boolean (index by HSecurityId/SecurityId)
#' @param h = a breakdown filter (e.g. All/GeoId/DomicileId)
#' @param u = an integer (count only that many funds unless zero)
#' @param v = a ShareClass filter (All/Inst/Retail)
#' @param g = a boolean (chuck/keep securities held by just one fund)
#' @keywords sql.1mFundCt
#' @export
#' @family sql

sql.1mFundCt <- function (x, y, n, w, h, u = 0, v = "All", g = F) 
{
    y <- sql.arguments(y)
    x <- yyyymm.to.day(x)
    v <- sql.ShareClass("ReportDate = @dy", v)
    if (n != "All") 
        n <- list(A = sql.in("h.HSecurityId", sql.RDSuniv(n)))
    else n <- list()
    n[[LETTERS[length(n) + 1]]] <- "ReportDate = @dy"
    for (k in setdiff(y$filter, "All")) n[[LETTERS[length(n) + 
        1]]] <- sql.FundHistory.sf(k)
    n[[LETTERS[length(n) + 1]]] <- sql.in("his.HFundId", sql.tbl("HFundId", 
        "MonthlyData", v))
    n <- sql.and(n)
    if (h == "GeoId") 
        z <- "GeoId = GeographicFocus"
    else z <- sql.breakdown(h)
    if (w) 
        z <- c(sql.ReportDate(x), z, "HSecurityId")
    else z <- c("SecurityId", z)
    for (j in y$factor) {
        if (j == "FundCt") {
            z <- c(z, paste(j, "count(HoldingValue)", sep = " = "))
        }
        else if (j == "Herfindahl") {
            z <- c(z, paste(j, "1 - sum(square(HoldingValue))/square(sum(HoldingValue))", 
                sep = " = "))
        }
        else if (j == "HoldSum" & u == 0) {
            z <- c(z, paste(j, "sum(HoldingValue)", sep = " = "))
        }
        else if (j == "SharesHeld" & u == 0) {
            z <- c(z, paste(j, "sum(SharesHeld)", sep = " = "))
        }
        else if (j == "HoldSum" & u > 0) {
            z <- c(z, paste0(j, "Top", toupper(latin.ex.arabic(u)), 
                " = sum(HoldingValue)"))
        }
        else {
            stop("Bad factor", j)
        }
    }
    r <- c("Holdings h", "inner join", "FundHistory his on his.FundId = h.FundId")
    if (!w) 
        r <- c(r, "inner join", "SecurityHistory id on id.HSecurityId = h.HSecurityId")
    w <- ifelse(w, "HSecurityId", "SecurityId")
    if (g) 
        g <- paste0("count(", w, ") > 1")
    else g <- ""
    w <- paste(c(w, sql.breakdown(h)), collapse = ", ")
    if (u > 0 & h == "All" & g == "") {
        v <- c(w, "HoldingValue")
        v <- c(v, "HVRnk = ROW_NUMBER() over (partition by h.HSecurityId order by HoldingValue desc)")
        v <- sql.label(sql.tbl(v, r, n), "t")
        z <- sql.tbl(z, v, paste("HVRnk <", u + 1), w)
    }
    else if (u > 0) {
        stop("Can't handle yet!")
    }
    else {
        z <- sql.tbl(z, r, n, w, g)
    }
    z <- sql.declare.wrapper("@dy", x, z)
    z
}

#' sql.1mHoldAum
#' 
#' Total AUM of all funds owning a particular security
#' @param x = a YYYYMM
#' @param y = factors and filters
#' @param n = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @param w = a boolean (index by HSecurityId/SecurityId)
#' @param h = a breakdown filter (e.g. All/GeoId/DomicileId)
#' @param u = a boolean (chuck/keep securities held by just one fund)
#' @keywords sql.1mHoldAum
#' @export
#' @family sql

sql.1mHoldAum <- function (x, y, n, w, h, u = F) 
{
    y <- sql.arguments(y)
    x <- r <- yyyymm.to.day(x)
    if (n != "All") 
        n <- list(A = sql.in("h.HSecurityId", sql.RDSuniv(n)))
    else n <- list()
    n[[LETTERS[length(n) + 1]]] <- "ReportDate = @dy"
    for (k in setdiff(y$filter, "All")) n[[LETTERS[length(n) + 
        1]]] <- sql.FundHistory.sf(k)
    n <- sql.and(n)
    if (h == "GeoId") 
        z <- "GeoId = GeographicFocus"
    else z <- sql.breakdown(h)
    if (w) 
        z <- c(sql.ReportDate(r), z, "HSecurityId")
    else z <- c("SecurityId", z)
    addl <- NULL
    for (j in y$factor) {
        if (j == "HoldAum") {
            z <- c(z, paste0(j, " = sum(AssetsEnd)"))
        }
        else if (j == "FloMo") {
            z <- c(z, sql.1dFloMo.select(j))
            addl <- union(addl, c("Flow", "AssetsStart"))
        }
        else if (j == "FloDollar" & !w) {
            z <- c(z, sql.1dFloMo.select(j))
            addl <- union(addl, "Flow")
        }
        else if (j == "FloDollar" & w) {
            z <- c(z, "CalculatedStockFlow = sum(Flow * HoldingValue/AssetsEnd)")
            addl <- union(addl, "Flow")
        }
        else if (j == "Inflow") {
            z <- c(z, paste(j, "= sum(Inflow * HoldingValue/AssetsEnd)"))
            addl <- union(addl, "Inflow")
        }
        else if (j == "Outflow") {
            z <- c(z, paste(j, "= sum(Outflow * HoldingValue/AssetsEnd)"))
            addl <- union(addl, "Outflow")
        }
        else {
            stop("Bad factor", j)
        }
    }
    r <- c("Holdings t1", "inner join", "FundHistory t2 on t2.FundId = t1.FundId")
    r <- c(r, "inner join", sql.label(sql.MonthlyAssetsEnd("@dy", 
        addl), "t3 on t3.HFundId = t2.HFundId"))
    if (!w) 
        r <- c(r, "inner join", "SecurityHistory id on id.HSecurityId = t1.HSecurityId")
    w <- ifelse(w, "HSecurityId", "SecurityId")
    if (u) 
        u <- paste0("count(", w, ") > 1 and ")
    else u <- NULL
    u <- paste0(u, "sum(HoldingValue/AssetsEnd) > 0")
    w <- paste(c(w, sql.breakdown(h)), collapse = ", ")
    z <- sql.tbl(z, r, n, w, u)
    z <- sql.declare.wrapper("@dy", x, z)
    z
}

#' sql.1mSRIAdvisorPct
#' 
#' SQL query for 1mSRIAdvisorPct
#' @param x = a YYYYMM
#' @param y = factors and filters
#' @param n = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @param w = a boolean (index by HSecurityId/SecurityId)
#' @keywords sql.1mSRIAdvisorPct
#' @export
#' @family sql

sql.1mSRIAdvisorPct <- function (x, y, n, w) 
{
    y <- sql.arguments(y)
    x <- yyyymm.to.day(x)
    h <- sql.FundHistory(c(y$filter, "SRI"), T, "AdvisorId")
    h <- c("Holdings t1", "inner join", sql.label(h, "t2 on t2.HFundId = t1.HFundId"))
    z <- c("HSecurityId", "Num = count(distinct AdvisorId)")
    z <- sql.label(sql.tbl(z, h, "ReportDate = @floDt", z[1]), 
        "t1")
    h <- sql.tbl("Den = count(distinct AdvisorId)", h, "ReportDate = @floDt")
    z <- c(z, "cross join", sql.label(h, "t2"))
    h <- yyyymm.to.day(x)
    if (w) 
        x <- c(sql.ReportDate(x), "t1.HSecurityId")
    else x <- "SecurityId"
    if (length(y$factor) != 1 | y$factor[1] != "SRIAdvisorPct") 
        stop("Bad Argument")
    x <- c(x, "SRIAdvisorPct = 100 * cast(sum(Num) as float)/max(Den)")
    if (!w) 
        z <- c(z, "inner join", "SecurityHistory id on id.HSecurityId = t1.HSecurityId")
    w <- ifelse(w, "t1.HSecurityId", "SecurityId")
    z <- sql.declare.wrapper("@floDt", h, sql.tbl(x, z, , w))
    z
}

#' sql.1wFlow.Corp
#' 
#' Generates the SQL query to get weekly corporate flow ($MM)
#' @param x = a YYYYMMDD from which flows are to be computed
#' @keywords sql.1wFlow.Corp
#' @export
#' @family sql

sql.1wFlow.Corp <- function (x) 
{
    h <- mat.read(parameters("classif-StyleSector"))
    h <- map.rname(h, c(136, 133, 140, 135, 132, 139, 142, 125))
    h$Domicile <- ifelse(rownames(h) == 125, "US", NA)
    z <- vec.named(paste("StyleSector", rownames(h), sep = " = "), 
        h[, "Abbrv"])
    z[!is.na(h$Domicile)] <- paste(z[!is.na(h$Domicile)], "Domicile = 'US'", 
        sep = " and ")
    names(z)[!is.na(h$Domicile)] <- paste(names(z)[!is.na(h$Domicile)], 
        "US")
    z <- paste0("[", names(z), "] = sum(case when ", z, " then Flow else NULL end)")
    z <- c(sql.yyyymmdd("WeekEnding"), z)
    y <- list(A = "FundType = 'B'", B = "GeographicFocus = 77")
    y[["C"]] <- sql.in("StyleSector", paste0("(", paste(rownames(h), 
        collapse = ", "), ")"))
    y[["D"]] <- paste0("WeekEnding >= '", x, "'")
    z <- sql.tbl(z, c("WeeklyData t1", "inner join", "FundHistory t2 on t2.HFundId = t1.HFundId"), 
        sql.and(y), "WeekEnding")
    z <- paste(sql.unbracket(z), collapse = "\n")
    z
}

#' sql.ActWtDiff2
#' 
#' ActWtDiff2 on R1 Materials for positioning
#' @param x = a flowdate
#' @keywords sql.ActWtDiff2
#' @export
#' @family sql

sql.ActWtDiff2 <- function (x) 
{
    mo.end <- yyyymmdd.to.AllocMo(x, 26)
    w <- sql.in("HFundId", sql.FundHistory(c("Matls", "USGeo", 
        "Pas"), T))
    w <- list(A = w, B = paste0("ReportDate = '", yyyymm.to.day(mo.end), 
        "'"))
    z <- sql.in("HFundId", sql.tbl("HFundId", "FundHistory", 
        "FundId = 5152"))
    z <- sql.and(list(A = z, B = paste0("ReportDate = '", yyyymm.to.day(mo.end), 
        "'")))
    z <- sql.tbl("HSecurityId", "Holdings", z, "HSecurityId")
    w[["C"]] <- sql.in("HSecurityId", z)
    w <- sql.tbl("HSecurityId", "Holdings", sql.and(w), "HSecurityId")
    z <- sql.1mAllocSkew.underlying(x, "All", w, "All")
    z <- c(z, sql.1mAllocSkew.topline("ActWtDiff2", F, F, F))
    z
}

#' sql.Allocation
#' 
#' SQL query to fetch Country/Sector/Industry allocations
#' @param x = a column vector
#' @param y = one of Country/Sector/Industry
#' @param n = a column vector (must be in FundHistory!)
#' @param w = a filter vector
#' @param h = a where clause (can be missing)
#' @param u = group by clause (can be missing)
#' @param v = having clause (can be missing)
#' @keywords sql.Allocation
#' @export
#' @family sql

sql.Allocation <- function (x, y, n = NULL, w = "All", h, u, v) 
{
    x <- as.list(environment())
    z <- paste0(y, "Allocations_FromAllocationFlows")
    z <- sql.label(z, paste0("t2 on ", y, "AllocationsHistoryId = [Id]"))
    z <- c(paste0(y, "AllocationsHistory_FromAllocationFlows t1"), 
        "inner join", z)
    x[["y"]] <- c(z, "inner join", sql.label(sql.FundHistory(w, 
        F, c("FundId", n)), "t3 on t3.HFundId = t1.HFundId"))
    z <- x[!is.element(names(x), c("n", "w"))]
    z <- do.call(sql.tbl, list.rename(z, c("x", "y", "h", "u", 
        "v")))
    z
}

#' sql.Allocation.Sec
#' 
#' SQL query for sector allocations for month ending <x>
#' @param x = a where clause vector
#' @param y = a column vector (must be in FundHistory!)
#' @param n = a filter vector
#' @keywords sql.Allocation.Sec
#' @export
#' @family sql

sql.Allocation.Sec <- function (x, y = NULL, n = "All") 
{
    r <- c("FundId", "SectorId", y, "Allocation")
    z <- sql.unbracket(sql.Allocation(r, "Sector", y, n, sql.and(x)))
    z <- c("insert into", paste0("\t#SEC (", paste(r, collapse = ", "), 
        ")"), z)
    x[[LETTERS[length(x) + 1]]] <- "IndustryId = 20"
    h <- ifelse(r == "SectorId", "IndustryId", r)
    v <- sql.unbracket(sql.Allocation(h, "Industry", y, n, sql.and(x)))
    z <- c(z, "", "insert into", paste0("\t#SEC (", paste(r, 
        collapse = ", "), ")"), v)
    v <- sql.tbl("FundId", "#SEC", "SectorId = 7")
    v <- list(A = "SectorId = 20", B = sql.in("FundId", v, F))
    z <- c(z, "", sql.delete("#SEC", sql.and(v)))
    z <- c(z, "", sql.Allocation.Sec.FinsExREst(r))
    z
}

#' sql.Allocation.Sec.FinsExREst
#' 
#' SQL query to add FinsExREst sector allocations
#' @param x = a column vector (names of table #SEC)
#' @keywords sql.Allocation.Sec.FinsExREst
#' @export
#' @family sql

sql.Allocation.Sec.FinsExREst <- function (x) 
{
    v <- list(A = "SectorId = 7")
    v[["B"]] <- sql.in("FundId", sql.tbl("FundId", "#SEC", "SectorId = 20"), 
        F)
    h <- ifelse(x == "SectorId", "SectorId = 20", x)
    h <- ifelse(h == "Allocation", "Allocation = 0", h)
    v <- sql.unbracket(sql.tbl(h, "#SEC", sql.and(v)))
    z <- c("insert into", paste0("\t#SEC (", paste(x, collapse = ", "), 
        ")"), v)
    h <- ifelse(is.element(x, c("SectorId", "Allocation")), x, 
        paste0("t1.", x))
    h <- ifelse(h == "SectorId", "SectorId = 30", h)
    h <- ifelse(h == "Allocation", "Allocation = t1.Allocation - t2.Allocation", 
        h)
    v <- sql.and(list(A = "t1.SectorId = 7", B = "t2.SectorId = 20"))
    v <- sql.unbracket(sql.tbl(h, c("#SEC t1", "inner join", 
        "#SEC t2 on t2.FundId = t1.FundId"), v))
    z <- c(z, "", "insert into", paste0("\t#SEC (", paste(x, 
        collapse = ", "), ")"), v)
    z
}

#' sql.Allocations.bulk.EqWtAvg
#' 
#' Bulks up allocations with equal-weight averages
#' @param x = a column (to be bulked up)
#' @param y = a column vector (averages computed within these and <w>)
#' @param n = a SQL table (allocations)
#' @param w = primary grouping within which averages are computed
#' @keywords sql.Allocations.bulk.EqWtAvg
#' @export
#' @family sql

sql.Allocations.bulk.EqWtAvg <- function (x, y, n, w) 
{
    r <- c(w, y, paste0(x, " = avg(", x, ")"))
    r <- sql.label(sql.tbl(r, n, , paste(c(w, y), collapse = ", ")), 
        "t2")
    z <- sql.in("FundId", sql.tbl("FundId", n), F)
    z <- sql.label(sql.tbl(c("FundId", paste0(w, " = max(", w, 
        ")")), "#FLO", z, "FundId"), "t1")
    z <- c(z, "inner join", r, paste0("\ton t2.", w, " = t1.", 
        w))
    z <- sql.unbracket(sql.tbl(c("FundId", paste0("t1.", w), 
        y, x), z))
    r <- paste0("\t", n, " (", paste(c("FundId", w, y, x), collapse = ", "), 
        ")")
    z <- c("insert into", r, z)
    z
}

#' sql.Allocations.bulk.Single
#' 
#' Bulks up allocations with single-group funds
#' @param x = a column (to be bulked up)
#' @param y = a column vector (funds tagged with these and <w>)
#' @param n = a SQL table (allocations)
#' @param w = allocation bulking group (e.g. GeographicFocus/BenchIndex)
#' @param h = a string vector (single-group column and value)
#' @keywords sql.Allocations.bulk.Single
#' @export
#' @family sql

sql.Allocations.bulk.Single <- function (x, y, n, w, h) 
{
    r <- y[1]
    if (!is.null(y)) 
        y <- paste(y, collapse = " = ")
    z <- paste0(w[1], " = max(", w[1], ")")
    z <- c("FundId", z, y, paste(x, "= 100"))
    if (h[1] != w & is.null(y)) {
        h <- paste0(h[1], " in (", h[2], ")")
        h <- sql.tbl("FundId", "FundHistory", h)
        h <- sql.in("FundId", h)
    }
    else {
        h <- paste0(h[1], " in (", h[2], ")")
    }
    z <- sql.unbracket(sql.tbl(z, "#FLO", h, "FundId"))
    z <- c(paste0("\t", n, " (", paste(c("FundId", w, r, x), 
        collapse = ", "), ")"), z)
    z <- c("insert into", z)
    z
}

#' sql.and
#' 
#' and segment of a SQL statement
#' @param x = a where clause vector
#' @param y = string (logical operator to use)
#' @keywords sql.and
#' @export
#' @family sql

sql.and <- function (x, y = "and") 
{
    m <- length(x)
    if (m > 1) {
        fcn <- function(z) c(y, paste0("\t", z))
        z <- unlist(lapply(x, fcn))[-1]
    }
    else {
        z <- x[[1]]
    }
    z
}

#' sql.arguments
#' 
#' splits factors from filters
#' @param x = factors and filters
#' @keywords sql.arguments
#' @export
#' @family sql

sql.arguments <- function (x) 
{
    w <- c("All", "Num", "CBE", names(vec.ex.filters("sf")))
    w <- !is.element(x, w)
    if (all(w)) {
        x <- c(x, "All")
        w <- c(w, F)
    }
    z <- split(x, ifelse(w, "factor", "filter"))
    z
}

#' sql.bcp
#' 
#' code to bcp data out of server
#' @param x = a SQL table
#' @param y = the output file
#' @param n = a connection string
#' @param w = the database on which <x> resides
#' @param h = the owner of <x>
#' @keywords sql.bcp
#' @export
#' @family sql

sql.bcp <- function (x, y, n = "Quant", w = "EPFRUI", h = "dbo") 
{
    h <- paste(w, h, x, sep = ".")
    x <- parameters("SQL")
    x <- mat.read(x, "\t")
    z <- is.element(rownames(x), n)
    if (sum(z) != 1) 
        stop("Bad type", n)
    if (sum(z) == 1) {
        z <- paste("-S", x[, "DB"], "-U", x[, "UID"], "-P", x[, 
            "PWD"])[z]
        z <- paste("bcp", h, "out", y, z, "-c")
    }
    z
}

#' sql.BenchIndex.duplication
#' 
#' updates BenchIndex field in table <x> to remove duplicates
#' @param x = a SQL table
#' @keywords sql.BenchIndex.duplication
#' @export
#' @family sql

sql.BenchIndex.duplication <- function (x) 
{
    z <- sql.tbl(c("BenchIndex", "obs = count(BenchIndex)"), 
        x, , "BenchIndex")
    v <- c("BIDesc", "BenchIndex", "obs")
    v <- c(v, "Rnk = ROW_NUMBER() over (partition by BIDesc order by obs desc)")
    z <- sql.tbl(v, c(sql.label(z, "t1"), "inner join", "BenchIndexes t2 on BIID = BenchIndex"))
    z <- sql.tbl(c("BIDesc", "BenchIndex"), sql.label(z, "t"), 
        "Rnk = 1")
    z <- c(sql.label(z, "t1"), "inner join", "BenchIndexes t2 on t2.BIDesc = t1.BIDesc")
    z <- sql.label(sql.tbl(c("BIID", "BenchIndex"), z, "not BIID = BenchIndex"), 
        "t")
    z <- sql.update(x, "BenchIndex = t.BenchIndex", z, paste0(x, 
        ".BenchIndex = t.BIID"))
    z
}

#' sql.breakdown
#' 
#' Returns
#' @param x = a breakdown filter vector (e.g. All/GeoId/DomicileId)
#' @keywords sql.breakdown
#' @export
#' @family sql

sql.breakdown <- function (x) 
{
    z <- setdiff(x, "All")
    z <- ifelse(z == "GeoId", "GeographicFocus", x)
    z
}

#' sql.Bullish
#' 
#' SQL query for Bullish-sentiment factor
#' @param x = a YYYYMM
#' @param y = factors and filters
#' @param n = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @param w = a boolean (index by HSecurityId/SecurityId)
#' @keywords sql.Bullish
#' @export
#' @family sql

sql.Bullish <- function (x, y, n, w) 
{
    y <- sql.arguments(y)
    x <- yyyymm.to.day(x)
    cols <- c("HFundId", "HSecurityId", "HoldingValue")
    z <- c(sql.drop(c("#HLD", "#BMK")), "")
    z <- c(z, "create table #HLD (HFundId int not null, HSecurityId int not null, HoldingValue float)")
    z <- c(z, sql.index("#HLD", "HFundId, HSecurityId"))
    z <- c(z, "insert into", paste0("\t#HLD (", paste(cols, collapse = ", "), 
        ")"))
    h <- list(A = paste0("ReportDate = '", x, "'"))
    if (n != "All") 
        h[[LETTERS[length(h) + 1]]] <- sql.in("HSecurityId", 
            sql.RDSuniv(n))
    if (y$filter != "All") 
        h[[LETTERS[length(h) + 1]]] <- sql.in("HFundId", sql.FundHistory(y$filter, 
            T))
    h <- sql.and(h)
    z <- c(z, sql.unbracket(sql.tbl(cols, "Holdings", h)), "")
    h <- sql.label(sql.MonthlyAssetsEnd(wrap(x), , , , "PortVal"), 
        "t")
    z <- c(z, sql.update("#HLD", "HoldingValue = 100 * HoldingValue/PortVal", 
        h, "#HLD.HFundId = t.HFundId"))
    h <- c("Pas", "HFundId in (select HFundId from #HLD)")
    h <- sql.FundHistory(h, T, "BenchIndexId")
    h <- c(sql.label(h, "t1"), "inner join")
    h <- c(h, sql.label(sql.tbl("BenchIndexId, nFunds = count(HFundId)", 
        h, , "BenchIndexId"), "t2"))
    h <- c(h, "\ton t2.BenchIndexId = t1.BenchIndexId", "inner join", 
        "#HLD t3 on t3.HFundId = t1.HFundId")
    u <- "t1.BenchIndexId, t3.HSecurityId, BmkWt = sum(HoldingValue)/nFunds"
    h <- sql.tbl(u, h, , "t1.BenchIndexId, t3.HSecurityId, nFunds")
    z <- c(z, "", sql.into(h, "#BMK"), "")
    z <- c(z, sql.delete("#HLD", sql.in("HFundId", sql.FundHistory("Pas", 
        T))))
    if (w) 
        x <- c(sql.ReportDate(x), "t1.HSecurityId")
    else x <- "SecurityId"
    if (length(y$factor) != 1 | y$factor[1] != "Bullish") 
        stop("Bad Argument")
    x <- c(x, "Bullish = 100 * sum(case when HoldingValue > isnull(BmkWt, 0) then 1.0 else 0.0 end)/FundCt")
    h <- c("#HLD t1", "inner join", "FundHistory t2 on t2.HFundId = t1.HFundId")
    if (!w) 
        h <- c(h, "inner join", "SecurityHistory id on id.HSecurityId = t1.HSecurityId")
    h <- c(h, "cross join", sql.label(sql.tbl("FundCt = count(distinct HFundId)", 
        "#HLD"), "t4"), "left join")
    h <- c(h, "#BMK t3 on t3.BenchIndexId = t2.BenchIndexId and t3.HSecurityId = t1.HSecurityId")
    w <- paste0(ifelse(w, "t1.HSecurityId", "SecurityId"), ", FundCt")
    z <- c(paste(z, collapse = "\n"), paste(sql.unbracket(sql.tbl(x, 
        h, , w)), collapse = "\n"))
    z
}

#' sql.case
#' 
#' case statement assigning labels <n> based on conditions <y>
#' @param x = final label
#' @param y = a string vector (conditions)
#' @param n = a string vector (labels, length exceeds <y> by one)
#' @param w = a boolean (labels are/aren't numeric)
#' @keywords sql.case
#' @export
#' @family sql

sql.case <- function (x, y, n, w = T) 
{
    if (!w) 
        n <- wrap(n)
    z <- n[length(y) + 1]
    z <- c(paste("when", y, "then", n[seq_along(y)]), paste("else", 
        z, "end"))
    z <- c(paste(x, "= case"), paste0("\t", z))
    z
}

#' sql.close
#' 
#' Closes a SQL connection (if needed)
#' @param x = output of sql.connect
#' @keywords sql.close
#' @export
#' @family sql

sql.close <- function (x) 
{
    if (x[["close"]]) 
        close(x[["conn"]])
    invisible()
}

#' sql.common
#' 
#' ensures common records in <x> based on <y>
#' @param x = a SQL table vector (length 2)
#' @param y = a column
#' @keywords sql.common
#' @export
#' @family sql

sql.common <- function (x, y) 
{
    z <- sql.delete(x[1], sql.in(y, sql.tbl(y, x[2]), F))
    z <- c(z, "", sql.delete(x[2], sql.in(y, sql.tbl(y, x[1]), 
        F)))
    z
}

#' sql.connect
#' 
#' Opens a SQL connection
#' @param x = a connection string
#' @keywords sql.connect
#' @export
#' @family sql
#' @@importFrom RODBC odbcDriverConnect

sql.connect <- function (x) 
{
    y <- mat.read(parameters("SQL"), "\t")
    if (all(rownames(y) != x)) 
        stop("Bad SQL connection!")
    z <- t(y)[c("PWD", "UID", "DSN"), x]
    z["Connection Timeout"] <- "0"
    z <- paste(paste(names(z), z, sep = "="), collapse = ";")
    z <- odbcDriverConnect(z, readOnlyOptimize = T)
    z
}

#' sql.connect.wrapper
#' 
#' Opens a SQL connection (if needed)
#' @param x = a connection string/connection
#' @keywords sql.connect.wrapper
#' @export
#' @family sql
#' @@importFrom RODBC odbcDriverConnect

sql.connect.wrapper <- function (x) 
{
    if (is.character(x)) {
        z <- list(conn = sql.connect(x), close = T)
    }
    else {
        z <- list(conn = x, close = F)
    }
    z
}

#' sql.cross.border
#' 
#' Returns a list object of cross-border Geo. Foci and their names
#' @param x = a boolean (StockFlows/Macro)
#' @keywords sql.cross.border
#' @export
#' @family sql

sql.cross.border <- function (x) 
{
    y <- parameters("classif-GeoId")
    y <- mat.read(y, "\t")
    y <- y[is.element(y$xBord, 1), ]
    if (x) 
        x <- "GeographicFocus"
    else x <- "GeographicFocus"
    z <- paste(x, "=", paste(rownames(y), y[, "Name"], sep = "--"))
    z <- split(z, y[, "Abbrv"])
    z
}

#' sql.CtryFlow.Alloc
#' 
#' SQL query for allocations needed in country flows
#' @param x = a numeric vector (identifiers, can be NULL)
#' @param y = FundType
#' @param n = a month end (allocation)
#' @param w = one of Country/Sector/Industry
#' @param h = a filter vector
#' @keywords sql.CtryFlow.Alloc
#' @export
#' @family sql

sql.CtryFlow.Alloc <- function (x, y, n, w, h) 
{
    r <- c("Advisor", paste0(w, "Id"), "GeographicFocus", "Allocation = avg(Allocation)")
    u <- list(A = "ReportDate = @floDt")
    if (!is.null(x)) 
        u[["B"]] <- paste0(w, "Id in (", paste(x[!is.na(x)], 
            collapse = ", "), ")")
    z <- sql.Allocation(r, w, c("Advisor", "GeographicFocus"), 
        c(h, y[1], "UI"), sql.and(u), paste(r[-length(r)], collapse = ", "))
    z <- sql.tbl(r[-1], sql.label(z, "t"), , paste(r[-length(r)][-1], 
        collapse = ", "))
    z <- sql.declare.wrapper("@floDt", n, z)
    z
}

#' sql.CtryFlow.Flow
#' 
#' SQL query for single-group flows
#' @param x = a YYYYMMDD
#' @param y = a string vector (Flow/AssetsStart/AssetsEnd/PortfolioChange)
#' @param n = a column vector (must be in FundHistory!)
#' @param w = a frequency (T/F for daily/weekly or D/W/M)
#' @param h = a filter vector
#' @keywords sql.CtryFlow.Flow
#' @export
#' @family sql

sql.CtryFlow.Flow <- function (x, y, n, w, h) 
{
    y <- c(n, paste0(y, " = sum(", y, ")"))
    z <- sql.Flow(y, list(A = "@floDt"), h, n, w, paste(n, collapse = ", "))
    z <- sql.declare.wrapper("@floDt", x, z)
    z
}

#' sql.currprior
#' 
#' SQL query for current & prior allocations
#' @param fcn = SQL-script generator
#' @param x = a YYYYMM
#' @param y = a SQL table vector
#' @param n = parameter (primary, can be missing)
#' @param w = parameter (secondary, can be missing)
#' @keywords sql.currprior
#' @export
#' @family sql

sql.currprior <- function (fcn, x, y, n, w) 
{
    if (missing(n)) {
        z <- matrix(c(yyyymm.lag(x, 1:0), y), 2, 2, T)
    }
    else if (missing(w)) {
        z <- matrix(c(yyyymm.lag(x, 1:0), y, n), 3, 2, T)
    }
    else {
        z <- matrix(c(yyyymm.lag(x, 1:0), y, n, w), 4, 2, T)
    }
    z[1, ] <- yyyymm.to.day(z[1, ])
    colnames(z) <- c("Old", "New")
    z <- lapply(mat.ex.matrix(z), fcn)
    z[[1]] <- c(z[[1]], "")
    z <- Reduce(c, z)
    z
}

#' sql.DailyFlo
#' 
#' SQL query for daily Flow
#' @param x = a flowdate vector
#' @param y = a boolean (group by HFundId/FundId)
#' @param n = a boolean (StockFlows/Macro)
#' @param w = a ShareClass filter (All/Inst/Retail)
#' @param h = a boolean (do/don't report AssetsEnd)
#' @keywords sql.DailyFlo
#' @export
#' @family sql

sql.DailyFlo <- function (x, y = T, n = T, w = "All", h = F) 
{
    n <- ifelse(n, "ReportDate", "DayEnding")
    if (length(x) == 1) 
        x <- paste("=", x)
    else x <- paste0("in (", paste(x, collapse = ", "), ")")
    x <- paste(n, x)
    x <- sql.ShareClass(x, w)
    z <- c("Flow", "AssetsStart")
    if (h) 
        z <- c(z, "AssetsEnd")
    if (y) 
        z <- paste0(z, " = sum(", z, ")")
    z <- c(n, "HFundId", z)
    if (y) {
        z <- sql.tbl(z, "DailyData", x, paste(z[1:2], collapse = ", "))
    }
    else {
        z <- sql.tbl(z, "DailyData", x)
    }
    z
}

#' sql.datediff
#' 
#' Before <n>, falls back two else one month
#' @param x = a column (in the monthly table)
#' @param y = a column (in the daily table)
#' @param n = an integer (day on which previous month's data available)
#' @keywords sql.datediff
#' @export
#' @family sql

sql.datediff <- function (x, y, n) 
{
    paste0("datediff(month, ", x, ", ", y, ") = case when day(", 
        y, ") < ", n, " then 2 else 1 end")
}

#' sql.declare
#' 
#' declare statement
#' @param x = a string vector (name)
#' @param y = a string vector (datatype)
#' @param n = a string vector (values)
#' @keywords sql.declare
#' @export
#' @family sql

sql.declare <- function (x, y, n) 
{
    c(paste("declare", x, y), paste0("set ", x, " = '", n, "'"))
}

#' sql.declare.wrapper
#' 
#' string
#' @param x = a string (temp variable like @@floDt)
#' @param y = a string (date argument)
#' @param n = a string vector (sql query to be unbracketed)
#' @keywords sql.declare.wrapper
#' @export
#' @family sql

sql.declare.wrapper <- function (x, y, n) 
{
    paste(c(sql.declare(x, "datetime", y), "", sql.unbracket(n)), 
        collapse = "\n")
}

#' sql.delete
#' 
#' delete from <x> where <y>
#' @param x = a SQL table
#' @param y = a where clause
#' @keywords sql.delete
#' @export
#' @family sql

sql.delete <- function (x, y) 
{
    c("delete from", paste0("\t", x), "where", paste0("\t", y))
}

#' sql.Diff
#' 
#' SQL statement for diffusion
#' @param x = bit of SQL string
#' @param y = bit of SQL string
#' @param n = one of ""/"Num"/"Den"
#' @keywords sql.Diff
#' @export
#' @family sql

sql.Diff <- function (x, y, n = "") 
{
    z <- paste0("= sum((", x, ") * cast(sign(", y, ") as float))")
    if (n == "") {
        z <- paste0(z, "/", sql.nonneg(paste0("sum(abs(", x, 
            "))")))
    }
    else if (n == "Den") {
        z <- paste0("= sum(abs(", x, "))")
    }
    z
}

#' sql.Dispersion
#' 
#' Generates the dispersion measure set forth in Jiang & Sun (2011) #		:	"Dispersion in beliefs among active mutual funds and the cross-section of stock returns"
#' @param x = a YYYYMM
#' @param y = factors and filters
#' @param n = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @param w = a boolean (index by HSecurityId/SecurityId)
#' @keywords sql.Dispersion
#' @export
#' @family sql

sql.Dispersion <- function (x, y, n, w) 
{
    x <- yyyymm.to.day(x)
    z <- sql.drop(c("#HLD", "#BMK"))
    z <- c(z, "", "create table #BMK (BenchIndexId int not null, HSecurityId int not null, HoldingValue float not null)")
    z <- c(z, sql.index("#BMK", "BenchIndexId, HSecurityId"))
    u <- sql.and(list(A = paste0("ReportDate = '", x, "'"), B = "not isnull(Idx, 'N') = 'N'"))
    h <- "Holdings t1 inner join FundHistory t2 on t2.HFundId = t1.HFundId"
    h <- sql.tbl("BenchIndexId, HSecurityId, HoldingValue = sum(HoldingValue)", 
        h, u, "BenchIndexId, HSecurityId", "sum(HoldingValue) > 0")
    z <- c(z, "insert into #BMK", sql.unbracket(h))
    h <- sql.label(sql.tbl("BenchIndexId, AUM = sum(HoldingValue)", 
        "#BMK", , "BenchIndexId", "sum(HoldingValue) > 0"), "t")
    z <- c(z, "", sql.update("#BMK", "HoldingValue = HoldingValue/AUM", 
        h, "#BMK.BenchIndexId = t.BenchIndexId"))
    z <- c(z, "", "create table #HLD (HFundId int not null, HSecurityId int not null, HoldingValue float not null)")
    z <- c(z, sql.index("#HLD", "HFundId, HSecurityId"))
    u <- sql.in("BenchIndexId", sql.tbl("BenchIndexId", "#BMK"))
    u <- sql.and(list(A = paste0("ReportDate = '", x, "'"), B = "isnull(Idx, 'N') = 'N'", 
        C = u, D = "HoldingValue > 0"))
    h <- "Holdings t1 inner join FundHistory t2 on t2.HFundId = t1.HFundId"
    h <- sql.tbl("t1.HFundId, HSecurityId, HoldingValue", h, 
        u)
    z <- c(z, "insert into #HLD", sql.unbracket(h))
    h <- sql.label(sql.tbl("HFundId, AUM = sum(HoldingValue)", 
        "#HLD", , "HFundId", "sum(HoldingValue) > 0"), "t")
    z <- c(z, "", sql.update("#HLD", "HoldingValue = HoldingValue/AUM", 
        h, "#HLD.HFundId = t.HFundId"))
    h <- c("FundHistory t1", "inner join", "#BMK t2 on t2.BenchIndexId = t1.BenchIndexId")
    u <- "#HLD.HFundId = t1.HFundId and #HLD.HSecurityId = t2.HSecurityId"
    z <- c(z, "", sql.update("#HLD", "HoldingValue = #HLD.HoldingValue - t2.HoldingValue", 
        h, u))
    u <- sql.tbl("HFundId, HSecurityId", "#HLD t", "t1.HFundId = t.HFundId and t2.HSecurityId = t.HSecurityId")
    u <- sql.and(list(A = sql.exists(u, F), B = sql.in("t1.HFundId", 
        sql.tbl("HFundId", "#HLD"))))
    h <- c("FundHistory t1", "inner join", "#BMK t2 on t2.BenchIndexId = t1.BenchIndexId")
    h <- sql.tbl("HFundId, HSecurityId, -HoldingValue", h, u)
    z <- c(z, "", "insert into #HLD", sql.unbracket(h))
    if (n != "All") 
        z <- c(z, "", sql.delete("#HLD", sql.in("HSecurityId", 
            sql.RDSuniv(n), F)))
    z <- paste(z, collapse = "\n")
    h <- "#HLD hld"
    if (w) {
        u <- c(sql.ReportDate(x), "HSecurityId")
    }
    else {
        h <- c(h, "inner join", "SecurityHistory id on id.HSecurityId = hld.HSecurityId")
        u <- "SecurityId"
    }
    w <- ifelse(w, "HSecurityId", "SecurityId")
    u <- c(u, "Dispersion = 10000 * (avg(square(HoldingValue)) - square(avg(HoldingValue)))")
    z <- c(z, paste(sql.unbracket(sql.tbl(u, h, , w)), collapse = "\n"))
    z
}

#' sql.drop
#' 
#' drops the elements of <x> if they exist
#' @param x = a temp table vector
#' @keywords sql.drop
#' @export
#' @family sql

sql.drop <- function (x) 
{
    paste0("IF OBJECT_ID('tempdb..", x, "') IS NOT NULL DROP TABLE ", 
        x)
}

#' sql.exists
#' 
#' <x> in <y> if <n> or <x> not in <y> otherwise
#' @param x = a string (SQL statement)
#' @param y = a boolean (exists/not exists)
#' @keywords sql.exists
#' @export
#' @family sql

sql.exists <- function (x, y = T) 
{
    c(ifelse(y, "exists", "not exists"), paste0("\t", x))
}

#' sql.extra.domicile
#' 
#' where clauses to ensure foreign flow
#' @param x = a flowdate/YYYYMMDD (depending on whether daily/weekly)
#' @param y = a string (column in classif-Ctry corresponding to names of <x>)
#' @param n = a string (column in FundHistory corresponding to names of <x>)
#' @keywords sql.extra.domicile
#' @export
#' @family sql

sql.extra.domicile <- function (x, y, n) 
{
    z <- mat.read(parameters("classif-Ctry"))
    z <- z[is.element(z[, y], names(x)) & !is.na(z$DomicileId), 
        ]
    z <- vec.named(z$DomicileId, z[, y])
    z <- split(as.character(z), x[names(z)])
    z <- list(Domicile = z, Allocation = x[is.element(x, names(z))])
    z[["Allocation"]] <- split(names(z$Allocation), z$Allocation)
    for (j in names(z[["Domicile"]])) {
        if (length(z[["Domicile"]][[j]]) == 1) {
            z[["Domicile"]][[j]] <- paste0("Domicile = '", z[["Domicile"]][[j]], 
                "'")
        }
        else {
            z[["Domicile"]][[j]] <- paste(z[["Domicile"]][[j]], 
                collapse = "', '")
            z[["Domicile"]][[j]] <- paste0("Domicile in ('", 
                z[["Domicile"]][[j]], "')")
        }
    }
    for (j in names(z[["Allocation"]])) {
        if (length(z[["Allocation"]][[j]]) == 1) {
            z[["Allocation"]][[j]] <- paste0(n, " = ", z[["Allocation"]][[j]])
        }
        else {
            z[["Allocation"]][[j]] <- paste(z[["Allocation"]][[j]], 
                collapse = ", ")
            z[["Allocation"]][[j]] <- paste0(n, " in (", z[["Allocation"]][[j]], 
                ")")
        }
    }
    z <- lapply(z, unlist)
    z <- array.ex.list(z, F, T)
    z <- vec.named(paste0("not (", z[, 1], " and ", z[, 2], ")"), 
        rownames(z))
    z <- split(z, names(z))
    z
}

#' sql.Flow
#' 
#' SQL query to fetch daily/weekly/monthly flows
#' @param x = a string vector
#' @param y = a where clause list (can be missing)
#' @param n = a filter vector
#' @param w = a column vector (must be in FundHistory!)
#' @param h = a frequency (T/F for daily/weekly or D/W/M)
#' @param u = group by clause (can be missing)
#' @param v = having clause (can be missing)
#' @keywords sql.Flow
#' @export
#' @family sql

sql.Flow <- function (x, y, n = "All", w = NULL, h = T, u, v) 
{
    z <- sql.label(sql.FundHistory(n, F, c("FundId", w)), "t2")
    z <- c(z, "\ton t2.HFundId = t1.HFundId")
    z <- c(paste(sql.Flow.tbl(h, T), "t1"), "inner join", z)
    z <- list(x = x, y = z)
    if (!missing(y)) 
        if (length(y[[1]]) > 1) {
            y[[1]] <- paste(y[[1]], collapse = ", ")
            y[[1]] <- paste0(sql.Flow.tbl(h, F), " in (", y[[1]], 
                ")")
        }
        else if (grepl("^(@.*|'.*')$", y[[1]])) {
            y[[1]] <- paste(sql.Flow.tbl(h, F), "=", y[[1]])
        }
    if (!missing(y)) 
        z[["n"]] = sql.and(y)
    if (!missing(u)) 
        z[["w"]] <- u
    if (!missing(v)) 
        z[["h"]] <- v
    z <- do.call(sql.tbl, z)
    z
}

#' sql.Flow.tbl
#' 
#' table/date field name
#' @param x = a frequency (T/F for daily/weekly or D/W/M)
#' @param y = a boolean (table/date field)
#' @keywords sql.Flow.tbl
#' @export
#' @family sql

sql.Flow.tbl <- function (x, y) 
{
    if (is.logical(x)) 
        x <- ifelse(x, "D", "W")
    if (y) {
        z <- vec.named(c("DailyData", "WeeklyData", "MonthlyData"), 
            c("D", "W", "M"))
    }
    else {
        z <- vec.named(c("DayEnding", "WeekEnding", "MonthEnding"), 
            c("D", "W", "M"))
    }
    z <- as.character(z[x])
    z
}

#' sql.Foreign
#' 
#' list object of foreign-fund restrictions
#' @keywords sql.Foreign
#' @export
#' @family sql

sql.Foreign <- function () 
{
    x <- mat.read(parameters("classif-Ctry"))[, c("GeoId", "DomicileId")]
    x <- x[apply(x, 1, function(z) sum(!is.na(z))) == 2, ]
    x[, "DomicileId"] <- paste0("Domicile = '", x[, "DomicileId"], 
        "'")
    x[, "DomicileId"] <- paste("Domicile is not NULL and", x[, 
        "DomicileId"])
    x[, "GeoId"] <- paste("GeographicFocus =", x[, "GeoId"])
    x[, "GeoId"] <- paste("GeographicFocus is not NULL and", 
        x[, "GeoId"])
    z <- split(paste0("not (", x[, "DomicileId"], " and ", x[, 
        "GeoId"], ")"), rownames(x))
    z
}

#' sql.FundHistory
#' 
#' SQL query to restrict to Global and Regional equity funds
#' @param x = a filter vector
#' @param y = a boolean (StockFlows/Macro)
#' @param n = a column vector (besides HFundId, can be missing)
#' @keywords sql.FundHistory
#' @export
#' @family sql

sql.FundHistory <- function (x, y, n) 
{
    x <- setdiff(x, c("Aggregate", "All"))
    if (missing(n)) 
        n <- "HFundId"
    else n <- c("HFundId", n)
    if (length(x) == 0) {
        z <- sql.tbl(n, "FundHistory")
    }
    else {
        if (y) 
            x <- sql.FundHistory.sf(x)
        else x <- sql.FundHistory.macro(x)
        z <- sql.tbl(n, "FundHistory", sql.and(x))
    }
    z
}

#' sql.FundHistory.macro
#' 
#' SQL query where clause
#' @param x = a filter vector
#' @keywords sql.FundHistory.macro
#' @export
#' @family sql

sql.FundHistory.macro <- function (x) 
{
    n <- vec.ex.filters("macro")
    z <- list()
    for (y in x) {
        if (any(y == names(n))) {
            z[[LETTERS[length(z) + 1]]] <- n[y]
        }
        else if (y == "CB") {
            z[[LETTERS[length(z) + 1]]] <- c("(", sql.and(sql.cross.border(F), 
                "or"), ")")
        }
        else if (y == "UI") {
            z[[LETTERS[length(z) + 1]]] <- sql.ui()
        }
        else if (y == "Foreign") {
            z <- c(z, sql.Foreign())
        }
        else {
            z[[LETTERS[length(z) + 1]]] <- y
        }
    }
    z
}

#' sql.FundHistory.sf
#' 
#' SQL query where clause
#' @param x = a filter vector
#' @keywords sql.FundHistory.sf
#' @export
#' @family sql

sql.FundHistory.sf <- function (x) 
{
    n <- vec.ex.filters("sf")
    z <- list()
    for (h in x) {
        if (any(h == names(n))) {
            z[[LETTERS[length(z) + 1]]] <- n[h]
        }
        else if (h == "CBE") {
            z[[LETTERS[length(z) + 1]]] <- c("(", sql.and(sql.cross.border(T), 
                "or"), ")")
        }
        else {
            z[[LETTERS[length(z) + 1]]] <- h
        }
    }
    z
}

#' sql.get
#' 
#' gets data using <fcn>
#' @param fcn = a fetch function
#' @param x = a flowdate vector list
#' @param y = a connection string
#' @param n = an integer (max queries using same connection)
#' @param w = argument passed down to <fcn>
#' @keywords sql.get
#' @export
#' @family sql

sql.get <- function (fcn, x, y, n, w = NULL) 
{
    z <- list()
    conn <- sql.connect(y)
    ctr <- 0
    for (j in names(x)) {
        cat(j, "..\n")
        if (ctr == n) {
            close(conn)
            conn <- sql.connect(y)
            ctr <- 0
        }
        z[[j]] <- fcn(x[[j]], w, conn)
        ctr <- ctr + 1
        while (is.null(dim(z[[j]]))) {
            cat(txt.hdr("NEW CONNECTION"), "\n")
            close(conn)
            conn <- sql.connect(y)
            z[[j]] <- fcn(x[[j]], w, conn)
            ctr <- 1
        }
    }
    close(conn)
    z
}

#' sql.HerdingLSV
#' 
#' Generates ingredients of the herding measure set forth in LSV's 1991 #		:	paper "Do institutional investors destabilize stock prices?"
#' @param x = a YYYYMM
#' @param y = factors and filters
#' @param n = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @param w = a boolean (index by HSecurityId/SecurityId)
#' @keywords sql.HerdingLSV
#' @export
#' @family sql

sql.HerdingLSV <- function (x, y, n, w) 
{
    y <- sql.arguments(y)
    u <- "expPctBuy = avg(case when Flow > 0 then 1.0 else 0.0 end)"
    u <- sql.tbl(u, "#NEWAUM", sql.in("FundId", sql.tbl("FundId", 
        "#NEWHLD")))
    u <- c("cross join", sql.label(u, "t4"))
    u <- c("inner join", "#NEWAUM t3 on t3.FundId = isnull(t1.FundId, t2.FundId)", 
        u)
    z <- sql.1mAllocD.data(x, y$filter, T, F, T, "Flow")
    h <- paste(z, collapse = "\n")
    if (w) 
        z <- "HSecurityId"
    else z <- "SecurityId"
    l <- paste0("isnull(t1.", z, ", t2.", z, ")")
    z <- paste(z, "=", l)
    if (w) 
        z <- c(sql.ReportDate(yyyymm.to.day(x)), z)
    for (i in y$factor) {
        if (i == "expPctBuy") {
            z <- c(z, "expPctBuy = avg(expPctBuy)")
        }
        else if (i == "B") {
            z <- c(z, "B = sum(case when isnull(t1.HoldingValue, 0) > isnull(t2.HoldingValue, 0) then 1 else 0 end)")
        }
        else if (i == "S") {
            z <- c(z, "S = sum(case when isnull(t1.HoldingValue, 0) < isnull(t2.HoldingValue, 0) then 1 else 0 end)")
        }
        else {
            stop(paste("Bad factor ", i, "!"))
        }
    }
    u <- c("#OLDHLD t2 on t2.FundId = t1.FundId and t2.SecurityId = t1.SecurityId", 
        u)
    u <- c("#NEWHLD t1", "full outer join", u)
    if (n == "All") {
        z <- sql.tbl(z, u, , l)
    }
    else {
        z <- sql.tbl(z, u, sql.in("isnull(t1.HSecurityId, t2.HSecurityId)", 
            sql.RDSuniv(n)), l)
    }
    z <- c(h, paste(sql.unbracket(z), collapse = "\n"))
    z
}

#' sql.Holdings
#' 
#' query to access stock-holdings data
#' @param x = a where clause
#' @param y = a column vector (the ones to fetch)
#' @param n = a temp table
#' @keywords sql.Holdings
#' @export
#' @family sql

sql.Holdings <- function (x, y, n) 
{
    z <- sql.tbl(y, "Holdings", x)
    if (!missing(n)) 
        z <- sql.into(z, n)
    z
}

#' sql.in
#' 
#' <x> in <y> if <n> or <x> not in <y> otherwise
#' @param x = a column
#' @param y = a string (SQL statement)
#' @param n = a boolean (<x> is/isn't in <y>)
#' @keywords sql.in
#' @export
#' @family sql

sql.in <- function (x, y, n = T) 
{
    c(paste(x, ifelse(n, "in", "not in")), paste0("\t", y))
}

#' sql.index
#' 
#' SQL for primary key on <x> by columns <y>
#' @param x = a SQL table
#' @param y = a string vector (column labels to index by like "DayEnding, FundId")
#' @keywords sql.index
#' @export
#' @family sql

sql.index <- function (x, y) 
{
    paste0("create unique clustered index ", substring(x, 2, 
        nchar(x)), "Index ON ", x, " (", y, ")")
}

#' sql.into
#' 
#' unbrackets and selects into <y>
#' @param x = a string (SQL statement)
#' @param y = a temp table
#' @keywords sql.into
#' @export
#' @family sql

sql.into <- function (x, y) 
{
    z <- sql.unbracket(x)
    n <- length(z)
    w <- z == "from"
    w <- w & !duplicated(w)
    if (sum(w) != 1) 
        stop("Failure in sql.into!")
    w <- c(1:n, (1:n)[w] + 1:2/3 - 1)
    z <- c(z, "into", paste0("\t", y))[order(w)]
    z
}

#' sql.label
#' 
#' labels <x> as <y>
#' @param x = a string (SQL statement)
#' @param y = label
#' @keywords sql.label
#' @export
#' @family sql

sql.label <- function (x, y) 
{
    z <- length(x)
    if (z == 1) 
        z <- paste(x, y)
    else z <- c(x[-z], paste(x[z], y))
    z
}

#' sql.map.classif
#' 
#' Returns flow variables with the same row space as <w>
#' @param x = a SQL query vector
#' @param y = a connection, the output of odbcDriverConnect
#' @param n = classif file
#' @keywords sql.map.classif
#' @export
#' @family sql
#' @@importFrom RODBC sqlQuery

sql.map.classif <- function (x, y, n) 
{
    z <- sql.query.underlying(x, y, F)
    z <- map.rname(mat.index(z, "SecurityId"), rownames(n))
    if (is.null(dim(z))) 
        z <- char.to.num(z)
    z
}

#' sql.mat.cofactor
#' 
#' SQL for the cofactor matrix
#' @param x = a matrix (square, character)
#' @keywords sql.mat.cofactor
#' @export
#' @family sql

sql.mat.cofactor <- function (x) 
{
    z <- matrix("", dim(x)[1], dim(x)[2], F, dimnames(x))
    for (i in 1:dim(z)[1]) {
        for (j in 1:dim(z)[2]) {
            z[i, j] <- sql.mat.determinant(x[-i, -j])
            if ((i + j)%%2 == 1) 
                z[i, j] <- sql.mat.flip(z[i, j])
        }
    }
    z
}

#' sql.mat.crossprod
#' 
#' SQL for entries of X'X
#' @param x = a string vector
#' @param y = a boolean (is/isn't an intercept)
#' @keywords sql.mat.crossprod
#' @export
#' @family sql

sql.mat.crossprod <- function (x, y) 
{
    m <- length(x)
    names(x) <- 1:m
    z <- rep(1:m, m)
    w <- z[order(rep(1:m, m))]
    h <- vec.max(w, z)
    z <- vec.min(w, z)
    z <- map.rname(x, z)
    h <- map.rname(x, h)
    z <- ifelse(z == h, paste0("sum(square(", z, "))"), paste0("sum(", 
        z, " * ", h, ")"))
    z <- matrix(z, m, m, F, list(x, x))
    if (y) {
        z <- map.rname(z, c("Unity", x))
        z <- t(map.rname(t(z), c("Unity", x)))
        z[1, -1] <- z[-1, 1] <- paste0("sum(", x, ")")
        z[1, 1] <- paste0("count(", x[1], ")")
    }
    z
}

#' sql.mat.crossprod.vector
#' 
#' SQL for entries of X'Y
#' @param x = a string vector
#' @param y = a string
#' @param n = a boolean (yes/no intercept)
#' @keywords sql.mat.crossprod.vector
#' @export
#' @family sql

sql.mat.crossprod.vector <- function (x, y, n) 
{
    z <- vec.named(paste0("sum(", x, " * ", y, ")"), x)
    if (n) {
        z["Unity"] <- paste0("sum(", y, ")")
        w <- length(z)
        z <- z[order(1:w%%w)]
    }
    z
}

#' sql.mat.determinant
#' 
#' SQL for the determinant
#' @param x = a matrix (square, character)
#' @keywords sql.mat.determinant
#' @export
#' @family sql

sql.mat.determinant <- function (x) 
{
    n <- dim(x)[2]
    if (is.null(n)) {
        z <- x
    }
    else if (n == 2) {
        z <- sql.mat.multiply(x[1, 2], x[2, 1])
        z <- paste0(sql.mat.multiply(x[1, 1], x[2, 2]), " - ", 
            z)
    }
    else {
        i <- 1
        z <- paste0(x[1, i], " * (", sql.mat.determinant(x[-1, 
            -i]), ")")
        for (i in 2:n) {
            h <- ifelse(i%%2 == 0, " - ", " + ")
            z <- paste(z, paste0(x[1, i], " * (", sql.mat.determinant(x[-1, 
                -i]), ")"), sep = h)
        }
    }
    z
}

#' sql.mat.flip
#' 
#' flips the sign for a term in a matrix
#' @param x = a matrix (square, character)
#' @keywords sql.mat.flip
#' @export
#' @family sql

sql.mat.flip <- function (x) 
{
    h <- NULL
    n <- nchar(x)
    i <- 1
    m <- 0
    while (i <= n) {
        if (m == 0 & is.element(substring(x, i, i), c("+", "-"))) {
            h <- c(h, i)
        }
        else if (substring(x, i, i) == "(") {
            m <- m + 1
        }
        else if (substring(x, i, i) == ")") {
            m <- m - 1
        }
        i <- i + 1
    }
    if (!is.null(h)) {
        h <- c(-1, h, n + 2)
        i <- 2
        z <- substring(x, h[i] + 2, h[i + 1] - 2)
        while (i + 3 <= length(h)) {
            i <- i + 2
            z <- paste(z, substring(x, h[i] + 2, h[i + 1] - 2), 
                sep = " + ")
        }
        i <- -1
        while (i + 3 <= length(h)) {
            i <- i + 2
            z <- paste(z, substring(x, h[i] + 2, h[i + 1] - 2), 
                sep = " - ")
        }
    }
    else {
        z <- paste0("(-", x, ")")
    }
    z
}

#' sql.mat.multiply
#' 
#' SQL for the determinant
#' @param x = a string
#' @param y = a string
#' @keywords sql.mat.multiply
#' @export
#' @family sql

sql.mat.multiply <- function (x, y) 
{
    if (x == y) {
        z <- paste0("square(", x, ")")
    }
    else {
        z <- paste(x, y, sep = " * ")
    }
    z
}

#' sql.median
#' 
#' median (or alternate ptile point) of <x> within <y>
#' @param x = a column (on which computation is run)
#' @param y = a column (on which partitioning is performed)
#' @param n = a string (SQL statement)
#' @param w = desired ptile break point
#' @keywords sql.median
#' @export
#' @family sql

sql.median <- function (x, y, n, w = 0.5) 
{
    z <- paste0("Ptile = PERCENT_RANK() over (partition by ", 
        y, " order by ", x, ")")
    z <- sql.label(sql.tbl(c(x, y, z), sql.label(n, "t")), "t")
    h <- paste0(c("Mx", "Mn"), " = ", c("max", "min"), "(case when Ptile ", 
        c("<= ", ">= "), w, " then ", x, " else NULL end)")
    z <- sql.label(sql.tbl(c(y, h), z, , y), "t")
    z <- sql.tbl(c(y, "Stat = (Mx + isnull(Mn, Mx))/2"), z)
    z
}

#' sql.Mo
#' 
#' SQL statement for momentum
#' @param x = a string vector (flow)
#' @param y = a string vector (assets)
#' @param n = a string vector (weights, can be NULL)
#' @param w = a boolean (handle/ignore division by zero)
#' @keywords sql.Mo
#' @export
#' @family sql

sql.Mo <- function (x, y, n, w) 
{
    if (is.null(n)) {
        z <- paste0("sum(", y, ")")
    }
    else {
        z <- paste0("sum(", y, " * cast(", n, " as float))")
    }
    if (w) {
        w <- sql.nonneg(z)
    }
    else {
        w <- z
    }
    if (is.null(n)) {
        z <- paste0("sum(", x, ")")
    }
    else {
        z <- paste0("sum(", x, " * cast(", n, " as float))")
    }
    z <- paste0("= 100 * ", z, "/", w)
    z
}

#' sql.MonthlyAlloc
#' 
#' SQL query for monthly allocations for StockFlows
#' @param x = a YYYYMMDD for which you want allocations
#' @param y = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @param n = a boolean (SharesHeld/HoldingValue)
#' @param w = a boolean (do/don't get SecurityId)
#' @keywords sql.MonthlyAlloc
#' @export
#' @family sql

sql.MonthlyAlloc <- function (x, y = "All", n = F, w = F) 
{
    x <- paste("ReportDate =", x)
    if (y != "All") 
        x <- sql.and(list(A = x, B = sql.in("HSecurityId", sql.RDSuniv(y))))
    n <- ifelse(n, "SharesHeld", "HoldingValue")
    if (w) 
        n <- c("t.HSecurityId", "SecurityId", n)
    else n <- c("HSecurityId", n)
    n <- c("FundId", "HFundId", n)
    z <- c("Holdings t", "inner join", "SecurityHistory id on id.HSecurityId = t.HSecurityId")
    if (!w) 
        z <- "Holdings"
    z <- sql.tbl(n, z, x)
    z
}

#' sql.MonthlyAssetsEnd
#' 
#' SQL query for monthly Assets End
#' @param x = a YYYYMMDD or list (where clause)
#' @param y = a column vector (besides AssetsEnd)
#' @param n = a boolean (data are indexed by FundId/HFundId)
#' @param w = a ShareClass filter (All/Inst/Retail)
#' @param h = a column (name for AssetsEnd like "PortVal")
#' @keywords sql.MonthlyAssetsEnd
#' @export
#' @family sql

sql.MonthlyAssetsEnd <- function (x, y = NULL, n = F, w = "All", h = "AssetsEnd") 
{
    n <- ifelse(n, "FundId", "HFundId")
    h <- c(h, y)
    y <- c("AssetsEnd", y)
    z <- ifelse(y == "Inflow", "case when Flow > 0 then Flow else 0 end", 
        y)
    z <- ifelse(z == "Outflow", "case when Flow < 0 then Flow else 0 end", 
        z)
    z <- c(n, paste0(h, " = sum(", z, ")"))
    if (!is.null(x)) 
        if (is.list(x)) {
            x <- sql.and(x)
        }
        else x <- sql.ShareClass(paste("ReportDate =", x), w)
    u <- c("AssetsEnd", "AssetsStart")
    u <- vec.to.list(intersect(u, y), T)
    u <- sql.and(lapply(u, function(z) paste0("sum(", z, ") > 0")))
    y <- "MonthlyData"
    if (n == "FundId") 
        y <- c(sql.label(y, "t1"), "inner join", "FundHistory t2 on t2.HFundId = t1.HFundId")
    if (is.null(x)) {
        z <- c("ReportDate", z)
        n <- paste0(n, ", ReportDate")
        z <- sql.tbl(z, y, , n, u)
    }
    else z <- sql.tbl(z, y, x, n, u)
    z
}

#' sql.nonneg
#' 
#' case when <x> > 0 then <x> else NULL end
#' @param x = bit of sql string
#' @keywords sql.nonneg
#' @export
#' @family sql

sql.nonneg <- function (x) 
{
    paste("case when", x, "> 0 then", x, "else NULL end")
}

#' sql.Overweight
#' 
#' weight/shares normalized across stocks, then funds
#' @param x = a YYYYMMDD
#' @keywords sql.Overweight
#' @export
#' @family sql

sql.Overweight <- function (x) 
{
    z <- sql.label(sql.MonthlyAlloc(wrap(x), , T), "t1")
    h <- c("HSecurityId", "TotShs = sum(SharesHeld)")
    h <- sql.tbl(h, z, , "HSecurityId", "sum(SharesHeld) > 0")
    h <- c(z, "inner join", sql.label(h, "t2 on t2.HSecurityId = t1.HSecurityId"))
    z <- sql.tbl(c("t1.HSecurityId", "HFundId", "NormShs = SharesHeld/TotShs"), 
        h)
    h <- sql.tbl(c("HFundId", "TotNormShs = sum(SharesHeld/TotShs)"), 
        h, , "HFundId", "sum(SharesHeld/TotShs) > 0")
    z <- c(sql.label(z, "t1"), "inner join", sql.label(h, "t2 on t2.HFundId = t1.HFundId"))
    z <- sql.tbl(c("t1.HSecurityId", "t1.HFundId", "Overweight = NormShs/TotNormShs"), 
        z)
    z
}

#' sql.query
#' 
#' opens a connection, executes sql query, then closes the connection
#' @param x = a SQL query vector
#' @param y = a connection string/connection
#' @param n = a boolean (report/ignore record count)
#' @keywords sql.query
#' @export
#' @family sql
#' @@importFrom RODBC sqlQuery

sql.query <- function (x, y, n = T) 
{
    y <- sql.connect.wrapper(y)
    z <- sql.query.underlying(x, y$conn, n)
    sql.close(y)
    z
}

#' sql.RDSuniv
#' 
#' Generates the SQL query to get the row space for a #		:	stock flows research data set
#' @param x = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @keywords sql.RDSuniv
#' @export
#' @family sql

sql.RDSuniv <- function (x) 
{
    u <- mat.read(parameters("classif-RDSuniv"), "\t", NULL)
    u <- split(u, ifelse(grepl("^\\d+$", u[, "FundId"]), "F", 
        "U"))
    colnames(u[["U"]]) <- c("Univ", "RDS")
    u[["U"]] <- Reduce(merge, u)
    u[["F"]][, "RDS"] <- u[["F"]][, "Univ"]
    u <- Reduce(rbind, lapply(u, function(z) z[, names(u[["F"]])]))
    if (any(x == u[, "RDS"])) {
        u <- vec.named(u[u[, "RDS"] == x, "Univ"], u[u[, "RDS"] == 
            x, "FundId"])
        z <- vec.to.list(paste("FundId =", paste(names(u), u, 
            sep = " --")))
        z <- sql.in("HFundId", sql.tbl("HFundId", "FundHistory", 
            sql.and(z, "or")))
        z <- sql.tbl("HSecurityId", "Holdings", z, "HSecurityId")
    }
    else if (x == "File") {
        z <- paste0("(", paste(readLines("C:\\temp\\crap\\ids.txt"), 
            collapse = ", "), ")")
    }
    else if (x == "China") {
        z <- sql.tbl("HCompanyId", "CompanyHistory", "CountryCode = 'CN'")
        z <- sql.tbl("HSecurityId", "SecurityHistory", sql.in("HCompanyId", 
            z))
        z <- sql.in("HSecurityId", z)
        z <- list(A = z, B = sql.in("HFundId", sql.tbl("HFundId", 
            "FundHistory", "GeographicFocus = 16")))
        z <- sql.and(z, "or")
        z <- sql.tbl("HSecurityId", "Holdings", z, "HSecurityId")
    }
    else if (x == "All") {
        z <- ""
    }
    else {
        stop("Unknown universe!")
    }
    z
}

#' sql.regr
#' 
#' SQL for regression coefficients
#' @param x = a string vector (independent variable(s))
#' @param y = a string (dependent variable)
#' @param n = a boolean (yes/no intercept)
#' @keywords sql.regr
#' @export
#' @family sql

sql.regr <- function (x, y, n) 
{
    y <- sql.mat.crossprod.vector(x, y, n)
    x <- sql.mat.crossprod(x, n)
    h <- sql.mat.cofactor(x)
    n <- sql.mat.determinant(x)
    z <- NULL
    for (j in seq_along(y)) {
        w <- paste(paste0(y, " * (", h[, j], ")"), collapse = " + ")
        w <- paste0("(", w, ")/(", n, ")")
        z <- c(z, paste(names(y)[j], w, sep = " = "))
    }
    z
}

#' sql.ReportDate
#' 
#' SQL select statement for constant date <x>
#' @param x = a YYYYMMDD
#' @keywords sql.ReportDate
#' @export
#' @family sql

sql.ReportDate <- function (x) 
{
    paste0("ReportDate = '", yyyymmdd.to.txt(x), "'")
}

#' sql.ShareClass
#' 
#' Generates where clause for share-class filter
#' @param x = date restriction
#' @param y = a ShareClass filter (All/Inst/Retail)
#' @keywords sql.ShareClass
#' @export
#' @family sql

sql.ShareClass <- function (x, y) 
{
    if (any(y == c("Inst", "Retail"))) {
        z <- sql.tbl("SCID", "ShareClass", "InstOrRetail = 'Inst'")
        z <- sql.in("SCID", z, y == "Inst")
        z <- sql.and(list(A = x, B = z))
    }
    else z <- x
    z
}

#' sql.ShsSurp
#' 
#' SQL query for ShsSurp
#' @param x = a YYYYMM
#' @param y = factors and filters
#' @param n = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @param w = a boolean (index by HSecurityId/SecurityId)
#' @keywords sql.ShsSurp
#' @export
#' @family sql

sql.ShsSurp <- function (x, y, n, w) 
{
    y <- sql.arguments(y)
    if (length(y$factor) != 1 | y$factor[1] != "ShsSurp") 
        stop("Bad factor!")
    if (n != "All") 
        n <- list(A = sql.in("HSecurityId", sql.RDSuniv(n)))
    else n <- list()
    n[[LETTERS[length(n) + 1]]] <- "AssetsEnd > 0"
    z <- c("SecurityId", "HSecurityId", "SharesHeld = sum(SharesHeld)")
    z <- c(z, "Flow = sum(Flow * HoldingValue/AssetsEnd)")
    h <- c("#NEWHLD t1", "inner join", "#NEWAUM t2 on t2.FundId = t1.FundId")
    z <- sql.tbl(z, h, sql.and(n), "SecurityId, HSecurityId")
    h <- c(sql.label(z, "t1"), "inner join", "#NEWPRC t2 on t2.SecurityId = t1.SecurityId")
    z <- c("t1.SecurityId", "HSecurityId", "SharesHeld = SharesHeld - 1000000 * Flow/Stat")
    z <- sql.tbl(z, h, "Stat > 0")
    if (w) 
        w <- c(sql.ReportDate(yyyymm.to.day(x)), "HSecurityId")
    else w <- "t1.SecurityId"
    h <- c("SecurityId", "SharesHeld = sum(SharesHeld)")
    h <- sql.tbl(h, "#OLDHLD", , "SecurityId")
    h <- sql.label(h, "t2 on t2.SecurityId = t1.SecurityId")
    h <- c(sql.label(z, "t1"), "inner join", h)
    z <- c(w, "ShsSurp = 100 * t1.SharesHeld/t2.SharesHeld - 100")
    z <- sql.tbl(z, h, "t2.SharesHeld > 0")
    z <- paste(sql.unbracket(z), collapse = "\n")
    z <- c(paste(sql.1mAllocD.data(x, y$filter, T, F, T, "Flow"), 
        collapse = "\n"), z)
    z
}

#' sql.SRI
#' 
#' number of SRI funds holding the stock at time <x>
#' @param x = a YYYYMM
#' @param y = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @keywords sql.SRI
#' @export
#' @family sql

sql.SRI <- function (x, y) 
{
    w <- list(A = "ReportDate = @holdDt", B = sql.in("HFundId", 
        sql.tbl("HFundId", "FundHistory", "SRI = 1")))
    z <- sql.label(sql.tbl("HSecurityId, Ct = count(HFundId)", 
        "Holdings", sql.and(w), "HSecurityId"), "t1")
    z <- c(z, "inner join", "SecurityHistory id on id.HSecurityId = t1.HSecurityId")
    z <- sql.tbl("SecurityId, Ct = sum(Ct)", z, sql.in("t1.HSecurityId", 
        sql.RDSuniv(y)), "SecurityId")
    z <- sql.declare.wrapper("@holdDt", yyyymm.to.day(x), z)
    z
}

#' sql.tbl
#' 
#' Full SQL statement
#' @param x = a column vector
#' @param y = a from clause
#' @param n = a where clause
#' @param w = a group by clause
#' @param h = having clause
#' @param u = order by clause
#' @keywords sql.tbl
#' @export
#' @family sql

sql.tbl <- function (x, y, n, w, h, u) 
{
    m <- length(x)
    z <- c(!grepl("^\t", x[-1]), F)
    z <- paste0(x, ifelse(z, ",", ""))
    z <- c("(select", paste0("\t", txt.replace(z, "\n", "\n\t")))
    z <- c(z, "from", sql.tbl.from(y))
    if (!missing(n)) 
        if (n != "") 
            z <- c(z, "where", paste0("\t", n))
    if (!missing(w)) 
        z <- c(z, "group by", paste0("\t", w))
    if (!missing(h)) 
        if (h != "") 
            z <- c(z, "having", paste0("\t", h))
    if (!missing(u)) 
        z <- c(z, "order by", paste0("\t", u))
    z <- c(z, ")")
    z
}

#' sql.tbl.from
#' 
#' indented from clause
#' @param x = a from clause
#' @keywords sql.tbl.from
#' @export
#' @family sql

sql.tbl.from <- function (x) 
{
    z <- grepl(" join$", x) & !grepl("^\t", c(x[-1], ""))
    z <- ifelse(z, "", "\t")
    z <- paste0(z, txt.replace(x, "\n", "\n\t"))
    z
}

#' sql.TopDownAllocs
#' 
#' Generates the SQL query to get Active/Passive Top-Down Allocations
#' @param x = a YYYYMM
#' @param y = factors and filters
#' @param n = DB - any of StockFlows/China/Japan/CSI300/Energy
#' @param w = a boolean (index by HSecurityId/SecurityId)
#' @param h = a breakdown filter (e.g. All/GeoId/DomicileId)
#' @param u = a boolean (chuck/keep securities held by just one fund)
#' @keywords sql.TopDownAllocs
#' @export
#' @family sql

sql.TopDownAllocs <- function (x, y, n, w, h, u = F) 
{
    x <- yyyymm.to.day(x)
    y <- sql.arguments(y)
    g <- paste0("ReportDate = '", x, "'")
    if (n == "All") 
        n <- list()
    else n <- list(A = sql.in("HSecurityId", sql.RDSuniv(n)))
    n[[LETTERS[length(n) + 1]]] <- g
    n <- sql.and(n)
    r <- sql.FundHistory(y$filter, T, c("FundId", sql.breakdown(h)))
    r <- c("inner join", sql.label(r, "t2"), "\ton t2.HFundId = t1.HFundId")
    r <- c(sql.label(sql.MonthlyAssetsEnd(wrap(x)), "t1"), r)
    r <- sql.tbl(c("FundId", sql.breakdown(h), "AssetsEnd"), 
        r, sql.in("FundId", sql.tbl("FundId", "Holdings h", g)))
    r <- sql.label(r, "t2")
    if (h != "All") {
        v <- c("HSecurityId", sql.breakdown(h))
        g <- c("Holdings t1", "inner join", "FundHistory t2 on t2.HFundId = t1.HFundId")
        g <- sql.tbl(v, g, n, paste(v, collapse = ", "))
        r <- c(r, "inner join", sql.label(g, "t1"))
        r <- c(r, paste0("\ton t1.", sql.breakdown(h), " = t2.", 
            sql.breakdown(h)))
    }
    else {
        r <- c(r, "cross join", sql.label(sql.tbl("HSecurityId", 
            "Holdings", n, "HSecurityId"), "t1"))
    }
    r <- c(r, "left join", sql.label(sql.Holdings(n, c("FundId", 
        "HSId = HSecurityId", "HoldingValue")), "t3"))
    r <- c(r, "\ton t3.FundId = t2.FundId and HSId = HSecurityId")
    if (!w) 
        r <- c(r, "inner join", "SecurityHistory id on id.HSecurityId = t1.HSecurityId")
    g <- ifelse(w, "HSecurityId", "SecurityId")
    if (h != "All") 
        g <- paste(c(paste0("t2.", sql.breakdown(h)), g), collapse = ", ")
    if (u) {
        u <- ifelse(w, "HSecurityId", "SecurityId")
        u <- paste0("count(", u, ") > 1")
    }
    else u <- ""
    if (h == "GeoId") {
        z <- "GeoId = t2.GeographicFocus"
    }
    else if (h == "All") {
        z <- NULL
    }
    else {
        z <- paste0("t2.", h)
    }
    if (w) {
        z <- c(sql.ReportDate(x), z, "HSecurityId")
    }
    else {
        z <- c("SecurityId", z)
    }
    if (length(y$factor) == 1) {
        if (w) {
            n <- sql.TopDownAllocs.items(y$factor)
            n <- gsub(paste0("^", y$factor), "AverageAllocation", 
                n)
            z <- c(z, n)
        }
        else {
            z <- c(z, sql.TopDownAllocs.items(y$factor))
        }
        y <- sql.TopDownAllocs.items(y$factor, F)
        if (u == "") 
            u <- y
        else u <- paste(u, y, sep = " and ")
        z <- sql.tbl(z, r, , g, u)
    }
    else {
        z <- c(z, sql.TopDownAllocs.items(y$factor))
        z <- sql.tbl(z, r, , g, u)
    }
    z <- paste(sql.unbracket(z), collapse = "\n")
    z
}

#' sql.TopDownAllocs.items
#' 
#' allocations to select in Top-Down Allocations SQL query
#' @param x = a variable
#' @param y = a boolean (select item/having clause)
#' @keywords sql.TopDownAllocs.items
#' @export
#' @family sql

sql.TopDownAllocs.items <- function (x, y = T) 
{
    if (y) {
        z <- NULL
        for (i in x) {
            if (i == "SwtdEx0") {
                z <- c(z, "SwtdEx0 = 100 * avg(HoldingValue/AssetsEnd)")
            }
            else if (i == "SwtdIn0") {
                z <- c(z, "SwtdIn0 = 100 * sum(HoldingValue/AssetsEnd)/count(AssetsEnd)")
            }
            else if (i == "FwtdEx0") {
                z <- c(z, "FwtdEx0 = 100 * sum(HoldingValue)/sum(case when HoldingValue is not null then AssetsEnd else NULL end)")
            }
            else if (i == "FwtdIn0") {
                z <- c(z, "FwtdIn0 = 100 * sum(HoldingValue)/sum(AssetsEnd)")
            }
            else {
                stop("Bad Argument")
            }
        }
    }
    else if (length(x) > 1) {
        stop("Element expected, not vector")
    }
    else {
        if (x == "SwtdEx0") {
            z <- "count(HoldingValue/AssetsEnd) > 0"
        }
        else if (x == "SwtdIn0") {
            z <- "count(AssetsEnd) > 0"
        }
        else if (x == "FwtdEx0") {
            z <- "sum(case when HoldingValue is not null then AssetsEnd else NULL end) > 0"
        }
        else if (x == "FwtdIn0") {
            z <- "sum(AssetsEnd) > 0"
        }
        else {
            stop("Bad Argument")
        }
    }
    z
}

#' sql.Trend
#' 
#'  = sum(<x>)/case when sum(<x>) = 0 then NULL else sum(<x>) end
#' @param x = bit of SQL string
#' @param y = one of ""/"Num"/"Den"
#' @keywords sql.Trend
#' @export
#' @family sql

sql.Trend <- function (x, y = "") 
{
    z <- paste0("= sum(", x, ")")
    if (y == "") {
        z <- paste0(z, "/", sql.nonneg(paste0("sum(abs(", x, 
            "))")))
    }
    else if (y == "Den") {
        z <- paste0("= sum(abs(", x, "))")
    }
    z
}

#' sql.ui
#' 
#' funds to be displayed on the UI
#' @keywords sql.ui
#' @export
#' @family sql

sql.ui <- function () 
{
    z <- list()
    z[["A"]] <- "FundType in ('M', 'A', 'Y', 'B', 'E')"
    z[["B"]] <- "GeographicFocus not in (0, 18, 48)"
    z[["C"]] <- "Category >= '1'"
    z[["D"]] <- "isActive = 'Y'"
    z <- c("(", sql.and(z), ")")
    x <- list()
    x[["A"]] <- "Commodity = 'Y'"
    x[["B"]] <- "StyleSector in (101, 103)"
    x[["C"]] <- "FundType in ('Y', 'E')"
    x[["D"]] <- "isActive = 'Y'"
    x <- c("(", sql.and(x), ")")
    z <- list(A = z, B = x)
    z <- c("(", sql.and(z, "or"), ")")
    z
}

#' sql.unbracket
#' 
#' removes brackets around a SQL block
#' @param x = a string vector
#' @keywords sql.unbracket
#' @export
#' @family sql

sql.unbracket <- function (x) 
{
    n <- length(x)
    if (!grepl("^\\(", x[1]) | x[n] != ")") 
        stop("Can't unbracket!")
    x[1] <- gsub("^.", "", x[1])
    z <- x[-n]
    z
}

#' sql.update
#' 
#' update <x> set <y> from <n> where <w>
#' @param x = a SQL table
#' @param y = a string (set argument)
#' @param n = a from clause
#' @param w = a where clause
#' @keywords sql.update
#' @export
#' @family sql

sql.update <- function (x, y, n, w) 
{
    z <- c("update", paste0("\t", x), "set", paste0("\t", y))
    if (!missing(n)) 
        z <- c(z, "from", sql.tbl.from(n))
    z <- c(z, "where", paste0("\t", w))
    z
}

#' sql.yield.curve
#' 
#' buckets holdings by maturities
#' @param x = value to match CompanyName field
#' @param y = value to match SecurityType field
#' @param n = value to match BondCurrency field
#' @param w = type of maturity buckets
#' @param h = fund identifier
#' @keywords sql.yield.curve
#' @export
#' @family sql

sql.yield.curve <- function (x, y, n, w = "General", h = "FundId") 
{
    z <- list(A = "ReportDate = @date")
    z[["BondMaturity"]] <- "BondMaturity is not null"
    z[["Future"]] <- "BondMaturity > @date"
    z[["CompanyName"]] <- paste0("CompanyName = '", x, "'")
    z[["SecurityType"]] <- paste0("SecurityType = '", y, "'")
    z[["BondCurrency"]] <- paste0("BondCurrency = '", n, "'")
    if (w == "US") {
        v <- vec.named(c(0, 500, 2500), c("ST", "IT", "LT"))
    }
    else {
        v <- vec.named(c(0, 730, 1826, 3652), c("y0-2", "y2-5", 
            "y5-10", "y10+"))
    }
    v <- maturity.bucket(v)
    v <- sql.case("grp", v, c(names(v), "OTHER"), F)
    y <- c(h, v, "HoldingValue")
    z <- sql.label(sql.tbl(y, "vwBondMonthlyHoldingsReport_WithoutEmbargo", 
        sql.and(z)), "t")
    z <- sql.tbl(c(h, "grp", "HoldingValue = sum(HoldingValue)"), 
        z, , paste0(h, ", grp"))
    z
}

#' sql.yield.curve.1dFloMo
#' 
#' daily FloMo by yield-curve bucket
#' @param x = value to match CompanyName field
#' @param y = value to match SecurityType field
#' @param n = value to match BondCurrency field
#' @param w = a YYYYMMDD vector
#' @keywords sql.yield.curve.1dFloMo
#' @export
#' @family sql

sql.yield.curve.1dFloMo <- function (x, y, n, w) 
{
    z <- c("Flow", "AssetsStart")
    z <- paste0(z, " = sum(", z, ")")
    z <- c("DayEnding", "FundId", z)
    z <- sql.Flow(z, list(A = wrap(w)), , , T, paste(z[1:2], 
        collapse = ", "))
    w <- yyyymm.to.day(yyyymmdd.to.AllocMo.unique(flowdate.lag(w, 
        5), 26, F))
    x <- sql.yield.curve(x, y, n)
    z <- c(sql.label(z, "t1"), "inner join", sql.label(x, "t2 on t2.FundId = t1.FundId"))
    x <- sql.MonthlyAssetsEnd(list(A = "MonthEnding = @date"), 
        , T)
    z <- c(z, "inner join", sql.label(x, "t3 on t3.FundId = t1.FundId"))
    x <- c(sql.yyyymmdd("DayEnding"), "grp", sql.1dFloMo.select("FloMo"))
    z <- sql.tbl(x, z, , "DayEnding, grp")
    z <- sql.declare.wrapper("@date", w, z)
    z
}

#' sql.yyyymm
#' 
#' SQL code to convert to YYYYMM
#' @param x = a column (datetime field)
#' @param y = a string (post-conversion label, can be missing)
#' @keywords sql.yyyymm
#' @export
#' @family sql

sql.yyyymm <- function (x, y) 
{
    if (missing(y)) 
        z <- x
    else z <- y
    z <- paste0(z, " = convert(char(6), ", x, ", 112)")
    z
}

#' sql.yyyymmdd
#' 
#' SQL code to convert to YYYYMMDD
#' @param x = a column (datetime field)
#' @param y = a string (post-conversion label, can be missing)
#' @param n = a boolean (index by HSecurityId/SecurityId)
#' @keywords sql.yyyymmdd
#' @export
#' @family sql

sql.yyyymmdd <- function (x, y, n = F) 
{
    if (missing(y)) 
        z <- x
    else z <- y
    if (n) {
        z <- paste0(z, " = convert(char(10), ", x, ", 101) + ' 12:00:00 AM'")
    }
    else {
        z <- paste0(z, " = convert(char(8), ", x, ", 112)")
    }
    z
}

#' straight
#' 
#' the number of elements equalling the first
#' @param x = a logical vector
#' @keywords straight
#' @export

straight <- function (x) 
{
    seq(1, 1 + length(x))[!duplicated(c(x, !x[1]))][2] - 1
}

#' strat.dir
#' 
#' the folder where <x> factors live
#' @param x = a frequency (e.g. "daily", "weekly" or "monthly")
#' @keywords strat.dir
#' @export
#' @family strat

strat.dir <- function (x) 
{
    parameters.ex.file(dir.parameters("data"), x)
}

#' strat.email
#' 
#' emails strategies <x> of frequency <y>
#' @param x = a string vector (strategy names like FX/FloPctCtry)
#' @param y = a frequency (e.g. "daily", "weekly" or "monthly")
#' @param n = the email address(es) of the recipient(s)
#' @param w = the salutation
#' @keywords strat.email
#' @export
#' @family strat

strat.email <- function (x, y, n, w = "All") 
{
    z <- paste0("Dear ", w, ",<p>Please find attached the latest")
    z <- paste(z, ifelse(length(x) > 1, "files", "file"), "for the")
    z <- paste(z, y, html.and(x), ifelse(length(x) > 1, "strategies.", 
        "strategy."), "</p>\n<p>The data in")
    z <- paste(z, ifelse(length(x) > 1, "these files", "this file"), 
        "are indexed by the period they are as of")
    if (y == "monthly") {
        z <- paste(z, "and known the following month, before midnight, New York time, on the first")
        z <- paste(z, "business day after the 22nd.</p>")
    }
    else {
        z <- paste(z, "and known the following business day, usually before 5:00 PM New York time.</p>")
    }
    z <- paste(z, "<p>A business day is one that does not fall on Saturday, Sunday, Christmas or New Year's.</p>")
    z <- paste(z, "<p>The data in", ifelse(length(x) > 1, "these files", 
        "this file"), "are for a single")
    z <- paste(z, "period only. For multi-period lookbacks aggregate across time.</p>")
    z <- paste0(z, html.signature())
    email(n, paste("EPFR", txt.name.format(y), html.and(x)), 
        z, strat.path(x, y), T)
    invisible()
}

#' strat.file
#' 
#' the path to the factor file
#' @param x = a string vector (strategy names like FX/FloPctCtry)
#' @param y = a frequency (e.g. "daily", "weekly" or "monthly")
#' @keywords strat.file
#' @export
#' @family strat

strat.file <- function (x, y) 
{
    paste0(x, "-", y, ".csv")
}

#' strat.path
#' 
#' Returns the full path to the factor file
#' @param x = a string vector (strategy like FX/FloPctCtry)
#' @param y = a frequency (e.g. "daily", "weekly" or "monthly")
#' @keywords strat.path
#' @export
#' @family strat

strat.path <- function (x, y) 
{
    paste(strat.dir(y), strat.file(x, y), sep = "\\")
}

#' stratrets
#' 
#' data frame of TxB return spreads
#' @param x = a variable
#' @keywords stratrets
#' @export
#' @family stratrets

stratrets <- function (x) 
{
    y <- mat.read(parameters("classif-strat"), "\t", NULL)
    y <- y[is.element(y[, "vbl"], x), ]
    z <- vec.to.list(y[, "strat"], T)
    z <- lapply(z, function(z) stratrets.bbk(z, x))
    z <- array.ex.list(z, T, T)
    z <- z[order(rownames(z)), y[, "strat"]]
    if (nchar(rownames(z)[1]) == 6) {
        rownames(z) <- yyyymm.lag(rownames(z), -1)
    }
    else {
        rownames(z) <- day.lag(rownames(z), -7)
    }
    z <- mat.ex.matrix(z)
    x <- min(sapply(z, function(z) find.data(!is.na(z), T)))
    x <- c(x, max(sapply(z, function(z) find.data(!is.na(z), 
        F))))
    z <- z[seq(x[1], x[2]), ]
    z
}

#' stratrets.bbk
#' 
#' named vector of TxB return spreads indexed by BoP
#' @param x = strategy
#' @param y = a variable
#' @keywords stratrets.bbk
#' @export
#' @family stratrets

stratrets.bbk <- function (x, y) 
{
    cat("\t", x, y, "..\n")
    x <- stratrets.data(x, y)
    x[["retW"]] <- ifelse(nchar(rownames(x[["x"]])[1]) == 8, 
        5, 1)
    z <- do.call(bbk, x)[["rets"]]
    z <- z[order(rownames(z)), ]
    z <- as.matrix(z)[, "TxB"]
    z
}

#' stratrets.beta
#' 
#' beta-adjusted indicator
#' @param x = a matrix/data frame (predictors)
#' @param y = a matrix/data frame (total return indices)
#' @param n = a string (benchmark like "ACWorld")
#' @param w = a positive integer (lookback in days)
#' @keywords stratrets.beta
#' @export
#' @family stratrets

stratrets.beta <- function (x, y, n, w) 
{
    portfolio.residual(x, map.rname(portfolio.beta.wrapper(y, 
        n, w), rownames(x)))
}

#' stratrets.data
#' 
#' list object containing arguments needed for function <bbk>
#' @param x = strategy
#' @param y = a variable
#' @keywords stratrets.data
#' @export
#' @family stratrets

stratrets.data <- function (x, y) 
{
    h <- mat.read(parameters("classif-strat"), "\t", NULL)
    h <- mat.index(h[is.element(h[, "vbl"], y), colnames(h) != 
        "vbl"], "strat")
    if (is.na(h[x, "path"])) {
        z <- mat.read(parameters("classif-strat-multi"), "\t", 
            NULL)
        z <- z[is.element(z[, "strat"], x), "pieces"]
    }
    else z <- x
    z <- parameters.ex.file(fcn.dir(), h[z, "path"])
    z <- stratrets.indicator(z, h[x, "lkbk"], h[x, "comp"] == 
        0, h[x, "sec"] == 1, h[x, "delay"])
    if (!is.na(h[x, "sub"])) 
        z <- stratrets.subset(z, h[x, "sub"])
    z <- list(x = z, y = stratrets.returns(h[x, "rets"])[, colnames(z)])
    if (nchar(rownames(z[["x"]])[1]) == 6) 
        z[["y"]] <- mat.daily.to.monthly(z[["y"]], T)
    if (!is.na(h[x, "beta"])) 
        z[["x"]] <- stratrets.beta(z[["x"]], z[["y"]], h[x, "beta"], 
            h[x, "lkbk"])
    h <- h[, !is.element(colnames(h), c("path", "lkbk", "comp", 
        "beta", "sec", "sub", "rets"))]
    for (j in colnames(h)) if (!is.na(h[x, j])) 
        z[[j]] <- h[x, j]
    z
}

#' stratrets.indicator
#' 
#' data frame compounded across <y>
#' @param x = a file vector (strategies)
#' @param y = a positive integer (lookback)
#' @param n = a boolean (sum/compound)
#' @param w = if T, sector-adjustment is performed
#' @param h = a non-negative integer (delay, only used when <w>)
#' @keywords stratrets.indicator
#' @export
#' @family stratrets

stratrets.indicator <- function (x, y, n, w, h) 
{
    z <- compound.flows(multi.asset(x), y, n)
    if (w) {
        w <- rownames(z) >= yyyymmdd.lag("20160831", h)
        z[w, "Fins"] <- z[w, "FinsExREst"]
        z <- z[, colnames(z) != "FinsExREst"]
    }
    z
}

#' stratrets.path
#' 
#' path to strategy indicators
#' @param x = a string (e.g. Ctry/FX/SectorUK/Rgn/FI)
#' @param y = FundType (e.g. E/B)
#' @param n = a filter (e.g. Aggregate, Act, SRI. etc.)
#' @param w = a string (Flow/AssetsStart/Result)
#' @param h = variant (e.g. CB/SG/CBSG)
#' @keywords stratrets.path
#' @export
#' @family stratrets

stratrets.path <- function (x, y, n, w, h) 
{
    z <- NULL
    if (x == "FX" & y == "E" & n == "Aggregate" & w == "Flow" & 
        h == "CB") {
        z <- strat.path("FX$", "daily")
    }
    else if (x == "Rgn" & y == "E" & n == "Act" & w == "Result" & 
        h == "SG") {
        z <- strat.path("MultiAsset-Rgn", "daily")
    }
    else if (x == "FI" & y == "B" & n == "Aggregate" & w == "Result" & 
        h == "SG") {
        z <- strat.path("MultiAsset-FI", "daily")
    }
    else if (x == "FX" & y == "E" & n == "Aggregate" & w == "Result" & 
        h == "CB") {
        z <- strat.path("FX", "daily")
    }
    else if (x == "Ctry" & y == "E" & n == "Aggregate" & w == 
        "Result" & h == "CB") {
        z <- strat.path("FloPctCtry", "daily")
    }
    else if (x == "Ctry" & y == "B" & n == "Aggregate" & w == 
        "Result" & h == "CB") {
        z <- strat.path("FloPctCtry-B", "daily")
    }
    else if (y == "E" & n == "Act" & w == "Result" & h == "CB") {
        if (is.element(x, paste0("Sector", c("EM", "JP", "US", 
            "UK", "Eurozone")))) {
            z <- txt.replace(x, "Sector", "FloPctSector-")
            z <- strat.path(z, "daily")
        }
    }
    if (is.null(z)) {
        y <- paste0("-FundType", y)
        n <- paste0("-", n)
        w <- paste0("-", w)
        h <- paste0("-", h)
    }
    if (is.null(z)) {
        z <- paste0(fcn.dir(), "\\New Model Concept\\", x, "\\FloMo\\csv")
        z <- parameters.ex.file(z, paste0("oneDayFloMo", h, y, 
            n, w, ".csv"))
    }
    z
}

#' stratrets.returns
#' 
#' data frame of daily returns
#' @param x = return type (e.g. Ctry/FX/SectorUK/Multi)
#' @keywords stratrets.returns
#' @export
#' @family stratrets

stratrets.returns <- function (x) 
{
    if (x == "Ctry") {
        z <- paste0(fcn.dir(), "\\New Model Concept\\Ctry\\FloMo\\csv")
        z <- parameters.ex.file(z, "OfclMsciTotRetIdx.csv")
        z <- mat.read(z)
    }
    else if (x == "China") {
        z <- paste0(fcn.dir(), "\\New Model Concept\\ChinaShareClass\\csv")
        z <- parameters.ex.file(z, "OfclMsciTotRetIdx.csv")
        z <- mat.read(z)
        z <- z[, c("CHINA A", "CHINA B", "CHINA H", "CHINA RED CHIP", 
            "CHINA P CHIP", "OVERSEAS CHINA (US)", "OVERSEAS CHINA (SG)")]
        colnames(z) <- c("A Share", "B Share", "H Share", "Red Chip", 
            "P Chip", "ADR", "S Chip")
    }
    else if (x == "Commodity") {
        z <- paste0(fcn.dir(), "\\New Model Concept\\Commodity\\FloMo\\csv")
        z <- parameters.ex.file(z, "S&P GSCI ER.csv")
        z <- mat.read(z)[, c("SPGSENP", "SPGSGCP", "SPGSSIP", 
            "SPGSAGP")]
        colnames(z) <- c("Energy", "Gold", "Silver", "AG")
    }
    else if (x == "FX") {
        z <- paste0(fcn.dir(), "\\New Model Concept\\FX\\FloMo\\csv")
        z <- parameters.ex.file(z, "ExchRates-pseudo.csv")
        z <- 1/mat.read(z)
        z$USD <- rep(1, dim(z)[1])
        z[, "XDR"] <- rowMeans(z[, c("USD", "EUR")])
        z <- z/z[, "XDR"]
    }
    else if (x == "Multi") {
        x <- c("Ctry", "FI")
        x <- paste0(fcn.dir(), "\\New Model Concept\\", x, "\\FloMo\\csv")
        x <- parameters.ex.file(x, c("OfclMsciTotRetIdx.csv", 
            "pseudoReturns.csv"))
        z <- mat.read(x[1])[, c("JP", "GB", "US")]
        colnames(z) <- c("Japan", "UK", "USA")
        x <- ret.to.idx(map.rname(mat.read(x[2]), rownames(z)))
        z <- data.frame(z, x, stringsAsFactors = F)
        x <- parameters.ex.file(dir.parameters("csv"), "IndexReturns-Daily.csv")
        x <- map.rname(mat.read(x), rownames(z))
        z <- data.frame(z, x[, c("LatAm", "EurXGB", "PacXJP", 
            "AsiaXJP")], stringsAsFactors = F)
        x <- max(sapply(z, function(z) find.data(!is.na(z), T)))
        x <- x:min(sapply(z, function(z) find.data(!is.na(z), 
            F)))
        z <- z[x, ]
    }
    else {
        x <- gsub("^.{6}", "", x)
        y <- mat.read(parameters("classif-GSec"), "\t")
        if (any(colnames(y) == x)) {
            z <- paste0(fcn.dir(), "\\New Model Concept\\Sector\\FloMo\\csv")
            z <- parameters.ex.file(z, "OfclMsciTotRetIdx.csv")
            z <- mat.subset(mat.read(z), y[, x])
            colnames(z) <- rownames(y)
        }
        else {
            z <- paste0(fcn.dir(), "\\New Model Concept\\Sector", 
                x, "\\FloMo\\csv")
            z <- parameters.ex.file(z, "WeeklyRets.csv")
            z <- mat.read(z)
        }
    }
    z
}

#' stratrets.subset
#' 
#' subsets to columns used in the back-test
#' @param x = indicators
#' @param y = a string (index within which you trade)
#' @keywords stratrets.subset
#' @export
#' @family stratrets

stratrets.subset <- function (x, y) 
{
    if (grepl("FX$", y)) {
        y <- gsub("..$", "", y)
        z <- stratrets.subset.Ctry(x, y)
        z <- unique(Ctry.info(z, "Curr"))
        if (is.element(y, "EM")) 
            z <- setdiff(z, c("USD", "EUR"))
    }
    else {
        z <- stratrets.subset.Ctry(x, y)
    }
    z <- x[, is.element(colnames(x), z)]
    z
}

#' stratrets.subset.Ctry
#' 
#' determine which countries to subset to
#' @param x = indicators
#' @param y = a string (index within which you trade)
#' @keywords stratrets.subset.Ctry
#' @export
#' @family stratrets

stratrets.subset.Ctry <- function (x, y) 
{
    z <- NULL
    w <- c("ACWI", "EAFE", "EM", "Frontier")
    if (is.element(y, w)) {
        z <- rownames(x)[c(1, dim(x)[1])]
        z <- Ctry.msci.members.rng(y, z[1], z[2])
    }
    else {
        w <- colnames(mat.read(parameters("MsciCtry2016"), ","))
    }
    if (length(z) == 0 & is.element(y, w)) 
        z <- Ctry.msci.members(y, "")
    z
}

#' summ.multi
#' 
#' summarizes the multi-period back test
#' @param fcn = a function (summary)
#' @param x = a matrix/data frame (bin returns)
#' @param y = a positive integer (return window in days/months)
#' @keywords summ.multi
#' @export

summ.multi <- function (fcn, x, y) 
{
    if (y == 1) {
        z <- fcn(x)
    }
    else {
        z <- split(x, 1:dim(x)[1]%%y)
        z <- sapply(z, fcn, simplify = "array")
        z <- apply(z, 2:length(dim(z)) - 1, mean)
    }
    z
}

#' today
#' 
#' returns current flow date
#' @keywords today
#' @export

today <- function () 
{
    z <- day.ex.date(Sys.Date())
    while (!flowdate.exists(z)) z <- day.lag(z, 1)
    z
}

#' tstat
#' 
#' t-statistic associated with the regression of each row of <x> on <y>
#' @param x = a matrix/data frame
#' @param y = a numeric vector (corresponds to columns of <x>)
#' @keywords tstat
#' @export

tstat <- function (x, y) 
{
    x <- t(scale(t(x), scale = F))
    y <- scale(y, scale = F)
    z <- (x %*% y)/crossprod(y)[1, 1]
    n <- x - tcrossprod(z, y)
    n <- rowSums(n^2)/(dim(n)[2] - 2)
    n <- sqrt(n/crossprod(y)[1, 1])
    z <- z/n
    z
}

#' txt.anagram
#' 
#' all possible anagrams
#' @param x = a string
#' @param y = a file (usable capitalized words, can be missing)
#' @param n = an integer vector (minimum number of characters)
#' @keywords txt.anagram
#' @export
#' @family txt

txt.anagram <- function (x, y, n = 0) 
{
    x <- toupper(x)
    x <- txt.to.char(x)
    x <- x[is.element(x, LETTERS)]
    x <- paste(x, collapse = "")
    if (missing(y)) 
        y <- txt.words()
    else y <- txt.words(y)
    y <- y[order(y, decreasing = T)]
    y <- y[order(nchar(y))]
    z <- txt.anagram.underlying(x, y, n)
    z
}

#' txt.anagram.underlying
#' 
#' all possible anagrams
#' @param x = a string
#' @param y = a string vector (usable capitalized words)
#' @param n = an integer vector (minimum number of characters)
#' @keywords txt.anagram.underlying
#' @export
#' @family txt

txt.anagram.underlying <- function (x, y, n) 
{
    y <- y[txt.excise(y, txt.to.char(x)) == ""]
    z <- NULL
    m <- length(y)
    proceed <- m > 0
    if (proceed) 
        proceed <- nchar(y[m]) >= n[1]
    while (proceed) {
        w <- txt.excise(x, txt.to.char(y[m]))
        if (nchar(w) == 0) {
            z <- c(z, y[m])
        }
        else if (m > 1) {
            w <- txt.anagram.underlying(w, y[2:m - 1], c(n, 0)[-1])
            if (!is.null(w)) 
                z <- c(z, paste(y[m], w))
        }
        m <- m - 1
        proceed <- m > 0
        if (proceed) 
            proceed <- nchar(y[m]) >= n[1]
    }
    z
}

#' txt.bracket
#' 
#' returns the part within brackets
#' @param x = a string (representing a line of code)
#' @param y = a string (representing a function name)
#' @keywords txt.bracket
#' @export
#' @family txt

txt.bracket <- function (x, y) 
{
    x <- gsub(paste0("^.*", y, "\\("), "", x)
    z <- txt.to.char(x)
    n <- F
    for (j in seq_along(z)) {
        if (z[j] == "\"") {
            n <- !n
            z[j] <- 0
        }
        else if (z[j] == "(" & !n) {
            z[j] <- 1
        }
        else if (z[j] == ")" & !n) {
            z[j] <- -1
        }
        else {
            z[j] <- 0
        }
    }
    z <- cumsum(as.numeric(z))
    z <- txt.left(x, which(z == -1 & !duplicated(z)) - 1)
    z
}

#' txt.core
#' 
#' renders with upper-case letters, spaces and numbers only
#' @param x = a numeric vector
#' @keywords txt.core
#' @export
#' @family txt

txt.core <- function (x) 
{
    txt.trim(txt.itrim(gsub("[^0-9A-Z]", " ", toupper(x))))
}

#' txt.count
#' 
#' counts the number of occurences of <y> in each element of <x>
#' @param x = a string vector
#' @param y = a substring
#' @keywords txt.count
#' @export
#' @family txt

txt.count <- function (x, y) 
{
    lengths(regmatches(x, gregexpr(y, x)))
}

#' txt.ex.file
#' 
#' reads in the file as a string
#' @param x = a file
#' @keywords txt.ex.file
#' @export
#' @family txt

txt.ex.file <- function (x) 
{
    paste(readLines(x), collapse = "\n")
}

#' txt.ex.int
#' 
#' strings describing <x> in words
#' @param x = an integer vector
#' @param y = a boolean (ordinal/cardinal)
#' @keywords txt.ex.int
#' @export
#' @family txt

txt.ex.int <- function (x, y = F) 
{
    if (y) 
        txt.ex.int.ordinal.wrapper(x)
    else txt.ex.int.cardinal.wrapper(x)
}

#' txt.ex.int.cardinal
#' 
#' strings describing <x> in words (cardinal numbers)
#' @param x = an integer vector
#' @keywords txt.ex.int.cardinal
#' @export
#' @family txt

txt.ex.int.cardinal <- function (x) 
{
    y <- vec.named(c("zero", "ten", "eleven", "twelve", "thirteen", 
        "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", 
        "nineteen"), c(0, 10:19))
    n <- vec.named(c("one", "two", "three", "four", "five", "six", 
        "seven", "eight", "nine"), 1:9)
    w <- vec.named(c("twenty", "thirty", "forty", "fifty", "sixty", 
        "seventy", "eighty", "ninety"), 2:9)
    z <- txt.ex.int.underlying(x, y, n, w, w)
    z
}

#' txt.ex.int.cardinal.wrapper
#' 
#' strings describing <x> in words (cardinal numbers)
#' @param x = an integer vector
#' @keywords txt.ex.int.cardinal.wrapper
#' @export
#' @family txt

txt.ex.int.cardinal.wrapper <- function (x) 
{
    z <- ifelse(x%/%10000 > 0, x, NA)
    z <- ifelse(is.na(z) & x%/%100 == 0, txt.ex.int.cardinal(x), 
        z)
    z <- ifelse(is.na(z) & x%%1000 == 0, paste(txt.ex.int.cardinal(x%/%1000), 
        "thousand"), z)
    z <- ifelse(is.na(z) & x%%100 == 0, paste(txt.ex.int.cardinal(x%/%100), 
        "hundred"), z)
    z <- ifelse(is.na(z) & (x%/%100)%%10 == 0, paste(txt.ex.int.cardinal(x%/%1000), 
        "thousand and", txt.ex.int.cardinal(x%%100)), z)
    z <- zav(z, paste(txt.ex.int.cardinal(x%/%100), "hundred and", 
        txt.ex.int.cardinal(x%%100)))
    z
}

#' txt.ex.int.ordinal
#' 
#' strings describing <x> in words (cardinal numbers)
#' @param x = an integer vector
#' @keywords txt.ex.int.ordinal
#' @export
#' @family txt

txt.ex.int.ordinal <- function (x) 
{
    y <- vec.named(c("tenth", "eleventh", "twelfth", "thirteenth", 
        "fourteenth", "fifteenth", "sixteenth", "seventeenth", 
        "eighteenth", "nineteenth"), 10:19)
    n <- vec.named(c("first", "second", "third", "fourth", "fifth", 
        "sixth", "seventh", "eighth", "ninth"), 1:9)
    w <- vec.named(c("twenty", "thirty", "forty", "fifty", "sixty", 
        "seventy", "eighty", "ninety"), 2:9)
    h <- vec.named(c("twentieth", "thirtieth", "fortieth", "fiftieth", 
        "sixtieth", "seventieth", "eightieth", "ninetieth"), 
        2:9)
    z <- txt.ex.int.underlying(x, y, n, w, h)
    z
}

#' txt.ex.int.ordinal.wrapper
#' 
#' strings describing <x> in words (cardinal numbers)
#' @param x = an integer vector
#' @keywords txt.ex.int.ordinal.wrapper
#' @export
#' @family txt

txt.ex.int.ordinal.wrapper <- function (x) 
{
    z <- ifelse(x%/%10000 > 0, x, NA)
    z <- ifelse(is.na(z) & x%/%100 == 0, txt.ex.int.ordinal(x), 
        z)
    z <- ifelse(is.na(z) & x%%1000 == 0, paste(txt.ex.int.cardinal(x%/%1000), 
        "thousandth"), z)
    z <- ifelse(is.na(z) & x%%100 == 0, paste(txt.ex.int.cardinal(x%/%100), 
        "hundredth"), z)
    z <- ifelse(is.na(z) & (x%/%100)%%10 == 0, paste(txt.ex.int.cardinal(x%/%1000), 
        "thousand and", txt.ex.int.ordinal(x%%100)), z)
    z <- zav(z, paste(txt.ex.int.cardinal(x%/%100), "hundred and", 
        txt.ex.int.ordinal(x%%100)))
    z
}

#' txt.ex.int.underlying
#' 
#' string vector describing <x> in words
#' @param x = an integer vector
#' @param y = a string vector (odds & ends)
#' @param n = a string vector (units)
#' @param w = a string vector (tens)
#' @param h = a string vector (tens ordinal)
#' @keywords txt.ex.int.underlying
#' @export
#' @family txt

txt.ex.int.underlying <- function (x, y, n, w, h) 
{
    z <- ifelse(x%/%100 > 0, x, NA)
    z <- ifelse(is.element(x, names(y)), y[as.character(x)], 
        z)
    y <- is.na(z)
    z <- ifelse(is.element(x%%10, names(n)) & y, map.rname(n, 
        x%%10), z)
    y <- y & !is.element(x, 1:9)
    z <- ifelse(y & !is.na(z), paste(map.rname(w, (x%/%10)%%10), 
        z, sep = "-"), z)
    z <- ifelse(y & is.na(z), map.rname(h, (x%/%10)%%10), z)
    z
}

#' txt.excise
#' 
#' cuts first instance of each element of <y> from <x>
#' @param x = a string vector
#' @param y = a string vector
#' @keywords txt.excise
#' @export
#' @family txt

txt.excise <- function (x, y) 
{
    z <- x
    for (j in y) z <- sub(paste0("(", j, ")"), "", z)
    z
}

#' txt.expand
#' 
#' Returns all combinations of <x> and <y> pasted together
#' @param x = a string vector
#' @param y = a string vector
#' @param n = the separator
#' @param w = a boolean (order by 2nd/1st variable)
#' @keywords txt.expand
#' @export
#' @family txt

txt.expand <- function (x, y, n = "-", w = F) 
{
    z <- list(x = x, y = y)
    if (w) 
        z <- expand.grid(z, stringsAsFactors = F)
    else z <- rev(expand.grid(rev(z), stringsAsFactors = F))
    z[["sep"]] <- n
    z <- do.call(paste, z)
    z
}

#' txt.first
#' 
#' first occurrence of pattern <y> in <x> (NA if none)
#' @param x = a string vector
#' @param y = a string (regular expression)
#' @keywords txt.first
#' @export
#' @family txt

txt.first <- function (x, y) 
{
    nonneg(char.to.num(regexpr(y, x)))
}

#' txt.gunning
#' 
#' the Gunning fog index measuring the number of years of  schooling beyond kindergarten needed to comprehend <x>
#' @param x = a string (representing a text passage)
#' @param y = a file (capitalized words, can be missing)
#' @param n = a file (simple capitalized words, can be missing)
#' @keywords txt.gunning
#' @export
#' @family txt

txt.gunning <- function (x, y, n) 
{
    x <- toupper(x)
    x <- txt.replace(x, "-", " ")
    x <- txt.replace(x, "?", ".")
    x <- txt.replace(x, "!", ".")
    x <- txt.to.char(x)
    x <- x[is.element(x, c(LETTERS, " ", "."))]
    x <- paste(x, collapse = "")
    x <- txt.replace(x, ".", " . ")
    x <- txt.itrim(txt.trim(x))
    if (grepl("\\.$", x)) 
        x <- gsub(".$", "", x)
    x <- txt.trim(x)
    if (missing(y)) 
        y <- txt.words()
    else y <- txt.words(y)
    x <- txt.parse(x, " ")
    x <- x[is.element(x, c(y, "."))]
    z <- 1 + sum(x == ".")
    x <- x[x != "."]
    h <- length(x)
    if (h < 100) 
        cat("Passage needs to have at least a 100 words.\nNeed at least", 
            100 - h, "more words ..\n")
    z <- h/nonneg(z)
    if (missing(n)) {
        n <- union(txt.words(1), txt.words(2))
    }
    else {
        n <- txt.words(n)
    }
    if (any(!is.element(x, n))) {
        x <- x[!is.element(x, n)]
        n <- length(x)/nonneg(h)
        x <- x[!duplicated(x)]
        x <- x[order(nchar(x))]
    }
    else {
        n <- 0
        x <- NULL
    }
    z <- list(result = 0.4 * (z + 100 * n), complex = x)
    z
}

#' txt.has
#' 
#' subset of <x> based on pattern <y>
#' @param x = a string vector
#' @param y = a string (regular expression)
#' @keywords txt.has
#' @export
#' @family txt

txt.has <- function (x, y) 
{
    x[grepl(y, x)]
}

#' txt.hdr
#' 
#' nice-looking header
#' @param x = any string
#' @keywords txt.hdr
#' @export
#' @family txt

txt.hdr <- function (x) 
{
    n <- nchar(x)
    if (n%%2 == 1) 
        x <- paste0(x, " ")
    n <- (100 - n - n%%2)/2
    z <- paste0(txt.space(n, "*"), x, txt.space(n, "*"))
    z
}

#' txt.itrim
#' 
#' replaces consecutive spaces by one
#' @param x = a string vector
#' @keywords txt.itrim
#' @export
#' @family txt

txt.itrim <- function (x) 
{
    gsub("([ ])\\1+", "\\1", x)
}

#' txt.left
#' 
#' Returns the left <y> characters
#' @param x = a string vector
#' @param y = a positive integer
#' @keywords txt.left
#' @export
#' @family txt

txt.left <- function (x, y) 
{
    substring(x, 1, y)
}

#' txt.levenshtein
#' 
#' Levenshtein distance between <x> and <y>. Similar to dtw
#' @param x = a string
#' @param y = a string
#' @keywords txt.levenshtein
#' @export
#' @family txt

txt.levenshtein <- function (x, y) 
{
    n <- nchar(x)
    m <- nchar(y)
    if (min(m, n) == 0) {
        z <- max(m, n)
    }
    else {
        x <- c("", txt.to.char(x))
        y <- c("", txt.to.char(y))
        z <- matrix(NA, n + 1, m + 1, F, list(x, y))
        z[1, ] <- 0:m
        z[, 1] <- 0:n
        for (i in 1:m + 1) {
            for (j in 1:n + 1) {
                z[j, i] <- min(z[j - 1, i], z[j, i - 1]) + 1
                z[j, i] <- min(z[j, i], z[j - 1, i - 1] + char.to.num(x[j] != 
                  y[i]))
            }
        }
        z <- z[n + 1, m + 1]
    }
    z
}

#' txt.na
#' 
#' Returns a list of strings considered NA
#' @keywords txt.na
#' @export
#' @family txt

txt.na <- function () 
{
    c("#N/A", "NA", "N/A", "NULL", "<NA>", "--", "#N/A N/A", 
        "#VALUE!")
}

#' txt.name.format
#' 
#' capitalizes first letter of each word, rendering remaining letters in lower case
#' @param x = a string vector
#' @keywords txt.name.format
#' @export
#' @family txt

txt.name.format <- function (x) 
{
    txt.trim(gsub("( .{1})", "\\U\\1", txt.itrim(paste0(" ", 
        x)), perl = T))
}

#' txt.parse
#' 
#' breaks up string <x> by <y>
#' @param x = a string vector
#' @param y = the separator
#' @keywords txt.parse
#' @export
#' @family txt

txt.parse <- function (x, y) 
{
    if (length(x) == 1) {
        z <- strsplit(x, y, fixed = T)[[1]]
    }
    else {
        x <- strsplit(x, y, fixed = T)
        n <- max(sapply(x, length))
        y <- rep("", n)
        z <- sapply(x, function(z) c(z, y)[1:n], simplify = "array")
        if (is.null(dim(z))) 
            z <- as.matrix(z)
        else z <- t(z)
    }
    z
}

#' txt.parse.delimit
#' 
#' breaks up <x> by comma
#' @param x = a string
#' @keywords txt.parse.delimit
#' @export
#' @family txt

txt.parse.delimit <- function (x) 
{
    z <- NULL
    y <- txt.to.char(x)
    n <- rep(0, 3)
    for (j in seq_along(y)) {
        if (y[j] == "[") {
            n[1] <- n[1] + 1
        }
        else if (y[j] == "]" & n[1]) {
            n[1] <- n[1] - 1
        }
        else if (y[j] == "(") {
            n[2] <- n[2] + 1
        }
        else if (y[j] == ")" & n[2]) {
            n[2] <- n[2] - 1
        }
        else if (y[j] == "\"") {
            n[3] <- (n[3] + 1)%%2
        }
        else if (y[j] == "," & all(n == 0)) {
            z <- c(z, j)
        }
    }
    y <- c(0, z, nchar(x) + 1)
    z <- NULL
    for (j in seq_along(y)[-1]) {
        z <- c(z, substring(x, y[j - 1] + 1, y[j] - 1))
    }
    z
}

#' txt.prepend
#' 
#' adds <n> <y> times to the beginning of <x>
#' @param x = a string vector
#' @param y = number of times to add <n>
#' @param n = a string (prefix)
#' @keywords txt.prepend
#' @export
#' @family txt

txt.prepend <- function (x, y, n) 
{
    paste0(txt.space(vec.max(y - nchar(x), 0), n), x)
}

#' txt.regexp
#' 
#' converts <x> to a regular expression by padding certain characters with \\\\
#' @param x = a string
#' @keywords txt.regexp
#' @export
#' @family txt

txt.regexp <- function (x) 
{
    gsub("([\\^$.?*|+()[{])", "\\\\\\1", x)
}

#' txt.regr
#' 
#' returns the string you need to regress the first column on the others
#' @param x = a column vector
#' @param y = a boolean (is/isn't an intercept)
#' @keywords txt.regr
#' @export
#' @family txt

txt.regr <- function (x, y = T) 
{
    z <- x[1]
    x <- x[-1]
    if (!y) 
        x <- c("-1", x)
    x <- paste(x, collapse = " + ")
    z <- paste(z, x, sep = " ~ ")
    z
}

#' txt.replace
#' 
#' replaces all instances of <y> with <n>
#' @param x = a string vector
#' @param y = a string to be swapped out
#' @param n = a string to replace <y> with
#' @keywords txt.replace
#' @export
#' @family txt

txt.replace <- function (x, y, n) 
{
    gsub(y, n, x, fixed = T)
}

#' txt.reverse
#' 
#' reverses the constitutent characters of <x>
#' @param x = a string vector
#' @keywords txt.reverse
#' @export
#' @family txt

txt.reverse <- function (x) 
{
    fcn <- function(z) paste(rev(txt.to.char(z)), collapse = "")
    z <- fcn.vec.num(fcn, x)
    z
}

#' txt.right
#' 
#' Returns the right <y> characters
#' @param x = a string vector
#' @param y = a positive integer
#' @keywords txt.right
#' @export
#' @family txt

txt.right <- function (x, y) 
{
    substring(x, nchar(x) - y + 1, nchar(x))
}

#' txt.space
#' 
#' returns <x> iterations of <y> pasted together
#' @param x = an integer vector
#' @param y = a string
#' @keywords txt.space
#' @export
#' @family txt

txt.space <- function (x, y = " ") 
{
    strrep(y, x)
}

#' txt.subclass
#' 
#' F/T depending on whether <x> is a subclass of <y>
#' @param x = a string
#' @param y = a string
#' @param n = a data frame
#' @keywords txt.subclass
#' @export
#' @family txt

txt.subclass <- function (x, y, n) 
{
    if (grepl(" vector$", x)) {
        z <- !grepl(" vector$", y)
        if (!z) {
            x <- gsub(" vector$", "", x)
            y <- gsub(" vector$", "", y)
            z <- txt.subclass.underlying(x, y, n)
        }
        else {
            z <- txt.subclass.underlying(x, y, n)
        }
    }
    else {
        z <- txt.subclass.underlying(x, y, n)
        y <- gsub(" vector", "", y)
        z <- z & txt.subclass.underlying(x, y, n)
    }
    z
}

#' txt.subclass.bulk
#' 
#' bulks up the map from the first column to the second
#' @param x = a data frame (2 column)
#' @keywords txt.subclass.bulk
#' @export
#' @family txt

txt.subclass.bulk <- function (x) 
{
    z <- x
    colnames(x) <- c("grandchild", colnames(x)[1])
    x <- merge(x, z)[, -1]
    colnames(x) <- colnames(z)
    w <- !is.element(do.call(paste, x), do.call(paste, z))
    while (any(w)) {
        x <- z <- rbind(z, x[w, ])
        colnames(x) <- c("grandchild", colnames(x)[1])
        x <- merge(x, z)[, -1]
        colnames(x) <- colnames(z)
        w <- !is.element(do.call(paste, x), do.call(paste, z))
    }
    z
}

#' txt.subclass.underlying
#' 
#' F/T depending on whether <x> is a subclass of <y>
#' @param x = a string
#' @param y = a string
#' @param n = a data frame
#' @keywords txt.subclass.underlying
#' @export
#' @family txt

txt.subclass.underlying <- function (x, y, n) 
{
    z <- x != y
    if (z & grepl("^ (a|an) .+/.+", y) & !grepl("^ (a|an) .+/.+", 
        x)) {
        u <- txt.parse(gsub("^ (a|an) ", "", y), "/")
        u <- split(paste(" a", u), u)
        z <- all(sapply(u, function(z) txt.subclass.underlying(x, 
            z, n)))
    }
    else if (z & grepl("^ (a|an) .+/.+", y) & grepl("^ (a|an) .+/.+", 
        x)) {
        u <- txt.parse(gsub("^ (a|an) ", "", y), "/")
        u <- split(paste(" a", u), u)
        v <- txt.parse(gsub("^ (a|an) ", "", x), "/")
        v <- split(paste(" a", v), v)
        fcn <- function(z) all(sapply(u, function(l) txt.subclass.underlying(z, 
            l, n)))
        z <- any(sapply(v, fcn))
    }
    u <- gsub("^ (a|an) ", "", x)
    if (grepl("/", x)) {
        u <- txt.parse(u, "/")
        n <- rbind(n, matrix(rep(n[, "child"], 2), dim(n)[1], 
            2, F, list(1:dim(n)[1], colnames(n))))
        n <- split(n[, "child"], n[, "parent"])
        n <- sapply(n, function(z) all(is.element(u, z)))
        u <- gsub("^ (a|an) ", "", x)
        u <- paste(c(u, names(n)[n]), collapse = "|")
    }
    else {
        u <- c(u, n[is.element(n[, "child"], u), "parent"])
        u <- paste(u, collapse = "|")
    }
    if (z) 
        if (grepl("^ (a|an) ", x)) {
            u <- paste0("(^ )(a|an)( )(.*/)?(", u, ")(/.*)?$")
            z <- z & !grepl(u, y)
        }
    z
}

#' txt.subclass.wrapper
#' 
#' functions, arguments and comments
#' @keywords txt.subclass.wrapper
#' @export
#' @family txt

txt.subclass.wrapper <- function () 
{
    z <- mat.read(parameters("classif-subclass"), "\t", NULL)
    z <- txt.subclass.bulk(z)
    z <- rbind(z, apply(z, 2, function(z) paste(z, "vector")))
    z
}

#' txt.to.char
#' 
#' a numeric vector of the constitutent characters of <x>
#' @param x = a string
#' @keywords txt.to.char
#' @export
#' @family txt

txt.to.char <- function (x) 
{
    strsplit(x, "")[[1]]
}

#' txt.trim
#' 
#' trims off leading/trailing occurences of <y>
#' @param x = a string vector
#' @param y = a string
#' @keywords txt.trim
#' @export
#' @family txt

txt.trim <- function (x, y = " ") 
{
    txt.trim.right(txt.trim.left(x, y), y)
}

#' txt.trim.left
#' 
#' trims off leading occurences of <y>
#' @param x = a string vector
#' @param y = a string
#' @keywords txt.trim.left
#' @export
#' @family txt

txt.trim.left <- function (x, y) 
{
    gsub(paste0("^(", txt.regexp(y), ")+"), "", x)
}

#' txt.trim.right
#' 
#' trims off trailing occurences of <y>
#' @param x = a string vector
#' @param y = a string
#' @keywords txt.trim.right
#' @export
#' @family txt

txt.trim.right <- function (x, y) 
{
    gsub(paste0("(", txt.regexp(y), ")*$"), "", x)
}

#' txt.words
#' 
#' a numeric vector of capitalized words
#' @param x = missing or an integer
#' @keywords txt.words
#' @export
#' @family txt

txt.words <- function (x = "All") 
{
    if (any(x == c("All", 1:2))) {
        if (x == "All") {
            z <- "EnglishWords.txt"
        }
        else if (x == 1) {
            z <- "EnglishWords-1syllable.txt"
        }
        else if (x == 2) {
            z <- "EnglishWords-2syllables.txt"
        }
        z <- parameters.ex.file(dir.parameters("data"), z)
    }
    else {
        z <- x
    }
    z <- readLines(z)
    z
}

#' urn.exact
#' 
#' probability of drawing precisely <x> balls from an urn containing <y> balls
#' @param x = an integer vector
#' @param y = an integer vector (pointwise >= <x>)
#' @keywords urn.exact
#' @export

urn.exact <- function (x, y) 
{
    z <- 1
    for (i in seq_along(x)) z <- z * factorial(y[i])/(factorial(x[i]) * 
        factorial(y[i] - x[i]))
    z <- (z/factorial(sum(y))) * factorial(sum(x)) * factorial(sum(y - 
        x))
    z
}

#' utf8.to.quoted.printable
#' 
#' quoted-printable representation of <x>
#' @param x = a single character
#' @keywords utf8.to.quoted.printable
#' @export

utf8.to.quoted.printable <- function (x) 
{
    y <- c(0:9, LETTERS[1:6])
    h <- c(8, 9, LETTERS[1:2])
    r <- LETTERS[5:8]
    x <- utf8ToInt(x)
    x <- base.ex.int(x, 64)
    x <- split(x, 1:3)
    x <- lapply(x, function(z) base.ex.int(z, 16))
    x <- lapply(x, function(z) c(rep(0, 2 - length(z)), z))
    x <- lapply(x, function(z) z + 1)
    x <- lapply(x, function(z) c(z[1], y[z[2]]))
    x[[1]][1] <- r[char.to.num(x[[1]][1])]
    x[[2]][1] <- h[char.to.num(x[[2]][1])]
    x[[3]][1] <- h[char.to.num(x[[3]][1])]
    x <- sapply(x, function(z) paste(z, collapse = ""))
    z <- paste(x, collapse = "=")
    z
}

#' variance.ratio.test
#' 
#' tests whether <x> follows a random walk (i.e. <x> independent of prior values)
#' @param x = vector
#' @param y = an integer (greater than 1)
#' @keywords variance.ratio.test
#' @export

variance.ratio.test <- function (x, y) 
{
    y <- char.to.num(y)
    if (is.na(y) | y == 1) 
        stop("Bad value of y ..")
    x <- x - mean(x)
    T <- length(x)
    sd.1 <- sum(x^2)/(T - 1)
    z <- x[y:T]
    for (i in 2:y - 1) z <- z + x[y:T - i]
    sd.y <- sum(z^2)/(T - y - 1)
    z <- sd.y/(y * sd.1 * (1 - y/T))
    z
}

#' vec.cat
#' 
#' displays on screen
#' @param x = vector
#' @keywords vec.cat
#' @export
#' @family vec

vec.cat <- function (x) 
{
    cat(paste(x, collapse = "\n"), "\n")
}

#' vec.count
#' 
#' Counts unique instances of <x>
#' @param x = a string vector
#' @keywords vec.count
#' @export
#' @family vec

vec.count <- function (x) 
{
    pivot.1d(length, x, x)
}

#' vec.cum
#' 
#' cumulative sum
#' @param x = a numeric vector
#' @keywords vec.cum
#' @export
#' @family vec

vec.cum <- function (x) 
{
    cumsum(c(0, x))
}

#' vec.diff
#' 
#' difference between <x> and itself lagged <y>
#' @param x = a numeric vector
#' @param y = an integer
#' @keywords vec.diff
#' @export
#' @family vec

vec.diff <- function (x, y) 
{
    c(rep(NA, y), diff(x, y))
}

#' vec.ex.filters
#' 
#' SQL query where clauses associated with filters
#' @param x = either "sf" or "macro"
#' @keywords vec.ex.filters
#' @export
#' @family vec

vec.ex.filters <- function (x) 
{
    z <- mat.read(parameters("classif-filters"), "\t", NULL)
    z <- z[is.element(z$type, x), ]
    z <- as.matrix(mat.index(z, "filter"))[, "SQL"]
    z
}

#' vec.first
#' 
#' latest element of a vector
#' @param x = a string vector
#' @keywords vec.first
#' @export
#' @family vec

vec.first <- function (x) 
{
    x[1]
}

#' vec.lag
#' 
#' simple positional lag of <x> by <y> periods
#' @param x = a numeric vector
#' @param y = an integer
#' @keywords vec.lag
#' @export
#' @family vec

vec.lag <- function (x, y) 
{
    x[nonneg(seq_along(x) - y)]
}

#' vec.last
#' 
#' latest element of a vector
#' @param x = a string vector
#' @keywords vec.last
#' @export
#' @family vec

vec.last <- function (x) 
{
    tail(x, 1)
}

#' vec.max
#' 
#' Returns the piecewise maximum of <x> and <y>
#' @param x = a numeric vector/matrix/data frame
#' @param y = a numeric vector/matrix/data frame
#' @keywords vec.max
#' @export
#' @family vec

vec.max <- function (x, y) 
{
    fcn.mat.vec(function(z, l) ifelse(!is.na(z) & !is.na(l) & 
        z < l, l, z), x, y, T)
}

#' vec.min
#' 
#' Returns the piecewise minimum of <x> and <y>
#' @param x = a numeric vector/matrix/data frame
#' @param y = a numeric vector/matrix/data frame
#' @keywords vec.min
#' @export
#' @family vec

vec.min <- function (x, y) 
{
    fcn.mat.vec(function(z, l) ifelse(!is.na(z) & !is.na(l) & 
        z > l, l, z), x, y, T)
}

#' vec.named
#' 
#' Returns a numeric vector with values <x> and names <y>
#' @param x = a string vector (can be missing)
#' @param y = a string vector
#' @keywords vec.named
#' @export
#' @family vec

vec.named <- function (x, y) 
{
    if (missing(x)) 
        z <- rep(NA, length(y))
    else z <- x
    names(z) <- y
    z
}

#' vec.read
#' 
#' reads into <x> a named vector
#' @param x = a file (vector)
#' @param y = the separator
#' @keywords vec.read
#' @export
#' @family vec

vec.read <- function (x, y = ",") 
{
    as.matrix(mat.read(x, y, , F))[, 1]
}

#' vec.swap
#' 
#' swaps elements <y> and <n> of vector <x>
#' @param x = a numeric vector
#' @param y = an integer between 1 and length(<x>)
#' @param n = an integer between 1 and length(<x>)
#' @keywords vec.swap
#' @export
#' @family vec

vec.swap <- function (x, y, n) 
{
    x[ifelse(seq_along(x) == y, n, ifelse(seq_along(x) == n, 
        y, seq_along(x)))]
}

#' vec.to.list
#' 
#' list object
#' @param x = a string vector
#' @param y = a boolean (names are <x>/seq_along(<x>))
#' @param n = a boolean (preserve/ignore original order)
#' @keywords vec.to.list
#' @export
#' @family vec

vec.to.list <- function (x, y = F, n = F) 
{
    if (y & !n) {
        z <- split(x, x)
    }
    else {
        z <- split(x, seq_along(x))
        if (y & n) 
            names(z) <- sapply(z, function(z) z)
    }
    z
}

#' vec.unique
#' 
#' returns unique values of <x> in ascending order
#' @param x = a string vector/matrix/data frame
#' @keywords vec.unique
#' @export
#' @family vec

vec.unique <- function (x) 
{
    z <- unlist(x)
    z <- z[!is.na(z)]
    z <- z[!duplicated(z)]
    z <- z[order(z)]
    z
}

#' versionR
#' 
#' current version of R
#' @keywords versionR
#' @export

versionR <- function () 
{
    version[["version.string"]]
}

#' weekday.to.name
#' 
#' Converts to 0 = Sun, 1 = Mon, .., 6 = Sat
#' @param x = an integer vector (entries must be 0-6)
#' @keywords weekday.to.name
#' @export

weekday.to.name <- function (x) 
{
    y <- c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
    y <- vec.named(y, 0:6)
    z <- map.rname(y, x)
    z <- as.character(z)
    z
}

#' wrap
#' 
#' <x> wrapped in apostrophes
#' @param x = a string vector
#' @keywords wrap
#' @export

wrap <- function (x) 
{
    paste0("'", x, "'")
}

#' yyyy.ex.period
#' 
#' the year in which the return window ends
#' @param x = a YYYYMM/flowdate vector (trade dates)
#' @param y = a positive integer (return window in days/months)
#' @keywords yyyy.ex.period
#' @export
#' @family yyyy

yyyy.ex.period <- function (x, y) 
{
    txt.left(yyyymm.lag(x, -y), 4)
}

#' yyyy.ex.yy
#' 
#' returns a numeric vector of YYYY
#' @param x = an integer vector (non-negative!)
#' @keywords yyyy.ex.yy
#' @export
#' @family yyyy

yyyy.ex.yy <- function (x) 
{
    x <- char.to.num(x)
    z <- ifelse(x < 100, ifelse(x < 50, 2000, 1900), 0) + x
    z
}

#' yyyy.periods.count
#' 
#' the number of periods that typically fall in a year
#' @param x = a string vector
#' @keywords yyyy.periods.count
#' @export
#' @family yyyy

yyyy.periods.count <- function (x) 
{
    ifelse(all(nchar(x) == 6), ifelse(all(substring(x, 5, 5) == 
        "Q"), 4, 12), 260)
}

#' yyyymm.diff
#' 
#' returns <x - y> in terms of YYYYMM
#' @param x = a YYYYMM vector
#' @param y = a YYYYMM vector
#' @keywords yyyymm.diff
#' @export
#' @family yyyymm

yyyymm.diff <- function (x, y) 
{
    obj.diff(yyyymm.to.int, x, y)
}

#' yyyymm.ex.int
#' 
#' returns = a YYYYMM vector
#' @param x = an integer vector
#' @keywords yyyymm.ex.int
#' @export
#' @family yyyymm

yyyymm.ex.int <- function (x) 
{
    z <- (x - 1)%/%12
    x <- x - 12 * z
    z <- 100 * z + x
    z <- as.character(z)
    z <- txt.prepend(z, 6, 0)
    z
}

#' yyyymm.ex.qtr
#' 
#' returns a specific yyyymm within the quarter
#' @param x = a qtr vector
#' @param y = month, in the quarter, to return
#' @keywords yyyymm.ex.qtr
#' @export
#' @family yyyymm

yyyymm.ex.qtr <- function (x, y = 3) 
{
    z <- qtr.to.int(x)
    z <- yyyymm.ex.int(z * 3)
    z <- yyyymm.lag(z, 3 - y)
    z
}

#' yyyymm.exists
#' 
#' T if <x> is a month expressed in YYYYMM format
#' @param x = a string vector
#' @keywords yyyymm.exists
#' @export
#' @family yyyymm

yyyymm.exists <- function (x) 
{
    grepl("^\\d{4}(0[1-9]|1[0-2])$", x)
}

#' yyyymm.lag
#' 
#' lags <x> by <y> periods
#' @param x = a qtr/YYYYMM/flowdate vector
#' @param y = an integer vector
#' @param n = a boolean (lag by yyyymmdd/flowdate)
#' @keywords yyyymm.lag
#' @export
#' @family yyyymm

yyyymm.lag <- function (x, y = 1, n = T) 
{
    if (nchar(x[1]) == 8 & n) {
        z <- yyyymmdd.lag(x, y)
    }
    else if (nchar(x[1]) == 8 & !n) {
        z <- flowdate.lag(x, y)
    }
    else if (substring(x[1], 5, 5) == "Q") {
        z <- qtr.lag(x, y)
    }
    else {
        z <- obj.lag(x, y, yyyymm.to.int, yyyymm.ex.int)
    }
    z
}

#' yyyymm.seq
#' 
#' returns a sequence between (and including) x and y
#' @param x = a YYYY/YYYYMM/YYYYMMDD
#' @param y = a YYYY/YYYYMM/YYYYMMDD
#' @param n = a positive integer
#' @keywords yyyymm.seq
#' @export
#' @family yyyymm

yyyymm.seq <- function (x, y, n = 1) 
{
    if (nchar(x) == 4) {
        z <- seq(x, y, n)
    }
    else if (nchar(x) == 8) {
        z <- yyyymmdd.seq(x, y, n)
    }
    else {
        z <- obj.seq(x, y, yyyymm.to.int, yyyymm.ex.int, n)
    }
    z
}

#' yyyymm.to.day
#' 
#' Returns the last day in the month whether weekend or not.
#' @param x = a YYYYMM vector
#' @keywords yyyymm.to.day
#' @export
#' @family yyyymm

yyyymm.to.day <- function (x) 
{
    day.lag(paste0(yyyymm.lag(x, -1), "01"), 1)
}

#' yyyymm.to.int
#' 
#' returns integers
#' @param x = a YYYYMM/flowdate/YYYYMMDD vector
#' @keywords yyyymm.to.int
#' @export
#' @family yyyymm

yyyymm.to.int <- function (x) 
{
    z <- char.to.num(substring(x, 1, 4))
    z <- 12 * z + char.to.num(substring(x, 5, 6))
    z
}

#' yyyymm.to.qtr
#' 
#' returns associated quarters
#' @param x = a YYYYMM/flowdate/YYYYMMDD vector
#' @keywords yyyymm.to.qtr
#' @export
#' @family yyyymm

yyyymm.to.qtr <- function (x) 
{
    z <- yyyymm.to.int(x)
    z <- z + (3 - z)%%3
    z <- qtr.ex.int(z/3)
    z
}

#' yyyymm.to.yyyy
#' 
#' Converts to yyyy years
#' @param x = a YYYYMM vector
#' @keywords yyyymm.to.yyyy
#' @export
#' @family yyyymm

yyyymm.to.yyyy <- function (x) 
{
    z <- char.to.num(x)
    z <- z%/%100
    z
}

#' yyyymmdd.bulk
#' 
#' Eliminates YYYYMMDD gaps
#' @param x = a matrix/data frame (indexed by YYYYMMDD)
#' @keywords yyyymmdd.bulk
#' @export
#' @family yyyymmdd

yyyymmdd.bulk <- function (x) 
{
    z <- rownames(x)
    z <- yyyymm.seq(z[1], z[dim(x)[1]])
    w <- !is.element(z, rownames(x))
    if (any(w)) 
        err.raise(z[w], F, "Following weekdays missing from data")
    z <- map.rname(x, z)
    z
}

#' yyyymmdd.diff
#' 
#' returns <x - y> in terms of weekdays
#' @param x = a YYYYMMDD vector
#' @param y = a YYYYMMDD vector
#' @keywords yyyymmdd.diff
#' @export
#' @family yyyymmdd

yyyymmdd.diff <- function (x, y) 
{
    obj.diff(yyyymmdd.to.int, x, y)
}

#' yyyymmdd.ex.day
#' 
#' Falls back to the closest weekday
#' @param x = a calendar date vector
#' @keywords yyyymmdd.ex.day
#' @export
#' @family yyyymmdd

yyyymmdd.ex.day <- function (x) 
{
    z <- day.to.int(x)
    z <- z - ifelse(is.element(z%%7, 2:3), z%%7 - 1, 0)
    z <- day.ex.int(z)
    z
}

#' yyyymmdd.ex.int
#' 
#' the <x>th weekday after Thursday, January 1, 1970
#' @param x = an integer vector
#' @keywords yyyymmdd.ex.int
#' @export
#' @family yyyymmdd

yyyymmdd.ex.int <- function (x) 
{
    day.ex.int(x + 2 * (x + 3)%/%5)
}

#' yyyymmdd.ex.txt
#' 
#' calendar dates
#' @param x = a string vector
#' @param y = the separator
#' @param n = a string (order of MDY)
#' @keywords yyyymmdd.ex.txt
#' @export
#' @family yyyymmdd

yyyymmdd.ex.txt <- function (x, y = "/", n = "MDY") 
{
    x <- as.character(x)
    w <- length(x) == 1
    if (w) 
        x <- txt.parse(x, " ")[1]
    else x <- txt.parse(x, " ")[, 1]
    x <- txt.parse(x, y)
    if (w) 
        x <- matrix(char.to.num(x), 1, 3)
    else x <- apply(x, 2, char.to.num)
    colnames(x) <- txt.to.char(n)
    x[, "Y"] <- yyyy.ex.yy(x[, "Y"])
    z <- as.character(x[, c("Y", "M", "D")] %*% c(10000, 100, 
        1))
    z
}

#' yyyymmdd.ex.yyyymm
#' 
#' last/all weekdays in <x>
#' @param x = a YYYYMM vector
#' @param y = a boolean (last/all weekdays)
#' @keywords yyyymmdd.ex.yyyymm
#' @export
#' @family yyyymmdd

yyyymmdd.ex.yyyymm <- function (x, y = T) 
{
    z <- paste0(yyyymm.lag(x, -1), "01")
    z <- yyyymmdd.ex.day(z)
    w <- yyyymmdd.to.yyyymm(z) != x
    if (any(w)) 
        z[w] <- yyyymm.lag(z[w])
    if (!y & length(x) > 1) 
        stop("You can't do this ..\n")
    if (!y) {
        x <- paste0(x, "01")
        x <- yyyymmdd.ex.day(x)
        if (yyyymmdd.to.yyyymm(x) != yyyymmdd.to.yyyymm(z)) 
            x <- yyyymm.lag(x, -1)
        z <- yyyymm.seq(x, z)
    }
    z
}

#' yyyymmdd.exists
#' 
#' returns T if <x> is a weekday
#' @param x = a string vector
#' @keywords yyyymmdd.exists
#' @export
#' @family yyyymmdd

yyyymmdd.exists <- function (x) 
{
    is.element(day.to.weekday(x), 1:5)
}

#' yyyymmdd.lag
#' 
#' lags <x> by <y> weekdays
#' @param x = a YYYYMMDD vector
#' @param y = an integer vector
#' @keywords yyyymmdd.lag
#' @export
#' @family yyyymmdd

yyyymmdd.lag <- function (x, y) 
{
    obj.lag(x, y, yyyymmdd.to.int, yyyymmdd.ex.int)
}

#' yyyymmdd.seq
#' 
#' a sequence of weekdays starting at <x> and, if possible, ending at <y>
#' @param x = a YYYYMMDD
#' @param y = a YYYYMMDD
#' @param n = a positive integer
#' @keywords yyyymmdd.seq
#' @export
#' @family yyyymmdd

yyyymmdd.seq <- function (x, y, n = 1) 
{
    if (any(!yyyymmdd.exists(c(x, y)))) 
        stop("Inputs are not weekdays")
    z <- obj.seq(x, y, yyyymmdd.to.int, yyyymmdd.ex.int, n)
    z
}

#' yyyymmdd.to.AllocMo
#' 
#' Returns the month for which you need to get allocations Flows as of the 23rd of each month are known by the 24th. By this time allocations from #		:	the previous month are known
#' @param x = a YYYYMMDD vector
#' @param y = calendar day allocations are known the next month
#' @keywords yyyymmdd.to.AllocMo
#' @export
#' @family yyyymmdd

yyyymmdd.to.AllocMo <- function (x, y = 23) 
{
    n <- as.numeric(txt.right(x, 2))
    n <- ifelse(n < y, 2, 1)
    z <- yyyymm.lag(yyyymmdd.to.yyyymm(x), n)
    z
}

#' yyyymmdd.to.AllocMo.unique
#' 
#' Checks each day in <x> has same allocation month. Error otherwise
#' @param x = a YYYYMMDD vector
#' @param y = calendar day allocations are known the next month
#' @param n = a boolean (do/don't convert to month end)
#' @keywords yyyymmdd.to.AllocMo.unique
#' @export
#' @family yyyymmdd

yyyymmdd.to.AllocMo.unique <- function (x, y, n) 
{
    z <- yyyymmdd.to.AllocMo(x, y)
    if (all(z == z[1])) 
        z <- z[1]
    else stop("Bad Allocation Month")
    if (n) 
        z <- yyyymm.to.day(z)
    z
}

#' yyyymmdd.to.int
#' 
#' number of weekdays after Thursday, January 1, 1970
#' @param x = a YYYYMMDD vector
#' @keywords yyyymmdd.to.int
#' @export
#' @family yyyymmdd

yyyymmdd.to.int <- function (x) 
{
    z <- day.to.int(x) + 3
    z <- z - 2 * (z%/%7) - 3
    z
}

#' yyyymmdd.to.txt
#' 
#' Engineering date format
#' @param x = a YYYYMMDD vector
#' @keywords yyyymmdd.to.txt
#' @export
#' @family yyyymmdd

yyyymmdd.to.txt <- function (x) 
{
    paste(format(day.to.date(x), "%m/%d/%Y"), "12:00:00 AM")
}

#' yyyymmdd.to.weekofmonth
#' 
#' returns 1 if the date fell in the first week of the month, 2 if it fell in the second, etc.
#' @param x = a YYYYMMDD vector
#' @keywords yyyymmdd.to.weekofmonth
#' @export
#' @family yyyymmdd

yyyymmdd.to.weekofmonth <- function (x) 
{
    1 + (as.numeric(txt.right(x, 2)) - 1)%/%7
}

#' yyyymmdd.to.yyyymm
#' 
#' Converts to yyyymm format
#' @param x = a YYYYMMDD vector
#' @param y = if T then falls back one month
#' @keywords yyyymmdd.to.yyyymm
#' @export
#' @family yyyymmdd

yyyymmdd.to.yyyymm <- function (x, y = F) 
{
    z <- substring(x, 1, 6)
    if (y) 
        z <- yyyymm.lag(z, 1)
    z
}

#' zav
#' 
#' Coverts NA's to <y>
#' @param x = a numeric vector/matrix/data frame
#' @param y = a string (value for NA's)
#' @keywords zav
#' @export

zav <- function (x, y = 0) 
{
    fcn <- function(z, l) ifelse(is.na(z), l, z)
    z <- fcn.mat.vec(fcn, x, y, T)
    z
}

#' zScore
#' 
#' zScores the rows of <x>
#' @param x = a matrix/data frame
#' @keywords zScore
#' @export

zScore <- function (x) 
{
    t(scale(t(x)))
}

#' zScore.underlying
#' 
#' zScores the first columns of <x> using the last column as weight
#' @param x = a matrix/data frame (last column is boolean without NA's)
#' @keywords zScore.underlying
#' @export

zScore.underlying <- function (x) 
{
    m <- dim(x)[1]
    n <- dim(x)[2]
    y <- x[, n]
    x <- x[, -n]
    if (sum(y) > 1 & n == 2) {
        mx <- mean(x[y], na.rm = T)
        sx <- nonneg(sd(x[y], na.rm = T))
        z <- (x - mx)/sx
    }
    else if (n == 2) {
        z <- rep(NA, length(x))
    }
    else if (sum(y) > 1) {
        mx <- colMeans(x[y, ], na.rm = T)
        sx <- apply(x[y, ], 2, sd, na.rm = T)
        z <- t(x)
        z <- (z - mx)/nonneg(sx)
        z <- mat.ex.matrix(t(z))
    }
    else {
        z <- matrix(NA, m, n - 1, F, dimnames(x))
        z <- mat.ex.matrix(z)
    }
    z
}
