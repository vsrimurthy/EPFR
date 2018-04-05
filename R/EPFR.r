
#' mat.read
#' 
#' reads the file into data frame
#' @param x = a path to a text file
#' @param y = the separator
#' @param n = the column containing the row names (or NULL if none)
#' @param w = T/F variable depending on whether <x> has a header
#' @keywords mat.read
#' @export
#' @family mat
#' @import utils

mat.read <- function (x = "C:\\temp\\write.csv", y = ",", n = 1, w = T) 
{
    if (!file.exists(x)) 
        stop("File ", x, " doesn't exist!\n")
    z <- read.table(x, w, y, row.names = n, quote = "", as.is = T, 
        na.strings = txt.na(), comment.char = "", check.names = F)
    z
}

#' ret.outliers
#' 
#' Sets big ones to NA (a way to control for splits)
#' @param x = a vector of returns
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

#' mk.1mPerfTrend
#' 
#' Returns a variable with the same row space as <n>
#' @param x = a single YYYYMM
#' @param y = variable to build
#' @param n = list object containing the following items: a) classif - classif file b) conn - a connection, the output of odbcDriverConnect c) uiconn - a connection to EPFRUI, the output of odbcDriverConnect d) DB - any of StockFlows/Japan/CSI300/Energy
#' @keywords mk.1mPerfTrend
#' @export
#' @family mk
#' @import RODBC

mk.1mPerfTrend <- function (x, y, n) 
{
    vbls <- paste("Perf", txt.expand(c("", "ActWt"), c("Trend", 
        "Diff", "Diff2"), ""), sep = "")
    if (length(y) != 1) 
        stop("Bad Argument Count")
    if (!is.element(y, vbls)) 
        stop("<y> must be one of", paste(vbls, collapse = "\\"))
    x <- yyyymm.lag(x, 1)
    ui <- "HFundId, FundRet = sum(PortfolioChange)/sum(AssetsStart)"
    ui <- sql.tbl(ui, "MonthlyData", "MonthEnding = @newDt", 
        "HFundId", "sum(AssetsStart) > 0")
    ui <- sql.tbl("t1.HFundId, GeographicFocus, FundRet", c(sql.label(ui, 
        "t1"), "inner join", "FundHistory t2", "\ton t2.HFundId = t1.HFundId"))
    ui <- paste(c(sql.declare("@newDt", "datetime", yyyymm.to.day(x)), 
        sql.unbracket(ui)), collapse = "\n")
    ui <- sqlQuery(n$uiconn, ui)
    ui[, "FundRet"] <- ui[, "FundRet"] - map.rname(pivot.1d(mean, 
        ui[, "GeographicFocus"], ui[, "FundRet"]), ui[, "GeographicFocus"])
    if (any(duplicated(ui[, "HFundId"]))) 
        stop("Problem")
    ui <- vec.named(ui[, "FundRet"], ui[, "HFundId"])
    if (is.element(y, paste("Perf", c("Trend", "Diff", "Diff2"), 
        sep = ""))) {
        sf <- c("SecurityId", "t.HFundId", "WtCol = n1.HoldingValue/AssetsEnd - o1.HoldingValue/AssetsStart")
        w <- sql.1mAllocMo.underlying("All", n$DB)
        sf <- sql.unbracket(sql.tbl(sf, w[["FROM"]], w[["WHERE"]]))
        sf <- c(sql.declare(c("@newDt", "@oldDt"), "datetime", 
            yyyymm.to.day(yyyymm.lag(x, 0:1))), sf)
    }
    else {
        sf <- c(sql.label(sql.MonthlyAssetsEnd("@newDt", ""), 
            "t"), "inner join", "FundHistory his", "\ton his.HFundId = t.HFundId")
        sf <- c(sf, "inner join", sql.label(sql.MonthlyAlloc("@newDt", 
            ""), "n1"), "\ton n1.HFundId = t.HFundId", "inner join")
        sf <- c(sf, "SecurityHistory id", "\ton id.HSecurityId = n1.HSecurityId")
        sf <- sql.tbl("SecurityId, t.HFundId, GeographicFocusId, WtCol = HoldingValue/AssetsEnd", 
            sf, sql.in("n1.HSecurityId", sql.RDSuniv(n$DB)))
        sf <- paste(c(sql.declare("@newDt", "datetime", yyyymm.to.day(x)), 
            sql.unbracket(sf)), collapse = "\n")
    }
    sf <- sqlQuery(n$conn, sf)
    sf <- sf[is.element(sf[, "HFundId"], names(ui)), ]
    if (is.element(y, paste("PerfActWt", c("Trend", "Diff", "Diff2"), 
        sep = ""))) {
        vec <- paste(sf[, "SecurityId"], sf[, "GeographicFocusId"])
        vec <- pivot.1d(mean, vec, sf[, "WtCol"])
        vec <- as.numeric(map.rname(vec, paste(sf[, "SecurityId"], 
            sf[, "GeographicFocusId"])))
        sf[, "WtCol"] <- sf[, "WtCol"] - vec
    }
    z <- as.numeric(ui[as.character(sf[, "HFundId"])])
    if (is.element(y, c("PerfDiff2", "PerfActWtDiff2"))) 
        z <- sign(z)
    if (is.element(y, c("PerfDiff", "PerfActWtDiff"))) 
        z <- z * sign(sf[, "WtCol"])
    else z <- z * sf[, "WtCol"]
    num <- pivot.1d(sum, sf[, "SecurityId"], z)
    den <- pivot.1d(sum, sf[, "SecurityId"], abs(z))
    z <- map.rname(den, dimnames(n$classif)[[1]])
    z <- nonneg(z)
    z <- map.rname(num, dimnames(n$classif)[[1]])/z
    z <- as.numeric(z)
    z
}

#' email
#' 
#' emails <x>
#' @param x = the email address of the recipient
#' @param y = subject of the email
#' @param n = text of the email
#' @param w = a vector of paths to attachement
#' @keywords email
#' @export
#' @import RDCOMClient

email <- function (x, y, n, w = "") 
{
    z <- COMCreate("Outlook.Application")
    z <- z$CreateItem(0)
    z[["To"]] <- x
    z[["subject"]] <- y
    z[["body"]] <- n
    for (j in w) if (file.exists(j)) 
        z[["Attachments"]]$Add(j)
    z$Send()
    invisible()
}

#' avg.model
#' 
#' constant-only (zero-variable) regression model
#' @param x = vector of results
#' @param y = lag length (to handle overlapping returns)     When using N-period returns, y is N - 1. So for     annual or qtrly periods of monthly data, y is 11 or 2.
#' @keywords avg.model
#' @export
#' @family avg
#' @import sandwich

avg.model <- function (x, y = 0) 
{
    x <- x[!is.na(x)]
    n <- length(x)
    x <- c(x, rep(1, n))
    x <- matrix(x, n, 2, F, list(1:n, c("y", "x")))
    x <- mat.ex.matrix(x)
    x <- lm(y ~ x, x)
    z <- summary(x)$coefficients
    z <- as.matrix(z)[1, ]
    if (y > 0) {
        z["Std. Error"] <- NeweyWest(x, lag = y)[1, 1]
        z["t value"] <- z["Estimate"]/z["Std. Error"]
        z["Pr(>|t|)"] <- NA
    }
    z
}

#' ascending
#' 
#' T/F depending on whether <x> is ascending
#' @param x = a vector
#' @keywords ascending
#' @export

ascending <- function (x) 
{
    if (any(is.na(x))) 
        stop("Problem")
    z <- x[order(x)]
    z <- all(z == x)
    z
}

#' avail
#' 
#' For each row, returns leftmost entry with data
#' @param x = a matrix/data-frame
#' @keywords avail
#' @export

avail <- function (x) 
{
    z <- rep(NA, dim(x)[1])
    for (i in 1:dim(x)[2]) z <- ifelse(is.na(z), x[, i], z)
    z
}

#' avg.winsorized
#' 
#' mean is computed over the quantiles 2 through <y> - 1
#' @param x = a numeric vector
#' @param y = number of quantiles
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
#' @param y = a numeric vector of weights
#' @keywords avg.wtd
#' @export
#' @family avg

avg.wtd <- function (x, y) 
{
    fcn <- function(x, y) sum(x * y)/nonneg(sum(y))
    z <- fcn.num.nonNA(fcn, x, y, F)
    z
}

#' base.ex.int
#' 
#' Expresses <x> in base <y>
#' @param x = a non-negative integer
#' @param y = a positive integer
#' @keywords base.ex.int
#' @export
#' @family base

base.ex.int <- function (x, y) 
{
    if (x == 0) 
        z <- 0
    else z <- NULL
    while (x > 0) {
        z <- c(x%%y, z)
        x <- (x - x%%y)/y
    }
    z
}

#' base.to.int
#' 
#' Evaluates the base <y> number <x>
#' @param x = a vector of positive integers
#' @param y = a positive integer
#' @keywords base.to.int
#' @export
#' @family base

base.to.int <- function (x, y) 
{
    m <- length(x)
    z <- x * y^(m:1 - 1)
    z <- sum(z)
    z
}

#' bbk
#' 
#' standard model output
#' @param x = predictor indexed by yyyymmdd or yyyymm
#' @param y = total return index indexed by the same date format as <x>
#' @param floW = number of <prd.size>'s over which the predictor should be compounded/summed
#' @param retW = return window in days or months depending on whether <x> is YYYYMMDD or YYYYMM
#' @param nBin = number of bins to divide the variable into
#' @param doW = day of the week you will trade on (5 = Fri)
#' @param sum.flows = T/F depending on whether <x> should be summed or compounded
#' @param lag = predictor lag in days or months depending on whether <x> is YYYYMMDD or YYYYMM
#' @param delay = delay in knowing data in days or months depending on whether <x> is YYYYMMDD or YYYYMM
#' @param idx = the index within which you are trading
#' @param prd.size = size of each period in days or months depending on whether <x> is YYYYMMDD or YYYYMM
#' @keywords bbk
#' @export
#' @family bbk

bbk <- function (x, y, floW = 20, retW = 5, nBin = 5, doW = 4, sum.flows = F, 
    lag = 0, delay = 2, idx = NULL, prd.size = 1) 
{
    x <- bbk.data(x, y, floW, sum.flows, lag, delay, doW, retW, 
        idx, prd.size)
    z <- bbk.bin.xRet(x$x, x$fwdRet, nBin, T, T)
    x <- z[["rets"]]
    z <- lapply(z, mat.reverse)
    quantum <- ifelse(is.null(doW), 1, 5)
    if (retW%%quantum != 0) 
        stop("Something's very wrong!")
    if (retW > quantum) {
        n <- retW/quantum
        y <- NULL
        for (offset in 1:n - 1) {
            w <- 1:dim(z$rets)[1]%%n == offset
            x <- bbk.summ(z$rets[w, ], z$bins[w, ], retW)[["summ"]]
            if (is.null(y)) 
                y <- array(NA, c(dim(x), n), list(dimnames(x)[[1]], 
                  dimnames(x)[[2]], 1:n - 1))
            y[, , as.character(offset)] <- unlist(x)
        }
        z[["summ"]] <- apply(y, 1:2, mean)
    }
    else {
        y <- bbk.summ(z$rets, z$bins, retW)
        for (i in names(y)) z[[i]] <- y[[i]]
    }
    z
}

#' bbk.bin.rets.geom.summ
#' 
#' Summarizes bin excess returns geometrically
#' @param x = a matrix/df with rows indexed by time and columns indexed by bins
#' @param y = number of rows of <x> needed to cover an entire calendar year
#' @keywords bbk.bin.rets.geom.summ
#' @export
#' @family bbk

bbk.bin.rets.geom.summ <- function (x, y) 
{
    if (any(dimnames(x)[[2]] == "uRet")) 
        uRet.vec <- x[, "uRet"]
    else uRet.vec <- rep(0, dim(x)[1])
    w <- !is.element(dimnames(x)[[2]], c("uRet", "TxB"))
    z <- list(por = x, bmk = x)
    for (i in dimnames(x)[[2]][w]) {
        z[["bmk"]][, i] <- ifelse(is.na(z[["por"]][, i]), NA, 
            uRet.vec)
        z[["por"]][, i] <- z[["por"]][, i] + uRet.vec
    }
    z <- lapply(z, ret.to.log)
    vec <- exp(apply(z[["bmk"]], 2, mean, na.rm = T) * y)
    vec <- ifelse(w, vec, 1)
    vec <- exp(apply(z[["por"]], 2, mean, na.rm = T) * y) - vec
    z <- matrix(NA, 4, dim(x)[2], F, list(c("AnnMn", "AnnSd", 
        "Sharpe", "HitRate"), dimnames(x)[[2]]))
    z["AnnMn", ] <- 100 * vec
    z["AnnSd", ] <- apply(x, 2, sd, na.rm = T) * sqrt(y)
    z["Sharpe", ] <- 100 * z["AnnMn", ]/z["AnnSd", ]
    z["HitRate", ] <- apply(sign(x), 2, mean, na.rm = T) * 50
    z
}

#' bbk.bin.rets.prd.summ
#' 
#' Summarizes bin excess returns by sub-periods of interest (as defined by <y>)
#' @param fcn = function you use to summarize results
#' @param x = a matrix/df with rows indexed by time and columns indexed by bins
#' @param y = a vector corresponding to the rows of <x> that maps each row to a sub-period of interest (e.g. calendar year)
#' @param n = number of rows of <x> needed to cover an entire calendar year
#' @keywords bbk.bin.rets.prd.summ
#' @export
#' @family bbk

bbk.bin.rets.prd.summ <- function (fcn, x, y, n) 
{
    w <- !is.na(y)
    y <- y[w]
    x <- x[w, ]
    z <- vec.count(y)
    z <- names(z)[z > 1]
    w <- fcn(x, n)
    z.dim <- c(dim(w)[1], 1 + dim(w)[2], length(z))
    z.nms <- dimnames(w)
    z.nms[[2]] <- c(z.nms[[2]], "nPrds")
    z.nms[[3]] <- z
    z <- array(NA, z.dim, z.nms)
    for (i in dimnames(z)[[3]]) {
        z[, dim(z)[2], i] <- sum(!is.na(x[is.element(y, i), 1]))
        z[, -dim(z)[2], i] <- fcn(x[is.element(y, i), ], n)
    }
    z
}

#' bbk.bin.rets.summ
#' 
#' Summarizes bin excess returns arithmetically
#' @param x = a matrix/df with rows indexed by time and columns indexed by bins
#' @param y = number of rows of <x> needed to cover an entire calendar year
#' @keywords bbk.bin.rets.summ
#' @export
#' @family bbk

bbk.bin.rets.summ <- function (x, y) 
{
    z <- c("AnnMn", "AnnSd", "Sharpe", "HitRate", "Beta", "Alpha", 
        "DrawDn", "DDnBeg", "DDnN")
    z <- matrix(NA, length(z), dim(x)[2], F, list(z, dimnames(x)[[2]]))
    z["AnnMn", ] <- apply(x, 2, mean, na.rm = T) * y
    z["AnnSd", ] <- apply(x, 2, sd, na.rm = T) * sqrt(y)
    z["Sharpe", ] <- 100 * z["AnnMn", ]/z["AnnSd", ]
    z["HitRate", ] <- apply(sign(x), 2, mean, na.rm = T) * 50
    w <- dimnames(x)[[2]] == "uRet"
    if (any(w)) {
        z[c("Alpha", "Beta"), "uRet"] <- 0:1
        for (i in dimnames(x)[[2]][!w]) {
            if (sum(!is.na(x[, i]) & !is.na(x[, "uRet"])) > 2) {
                z[c("Alpha", "Beta"), i] <- summary(lm(txt.regr(c(i, 
                  "uRet")), x, na.action = na.omit))$coeff[, 
                  1] * c(y, 1)
            }
        }
    }
    x <- x[order(dimnames(x)[[1]]), ]
    for (i in dimnames(x)[[2]]) {
        w <- bbk.drawdown(x[, i])
        z["DDnN", i] <- sum(w)
        z["DDnBeg", i] <- as.numeric(dimnames(x)[[1]][w & !duplicated(w)])
        z["DrawDn", i] <- sum(x[w, i])
    }
    z
}

#' bbk.bin.xRet
#' 
#' Returns equal weight bin returns through time
#' @param x = a matrix/df of predictors, the rows of which are indexed by time
#' @param y = a matrix/df of the same dimensions as <x> containing associated forward returns
#' @param n = number of desired bins
#' @param w = T/F depending on whether universe return is desired
#' @param h = T/F depending on whether full detail or bin returns are needed
#' @keywords bbk.bin.xRet
#' @export
#' @family bbk

bbk.bin.xRet <- function (x, y, n = 5, w = F, h = F) 
{
    if (h) 
        rslt <- list(raw.fwd.rets = y, raw = x)
    x <- bbk.holidays(x, y)
    x <- qtl.eq(x, n)
    if (h) 
        rslt[["bins"]] <- x
    uRetVec <- rowMeans(y, na.rm = T)
    y <- y - uRetVec
    z <- vec.unique(x)
    z <- matrix(NA, dim(x)[1], length(z), F, dimnames = list(dimnames(x)[[1]], 
        z))
    for (i in dimnames(z)[[1]]) {
        for (j in dimnames(z)[[2]]) {
            w.j <- is.element(x[i, ], j)
            if (any(w.j)) 
                z[i, j] <- mean(unlist(y[i, w.j]))
        }
    }
    dimnames(z)[[2]] <- paste("Q", dimnames(z)[[2]], sep = "")
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
#' @param x = predictor indexed by yyyymmdd or yyyymm
#' @param y = total return index indexed by the same date format as <x>
#' @param floW = number of <prd.size>'s over which the predictor should be compounded/summed
#' @param sum.flows = T/F depending on whether <x> should be summed or compounded
#' @param lag = predictor lag in days or months depending on whether <x> is YYYYMMDD or YYYYMM
#' @param delay = delay in knowing data in days or months depending on whether <x> is YYYYMMDD or YYYYMM
#' @param doW = day of the week you will trade on (5 = Fri)
#' @param retW = return window in days or months depending on whether <x> is YYYYMMDD or YYYYMM
#' @param idx = the index within which you are trading
#' @param prd.size = size of each period in days or months depending on whether <x> is YYYYMMDD or YYYYMM
#' @keywords bbk.data
#' @export
#' @family bbk

bbk.data <- function (x, y, floW, sum.flows, lag, delay, doW, retW, idx, 
    prd.size) 
{
    if (!ascending(dimnames(x)[[1]])) 
        stop("Flows are fucked")
    if (!ascending(dimnames(y)[[1]])) 
        stop("Returns are fucked")
    x <- compound.flows(x, floW, prd.size, sum.flows)
    x <- mat.lag(x, lag + delay, F)
    if (!is.null(doW)) {
        col <- dimnames(x)[[2]][order(-colSums(mat.to.obs(x)))][1]
        x <- bbk.doW.bulk(x, doW, col)
    }
    if (!is.null(doW)) {
        w <- !is.na(x[, col]) & is.element(day.to.weekday(dimnames(x)[[1]]), 
            doW)
        x <- x[w, ]
    }
    if (!is.null(doW)) {
        col <- dimnames(y)[[2]][order(-colSums(mat.to.obs(y)))][1]
        y <- bbk.doW.bulk(y, doW, col)
    }
    fwdRet <- bbk.fwdRet(x, y, retW, 0, 0)
    if (!is.null(idx)) 
        fwdRet <- Ctry.msci.index.changes(fwdRet, idx)
    z <- list(x = x, fwdRet = fwdRet)
    z
}

#' bbk.doW.bulk
#' 
#' Adds rows to <x> so that day <y> of the week is never missing
#' @param x = a matrix/data-frame indexed by <yyyymmdd> dates
#' @param y = a day of the week from 0:6 (Sun:Sat)
#' @param n = an essential column that cannot be NA
#' @keywords bbk.doW.bulk
#' @export
#' @family bbk

bbk.doW.bulk <- function (x, y, n) 
{
    w <- !is.na(x[, n]) & is.element(day.to.weekday(dimnames(x)[[1]]), 
        y)
    dts <- yyyymmdd.seq(dimnames(x)[[1]][w][1], dimnames(x)[[1]][w][sum(w)], 
        5)
    w <- is.na(map.rname(x, dts)[, n])
    z <- x
    if (any(w)) {
        vec <- rep(NA, sum(w))
        names(vec) <- dts[w]
        for (i in names(vec)) {
            w2 <- yyyymmdd.lag(i, 0:10)
            w2 <- map.rname(z, w2)[, n]
            w2 <- !is.na(w2)
            w2 <- w2 & !duplicated(w2)
            if (any(w2)) {
                vec[i] <- yyyymmdd.lag(i, 0:10)[w2]
            }
            else {
                w2 <- !is.na(z[, n])
                w2 <- dimnames(z)[[1]][w2]
                w2 <- w2[w2 < i]
                vec[i] <- max(w2)
            }
        }
        z <- map.rname(z, union(dimnames(z)[[1]], names(vec)))
        z[names(vec), ] <- unlist(map.rname(z, vec))
        z <- z[order(dimnames(z)[[1]]), ]
    }
    z
}

#' bbk.drawdown
#' 
#' returns a logical vector identifying the contiguous periods corresponding to max drawdown
#' @param x = a numeric vector
#' @keywords bbk.drawdown
#' @export
#' @family bbk

bbk.drawdown <- function (x) 
{
    n <- length(x)
    x <- zav(x)
    z <- matrix(NA, n, n, F)
    z[, 1] <- x
    for (i in 2:n) z[, i] <- c(z[-1, i - 1], NA)
    for (i in 2:n) z[, i] <- z[, i] + z[, i - 1]
    prd.num <- order(apply(z, 2, min, na.rm = T))[1]
    prd.beg <- order(z[, prd.num])[1]
    z <- seq(prd.beg, length.out = prd.num)
    z <- is.element(1:n, z)
    z
}

#' bbk.fwdRet
#' 
#' returns a matrix/data frame of the same dimensions as <x>
#' @param x = a matrix/data frame of predictors
#' @param y = a matrix/data frame of total return indices
#' @param n = the number of days in the return window
#' @param w = the number of days the predictors are lagged
#' @param h = the number of days needed for the predictors to be known
#' @keywords bbk.fwdRet
#' @export
#' @family bbk

bbk.fwdRet <- function (x, y, n, w, h) 
{
    if (dim(x)[2] != dim(y)[2]) 
        stop("Problem 1")
    if (any(dimnames(x)[[2]] != dimnames(y)[[2]])) 
        stop("Problem 2")
    y <- ret.ex.idx(y, n, F, T)
    y <- mat.lag(y, -h - w, F, F)
    z <- map.rname(y, dimnames(x)[[1]])
    z <- excise.zeroes(z)
    z
}

#' bbk.holidays
#' 
#' Sets <x> to NA whenever <y> is NA
#' @param x = a matrix/df of predictors, the rows of which are indexed by time
#' @param y = a matrix/df of the same dimensions as <x> containing associated forward returns
#' @keywords bbk.holidays
#' @export
#' @family bbk

bbk.holidays <- function (x, y) 
{
    fcn <- function(x, y) ifelse(is.na(y), NA, x)
    z <- fcn.matrix(fcn, x, y)
    z
}

#' bbk.summ
#' 
#' summarizes by year and overall. Assumes periods are non-overlapping.
#' @param x = bin returns
#' @param y = bin memberships
#' @param n = return window in days or months depending on whether <x> is YYYYMMDD or YYYYMM
#' @keywords bbk.summ
#' @export
#' @family bbk

bbk.summ <- function (x, y, n) 
{
    prdsPerYr <- ifelse(all(nchar(dimnames(x)[[1]]) == 6), 12, 
        260)
    z <- bbk.bin.rets.summ(x, prdsPerYr/n)
    y <- bbk.turnover(y)
    names(y) <- paste("Q", names(y), sep = "")
    y["TxB"] <- y["Q1"] + y["Q5"]
    y["uRet"] <- 0
    y <- y * prdsPerYr/n
    y <- map.rname(y, dimnames(z)[[2]])
    y <- matrix(y, 1, dim(z)[2], T, list("AnnTo", dimnames(z)[[2]]))
    z <- rbind(z, y)
    z <- mat.ex.matrix(z)
    z.ann <- dimnames(x)[[1]]
    z.ann <- yyyymm.lag(z.ann, -n)
    z.ann <- txt.left(z.ann, 4)
    z.ann <- t(bbk.bin.rets.prd.summ(bbk.bin.rets.summ, x, z.ann, 
        prdsPerYr/n)["AnnMn", , ])
    z <- list(summ = z, annSumm = z.ann)
    z
}

#' bbk.turnover
#' 
#' returns average name turnover per bin
#' @param x = a matrix/df of positive integers
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
    z
}

#' best.linear.strategy.blend
#' 
#' Returns optimal weights to put on <x> and <y>
#' @param x = a return stream from a strategy
#' @param y = an isomekic return stream from a strategy
#' @keywords best.linear.strategy.blend
#' @export

best.linear.strategy.blend <- function (x, y) 
{
    w <- !is.na(x) & !is.na(y)
    x <- x[w]
    y <- y[w]
    mx <- mean(x)
    my <- mean(y)
    sx <- sd(x)
    sy <- sd(y)
    gm <- correl(x, y)
    V <- c(sx^2, rep(sx * sy * gm, 2), sy^2)
    V <- matrix(V, 2, 2)
    V <- solve(V)
    z <- V %*% c(mx, my)
    z <- renorm(z[, 1])
    z
}

#' binomial.trial
#' 
#' returns the likelihood of getting <n> or more/fewer heads depending on whether <w> is T/F
#' @param x = probability of success in a 1/0 Bernoulli trial
#' @param y = number of coin flips
#' @param n = number of heads
#' @param w = T/F variable depending on which tail you want
#' @keywords binomial.trial
#' @export

binomial.trial <- function (x, y, n, w) 
{
    if (w) 
        pbinom(y - n, y, 1 - x)
    else pbinom(n, y, x)
}

#' britten.jones
#' 
#' transforms the design matrix as set out in Britten-Jones, M., Neuberger  , A., & Nolte, I. (2011). Improved inference in regression with overlapping  observations. Journal of Business Finance & Accounting, 38(5-6), 657-683.
#' @param x = design matrix of a regression with 1st column assumed to be dependent
#' @param y = constitutent lagged returns that go into the first period
#' @keywords britten.jones
#' @export
#' @family britten

britten.jones <- function (x, y) 
{
    m <- length(y)
    n <- dim(x)[1]
    orig.nms <- dimnames(x)[[2]]
    for (i in 1:n) y <- c(y, x[i, 1] - sum(y[i - 1 + 1:m]))
    x <- as.matrix(x[, -1])
    z <- matrix(0, n + m, dim(x)[2], F, list(seq(1, m + n), dimnames(x)[[2]]))
    for (i in 0:m) z[1:n + i, ] <- z[1:n + i, ] + x
    if (det(t(z) %*% z) > 0) {
        z <- z %*% solve(t(z) %*% z) %*% t(x) %*% x
        z <- data.frame(y, z)
        names(z) <- orig.nms
    }
    else z <- NULL
    z
}

#' britten.jones.data
#' 
#' returns data needed for a Britten-Jones analysis
#' @param x = a data frame of predictors
#' @param y = total return index of the same size as <x>
#' @param n = number of periods of forward returns used
#' @param w = the index within which you are trading
#' @keywords britten.jones.data
#' @export
#' @family britten

britten.jones.data <- function (x, y, n, w = NULL) 
{
    if (any(dim(x) != dim(y))) 
        stop("x/y are mismatched!")
    prd.ret <- 100 * mat.lag(y, -1, T, T)/nonneg(y) - 100
    prd.ret <- list(prd1 = prd.ret)
    if (n > 1) 
        for (i in 2:n) prd.ret[[paste("prd", i, sep = "")]] <- mat.lag(prd.ret[["prd1"]], 
            1 - i, T, T)
    y <- ret.ex.idx(y, n, T, T)
    vec <- as.numeric(unlist(y))
    w1 <- !is.na(vec) & abs(vec) < 1e-06
    if (any(w1)) {
        for (i in names(prd.ret)) {
            w2 <- as.numeric(unlist(prd.ret[[i]]))
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
        vec <- as.numeric(unlist(prd.ret[[i]]))
        vec <- ifelse(w1, vec, NA)
        prd.ret[[i]] <- matrix(vec, dim(y)[1], dim(y)[2], F, 
            dimnames(y))
    }
    fcn <- function(x) x - rowMeans(x, na.rm = T)
    y <- fcn(y)
    prd.ret <- lapply(prd.ret, fcn)
    z <- NULL
    for (i in dimnames(x$bins)[[2]]) {
        if (sum(!is.na(x$bins[, i]) & !duplicated(x$bins[, i])) > 
            1) {
            df <- as.numeric(x$bins[, i])
            w1 <- !is.na(df)
            n.beg <- find.data(w1, T)
            n.end <- find.data(w1, F)
            if (n > 1 & n.end - n.beg + 1 > sum(w1)) {
                vec <- find.gaps(w1)
                if (any(vec < n - 1)) {
                  vec <- vec[vec < n - 1]
                  for (j in names(vec)) df[as.numeric(j) + 1:as.numeric(vec[j]) - 
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
                z <- britten.jones.data.stack(z, df[n.beg:n.end, 
                  ], n, prd.ret, n.beg, i)
            }
            else {
                vec <- find.gaps(w1)
                if (any(vec < n - 1)) 
                  stop("Small return gap detected: i = ", i, 
                    ", retHz =", n, "...\n")
                if (any(vec >= n - 1)) {
                  vec <- vec[vec >= n - 1]
                  n.beg <- c(n.beg, as.numeric(names(vec)) + 
                    as.numeric(vec))
                  n.end <- c(as.numeric(names(vec)) - 1, n.end)
                  for (j in 1:length(n.beg)) z <- britten.jones.data.stack(z, 
                    df[n.beg[j]:n.end[j], ], n, prd.ret, n.beg[j], 
                    i)
                }
            }
        }
    }
    z
}

#' britten.jones.data.stack
#' 
#' applies the Britten-Jones transformation to a subset and then stacks
#' @param rslt =
#' @param df =
#' @param retHz =
#' @param prd.ret =
#' @param n.beg =
#' @param entity =
#' @keywords britten.jones.data.stack
#' @export
#' @family britten

britten.jones.data.stack <- function (rslt, df, retHz, prd.ret, n.beg, entity) 
{
    w <- colSums(df[, -1] == 0) == dim(df)[1]
    if (any(w)) {
        w <- !is.element(dimnames(df)[[2]], dimnames(df)[[2]][-1][w])
        df <- df[, w]
    }
    if (retHz > 1) {
        vec <- NULL
        for (j in names(prd.ret)[-retHz]) vec <- c(vec, prd.ret[[j]][n.beg, 
            entity])
        n <- dim(df)[1]
        df <- britten.jones(df, vec)
        if (is.null(df)) 
            cat("Discarding", n, "observations for", entity, 
                "due to Britten-Jones singularity ...\n")
    }
    if (!is.null(df)) 
        df <- mat.ex.matrix(zav(t(map.rname(t(df), c("ActRet", 
            paste("Q", 2:4, sep = ""), "TxB")))))
    if (!is.null(df)) {
        if (is.null(z)) {
            dimnames(df)[[1]] <- 1:dim(df)[1]
            z <- df
        }
        else {
            dimnames(df)[[1]] <- 1:dim(df)[1] + dim(z)[1]
            z <- rbind(z, df)
        }
    }
    z
}

#' char.ex.int
#' 
#' the characters whose ascii values correspond to <x>
#' @param x = a string of integers
#' @keywords char.ex.int
#' @export
#' @family char

char.ex.int <- function (x) 
{
    z <- rawToChar(as.raw(x))
    z <- strsplit(z, "")[[1]]
    z
}

#' char.seq
#' 
#' returns a sequence of ASCII characters between (and including) x and y
#' @param x = a SINGLE character
#' @param y = a SINGLE character
#' @param n = quantum size
#' @keywords char.seq
#' @export
#' @family char

char.seq <- function (x, y, n = 1) 
{
    obj.seq(x, y, char.to.int, char.ex.int, n)
}

#' char.to.int
#' 
#' ascii values
#' @param x = a string of single characters
#' @keywords char.to.int
#' @export
#' @family char

char.to.int <- function (x) 
{
    z <- paste(x, collapse = "")
    z <- strtoi(charToRaw(z), 16L)
    z
}

#' char.to.num
#' 
#' coerces to numeric much more brutally than does as.numeric
#' @param x = a vector of strings
#' @keywords char.to.num
#' @export
#' @family char

char.to.num <- function (x) 
{
    z <- txt.replace(x, "\"", "")
    z <- txt.replace(z, ",", "")
    z <- as.numeric(z)
    z
}

#' col.ex.int
#' 
#' Returns the relevant excel column (1 = "A", 2 = "B", etc.)
#' @param x = a positive integer
#' @keywords col.ex.int
#' @export
#' @family col

col.ex.int <- function (x) 
{
    z <- x - 1
    z <- base.ex.int(z, 26)
    z[length(z)] <- z[length(z)] + 1
    z <- char.ex.int(z + 64)
    z <- paste(z, collapse = "")
    z
}

#' col.offset
#' 
#' Offsets <x> by <y> columns
#' @param x = string representation of an excel column
#' @param y = an integer representing the desired column offset
#' @keywords col.offset
#' @export
#' @family col

col.offset <- function (x, y) 
{
    obj.lag(x, -y, col.to.int, col.ex.int)
}

#' col.smallest
#' 
#' returns the column name of the smallest non-NA column for each row
#' @param x = a numeric matrix
#' @keywords col.smallest
#' @export
#' @family col

col.smallest <- function (x) 
{
    n <- x[, 1]
    z <- ifelse(!is.na(n), dimnames(x)[[2]][1], "")
    for (i in dimnames(x)[[2]][-1]) {
        w <- !is.na(x[, i])
        w2 <- is.na(n)
        z <- ifelse(w & w2, i, z)
        n <- ifelse(w & w2, x[, i], n)
        z <- ifelse(w & !w2 & n > x[, i], i, z)
        n <- ifelse(w & !w2 & n > x[, i], x[, i], n)
    }
    z <- list(z = as.character(z), n = as.numeric(n))
    z
}

#' col.to.int
#' 
#' Returns the relevant associated integer (1 = "A", 2 = "B", etc.)
#' @param x = a SINGLE string representation of an excel column
#' @keywords col.to.int
#' @export
#' @family col

col.to.int <- function (x) 
{
    z <- txt.to.char(x)
    z <- char.to.int(z) - char.to.int("A") + 1
    z <- base.to.int(z, 26)
    z
}

#' combinations
#' 
#' returns all possible combinations of <y> values of <x>
#' @param x = a vector
#' @param y = an integer between 1 and <length(x)>
#' @keywords combinations
#' @export

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

#' combinations.next
#' 
#' returns the next combination in dictionary order
#' @param x = a logical vector
#' @keywords combinations.next
#' @export

combinations.next <- function (x) 
{
    m <- length(x)
    n <- (m:1)[!x[m:1] & !duplicated(!x[m:1])]
    w <- x[n:1] & !duplicated(x[n:1])
    if (any(w)) {
        n <- (n:1)[w]
        nT <- sum(x) - sum(x[1:n])
        x[n:m] <- F
        x[n + 1 + 0:nT] <- T
        z <- x
    }
    else {
        z <- rep(F, length(x))
    }
    z
}

#' compound
#' 
#' Outputs the compounded return
#' @param x = a vector of percentage returns
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
#' @param x = a matrix/data-frame of percentage flows
#' @param y = flow window in terms of the number of trailing periods to compound
#' @param n = size of each period in terms of days if the rows of <x> are yyyymmdd or months otherwise
#' @param w = if T, flows get summed. Otherwise they get compounded.
#' @keywords compound.flows
#' @export
#' @family compound

compound.flows <- function (x, y, n, w = F) 
{
    if (w) 
        fcn <- sum
    else fcn <- compound
    fcn2 <- function(x) if (is.na(x[1])) 
        NA
    else fcn(zav(x))
    z <- compound.flows.underlying(fcn2, x, y, F, n)
    z[compound.flows.initial(x, (y - 1) * n), ] <- NA
    z
}

#' compound.flows.initial
#' 
#' T/F depending on whether output for a row is to be set to NA
#' @param x = a matrix/data-frame of percentage flows
#' @param y = an integer representing the size of the window needed
#' @keywords compound.flows.initial
#' @export
#' @family compound

compound.flows.initial <- function (x, y) 
{
    z <- mat.to.first.data.row(x)
    z <- dimnames(x)[[1]][z]
    z <- yyyymm.lag(z, -y)
    z <- dimnames(x)[[1]] < z
    z
}

#' compound.flows.underlying
#' 
#' compounded flows over <y> trailing periods indexed by last day in the flow window
#' @param fcn = function used to compound flows
#' @param x = a matrix/data-frame of percentage flows
#' @param y = flow window in terms of the number of trailing periods to compound
#' @param n = if T simple positional lagging is used. If F, yyyymm.lag is invoked
#' @param w = size of each period in terms of days if the rows of <x> are yyyymmdd or months otherwise
#' @keywords compound.flows.underlying
#' @export
#' @family compound

compound.flows.underlying <- function (fcn, x, y, n, w) 
{
    if (y > 1) {
        z <- mat.to.lags(x, y, n, w)
        z <- apply(z, 1:2, fcn)
    }
    else {
        z <- x
    }
    z
}

#' compound.stock.flows
#' 
#' compounds flows
#' @param x = a matrix/data-frame of percentage flows
#' @param y = if T, flows get summed. Otherwise they get compounded.
#' @keywords compound.stock.flows
#' @export
#' @family compound

compound.stock.flows <- function (x, y) 
{
    if (y) 
        fcn <- sum
    else fcn <- compound
    w <- rowSums(mat.to.obs(x)) > dim(x)[2]/2
    x <- zav(x)
    z <- rep(NA, dim(x)[1])
    if (any(w)) 
        z[w] <- fcn.mat.num(fcn, x[w, ], , F)
    z
}

#' correl
#' 
#' the estimated correlation between <x> and <y> or the columns of <x>
#' @param x = a numeric vector/matrix/data frame
#' @param y = either missing or a numeric isomekic vector
#' @param n = T/F depending on whether rank correlations are desired
#' @keywords correl
#' @export

correl <- function (x, y, n = T) 
{
    if (missing(y)) 
        fcn.mat.col(cor, x, , n)
    else fcn.mat.col(cor, x, y, n)
}

#' correl.PrcMo
#' 
#' returns correlation of <n> day flows with price momentum (175d lag 10)
#' @param x = one-day flow percentage
#' @param y = total return index
#' @param n = flow window
#' @param w = the number of days needed for the flow data to be known
#' @keywords correl.PrcMo
#' @export

correl.PrcMo <- function (x, y, n, w) 
{
    x <- compound.flows(x, n, 1, F)
    dimnames(x)[[1]] <- yyyymmdd.lag(dimnames(x)[[1]], -w)
    z <- map.rname(y, yyyymmdd.lag(dimnames(y)[[1]], 175))
    z <- nonneg(z)
    y <- as.matrix(y)/z
    dimnames(y)[[1]] <- yyyymmdd.lag(dimnames(y)[[1]], -10)
    x <- qtl.eq(x, 5)
    y <- qtl.eq(y, 5)
    x <- x[is.element(dimnames(x)[[1]], dimnames(y)[[1]]), ]
    y <- y[dimnames(x)[[1]], ]
    z <- correl(unlist(x), unlist(y), F)
    z
}

#' covar
#' 
#' the estimated covariance between <x> and <y> or the columns of <x>
#' @param x = a numeric vector
#' @param y = a numeric isomekic vector
#' @param n = T/F depending on whether rank correlations are desired
#' @keywords covar
#' @export

covar <- function (x, y, n = F) 
{
    if (missing(y)) 
        fcn.mat.col(cov, x, , n)
    else fcn.mat.col(cov, x, y, n)
}

#' cpt.FloAlphaLt.Ctry
#' 
#' Computes flow alpha for countries. indexed by data date. Does not account for delay.
#' @param x = factor folder
#' @keywords cpt.FloAlphaLt.Ctry
#' @export
#' @family cpt

cpt.FloAlphaLt.Ctry <- function (x) 
{
    wts <- vec.named(c(30, 20, 15, 5, 5, 5, 20), c("FloMo", "ActWtDiff2", 
        "FloTrend", "FloDiff", "FloDiff2", "AllocMo", "ManagerTrend"))
    dy.vbls <- vec.named(c(30, 55, 55, 55, 15), c("FloMo", "ActWtDiff2", 
        "FloTrend", "FloDiff", "FloDiff2"))
    mo.vbls <- vec.named(c(11, 3, 11), c("AllocMo", "AllocTrend", 
        "ManagerTrend"))
    dy.vbls <- dy.vbls[is.element(names(dy.vbls), names(wts))]
    mo.vbls <- mo.vbls[is.element(names(mo.vbls), names(wts))]
    y <- list()
    for (i in names(dy.vbls)) {
        path <- paste(x, "\\", i, "\\Ctry\\csv\\oneDay", i, ".csv", 
            sep = "")
        y[[i]] <- mat.read(path)
    }
    for (i in names(mo.vbls)) {
        path <- paste(x, "\\", i, "\\Ctry\\csv\\oneMo", i, ".csv", 
            sep = "")
        y[[i]] <- mat.read(path)
    }
    y <- lapply(x, mat.subset, dimnames(y[[1]])[[2]])
    for (i in names(dy.vbls)) y[[i]] <- compound.flows(y[[i]], 
        dy.vbls[i], 1, i != "FloMo")
    for (i in names(mo.vbls)) y[[i]] <- compound.flows(y[[i]], 
        mo.vbls[i], 1, T)
    for (i in names(mo.vbls)) y[[i]] <- yyyymmdd.ex.AllocMo(y[[i]])
    rnames <- dimnames(y[[1]])[[1]]
    for (i in names(y)) rnames <- intersect(rnames, dimnames(y[[i]])[[1]])
    rnames <- rnames[order(rnames)]
    y <- lapply(y, map.rname, rnames)
    y <- lapply(y, zScore)
    z <- matrix(0, dim(y[[1]])[1], dim(y[[1]])[2], F, dimnames(y[[1]]))
    for (i in names(wts)) z <- z + wts[i] * zav(y[[i]])/100
    z
}

#' cpt.RgnSec
#' 
#' makes Region-Sector groupings
#' @param x = a vector of Sectors
#' @param y = a vector of country codes
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
    z <- as.numeric(z)
    z
}

#' cptRollingAverageWeights
#' 
#' Returns weights on individual weeks with the most recent week being to the RIGHT
#' @param x = number of trailing weeks to use
#' @param y = weight on the earliest as a percentage of weight on latest week
#' @param n = number of additional weeks to lag data
#' @keywords cptRollingAverageWeights
#' @export

cptRollingAverageWeights <- function (x = 4, y = 100, n = 0) 
{
    z <- x - 1
    z <- (y/100)^(1/z)
    z <- (z^(x:1 - 1))
    z <- z/sum(z)
    z <- c(z, rep(0, n))
    z
}

#' Ctry.info
#' 
#' handles the addition and removal of countries from an index
#' @param x = a vector of country codes
#' @param y = a column in the classif-ctry file
#' @keywords Ctry.info
#' @export
#' @family Ctry
#' @examples
#' Ctry.info("PK", "CtryNm")

Ctry.info <- function (x, y) 
{
    z <- mat.read(parameters("classif-ctry"))
    z <- map.rname(z, x)[, y]
    z
}

#' Ctry.msci
#' 
#' Countries added or removed from the index in ascending order
#' @param x = an index name such as ACWI/EAFE/EM
#' @keywords Ctry.msci
#' @export
#' @family Ctry

Ctry.msci <- function (x) 
{
    z <- parameters("MsciCtryClassification")
    z <- mat.read(z, "\t", NULL)
    z <- z[order(z$yyyymm), ]
    if (x == "ACWI") {
        rein <- c("Developed", "Emerging")
    }
    else if (x == "EAFE") {
        rein <- "Developed"
    }
    else if (x == "EM") {
        rein <- "Emerging"
    }
    else stop("Bad Index")
    raus <- setdiff(c("Developed", "Emerging", "Frontier", "Standalone"), 
        rein)
    vec <- as.character(unlist(mat.subset(z, c("From", "To"))))
    for (i in rein) vec <- ifelse(vec == i, "in", vec)
    for (i in raus) vec <- ifelse(vec == i, "out", vec)
    z[, c("From", "To")] <- vec
    z <- z[z$From != z$To, ]
    z <- mat.subset(z, c("CCode", "To", "yyyymm"))
    dimnames(z)[[2]] <- c("CCODE", "ACTION", "YYYYMM")
    z$ACTION <- toupper(z$ACTION)
    z
}

#' Ctry.msci.index.changes
#' 
#' handles the addition and removal of countries from an index
#' @param x = a matrix/df of total returns indexed by the beginning of the period (trade date in yyyymmdd format)
#' @param y = an MSCI index such as ACWI/EAFE/EM
#' @keywords Ctry.msci.index.changes
#' @export
#' @family Ctry

Ctry.msci.index.changes <- function (x, y) 
{
    super.set <- Ctry.msci.members.rng(y, dimnames(x)[[1]][1], 
        dimnames(x)[[1]][dim(x)[1]])
    z <- Ctry.msci(y)
    if (nchar(dimnames(x)[[1]][1]) == 8) 
        z$YYYYMM <- yyyymmdd.ex.yyyymm(z$YYYYMM)
    if (nchar(dimnames(x)[[2]][1]) == 3) {
        z$CCODE <- Ctry.info(z$CCODE, "Curr")
        super.set <- Ctry.info(super.set, "Curr")
        z <- z[!is.element(z$CCODE, c("USD", "EUR")), ]
    }
    w <- !is.element(z$CCODE, dimnames(x)[[2]])
    if (any(w)) {
        w2 <- is.element(super.set, z$CCODE[w])
        z <- z[!w, ]
        if (any(w2)) 
            err.raise(super.set[w2], F, "Warning: No data for the following")
    }
    u.Ctry <- z$CCODE[!duplicated(z$CCODE)]
    z <- z[order(z$YYYYMM), ]
    for (i in u.Ctry) {
        vec <- z$CCODE == i
        if (z[vec, "ACTION"][1] == "OUT") 
            vec <- c("19720809", z[vec, "YYYYMM"])
        else vec <- z[vec, "YYYYMM"]
        if (length(vec)%%2 == 0) 
            vec <- c(vec, "30720809")
        w <- dimnames(x)[[1]] < vec[1]
        vec <- vec[-1]
        while (length(vec) > 0) {
            w <- w | (dimnames(x)[[1]] >= vec[1] & dimnames(x)[[1]] < 
                vec[2])
            vec <- vec[-1]
            vec <- vec[-1]
        }
        x[w, i] <- NA
    }
    z <- x
    z
}

#' Ctry.msci.members
#' 
#' lists countries in an index at <y>
#' @param x = an index name such as ACWI/EAFE/EM
#' @param y = one of the following: (a) a YYYYMM date (b) a YYYYMMDD date (c) "" for a static series
#' @keywords Ctry.msci.members
#' @export
#' @family Ctry

Ctry.msci.members <- function (x, y) 
{
    z <- mat.read(parameters("MsciCtry2016"))
    z <- dimnames(z)[[1]][is.element(z[, x], 1)]
    if (y != "" & txt.left(y, 4) != "2016") {
        x <- Ctry.msci(x)
        point.in.2016 <- "201612"
        if (nchar(y) == 8) {
            x$YYYYMM <- yyyymmdd.ex.yyyymm(x$YYYYMM)
            point.in.2016 <- "20161231"
        }
    }
    if (y != "" & txt.left(y, 4) > "2016") {
        w <- x$YYYYMM >= point.in.2016
        w <- w & x$YYYYMM <= y
        if (any(w)) {
            for (i in 1:sum(w)) {
                if (x[w, "ACTION"][i] == "IN") 
                  z <- union(z, x[w, "CCODE"][i])
                if (x[w, "ACTION"][i] == "OUT") 
                  z <- setdiff(z, x[w, "CCODE"][i])
            }
        }
    }
    if (y != "" & txt.left(y, 4) < "2016") {
        w <- x$YYYYMM <= point.in.2016
        w <- w & x$YYYYMM > y
        if (any(w)) {
            x <- mat.reverse(x)
            w <- w[dim(x)[1]:1]
            x[, "ACTION"] <- ifelse(x[, "ACTION"] == "IN", "OUT", 
                "IN")
            for (i in 1:sum(w)) {
                if (x[w, "ACTION"][i] == "IN") 
                  z <- union(z, x[w, "CCODE"][i])
                if (x[w, "ACTION"][i] == "OUT") 
                  z <- setdiff(z, x[w, "CCODE"][i])
            }
        }
    }
    z
}

#' Ctry.msci.members.rng
#' 
#' lists countries that were ever in an index between <y> and <n>
#' @param x = an index name such as ACWI/EAFE/EM
#' @param y = a YYYYMM or YYYYMMDD date
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
    w <- x$YYYYMM >= y
    w <- w & x$YYYYMM <= n
    w <- w & x$ACTION == "IN"
    if (any(w)) 
        z <- union(z, x[w, "CCODE"])
    z
}

#' Ctry.to.CtryGrp
#' 
#' makes Country groups
#' @param x = a vector of country codes
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

#' dataset.subset
#' 
#' subsets all files in <x> so that column <y> is made up of elements of <n>. Original files are overwritten.
#' @param x = a local folder (e.g. "C:\\\\temp\\\\crap")
#' @param y = column on which to subset
#' @param n = a vector of identifiers
#' @keywords dataset.subset
#' @export

dataset.subset <- function (x, y, n) 
{
    x <- dir.all.files(x, "*.*")
    while (length(x) > 0) {
        z <- scan(x[1], what = "", sep = "\n", nlines = 1, quiet = T)
        m <- as.numeric(regexpr(y, z, fixed = T))
        if (m > 0) {
            m <- m + nchar(y)
            if (m <= nchar(z)) {
                m <- substring(z, m, m)
                z <- mat.read(x[1], m, NULL, T)
                write.table(z[is.element(z[, y], n), ], "C:\\temp\\write.csv", 
                  sep = m, col.names = T, quote = F, row.names = F)
            }
            else cat("Can't subset", x[1], "\n")
        }
        else cat("Can't subset", x[1], "\n")
        x <- x[-1]
    }
    invisible()
}

#' day.ex.date
#' 
#' calendar dates
#' @param x = a vector of R dates
#' @keywords day.ex.date
#' @export
#' @family day

day.ex.date <- function (x) 
{
    format(x, "%Y%m%d")
}

#' day.ex.int
#' 
#' calendar dates
#' @param x = an integer or vector of integers
#' @keywords day.ex.int
#' @export
#' @family day

day.ex.int <- function (x) 
{
    format(as.Date(x, origin = "2018-01-01"), "%Y%m%d")
}

#' day.lag
#' 
#' lags <x> by <y> days.
#' @param x = a vector of calendar dates
#' @param y = an integer or vector of integers (if <x> and <y> are vectors then <y> isomekic)
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
#' @param x = a single calendar date
#' @param y = a single calendar date
#' @param n = quantum size in calendar date
#' @keywords day.seq
#' @export
#' @family day

day.seq <- function (x, y, n = 1) 
{
    obj.seq(x, y, day.to.int, day.ex.int, n)
}

#' day.to.int
#' 
#' Number of days since Monday, 1/1/18
#' @param x = a vector of calendar dates
#' @keywords day.to.int
#' @export
#' @family day

day.to.int <- function (x) 
{
    z <- paste(substring(x, 1, 4), substring(x, 5, 6), substring(x, 
        7, 8), sep = "-")
    z <- as.numeric(as.Date(z) - as.Date("2018-01-01"))
    z
}

#' day.to.weekday
#' 
#' Converts to 0 = Sun, 1 = Mon, ..., 6 = Sat
#' @param x = a vector of calendar dates
#' @keywords day.to.weekday
#' @export
#' @family day

day.to.weekday <- function (x) 
{
    z <- day.to.int(x)
    z <- z + 1
    z <- as.character(z%%7)
    z
}

#' dir.all.files
#' 
#' Returns all files in the folder including sub-directories
#' @param x = a path such as "C:\\\\temp"
#' @param y = a string such as "*.txt"
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

#' dir.ensure
#' 
#' Creates necessary folders so files can be copied to <x>
#' @param x = a vector of full file paths
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
        for (z in x) dir.make(z)
    invisible()
}

#' dir.kill
#' 
#' removes <x>
#' @param x = a vector of full folder paths
#' @keywords dir.kill
#' @export
#' @family dir

dir.kill <- function (x) 
{
    for (z in x) if (dir.exists(z)) 
        unlink(z, recursive = T)
    invisible()
}

#' dir.make
#' 
#' creates folders <x>
#' @param x = a vector of full folder paths
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
#' @param x = a string of full paths
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

#' dir.size
#' 
#' size of directory <x> in KB
#' @param x = a SINGLE path to a directory
#' @keywords dir.size
#' @export
#' @family dir

dir.size <- function (x) 
{
    z <- dir.all.files(x, "*.*")
    if (length(z) == 0) {
        z <- 0
    }
    else {
        z <- file.size(z)
        z <- sum(z, na.rm = T)/2^10
    }
    z
}

#' err.raise
#' 
#' error message
#' @param x = a vector
#' @param y = T/F depending on whether output goes on many lines
#' @param n = main line of error message
#' @keywords err.raise
#' @export

err.raise <- function (x, y, n) 
{
    n <- paste(n, ":", sep = "")
    if (y) {
        cat(paste(c(n, paste("\t", x, sep = "")), collapse = "\n"), 
            "\n")
    }
    else {
        cat(paste(n, "\n\t", sep = ""))
        cat(paste(x, collapse = " "))
    }
    cat("\n")
    invisible()
}

#' excise.zeroes
#' 
#' Coverts zeroes to NA
#' @param x = a vector/matrix/dataframe
#' @keywords excise.zeroes
#' @export

excise.zeroes <- function (x) 
{
    fcn <- function(x) ifelse(!is.na(x) & abs(x) < 1e-06, NA, 
        x)
    z <- fcn.mat.vec(fcn, x, , T)
    z
}

#' extract.AnnMn.stock.flows
#' 
#' Subsets to "AnnMn" and re-lablels columns
#' @param x = a list object, each element of which is a 3D object The first dimension has AnnMn/AnnSd/Sharp/HitRate The second dimension has bins Q1/Q2/Qna/Q3/Q4/Q5 The third dimension is some kind of parameter
#' @param y = a string which must be one of AnnMn/AnnSd/Sharp/HitRate
#' @keywords extract.AnnMn.stock.flows
#' @export
#' @family extract

extract.AnnMn.stock.flows <- function (x, y = "AnnMn") 
{
    z <- x
    for (i in names(z)) {
        w <- dimnames(z[[i]])[[2]] != "uRet"
        z[[i]] <- as.data.frame(t(z[[i]][y, w, ]))
        z[[i]] <- mat.last.to.first(z[[i]])
        dimnames(z[[i]])[[2]] <- paste(i, dimnames(z[[i]])[[2]], 
            sep = ".")
    }
    z
}

#' extract.AnnMn.stock.flows.wrapper
#' 
#' Subsets to "AnnMn" and re-labels columns
#' @param x = a list object, each element of which is a 3D object The first dimension has AnnMn/AnnSd/Sharp/HitRate The second dimension has bins Q1/Q2/Qna/Q3/Q4/Q5 The third dimension is some kind of parameter
#' @param y = a string which must be one of AnnMn/AnnSd/Sharp/HitRate
#' @keywords extract.AnnMn.stock.flows.wrapper
#' @export
#' @family extract

extract.AnnMn.stock.flows.wrapper <- function (x, y = "AnnMn") 
{
    x <- extract.AnnMn.stock.flows(x, y)
    if (dim(x[[1]])[1] == 1) {
        z <- txt.parse(dimnames(x[[1]])[[2]], ".")
        z <- z[, dim(z)[2]]
        z <- setdiff(z, "uRet")
        z <- matrix(NA, length(names(x)), length(z), F, list(names(x), 
            z))
        for (i in names(x)) {
            for (j in dimnames(z)[[1]]) {
                w <- is.element(paste(j, dimnames(z)[[2]], sep = "."), 
                  dimnames(x[[i]])[[2]])
                if (any(w)) 
                  z[j, w] <- unlist(x[[i]][1, paste(j, dimnames(z)[[2]][w], 
                    sep = ".")])
            }
        }
    }
    else {
        z <- x[[1]]
        for (i in names(x)[-1]) z <- data.frame(z, x[[i]])
    }
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
    n <- length(x)
    w <- rep(F, n)
    for (j in 1:n) w[j] <- fcn.canonical(x[j])
    if (all(w)) 
        cat("All functions are canonical ...\n")
    if (any(!w)) 
        err.raise(x[!w], F, "The following functions are non-canonical")
    invisible()
}

#' fcn.all.roxygenize
#' 
#' roxygenizes all functions
#' @param x = path to output file
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
    y["RODBC"] <- "mk.1mPerfTrend"
    y["RDCOMClient"] <- "email"
    y["sandwich"] <- "avg.model"
    z <- NULL
    for (w in names(y)) z <- c(z, "", fcn.roxygenize(y[w], w, 
        n))
    y <- setdiff(fcn.list(), y)
    for (w in y) z <- c(z, "", fcn.roxygenize(w, , n))
    cat(z, file = x, sep = "\n")
    invisible()
}

#' fcn.all.sub
#' 
#' a string vector of names of all sub-functions
#' @param x = a vector of function names
#' @keywords fcn.all.sub
#' @export
#' @family fcn

fcn.all.sub <- function (x) 
{
    fcn.indirect(fcn.direct.sub, x)
}

#' fcn.all.super
#' 
#' names of all functions that depend on <x>
#' @param x = a vector of function names
#' @keywords fcn.all.super
#' @export
#' @family fcn

fcn.all.super <- function (x) 
{
    fcn.indirect(fcn.direct.super, x)
}

#' fcn.args.actual
#' 
#' list of actual arguments
#' @param x = a SINGLE function name
#' @keywords fcn.args.actual
#' @export
#' @family fcn

fcn.args.actual <- function (x) 
{
    names(formals(x))
}

#' fcn.canonical
#' 
#' T/F depending on whether <x> is in standard form
#' @param x = a SINGLE function name
#' @keywords fcn.canonical
#' @export
#' @family fcn

fcn.canonical <- function (x) 
{
    y <- fcn.to.comments(x)
    z <- fcn.comments.parse(y)
    if (z$canonical) {
        if (z$name != x) {
            cat(x, "has a problem with NAME!\n")
            z$canonical <- F
        }
    }
    if (z$canonical) {
        if (!ascending(fcn.dates.parse(z$date))) {
            cat(x, "has a problem with DATE!\n")
            z$canonical <- F
        }
    }
    if (z$canonical) {
        actual.args <- fcn.args.actual(x)
        if (length(z$args) != length(actual.args)) {
            cat(x, "has a problem with NUMBER of COMMENTED ARGUMENTS!\n")
            z$canonical <- F
        }
    }
    if (z$canonical) {
        if (any(z$args != actual.args)) {
            cat(x, "has a problem with COMMENTED ARGUMENTS NOT MATCHING ACTUAL!\n")
            z$canonical <- F
        }
    }
    canon <- c("fcn", "x", "y", "n", "w", "h")
    if (z$canonical) {
        if (length(z$args) < length(canon)) {
            n <- length(z$args)
            if (any(z$args != canon[1:n]) & any(z$args != canon[1:n + 
                1])) {
                cat(x, "has NON-CANONICAL ARGUMENTS!\n")
                z$canonical <- F
            }
        }
    }
    if (z$canonical) {
        z <- fcn.indent.proper(x)
    }
    else z <- F
    z
}

#' fcn.clean
#' 
#' removes trailing spaces and tabs & indents properly
#' @keywords fcn.clean
#' @export
#' @family fcn

fcn.clean <- function () 
{
    z <- vec.read(fcn.path(), F)
    w.com <- fcn.indent.ignore(z, 0)
    w.del <- txt.has(z, paste("#", txt.space(65, "-")), T)
    w.beg <- txt.has(z, " <- function(", T) & c(w.del[-1], F)
    if (any(!w.com)) 
        z[!w.com] <- txt.trim(z[!w.com], c(" ", "\t"))
    i <- 1
    n <- length(z)
    while (i <= n) {
        if (w.beg[i]) {
            i <- i + 1
            phase <- 1
        }
        else if (phase == 1 & w.del[i]) {
            phase <- 2
            w <- 1
        }
        else if (phase == 2 & fcn.indent.else(toupper(z[i]), 
            1)) {
            w <- w - 1
            z[i] <- paste(txt.space(w, "\t"), z[i], sep = "")
            w <- w + 1
        }
        else if (phase == 2 & fcn.indent.decrease(toupper(z[i]), 
            1)) {
            w <- w - 1
            z[i] <- paste(txt.space(w, "\t"), z[i], sep = "")
        }
        else if (phase == 2 & fcn.indent.increase(toupper(z[i]), 
            0)) {
            z[i] <- paste(txt.space(w, "\t"), z[i], sep = "")
            w <- w + 1
        }
        else if (phase == 2 & !w.com[i]) {
            z[i] <- paste(txt.space(w, "\t"), z[i], sep = "")
        }
        i <- i + 1
    }
    cat(z, file = fcn.path(), sep = "\n")
    invisible()
}

#' fcn.comments.parse
#' 
#' extracts information from the comments
#' @param x = comments section of a function
#' @keywords fcn.comments.parse
#' @export
#' @family fcn

fcn.comments.parse <- function (x) 
{
    z <- list(canonical = !is.null(x))
    if (z$canonical) {
        if (txt.left(x[1], 10) != "# Name\t\t: ") {
            cat("Problem with NAME!\n")
            z$canonical <- F
        }
        else {
            z$name <- txt.right(x[1], nchar(x[1]) - 10)
            x <- x[-1]
        }
    }
    if (z$canonical) {
        if (txt.left(x[1], 11) != "# Author\t: ") {
            cat("Problem with AUTHOR!\n")
            z$canonical <- F
        }
        else {
            z$author <- txt.right(x[1], nchar(x[1]) - 11)
            x <- x[-1]
        }
    }
    if (z$canonical) {
        if (txt.left(x[1], 10) != "# Date\t\t: ") {
            cat("Problem with DATE!\n")
            z$canonical <- F
        }
        else {
            z$date <- txt.right(x[1], nchar(x[1]) - 10)
            x <- x[-1]
            while (length(x) > 0 & txt.left(x[1], 5) == "#\t\t: ") {
                z$date <- paste(z$date, txt.right(x[1], nchar(x[1]) - 
                  5), sep = "")
                x <- x[-1]
            }
        }
    }
    if (z$canonical) {
        if (txt.left(x[1], 10) != "# Args\t\t: ") {
            cat("Problem with ARGS!\n")
            z$canonical <- F
        }
        else {
            z$detl.args <- x[1]
            x <- x[-1]
            while (length(x) > 0 & any(txt.left(x[1], 5) == c("#\t\t: ", 
                "#\t\t:\t"))) {
                z$detl.args <- c(z$detl.args, x[1])
                x <- x[-1]
            }
            z$detl.args <- fcn.extract.args(z$detl.args)
            if (length(z$detl.args) == 1 & z$detl.args[1] != 
                "none") {
                z$args <- as.character(txt.parse(z$detl.args, 
                  " =")[1])
            }
            else if (length(z$detl.args) > 1) 
                z$args <- txt.parse(z$detl.args, " =")[, 1]
        }
    }
    if (z$canonical) {
        if (txt.left(x[1], 11) != "# Output\t: ") {
            cat("Problem with OUTPUT!\n")
            z$canonical <- F
        }
        else {
            z$out <- x[1]
            x <- x[-1]
            while (length(x) > 0 & any(txt.left(x[1], 5) == c("#\t\t: ", 
                "#\t\t:\t"))) {
                z$out <- c(z$out, x[1])
                x <- x[-1]
            }
            z$out <- fcn.extract.out(z$out)
        }
    }
    if (z$canonical & length(x) > 0) {
        if (txt.left(x[1], 11) == "# Notes\t\t: ") {
            x <- x[-1]
            while (length(x) > 0 & any(txt.left(x[1], 5) == c("#\t\t: ", 
                "#\t\t:\t"))) x <- x[-1]
        }
    }
    if (z$canonical & length(x) > 0) {
        if (txt.left(x[1], 12) == "# Example\t: ") {
            z$example <- txt.right(x[1], nchar(x[1]) - 12)
            x <- x[-1]
        }
    }
    if (z$canonical & length(x) > 0) {
        if (txt.left(x[1], 11) == "# Import\t: ") {
            z$import <- txt.right(x[1], nchar(x[1]) - 11)
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
#' @param x = a SINGLE function name
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
#' @param x = date item from fcn.comments.parse
#' @keywords fcn.dates.parse
#' @export
#' @family fcn

fcn.dates.parse <- function (x) 
{
    z <- as.character(txt.parse(x, ","))
    if (length(z) == 1) 
        z <- yyyymmdd.ex.txt(z)
    if (length(z) > 1) {
        z <- txt.parse(z, "/")[, 1:3]
        z[, 3] <- fix.gaps(as.numeric(z[, 3]))
        z[, 3] <- yyyy.ex.yy(z[, 3])
        for (i in 1:2) z[, i] <- as.numeric(z[, i])
        z <- as.character(colSums(t(z) * 100^c(1, 0, 2)))
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
    vec.read("C:\\temp\\Automation\\root.txt", F)
}

#' fcn.direct.sub
#' 
#' a string vector of names of all direct sub-functions
#' @param x = a SINGLE function name
#' @keywords fcn.direct.sub
#' @export
#' @family fcn

fcn.direct.sub <- function (x) 
{
    x <- fcn.to.txt(x)
    z <- fcn.list()
    n <- length(z)
    w <- rep(NA, n)
    for (i in 1:n) w[i] <- txt.has(x, paste(z[i], "(", sep = ""), 
        T)
    if (any(w)) 
        z <- z[w]
    else z <- NULL
    z
}

#' fcn.direct.super
#' 
#' names of all functions that directly depend on <x>
#' @param x = a SINGLE function name
#' @keywords fcn.direct.super
#' @export
#' @family fcn

fcn.direct.super <- function (x) 
{
    x <- paste(x, "(", sep = "")
    z <- fcn.list()
    n <- length(z)
    w <- rep(NA, n)
    for (i in 1:n) {
        y <- fcn.to.txt(z[i])
        w[i] <- txt.has(y, x, T)
    }
    if (any(w)) 
        z <- z[w]
    else z <- NULL
    z
}

#' fcn.expressions.count
#' 
#' number of expressions
#' @param x = a SINGLE function name
#' @keywords fcn.expressions.count
#' @export
#' @family fcn

fcn.expressions.count <- function (x) 
{
    z <- fcn.lines.code(x, F)
    z <- parse(text = z)
    z <- length(z)
    z
}

#' fcn.extract.args
#' 
#' vector of arguments with explanations
#' @param x = string vector representing argument section of comments
#' @keywords fcn.extract.args
#' @export
#' @family fcn

fcn.extract.args <- function (x) 
{
    n <- length(x)
    x <- txt.right(x, nchar(x) - ifelse(1:n == 1, 10, 5))
    if (n > 1) {
        w <- txt.has(x, "=", T)
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
#' @param x = string vector representing output section of comments
#' @keywords fcn.extract.out
#' @export
#' @family fcn

fcn.extract.out <- function (x) 
{
    n <- length(x)
    z <- txt.right(x, nchar(x) - ifelse(1:n == 1, 11, 5))
    z <- paste(z, collapse = " ")
    z
}

#' fcn.indent.decrease
#' 
#' T/F depending on whether indent should be decreased
#' @param x = a line of code in a function
#' @param y = number of tabs
#' @keywords fcn.indent.decrease
#' @export
#' @family fcn

fcn.indent.decrease <- function (x, y) 
{
    txt.left(x, y) == paste(txt.space(y - 1, "\t"), "}", sep = "")
}

#' fcn.indent.else
#' 
#' T/F depending on whether line has an else statement
#' @param x = a line of code in a function
#' @param y = number of tabs
#' @keywords fcn.indent.else
#' @export
#' @family fcn

fcn.indent.else <- function (x, y) 
{
    h <- "} ELSE "
    z <- any(txt.left(x, nchar(h) + y - 1) == paste(txt.space(y - 
        1, "\t"), h, sep = ""))
    z <- z & txt.right(x, 1) == "{"
    z
}

#' fcn.indent.ignore
#' 
#' T/F depending on whether line should be ignored
#' @param x = a line of code in a function
#' @param y = number of tabs
#' @keywords fcn.indent.ignore
#' @export
#' @family fcn

fcn.indent.ignore <- function (x, y) 
{
    txt.left(txt.trim.left(x, "\t"), 1) == "#"
}

#' fcn.indent.increase
#' 
#' T/F depending on whether indent should be increased
#' @param x = a line of code in a function
#' @param y = number of tabs
#' @keywords fcn.indent.increase
#' @export
#' @family fcn

fcn.indent.increase <- function (x, y) 
{
    h <- c("FOR (", "WHILE (", "IF (")
    z <- any(txt.left(x, nchar(h) + y) == paste(txt.space(y, 
        "\t"), h, sep = ""))
    z <- z & txt.right(x, 1) == "{"
    z
}

#' fcn.indent.proper
#' 
#' T/F depending on whether the function is indented properly
#' @param x = a SINGLE function name
#' @keywords fcn.indent.proper
#' @export
#' @family fcn

fcn.indent.proper <- function (x) 
{
    y <- toupper(fcn.lines.code(x, T))
    n <- c(char.seq("A", "Z"), 1:9)
    w <- 1
    i <- 1
    z <- T
    while (i < 1 + length(y) & z) {
        if (fcn.indent.decrease(y[i], w) & !fcn.indent.else(y[i], 
            w)) {
            w <- w - 1
        }
        else if (fcn.indent.increase(y[i], w)) {
            w <- w + 1
        }
        else if (!fcn.indent.ignore(y[i], w) & !fcn.indent.else(y[i], 
            w)) {
            z <- nchar(y[i]) > nchar(txt.space(w, "\t"))
            if (z) 
                z <- is.element(substring(y[i], w + 1, w + 1), 
                  n)
            if (!z) 
                cat(x, ":", y[i], "\n")
        }
        i <- i + 1
    }
    z
}

#' fcn.indirect
#' 
#' applies <fcn> recursively
#' @param fcn = a function to apply
#' @param x = vector of function names
#' @keywords fcn.indirect
#' @export
#' @family fcn

fcn.indirect <- function (fcn, x) 
{
    z <- NULL
    while (length(x) > 0) {
        y <- NULL
        for (j in x) y <- union(y, fcn(j))
        y <- setdiff(y, x)
        z <- union(z, y)
        x <- y
    }
    z
}

#' fcn.lines.code
#' 
#' lines of actual code
#' @param x = a SINGLE function name
#' @param y = T/F depending on whether internal comments count
#' @keywords fcn.lines.code
#' @export
#' @family fcn

fcn.lines.code <- function (x, y) 
{
    z <- length(fcn.to.comments(x))
    x <- fcn.to.txt(x, T)
    x <- as.character(txt.parse(x, "\n"))
    z <- x[seq(z + 4, length(x) - 1)]
    if (!y) 
        z <- z[txt.left(txt.trim.left(z, "\t"), 1) != "#"]
    z
}

#' fcn.lines.count
#' 
#' number of lines of code
#' @param x = a SINGLE function name
#' @param y = T/F depending on whether internal comments count
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
#' @param x = pattern you want to see in returned objects
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

#' fcn.mat.col
#' 
#' applies <fcn> to the columns of <x> pairwise
#' @param fcn = function mapping two vectors to a single value
#' @param x = a vector/matrix/dataframe
#' @param y = either missing or a numeric isomekic vector
#' @param n = T/F depending on whether inputs should be ranked
#' @keywords fcn.mat.col
#' @export
#' @family fcn

fcn.mat.col <- function (fcn, x, y, n) 
{
    if (missing(y)) {
        z <- matrix(NA, dim(x)[2], dim(x)[2], F, list(dimnames(x)[[2]], 
            dimnames(x)[[2]]))
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
#' applies <fcn> to <x> if a vector or the columns/rows of <x> otherwise
#' @param fcn = function mapping vector(s) to a single value
#' @param x = a vector/matrix/dataframe
#' @param y = a number/vector or matrix/dataframe with the same dimensions as <x>
#' @param n = T/F depending on whether you want <fcn> applied to columns or rows
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
    else if (n & missing(y)) {
        z <- sapply(mat.ex.matrix(x), fcn)
    }
    else if (!n & missing(y)) {
        z <- sapply(mat.ex.matrix(t(x)), fcn)
    }
    else if (n & is.null(dim(y))) {
        z <- sapply(mat.ex.matrix(x), fcn, y)
    }
    else if (!n & is.null(dim(y))) {
        z <- sapply(mat.ex.matrix(t(x)), fcn, y)
    }
    else if (n) {
        z <- rep(NA, dim(x)[2])
        for (i in 1:dim(x)[2]) z[i] <- fcn(x[, i], y[, i])
    }
    else {
        z <- rep(NA, dim(x)[1])
        for (i in 1:dim(x)[1]) z[i] <- fcn(unlist(x[i, ]), unlist(y[i, 
            ]))
    }
    z
}

#' fcn.mat.vec
#' 
#' applies <fcn> to <x> if a vector or the columns/rows of <x> otherwise
#' @param fcn = function mapping vector(s) to an isomekic vector
#' @param x = a vector/matrix/dataframe
#' @param y = a number/vector or matrix/dataframe with the same dimensions as <x>
#' @param n = T/F depending on whether you want <fcn> applied to columns or rows
#' @keywords fcn.mat.vec
#' @export
#' @family fcn

fcn.mat.vec <- function (fcn, x, y, n) 
{
    z <- x
    if (is.null(dim(z)) & missing(y)) {
        z <- fcn(z)
    }
    else if (is.null(dim(z)) & !missing(y)) {
        z <- fcn(z, y)
    }
    else if (n & missing(y)) {
        for (i in 1:dim(z)[2]) z[, i] <- fcn(z[, i])
    }
    else if (!n & missing(y)) {
        for (i in 1:dim(z)[1]) z[i, ] <- fcn(unlist(z[i, ]))
    }
    else if (n & is.null(dim(y))) {
        for (i in 1:dim(z)[2]) z[, i] <- fcn(z[, i], y)
    }
    else if (!n & is.null(dim(y))) {
        for (i in 1:dim(z)[1]) z[i, ] <- fcn(unlist(z[i, ]), 
            y)
    }
    else if (n) {
        for (i in 1:dim(z)[2]) z[, i] <- fcn(z[, i], y[, i])
    }
    else {
        for (i in 1:dim(z)[1]) z[i, ] <- fcn(unlist(z[i, ]), 
            unlist(y[i, ]))
    }
    z
}

#' fcn.matrix
#' 
#' applies <fcn> to the elements of <x> and <y>
#' @param fcn = a function mapping values to values
#' @param x = a matrix/df
#' @param y = missing, isomekic vector, or isomekic isoplatic matrix/df
#' @keywords fcn.matrix
#' @export
#' @family fcn

fcn.matrix <- function (fcn, x, y) 
{
    if (missing(y)) 
        z <- fcn(unlist(x))
    else z <- fcn(unlist(x), unlist(y))
    z <- matrix(z, dim(x)[1], dim(x)[2], F, dimnames(x))
    z
}

#' fcn.nonNA
#' 
#' applies <fcn> to the non-NA values of <x>
#' @param fcn = a function that maps a vector to a vector
#' @param x = a vector
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
#' @param fcn = a function that maps a vector to a number
#' @param x = a vector
#' @param y = either missing or an isomekic vector
#' @param n = T/F depending on whether inputs should be ranked
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
    x <- fcn.list()
    append <- F
    z <- fcn.path()
    for (i in x) {
        y <- fcn.to.txt(i, T, F)
        y <- paste(i, "<-", y)
        cat(y, file = z, sep = "\n", append = append)
        append <- T
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
    paste(fcn.dir(), "functionsVKS.r", sep = "\\")
}

#' fcn.roxygenize
#' 
#' roxygenized function format
#' @param x = function name
#' @param y = library to import
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
        if (any(x == n) | any(txt.left(x, nchar(n) + 1) == paste(n, 
            ".", sep = ""))) {
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
#' @param x = a SINGLE function name
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
#' @param x = a SINGLE function name
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
#' @param x = a SINGLE function name
#' @keywords fcn.to.comments
#' @export
#' @family fcn

fcn.to.comments <- function (x) 
{
    y <- fcn.to.txt(x, T, T)
    z <- all(!is.element(txt.right(y, 1), c(" ", "\t")))
    if (!z) 
        cat(x, "has lines with trailing whitespace!\n")
    if (z & txt.left(y[1], 9) != "function(") {
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
#' @param x = a SINGLE function name
#' @param y = T/F vbl controlling whether comments are returned
#' @param n = T/F vbl controlling whether output is a string vector
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

#' fcn.vec.num
#' 
#' applies <fcn> to <x>
#' @param fcn = function mapping vector(s) to a single value
#' @param x = an element or vector
#' @param y = an element or isomekic vector
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
#' @param x = either a single variable or a vector of variable names
#' @param y = the YYYYMM or YYYYMMDD for which you want data
#' @param n = number of daily/monthly trailing periods
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
        mm <- as.numeric(txt.right(y, 2))
    }
    if (n > 1 & length(x) > 1) {
        stop("Can't handle this!\n")
    }
    else if (n > 1) {
        z <- paste(w, "\\", x, ".", yyyy, ".r", sep = "")
        lCol <- paste(x, mm, sep = ".")
        z <- readRDS(z)
        m <- 1:dim(z)[2]
        m <- m[dimnames(z)[[2]] == lCol]
        dimnames(z)[[2]] <- paste(dimnames(z)[[2]], yyyy, sep = ".")
        while (m < n) {
            if (daily) 
                yyyy <- yyyymm.lag(yyyy, 1)
            else yyyy <- yyyy - 1
            df <- paste(w, "\\", x, ".", yyyy, ".r", sep = "")
            df <- readRDS(df)
            dimnames(df)[[2]] <- paste(dimnames(df)[[2]], yyyy, 
                sep = ".")
            z <- data.frame(df, z)
            m <- m + dim(df)[2]
        }
        z <- z[, seq(m - n + 1, m)]
    }
    else if (length(x) > 1) {
        z <- matrix(NA, dim(h)[1], length(x), F, list(dimnames(h)[[1]], 
            x))
        z <- mat.ex.matrix(z)
        for (i in dimnames(z)[[2]]) {
            df <- paste(w, "\\", i, ".", yyyy, ".r", sep = "")
            lCol <- paste(i, mm, sep = ".")
            z[, i] <- readRDS(df)[, lCol]
        }
    }
    else {
        z <- paste(w, "\\", x, ".", yyyy, ".r", sep = "")
        lCol <- paste(x, mm, sep = ".")
        z <- readRDS(z)[, lCol]
    }
    z
}

#' file.bkp
#' 
#' Copies <x> to <y>
#' @param x = a string of full paths
#' @param y = an isomekic string of full paths
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

#' file.break
#' 
#' breaks up the file into 1GB chunks and rewrites to same directory with a "-001", "-002", etc extension
#' @param x = path to a file
#' @keywords file.break
#' @export
#' @family file

file.break <- function (x) 
{
    y <- c(txt.left(x, nchar(x) - 4), txt.right(x, 4))
    m <- ceiling(log(2 * file.size(x)/2^30, base = 10))
    w <- 1e+06
    n <- scan(file = x, what = "", skip = 0, sep = "\n", quiet = T, 
        nlines = w)
    n <- as.numeric(object.size(n))/2^30
    n <- round(w/n)
    i <- 1
    z <- scan(file = x, what = "", skip = (i - 1) * n, sep = "\n", 
        quiet = T, nlines = n)
    while (length(z) == n) {
        cat(z, file = paste(y[1], "-", txt.right(10^m + i, m), 
            y[2], sep = ""), sep = "\n")
        i <- i + 1
        z <- scan(file = x, what = "", skip = (i - 1) * n, sep = "\n", 
            quiet = T, nlines = n)
    }
    cat(z, file = paste(y[1], "-", txt.right(10^m + i, m), y[2], 
        sep = ""), sep = "\n")
    invisible()
}

#' file.date
#' 
#' Returns the last modified date in yyyymmdd format
#' @param x = a vector of full file paths
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
#' @param x = a string of full paths
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
#' @param x = a vector of dates
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
#' @param x = a vector of full file paths
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
#' @param x = csv file containing the predictors
#' @keywords file.to.last
#' @export
#' @family file

file.to.last <- function (x) 
{
    z <- mat.read(x)
    z <- mat.to.last.Idx(z)
    if (nchar(z) == 6) 
        z <- yyyymm.to.day(z)
    z
}

#' find.data
#' 
#' returns the position of the first/last true value of x
#' @param x = a logical vector
#' @param y = T/F depending on whether the position of the first/last true value of x is desired
#' @keywords find.data
#' @export
#' @family find

find.data <- function (x, y = T) 
{
    n <- length(x)
    if (y) 
        z <- (1:n)[x & !duplicated(x)]
    if (!y) 
        z <- (1:n)[x & !duplicated(x[n:1])[n:1]]
    z
}

#' find.gaps
#' 
#' returns the position of the first and last true value of x together with the first positions of all gaps
#' @param x = a logical vector
#' @keywords find.gaps
#' @export
#' @family find

find.gaps <- function (x) 
{
    m <- find.data(x, T)
    n <- find.data(x, F)
    z <- list(pos = NULL, size = NULL)
    while (n - m + 1 > sum(x[m:n])) {
        m <- m + find.data((!x)[m:n], T) - 1
        gap.size <- find.data(x[m:n], T) - 1
        z[["pos"]] <- c(z[["pos"]], m)
        z[["size"]] <- c(z[["size"]], gap.size)
        m <- m + gap.size
    }
    z <- vec.named(z[["size"]], z[["pos"]])
    z
}

#' fix.gaps
#' 
#' replaces NA's by previous value
#' @param x = a vector
#' @keywords fix.gaps
#' @export

fix.gaps <- function (x) 
{
    if (is.na(x[1])) 
        stop("Problem")
    z <- x
    n <- length(z)
    w <- is.na(z[-1])
    while (any(w)) {
        z[-1] <- ifelse(w, z[-n], z[-1])
        w <- is.na(z[-1])
    }
    z
}

#' fop
#' 
#' an array of summary statistics of each quantile, indexed by parameter
#' @param x = a matrix/data frame of predictors
#' @param y = a matrix/data frame of total return indices
#' @param delay = the number of days needed for the predictors to be known
#' @param lags = a numeric vector of predictor lags
#' @param floWind = a numeric vector of trailing flow windows
#' @param retWind = a numeric vector of forward return windows
#' @param nBins = a numeric vector
#' @param grp.fcn = a function that maps yyyymmdd dates to groups of interest (e.g. day of the week)
#' @param convert2df = T/F depending on whether you want the output converted to a data frame
#' @param reverse.vbl = T/F depending on whether you want the variable reversed
#' @param prd.size = size of each compounding period in terms of days (days = 1, wks = 5, etc.)
#' @param first.ret.date = if F grp.fcn is applied to formation dates. Otherwise it is applied to the first day in forward the return window.
#' @param findOptimalParametersFcn = the function you are using to summarize your results
#' @param sum.flows = if T, flows get summed. Otherwise they get compounded.
#' @keywords fop
#' @export
#' @family fop

fop <- function (x, y, delay, lags, floWind, retWind, nBins, grp.fcn, 
    convert2df, reverse.vbl, prd.size, first.ret.date, findOptimalParametersFcn, 
    sum.flows) 
{
    z <- NULL
    for (i in floWind) {
        cat(txt.hdr(paste("floW", i, sep = " = ")), "\n")
        x.comp <- compound.flows(x, i, prd.size, sum.flows)
        if (reverse.vbl) 
            x.comp <- -x.comp
        if (nchar(dimnames(x.comp)[[1]][1]) == 6 & nchar(dimnames(y)[[1]][1]) == 
            8) 
            x.comp <- yyyymmdd.ex.AllocMo(x.comp)
        for (h in lags) {
            cat("lag =", h, "")
            pctFlo <- x.comp
            j <- h
            delay.loc <- delay
            if (nchar(dimnames(pctFlo)[[1]][1]) == 8 & nchar(dimnames(y)[[1]][1]) == 
                6) {
                pctFlo <- mat.lag(pctFlo, j + delay, F, F)
                pctFlo <- mat.daily.to.monthly(pctFlo, F)
                delay.loc <- 0
                j <- 0
            }
            vec <- fop.grp.map(grp.fcn, pctFlo, j, delay.loc, 
                first.ret.date)
            for (n in retWind) {
                if (n != retWind[1]) 
                  cat("\t")
                cat("retW =", n, ":")
                fwdRet <- bbk.fwdRet(pctFlo, y, n, j, delay.loc)
                for (k in nBins) {
                  cat(k, "")
                  rslt <- findOptimalParametersFcn(pctFlo, fwdRet, 
                    vec, n, k)
                  if (is.null(z)) 
                    z <- array(NA, c(length(floWind), length(lags), 
                      length(retWind), length(nBins), dim(rslt)), 
                      list(floWind, lags, retWind, nBins, dimnames(rslt)[[1]], 
                        dimnames(rslt)[[2]], dimnames(rslt)[[3]]))
                  z[as.character(i), as.character(j), as.character(n), 
                    as.character(k), dimnames(rslt)[[1]], dimnames(rslt)[[2]], 
                    dimnames(rslt)[[3]]] <- rslt
                }
                cat("\n")
            }
            cat("\n")
        }
        cat("\n")
    }
    if (convert2df) {
        z <- mat.ex.array(z, c("floW", "lag", "retW", "nBin", 
            "stat", "bin", "dtGrp", "val"))
        z <- fop.stats(z, "stat", "val")
    }
    z
}

#' fop.Bin
#' 
#' Summarizes bin excess returns by sub-periods of interest (as defined by <vec>)
#' @param x = a matrix/df with rows indexed by time and columns indexed by bins
#' @param y = a matrix/data frame of returns of the same dimension as <x>
#' @param n = a vector corresponding to the rows of <x> that maps each row to a sub-period of interest (e.g. calendat year)
#' @param w = return horizon in weekdays or months
#' @param h = number of bins into which you are going to divide your predictors
#' @keywords fop.Bin
#' @export
#' @family fop

fop.Bin <- function (x, y, n, w, h) 
{
    x <- bbk.bin.xRet(x, y, h)
    m <- nchar(dimnames(x)[[1]][1])
    if (m == 6) 
        m <- 12
    else m <- 260
    z <- bbk.bin.rets.prd.summ(bbk.bin.rets.summ, x, n, m/w)
    z
}

#' fop.grp.map
#' 
#' maps dates to date groups
#' @param fcn = a function that maps yyyymmdd dates to groups of interest (e.g. day of the week)
#' @param x = a matrix/data frame of predictors
#' @param y = the number of days the predictors are lagged
#' @param n = the number of days needed for the predictors to be known
#' @param w = if F <fcn> is applied to formation dates. Otherwise it is applied to the first day in forward the return window.
#' @keywords fop.grp.map
#' @export
#' @family fop

fop.grp.map <- function (fcn, x, y, n, w) 
{
    z <- dimnames(x)[[1]]
    if (w) 
        z <- yyyymm.lag(z, -n - y - 1)
    z <- fcn(z)
    z
}

#' fop.IC
#' 
#' Summarizes bin excess returns by sub-periods of interest (as defined by <vec>)
#' @param x = a matrix/df with rows indexed by time and columns indexed by bins
#' @param y = a matrix/data frame of returns of the same dimension as <x>
#' @param n = a vector corresponding to the rows of <x> that maps each row to a sub-period of interest (e.g. calendat year)
#' @param w = return horizon in weekdays
#' @param h = an argument which is not used
#' @keywords fop.IC
#' @export
#' @family fop

fop.IC <- function (x, y, n, w, h) 
{
    x <- fop.rank.xRet(x, y)
    y <- fop.rank.xRet(y, x)
    x <- matrix(mat.correl(x, y), dim(x)[1], 2, F, list(dimnames(x)[[1]], 
        c("IC", "Crap")))
    z <- bbk.bin.rets.prd.summ(fop.IC.summ, x, n, 260/w)
    z
}

#' fop.IC.summ
#' 
#' Summarizes IC's
#' @param x = a vector of IC's
#' @param y = an argument which is not used
#' @keywords fop.IC.summ
#' @export
#' @family fop

fop.IC.summ <- function (x, y) 
{
    z <- matrix(NA, 2, dim(x)[2], F, list(c("Mean", "HitRate"), 
        dimnames(x)[[2]]))
    z["Mean", ] <- apply(x, 2, mean, na.rm = T)
    z["HitRate", ] <- apply(sign(x), 2, mean, na.rm = T) * 50
    z
}

#' fop.rank.xRet
#' 
#' Ranks <x> only when <y> is available
#' @param x = a matrix/df of predictors, the rows of which are indexed by time
#' @param y = an isomekic isoplatic matrix/df containing associated forward returns
#' @keywords fop.rank.xRet
#' @export
#' @family fop

fop.rank.xRet <- function (x, y) 
{
    z <- bbk.holidays(x, y)
    z <- mat.rank(z)
    z
}

#' fop.stats
#' 
#' puts all the entries corresponding to <y> on one row
#' @param x = output of <fop>
#' @param y = a column in <x>
#' @param n = another column in <x> containing values of interest
#' @keywords fop.stats
#' @export
#' @family fop

fop.stats <- function (x, y, n) 
{
    vec <- rep("", dim(x)[1])
    for (i in setdiff(dimnames(x)[[2]], c(y, n))) vec <- paste(vec, 
        x[, i], sep = "-")
    w <- !duplicated(vec)
    z <- x[w, !is.element(dimnames(x)[[2]], c(y, n))]
    dimnames(z)[[1]] <- vec[w]
    z <- mat.ex.matrix(z)
    for (i in unique(x[, y])) {
        w <- is.element(x[, y], i)
        z[, i] <- rep(NA, dim(z)[1])
        z[vec[w], i] <- x[w, n]
    }
    dimnames(z)[[1]] <- 1:dim(z)[1]
    z
}

#' fop.subset
#' 
#' Subsets to variations that have ALL combinations of Q1/TxB AnnMn/Sharpe in the <y>
#' @param x = output of <fop>
#' @param y = number
#' @keywords fop.subset
#' @export
#' @family fop

fop.subset <- function (x, y = 100) 
{
    cols <- c("floW", "lag", "retW", "nBin", "dtGrp")
    vec <- rep("", dim(x)[1])
    for (i in cols) vec <- paste(vec, x[, i], sep = "-")
    z <- rep(T, dim(x)[1])
    if (y > 0) {
        w <- x$bin == "Q1"
        z <- z & is.element(vec, vec[w][order(-x$AnnMn[w])][1:y]) & 
            is.element(vec, vec[w][order(-x$Sharpe[w])][1:y])
        w <- x$bin == "TxB"
        z <- z & is.element(vec, vec[w][order(-x$AnnMn[w])][1:y]) & 
            is.element(vec, vec[w][order(-x$Sharpe[w])][1:y])
    }
    z <- z & is.element(x$bin, c("Q1", "TxB"))
    z <- x[z, ]
    AnnMn <- fop.stats(mat.subset(z, c(cols, "bin", "AnnMn")), 
        "bin", "AnnMn")
    w <- !is.element(dimnames(AnnMn)[[2]], cols)
    dimnames(AnnMn)[[2]][w] <- paste("AnnMn", dimnames(AnnMn)[[2]][w], 
        sep = ".")
    vec <- rep("", dim(AnnMn)[1])
    for (i in cols) vec <- paste(vec, AnnMn[, i], sep = "-")
    dimnames(AnnMn)[[1]] <- vec
    Sharpe <- fop.stats(mat.subset(z, c(cols, "bin", "Sharpe")), 
        "bin", "Sharpe")
    w <- !is.element(dimnames(Sharpe)[[2]], cols)
    dimnames(Sharpe)[[2]][w] <- paste("Sharpe", dimnames(Sharpe)[[2]][w], 
        sep = ".")
    vec <- rep("", dim(Sharpe)[1])
    for (i in cols) vec <- paste(vec, Sharpe[, i], sep = "-")
    dimnames(Sharpe)[[1]] <- vec
    if (any(dim(AnnMn) != dim(Sharpe))) 
        stop("Problem 1")
    if (any(dimnames(AnnMn)[[1]] != dimnames(Sharpe)[[1]])) 
        stop("Problem 2")
    w <- !is.element(dimnames(Sharpe)[[2]], cols)
    z <- data.frame(AnnMn, Sharpe[, w])
    z <- z[order(-z[, "Sharpe.Q1"]), ]
    dimnames(z)[[1]] <- 1:dim(z)[1]
    z
}

#' fop.wrapper
#' 
#' a table of Sharpes, IC's and annualized mean excess returns for: Q1 - a strategy that goes long the top fifth and short the equal-weight universe TxB - a strategy that goes long and short the top and bottom fifth respectively
#' @param x = a matrix/data frame of predictors, the rows of which are YYYYMM or YYYYMMDD
#' @param y = a matrix/data frame of total return indices, the rows of which are YYYYMM or YYYYMMDD
#' @param retW = a numeric vector of forward return windows
#' @param prd.size = size of each compounding period in terms of days (days = 1, wks = 5, etc.) if <x> is indexed by YYYYMMDD or months if <x> is indexed by YYYYMM
#' @param sum.flows = if T, flows get summed. Otherwise they get compounded.
#' @param lag = an integer of predictor lags
#' @param delay = the number of days needed for the predictors to be known
#' @param floW = a numeric vector of trailing flow windows
#' @param nBin = a non-negative integer
#' @param reverse.vbl = T/F depending on whether you want the variable reversed
#' @keywords fop.wrapper
#' @export
#' @family fop

fop.wrapper <- function (x, y, retW, prd.size = 5, sum.flows = F, lag = 0, delay = 2, 
    floW = 1:20, nBin = 5, reverse.vbl = F) 
{
    z <- fop(x, y, delay, lag, floW, retW, 0, yyyymmdd.to.unity, 
        F, reverse.vbl, prd.size, F, fop.IC, sum.flows)
    z <- list(IC = z[, as.character(lag), , "0", "Mean", "IC", 
        "1"])
    x <- fop(x, y, delay, lag, floW, retW, nBin, yyyymmdd.to.unity, 
        F, reverse.vbl, prd.size, F, fop.Bin, sum.flows)
    for (i in c("Q1", "TxB")) for (j in c("Sharpe", "AnnMn")) z[[paste(i, 
        j, sep = ".")]] <- x[, as.character(lag), , as.character(nBin), 
        j, i, "1"]
    z <- mat.ex.matrix(z)
    y <- c("Q1.Sharpe", "TxB.Sharpe", "IC", "Q1.AnnMn", "TxB.AnnMn")
    z <- mat.subset(z, txt.expand(y, retW, "."))
    z
}

#' ftp.all.dir
#' 
#' remote-site directory listing of all sub-folders
#' @param x = remote folder on an ftp site (e.g. "/ftpdata/mystuff")
#' @param y = ftp site
#' @param n = user id
#' @param w = password
#' @keywords ftp.all.dir
#' @export
#' @family ftp

ftp.all.dir <- function (x, y, n, w) 
{
    z <- ftp.all.files.underlying(x, y, n, w, F)
    z <- txt.right(z, nchar(z) - nchar(x) - 1)
    z
}

#' ftp.all.files
#' 
#' remote-site directory listing of files (incl. sub-folders)
#' @param x = remote folder on an ftp site (e.g. "/ftpdata/mystuff")
#' @param y = ftp site
#' @param n = user id
#' @param w = password
#' @keywords ftp.all.files
#' @export
#' @family ftp

ftp.all.files <- function (x, y, n, w) 
{
    z <- ftp.all.files.underlying(x, y, n, w, T)
    if (x == "/") 
        x <- ""
    z <- txt.right(z, nchar(z) - nchar(x) - 1)
    z
}

#' ftp.all.files.underlying
#' 
#' remote-site directory listing of files or folders
#' @param x = remote folder on an ftp site (e.g. "/ftpdata/mystuff")
#' @param y = ftp site
#' @param n = user id
#' @param w = password
#' @param h = T/F depending on whether you want files or folders
#' @keywords ftp.all.files.underlying
#' @export
#' @family ftp

ftp.all.files.underlying <- function (x, y, n, w, h) 
{
    z <- NULL
    while (length(x) > 0) {
        cat(x[1], "...\n")
        j <- ftp.dir(x[1], y, n, w)
        if (x[1] != "/" & x[1] != "") 
            j <- paste(x[1], j, sep = "/")
        else j <- paste("/", j, sep = "")
        m <- ftp.is.file(j, y, n, w)
        if (any(m == h)) 
            z <- c(z, j[m == h])
        if (any(!m)) 
            x <- c(x, j[!m])
        x <- x[-1]
    }
    z
}

#' ftp.delete.script
#' 
#' ftp script to delete contents of remote directory
#' @param x = remote folder on an ftp site (e.g. "/ftpdata/mystuff")
#' @param y = ftp site
#' @param n = user id
#' @param w = password
#' @keywords ftp.delete.script
#' @export
#' @family ftp

ftp.delete.script <- function (x, y, n, w) 
{
    c(paste("open", y), n, w, ftp.delete.script.underlying(x, 
        y, n, w))
}

#' ftp.delete.script.underlying
#' 
#' ftp script to delete contents of remote directory
#' @param x = remote folder on an ftp site (e.g. "/ftpdata/mystuff")
#' @param y = ftp site
#' @param n = user id
#' @param w = password
#' @keywords ftp.delete.script.underlying
#' @export
#' @family ftp

ftp.delete.script.underlying <- function (x, y, n, w) 
{
    z <- paste("cd \"", x, "\"", sep = "")
    h <- ftp.dir(x, y, n, w)
    m <- ftp.is.file(paste(x, h, sep = "/"), y, n, w)
    if (any(m)) 
        z <- c(z, paste("del \"", h[m], "\"", sep = ""))
    if (any(!m)) {
        for (j in h[!m]) {
            z <- c(z, ftp.delete.script.underlying(paste(x, j, 
                sep = "/"), y, n, w))
            z <- c(z, paste("rmdir \"", x, "/", j, "\"", sep = ""))
        }
    }
    z
}

#' ftp.dir
#' 
#' remote site directory listing
#' @param x = remote folder on an ftp site (e.g. "/ftpdata/mystuff")
#' @param y = ftp site
#' @param n = user id
#' @param w = password
#' @keywords ftp.dir
#' @export
#' @family ftp

ftp.dir <- function (x, y, n, w) 
{
    ftp.file <- "C:\\temp\\foo.ftp"
    cat(ftp.dir.ftp.code(x, y, n, w, "ls"), file = ftp.file)
    z <- shell(paste("ftp -i -s:", ftp.file, sep = ""), intern = T)
    z <- ftp.dir.excise.crap(z, "150 Opening data channel for directory listing", 
        "226 Successfully transferred")
    z
}

#' ftp.dir.excise.crap
#' 
#' cleans up output
#' @param x = output from ftp directory listing
#' @param y = string demarcating the beginning of useful output
#' @param n = string demarcating the end of useful output
#' @keywords ftp.dir.excise.crap
#' @export
#' @family ftp

ftp.dir.excise.crap <- function (x, y, n) 
{
    w <- y
    w <- txt.left(x, nchar(w)) == w
    if (sum(w) != 1) 
        stop("Problem 1")
    m <- length(x)
    x <- x[seq((1:m)[w] + 1, m)]
    w <- n
    w <- txt.left(x, nchar(w)) == w
    if (sum(w) != 1) 
        stop("Problem 2")
    m <- length(x)
    if (!w[1]) 
        z <- x[seq(1, (1:m)[w] - 1)]
    else z <- NULL
    z
}

#' ftp.dir.ftp.code
#' 
#' generates ftp code for remote site directory listing
#' @param x = remote folder on an ftp site (e.g. "/ftpdata/mystuff")
#' @param y = ftp site
#' @param n = user id
#' @param w = password
#' @param h = command to execute (e.g. "ls" or "pwd")
#' @keywords ftp.dir.ftp.code
#' @export
#' @family ftp

ftp.dir.ftp.code <- function (x, y, n, w, h) 
{
    z <- ftp.txt(y, n, w)
    z <- paste(z, "\ncd \"", x, "\"", sep = "")
    z <- paste(z, h, "disconnect", "quit", sep = "\n")
    z
}

#' ftp.download.script
#' 
#' creates bat/ftp files to get all files from an ftp folder
#' @param x = remote folder on an ftp site (e.g. "/ftpdata/mystuff")
#' @param y = local folder (e.g. "C:\\\\temp\\\\mystuff")
#' @param n = ftp site
#' @param w = user id
#' @param h = password
#' @keywords ftp.download.script
#' @export
#' @family ftp

ftp.download.script <- function (x, y, n, w, h) 
{
    z <- ftp.all.files(x, n, w, h)
    h <- c(paste("open", n), w, h)
    w <- z
    w.par <- dir.parent(w)
    u.par <- w.par[!duplicated(w.par)]
    u.par <- u.par[order(nchar(u.par))]
    w2.par <- u.par != ""
    z <- txt.left(y, 2)
    if (any(w2.par)) 
        z <- c(z, paste("mkdir \"", y, "\\", u.par[w2.par], "\"", 
            sep = ""))
    vec <- ifelse(u.par == "", "", "\\")
    vec <- paste(y, vec, u.par, sep = "")
    vec <- paste("cd \"", vec, "\"", sep = "")
    vec <- c(vec, paste("ftp -i -s:", y, "\\script\\ftp", 1:length(u.par), 
        ".ftp", sep = ""))
    vec <- vec[order(rep(seq(1, length(vec)/2), 2))]
    z <- c(z, vec)
    dir.ensure(paste(y, "script", "bat.bat", sep = "\\"))
    cat(z, file = paste(y, "script", "bat.bat", sep = "\\"), 
        sep = "\n")
    for (i.n in 1:length(u.par)) {
        i <- u.par[i.n]
        w2.par <- is.element(w.par, i)
        z <- txt.replace(i, "\\", "/")
        if (x != "" & x != "/") 
            z <- paste(x, z, sep = "/")
        if (txt.right(z, 1) == "/") 
            z <- txt.left(z, nchar(z) - 1)
        z <- paste("cd \"", z, "\"", sep = "")
        z <- c(h, z)
        if (i == "") {
            i <- w[w2.par]
        }
        else {
            i <- txt.right(w[w2.par], nchar(w[w2.par]) - nchar(i) - 
                1)
        }
        z <- c(z, paste("get \"", i, "\"", sep = ""))
        z <- c(z, "disconnect", "quit")
        cat(z, file = paste(y, "\\script\\", "ftp", i.n, ".ftp", 
            sep = ""), sep = "\n")
    }
    invisible()
}

#' ftp.file.size
#' 
#' returns file size in KB
#' @param x = a file on ftp site
#' @param y = ftp site
#' @param n = user id
#' @param w = password
#' @keywords ftp.file.size
#' @export
#' @family ftp

ftp.file.size <- function (x, y, n, w) 
{
    ftp.file <- "C:\\temp\\foo.ftp"
    z <- ftp.txt(y, n, w)
    z <- paste(z, "\ndir \"", x, "\"", sep = "")
    z <- paste(z, "disconnect", "quit", sep = "\n")
    cat(z, file = ftp.file)
    z <- shell(paste("ftp -i -s:", ftp.file, sep = ""), intern = T)
    z <- ftp.dir.excise.crap(z, "150 Opening data channel for directory listing", 
        "226 Successfully transferred")
    z <- txt.itrim(z)
    z <- as.numeric(txt.parse(z, txt.space(1))[5])
    if (!is.na(z)) 
        z <- z * 2^-10
    z
}

#' ftp.is.file
#' 
#' T/F depending on whether <x> represents a file or folder
#' @param x = vector of paths to remote file or folder
#' @param y = ftp site
#' @param n = user id
#' @param w = password
#' @keywords ftp.is.file
#' @export
#' @family ftp

ftp.is.file <- function (x, y, n, w) 
{
    m <- length(x)
    z <- rep(NA, m)
    for (i in 1:m) z[i] <- ftp.is.file.underlying(x[i], y, n, 
        w)
    z
}

#' ftp.is.file.underlying
#' 
#' T/F depending on whether <x> represents a file or folder
#' @param x = path to remote file or folder (e.g. "/ftpdata/mystuff")
#' @param y = ftp site
#' @param n = user id
#' @param w = password
#' @keywords ftp.is.file.underlying
#' @export
#' @family ftp

ftp.is.file.underlying <- function (x, y, n, w) 
{
    ftp.file <- "C:\\temp\\foo.ftp"
    cat(ftp.dir.ftp.code(x, y, n, w, "pwd"), file = ftp.file)
    z <- shell(paste("ftp -i -s:", ftp.file, sep = ""), intern = T)
    z <- ftp.dir.excise.crap(z, "ftp> pwd", "ftp> disconnect")
    z <- z != paste("257 \"", x, "\" is current directory.", 
        sep = "")
    z
}

#' ftp.put
#' 
#' Writes ftp script to put the relevant file to the right folder
#' @param x = name of the strategy
#' @param y = "daily" or "weekly"
#' @param n = location of the folder on the ftp server
#' @keywords ftp.put
#' @export
#' @family ftp

ftp.put <- function (x, y, n) 
{
    z <- paste("cd /\ncd \"", n, "\"", sep = "")
    z <- paste(z, "\ndel ", strategy.file(x, y), sep = "")
    z <- paste(z, "\nput \"", strategy.path(x, y), "\"", sep = "")
    z
}

#' ftp.txt
#' 
#' credentials needed to access ftp
#' @param x = ftp site
#' @param y = user id
#' @param n = password
#' @keywords ftp.txt
#' @export
#' @family ftp

ftp.txt <- function (x, y, n) 
{
    paste(c(paste("open", x), y, n), collapse = "\n")
}

#' ftp.upload.script
#' 
#' returns ftp script to copy up files from the local machine
#' @param x = empty remote folder on an ftp site (e.g. "/ftpdata/mystuff")
#' @param y = local folder containing the data (e.g. "C:\\\\temp\\\\mystuff")
#' @param n = ftp site
#' @param w = user id
#' @param h = password
#' @keywords ftp.upload.script
#' @export
#' @family ftp

ftp.upload.script <- function (x, y, n, w, h) 
{
    c(paste("open", n), w, h, paste("cd \"", x, "\"", sep = ""), 
        ftp.upload.script.underlying(y), "disconnect", "quit")
}

#' ftp.upload.script.underlying
#' 
#' returns ftp script to copy up files from the local machine
#' @param x = local folder containing the data (e.g. "C:\\\\temp\\\\mystuff")
#' @keywords ftp.upload.script.underlying
#' @export
#' @family ftp

ftp.upload.script.underlying <- function (x) 
{
    y <- dir(x)
    z <- NULL
    if (length(y) > 0) {
        w <- !file.info(paste(x, y, sep = "\\"))$isdir
        if (any(w)) 
            z <- c(z, paste("put \"", x, "\\", y[w], "\"", sep = ""))
        if (any(!w)) {
            for (n in y[!w]) {
                z <- c(z, paste(c("mkdir", "cd"), " \"", n, "\"", 
                  sep = ""))
                z <- c(z, ftp.upload.script.underlying(paste(x, 
                  n, sep = "\\")))
                z <- c(z, "cd ..")
            }
        }
    }
    z
}

#' fwd.probs
#' 
#' probability that forward return is positive given predictor is positive
#' @param x = predictor indexed by yyyymmdd or yyyymm
#' @param y = total return index indexed by yyyymmdd or yyyymm
#' @param floW = flow window in days
#' @param sum.flows = T/F depending on whether the predictor is to be summed or compounded
#' @param lag = number of periods to lag the predictor
#' @param delay = delay in knowing data
#' @param doW = day of the week you will trade on (5 = Fri, NULL for monthlies)
#' @param retW = size of forward return horizon
#' @param idx = the index within which you trade
#' @param prd.size = size of each period in terms of days if the rows of <x> are yyyymmdd or months otherwise
#' @keywords fwd.probs
#' @export
#' @family fwd

fwd.probs <- function (x, y, floW, sum.flows, lag, delay, doW, retW, idx, 
    prd.size) 
{
    x <- bbk.data(x, y, floW, sum.flows, lag, delay, doW, retW, 
        idx, prd.size)
    y <- x$fwdRet
    x <- x$x
    z <- c("All", "Pos", "Exc", "Last")
    z <- matrix(NA, dim(x)[2], length(z), F, list(dimnames(x)[[2]], 
        z))
    z[, "Last"] <- unlist(x[dim(x)[1], ])
    for (j in dimnames(x)[[2]]) {
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
#' @param x = predictor indexed by yyyymmdd or yyyymm
#' @param y = total return index indexed by yyyymmdd or yyyymm
#' @param floW = flow window in days
#' @param sum.flows = T/F depending on whether the predictor is to be summed or compounded
#' @param lags = number of periods to lag the predictor
#' @param delay = delay in knowing data
#' @param doW = day of the week you will trade on (5 = Fri, NULL for monthlies)
#' @param hz = a vector of forward return windows
#' @param idx = the index within which you trade
#' @param prd.size = size of each period in terms of days if the rows of <x> are yyyymmdd or months otherwise
#' @keywords fwd.probs.wrapper
#' @export
#' @family fwd

fwd.probs.wrapper <- function (x, y, floW, sum.flows, lags, delay, doW, hz, idx, prd.size) 
{
    z <- NULL
    for (retW in hz) {
        for (lag in lags) {
            w <- fwd.probs(x, y, floW, sum.flows, lag, delay, 
                doW, retW, idx, prd.size)
            if (is.null(z)) 
                z <- array(NA, c(dim(w), length(lags), length(hz)), 
                  list(dimnames(w)[[1]], dimnames(w)[[2]], lags, 
                    hz))
            z[, , as.character(lag), as.character(retW)] <- unlist(w)
        }
    }
    z
}

#' greek.ex.english
#' 
#' returns a named vector
#' @keywords greek.ex.english
#' @export

greek.ex.english <- function () 
{
    vec.named(c("platos", "mekos", "hypsos", "bathos"), c("breadth", 
        "length", "height", "depth"))
}

#' GSec.to.GSgrp
#' 
#' makes Sector groups
#' @param x = a vector of sectors
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

#' int.to.prime
#' 
#' prime factors of <x>
#' @param x = an integer
#' @keywords int.to.prime
#' @export

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

#' isin.check.digit
#' 
#' The check digit, derived using the 'Modulus 10 Double Add Double' technique.
#' @param x = a string of 9-digit nsin's (national security id's)
#' @param y = the code of the country of origin
#' @keywords isin.check.digit
#' @export
#' @family isin

isin.check.digit <- function (x, y) 
{
    z <- paste(y, x, sep = "")
    for (i in 10:1) {
        x <- substring(z, i, i)
        w <- !is.element(x, 0:9)
        if (i == 11) {
            z[w] <- paste(substring(z[w], 1, i - 1), char.to.int(x[w]) - 
                55, sep = "")
        }
        else if (i == 1) {
            z[w] <- paste(char.to.int(x[w]) - 55, substring(z[w], 
                i + 1, nchar(z[w])), sep = "")
        }
        else z[w] <- paste(substring(z[w], 1, i - 1), char.to.int(x[w]) - 
            55, substring(z[w], i + 1, nchar(z[w])), sep = "")
    }
    x <- matrix(NA, length(x), max(nchar(z)), F, list(x, 1:max(nchar(z))))
    for (i in dim(x)[2]:1) {
        w <- nchar(z) + i - dim(x)[2]
        x[w > 0, i] <- as.numeric(substring(z[w > 0], w[w > 0], 
            w[w > 0]))
    }
    w <- dim(x)[2]%%2
    if (w == 0) 
        w <- 2
    w <- seq(w, dim(x)[2], 2)
    w <- is.element(1:dim(x)[2], w)
    x[, w] <- 2 * x[, w]
    z <- rep("", dim(x)[1])
    for (i in 1:dim(x)[2]) {
        w <- !is.na(x[, i])
        if (any(w)) 
            z[w] <- paste(z[w], x[w, i], sep = "")
    }
    x <- rep(0, length(z))
    n <- max(nchar(z))
    for (i in 1:n) {
        w <- i <= nchar(z)
        if (any(w)) 
            x[w] <- x[w] + as.numeric(substring(z[w], i, i))
    }
    z <- x%%10
    z <- 10 - z
    z <- z%%10
    z
}

#' isin.ex.cusip
#' 
#' a string of isin's
#' @param x = a string of cusips
#' @param y = the country of origin (either "CA" or "US")
#' @keywords isin.ex.cusip
#' @export
#' @family isin

isin.ex.cusip <- function (x, y) 
{
    if (!is.element(y, c("US", "CA"))) 
        stop("Can't do this country!")
    z <- isin.check.digit(x, y)
    z <- paste(y, x, z, sep = "")
    z
}

#' isin.ex.sedol
#' 
#' a string of isin's
#' @param x = a string of 7-digit sedols
#' @param y = the country of origin
#' @keywords isin.ex.sedol
#' @export
#' @family isin

isin.ex.sedol <- function (x, y) 
{
    if (y != "GB") 
        stop("Can't do this country yet!")
    x <- paste("00", x, sep = "")
    z <- isin.check.digit(x, y)
    z <- paste(y, x, z, sep = "")
    z
}

#' latin.ex.arabic
#' 
#' returns <x> expressed as lower-case latin numerals
#' @param x = a numeric vector
#' @keywords latin.ex.arabic
#' @export
#' @family latin

latin.ex.arabic <- function (x) 
{
    y <- latin.to.arabic.underlying()
    x <- as.numeric(x)
    w <- is.na(x) | x < 0 | round(x) != x
    z <- rep("", length(x))
    if (all(!w)) {
        for (i in names(y)) {
            w <- x >= y[i]
            while (any(w)) {
                z[w] <- paste(z[w], i, sep = "")
                x[w] <- x[w] - y[i]
                w <- x >= y[i]
            }
        }
    }
    else z[!w] <- latin.ex.arabic(x[!w])
    z
}

#' latin.to.arabic
#' 
#' returns <x> expressed as an integer
#' @param x = a character vector of latin numerals
#' @keywords latin.to.arabic
#' @export
#' @family latin

latin.to.arabic <- function (x) 
{
    y <- latin.to.arabic.underlying()
    x <- as.character(x)
    x <- txt.trim(x)
    x <- ifelse(is.na(x), "NA", x)
    x <- tolower(x)
    w <- x
    for (i in names(y)) w <- txt.replace(w, i, "")
    w <- w == ""
    if (all(w)) {
        z <- rep(0, length(x))
        for (i in names(y)) {
            n <- nchar(i)
            w <- txt.left(x, n) == i
            while (any(w)) {
                z[w] <- z[w] + as.numeric(y[i])
                x[w] <- txt.right(x[w], nchar(x[w]) - n)
                w <- txt.left(x, n) == i
            }
        }
    }
    else {
        z <- rep(NA, length(x))
        z[w] <- latin.to.arabic(x[w])
    }
    z
}

#' latin.to.arabic.underlying
#' 
#' basic map of latin to arabic numerals
#' @keywords latin.to.arabic.underlying
#' @export
#' @family latin

latin.to.arabic.underlying <- function () 
{
    z <- c(1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 
        1)
    names(z) <- c("m", "cm", "d", "cd", "c", "xc", "l", "xl", 
        "x", "ix", "v", "iv", "i")
    z
}

#' lead.lag.effects
#' 
#' Correlates predictor with return columns with various leads/lags. Zero is contemporaneous. +ve numbers associated with future returns
#' @param fcn = a function that maps yyyymmdd dates to groups of interest (e.g. day.to.weekday)
#' @param x = a matrix/data frame of predictors
#' @param y = a vector of lags corresponding to each column
#' @param n = a vector of integers
#' @keywords lead.lag.effects
#' @export

lead.lag.effects <- function (fcn, x, y, n = seq(-10, 10)) 
{
    z <- fcn(dimnames(x)[[1]])
    z <- vec.unique(z)
    z <- array(NA, c(length(n), length(z), dim(x)[2]), list(n, 
        z, dimnames(x)[[2]]))
    for (i in n) {
        cat(i, "")
        fwdRet <- bbk.fwdRet(x, y, 1, i - 1, 0)
        for (j in dimnames(x)[[2]]) {
            cat(j, "")
            for (k in dimnames(z)[[2]]) {
                w <- fcn(dimnames(x)[[1]]) == k
                z[as.character(i), k, j] <- 100 * correl(x[w, 
                  j], fwdRet[w, j])
            }
        }
        cat("\n")
    }
    z
}

#' load.dy.vbl
#' 
#' Loads a daily variable
#' @param beg = a single YYYYMMDD
#' @param end = a single YYYYMMDD
#' @param mk.fcn = a function
#' @param optional.args = passed down to <mk.fcn>
#' @param vbl.name = name under which the variable is to be stored
#' @param out.fldr = R-object folder
#' @param env = stock-flows environment
#' @keywords load.dy.vbl
#' @export
#' @family load

load.dy.vbl <- function (beg, end, mk.fcn, optional.args, vbl.name, out.fldr, 
    env) 
{
    for (mo in yyyymm.seq(yyyymmdd.to.yyyymm(beg), yyyymmdd.to.yyyymm(end))) {
        cat(mo, ":")
        z <- load.dy.vbl.1obj(beg, end, mk.fcn, optional.args, 
            vbl.name, mo, env)
        saveRDS(z, file = paste(out.fldr, paste(vbl.name, mo, 
            "r", sep = "."), sep = "\\"), ascii = T)
        cat("\n")
    }
    invisible()
}

#' load.dy.vbl.1obj
#' 
#' Loads a daily variable
#' @param beg = a single YYYYMMDD
#' @param end = a single YYYYMMDD
#' @param mk.fcn = a function
#' @param optional.args = passed down to <mk.fcn>
#' @param vbl.name = name under which the variable is to be stored
#' @param mo = the YYYYMM for which the object is to be made
#' @param env = stock-flows environment
#' @keywords load.dy.vbl.1obj
#' @export
#' @family load

load.dy.vbl.1obj <- function (beg, end, mk.fcn, optional.args, vbl.name, mo, env) 
{
    z <- yyyymmdd.ex.yyyymm(mo, F)
    z <- paste(vbl.name, txt.right(z, 2), sep = ".")
    z <- matrix(NA, dim(env$classif)[1], length(z), F, list(dimnames(env$classif)[[1]], 
        z))
    dd <- txt.right(dimnames(z)[[2]], 2)
    dd <- dd[as.numeric(paste(mo, dd, sep = "")) >= as.numeric(beg)]
    dd <- dd[as.numeric(paste(mo, dd, sep = "")) <= as.numeric(end)]
    for (i in dd) {
        cat(i, "")
        z[, paste(vbl.name, i, sep = ".")] <- mk.fcn(paste(mo, 
            i, sep = ""), optional.args, env)
    }
    z <- mat.ex.matrix(z)
    z
}

#' load.mo.vbl
#' 
#' Loads a monthly variable
#' @param beg = a single YYYYMM
#' @param end = a single YYYYMM
#' @param mk.fcn = a function
#' @param optional.args = passed down to <mk.fcn>
#' @param vbl.name = name under which the variable is to be stored
#' @param out.fldr = R-object folder
#' @param env = stock-flows environment
#' @keywords load.mo.vbl
#' @export
#' @family load

load.mo.vbl <- function (beg, end, mk.fcn, optional.args, vbl.name, out.fldr, 
    env) 
{
    for (yyyy in seq(yyyymm.to.yyyy(beg), yyyymm.to.yyyy(end))) {
        cat(yyyy, ":")
        z <- load.mo.vbl.1obj(beg, end, mk.fcn, optional.args, 
            vbl.name, yyyy, env)
        saveRDS(z, file = paste(out.fldr, paste(vbl.name, yyyy, 
            "r", sep = "."), sep = "\\"), ascii = T)
        cat("\n")
    }
    invisible()
}

#' load.mo.vbl.1obj
#' 
#' Loads a monthly variable
#' @param beg = a single YYYYMM
#' @param end = a single YYYYMM
#' @param mk.fcn = a function
#' @param optional.args = passed down to <mk.fcn>
#' @param vbl.name = name under which the variable is to be stored
#' @param yyyy = the period for which the object is to be made
#' @param env = stock-flows environment
#' @keywords load.mo.vbl.1obj
#' @export
#' @family load

load.mo.vbl.1obj <- function (beg, end, mk.fcn, optional.args, vbl.name, yyyy, env) 
{
    z <- paste(vbl.name, 1:12, sep = ".")
    z <- matrix(NA, dim(env$classif)[1], length(z), F, list(dimnames(env$classif)[[1]], 
        z))
    mm <- 1:12
    mm <- mm[100 * yyyy + mm >= beg]
    mm <- mm[100 * yyyy + mm <= end]
    for (i in mm) {
        cat(i, "")
        z[, paste(vbl.name, i, sep = ".")] <- mk.fcn(as.character(100 * 
            yyyy + i), optional.args, env)
    }
    z <- mat.ex.matrix(z)
    z
}

#' map.classif
#' 
#' Maps data to the row space of <y>
#' @param x = a named vector
#' @param y = <classif>
#' @param n = something like "isin" or "HSId"
#' @keywords map.classif
#' @export
#' @family map

map.classif <- function (x, y, n) 
{
    z <- c(n, paste(n, 1:3, sep = ""))
    z <- matrix(NA, dim(y)[1], length(z), F, list(dimnames(y)[[1]], 
        z))
    for (i in dimnames(z)[[2]]) if (any(dimnames(y)[[2]] == i)) 
        z[, i] <- as.numeric(map.rname(x, y[, i]))
    z <- avail(z)
    z
}

#' map.rname
#' 
#' returns a matrix/df, the row names of which match up with <y>
#' @param x = a vector/matrix/data-frame
#' @param y = a vector (usually string)
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
        w <- !is.element(y, dimnames(x)[[1]])
        if (any(w)) {
            y.loc <- matrix(NA, sum(w), dim(x)[2], F, list(y[w], 
                dimnames(x)[[2]]))
            x <- rbind(x, y.loc)
        }
        if (dim(x)[2] == 1) {
            z <- matrix(x[as.character(y), 1], length(y), 1, 
                F, list(y, dimnames(x)[[2]]))
        }
        else z <- x[as.character(y), ]
    }
    z
}

#' mat.combine
#' 
#' Combines <x> and <y>
#' @param fcn = the function you want applied to row space of <x> and <y>
#' @param x = a matrix/df
#' @param y = a matrix/df
#' @keywords mat.combine
#' @export
#' @family mat

mat.combine <- function (fcn, x, y) 
{
    z <- fcn(dimnames(x)[[1]], dimnames(y)[[1]])
    z <- z[order(z)]
    x <- map.rname(x, z)
    y <- map.rname(y, z)
    z <- data.frame(x, y)
    z
}

#' mat.compound
#' 
#' Compounds across the rows
#' @param x = a matrix/df of percentage returns
#' @keywords mat.compound
#' @export
#' @family mat

mat.compound <- function (x) 
{
    fcn.mat.num(compound, x, , F)
}

#' mat.correl
#' 
#' Returns the correlation of <x> & <y> if <x> is a vector or those between the rows of <x> and <y> otherwise
#' @param x = a vector/matrix/data-frame
#' @param y = an isomekic vector or isomekic isoplatic matrix/data-frame
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
#' @param x = a matrix/df
#' @keywords mat.count
#' @export
#' @family mat

mat.count <- function (x) 
{
    fcn <- function(x) sum(!is.na(x))
    z <- fcn.mat.num(fcn, x, , T)
    z <- c(z, round(100 * z/dim(x)[1], 1))
    z <- matrix(z, dim(x)[2], 2, F, list(dimnames(x)[[2]], c("obs", 
        "pct")))
    z
}

#' mat.daily.to.monthly
#' 
#' returns latest data in each month indexed by <yyyymm> ascending
#' @param x = a matrix/df of daily data
#' @param y = T/F depending on whether data points must be from month ends
#' @keywords mat.daily.to.monthly
#' @export
#' @family mat

mat.daily.to.monthly <- function (x, y = F) 
{
    z <- x[order(dimnames(x)[[1]]), ]
    z <- mat.reverse(z)
    z <- z[!duplicated(yyyymmdd.to.yyyymm(dimnames(z)[[1]])), 
        ]
    if (y) {
        w <- yyyymmdd.to.yyyymm(dimnames(z)[[1]])
        w <- yyyymmdd.ex.yyyymm(w)
        w <- w == dimnames(z)[[1]]
        z <- z[w, ]
    }
    dimnames(z)[[1]] <- yyyymmdd.to.yyyymm(dimnames(z)[[1]])
    z <- mat.reverse(z)
    z
}

#' mat.ex.array
#' 
#' unlists the contents of an array
#' @param x = any numerical array
#' @param y = a vector of names for the columns of the output corresponding to the dimensions of <x>
#' @keywords mat.ex.array
#' @export
#' @family mat

mat.ex.array <- function (x, y) 
{
    n <- length(dim(x))
    if (missing(y)) 
        y <- char.seq("A", "Z")[seq(1, n + 1)]
    if (length(y) != n + 1) 
        stop("Problem")
    z <- permutations.buckets.many(dimnames(x))
    z <- mat.ex.matrix(z)
    names(z) <- y[1:n]
    z[, y[n + 1]] <- as.vector(x)
    z
}

#' mat.ex.array3d
#' 
#' unlists the contents of an array to a data frame
#' @param x = a three-dimensional numerical array
#' @param y = dimension which becomes the panel header
#' @param n = dimension which forms the rows
#' @keywords mat.ex.array3d
#' @export
#' @family mat

mat.ex.array3d <- function (x, y = "C", n = "A") 
{
    cols <- char.seq("A", "C")
    x <- mat.ex.array(x, c(cols, "X"))
    x <- mat.subset(x, c(n, setdiff(cols, c(n, y)), y, "X"))
    names(x) <- c(cols, "X")
    panl <- x$C[!duplicated(x$C)]
    cols <- x$B[!duplicated(x$B)]
    rows <- x$A[!duplicated(x$A)]
    m <- length(panl) * length(cols)
    j <- length(rows)
    x <- vec.named(x$X, paste(x$C, x$B, x$A, sep = "."))
    z <- txt.expand(panl, cols, ".")
    z <- matrix(as.numeric(map.rname(x, paste(rep(z, j)[order(rep(1:m, 
        j))], rep(rows, m), sep = "."))), j, m, F, list(rows, 
        z))
    z
}

#' mat.ex.matrix
#' 
#' converts into a data frame
#' @param x = a matrix
#' @param y = desired row names (defaults to NULL)
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
#' @param x = a numeric or character vector
#' @param y = an isomekic vector of associated values
#' @param n = T/F depending on whether "Q" is to be appended to column headers
#' @keywords mat.ex.vec
#' @export
#' @family mat

mat.ex.vec <- function (x, y, n = T) 
{
    if (!is.null(names(x))) 
        w <- names(x)
    else w <- 1:length(x)
    x <- as.vector(x)
    z <- x[!duplicated(x)]
    z <- z[!is.na(z)]
    z <- z[order(z)]
    z <- matrix(x, length(x), length(z), F, list(w, z))
    z <- !is.na(z) & z == matrix(dimnames(z)[[2]], dim(z)[1], 
        dim(z)[2], T)
    if (!missing(y)) 
        z <- ifelse(z, y, NA)
    else z <- fcn.mat.vec(as.numeric, z, , T)
    if (n) 
        dimnames(z)[[2]] <- paste("Q", dimnames(z)[[2]], sep = "")
    z <- mat.ex.matrix(z)
    z
}

#' mat.fake
#' 
#' Returns a data frame for testing purposes
#' @keywords mat.fake
#' @export
#' @family mat

mat.fake <- function () 
{
    n <- 7
    m <- 5
    z <- seq(1, n * m)
    z <- z[order(rnorm(n * m))]
    z <- matrix(z, n, m, F, list(1:n, char.ex.int(64 + 1:m)))
    z <- mat.ex.matrix(z)
    z
}

#' mat.index
#' 
#' indexes <x> by the first column
#' @param x = a matrix/df
#' @keywords mat.index
#' @export
#' @family mat

mat.index <- function (x) 
{
    if (any(is.na(x[, 1]))) 
        stop("NA's in row indices ...")
    if (any(duplicated(x[, 1]))) 
        stop("Duplicated row indices ...")
    if (dim(x)[2] > 2) {
        dimnames(x)[[1]] <- x[, 1]
        z <- x[, -1]
    }
    else {
        z <- vec.named(x[, 2], x[, 1])
    }
    z
}

#' mat.lag
#' 
#' Returns data lagged <y> periods with the same row space as <x>
#' @param x = a matrix/df indexed by time running FORWARDS
#' @param y = number of periods over which to lag
#' @param n = if T simple positional lagging is used. If F, yyyymm.lag is invoked.
#' @param w = used only when !n. Maps to the original row space of <x>
#' @keywords mat.lag
#' @export
#' @family mat

mat.lag <- function (x, y, n, w = T) 
{
    z <- x
    if (n) {
        if (y > 0) {
            z[seq(1 + y, dim(x)[1]), ] <- x[seq(1, dim(x)[1] - 
                y), ]
            z[1:y, ] <- NA
        }
        if (y < 0) {
            z[seq(1, dim(x)[1] + y), ] <- x[seq(1 - y, dim(x)[1]), 
                ]
            z[seq(dim(x)[1] + y + 1, dim(x)[1]), ] <- NA
        }
    }
    else {
        dimnames(z)[[1]] <- yyyymm.lag(dimnames(x)[[1]], -y)
        if (w) 
            z <- map.rname(z, dimnames(x)[[1]])
    }
    z
}

#' mat.lag.cols
#' 
#' lags columns of <x> individually based on <y>
#' @param x = a matrix/data frame of predictors
#' @param y = a vector of lags corresponding to each column
#' @keywords mat.lag.cols
#' @export
#' @family mat

mat.lag.cols <- function (x, y) 
{
    z <- x
    for (i in 1:dim(z)[2]) {
        vec <- vec.named(z[, i], dimnames(z)[[1]])
        names(vec) <- yyyymm.lag(names(vec), -y[i])
        vec <- map.rname(vec, dimnames(z)[[1]])
        vec <- ifelse(is.na(vec), z[, i], vec)
        vec <- as.numeric(vec)
        z[, i] <- vec
    }
    z
}

#' mat.last.to.first
#' 
#' Re-orders so the last column comes first
#' @param x = a matrix/df
#' @keywords mat.last.to.first
#' @export
#' @family mat

mat.last.to.first <- function (x) 
{
    x[, order(1:dim(x)[2]%%dim(x)[2])]
}

#' mat.rank
#' 
#' ranks <x> if <x> is a vector or the rows of <x> otherwise
#' @param x = a vector/matrix/data-frame
#' @keywords mat.rank
#' @export
#' @family mat

mat.rank <- function (x) 
{
    fcn <- function(x) fcn.nonNA(rank, -x)
    z <- fcn.mat.vec(fcn, x, , F)
    z
}

#' mat.reverse
#' 
#' reverses row order
#' @param x = a matrix/data-frame
#' @keywords mat.reverse
#' @export
#' @family mat

mat.reverse <- function (x) 
{
    x[dim(x)[1]:1, ]
}

#' mat.same
#' 
#' T/F depending on whether <x> and <y> are identical
#' @param x = a matrix/df
#' @param y = an isomekic isoplatic matrix/df
#' @keywords mat.same
#' @export
#' @family mat

mat.same <- function (x, y) 
{
    all(fcn.mat.num(vec.same, x, y, T))
}

#' mat.subset
#' 
#' <x> subset to <y>
#' @param x = a matrix/df
#' @param y = a vector
#' @keywords mat.subset
#' @export
#' @family mat

mat.subset <- function (x, y) 
{
    w <- is.element(y, dimnames(x)[[2]])
    if (any(!w)) {
        err.raise(y[!w], F, "Warning: The following columns are missing")
        z <- t(map.rname(t(z), y))
    }
    else z <- x[, y]
    z
}

#' mat.to.first.data.row
#' 
#' the row number of the first row containing data
#' @param x = a matrix/data-frame
#' @keywords mat.to.first.data.row
#' @export
#' @family mat

mat.to.first.data.row <- function (x) 
{
    z <- 1
    while (all(is.na(unlist(x[z, ])))) z <- z + 1
    z
}

#' mat.to.lags
#' 
#' a 3D array of <x> together with itself lagged 1, ..., <y> - 1 times
#' @param x = a matrix/df indexed by time running FORWARDS
#' @param y = number of lagged values desired plus one
#' @param n = if T simple positional lagging is used. If F, yyyymm.lag is invoked
#' @param w = size of each period in terms of YYYYMMDD or YYYYMM depending on the rows of <x>
#' @keywords mat.to.lags
#' @export
#' @family mat

mat.to.lags <- function (x, y, n = T, w = 1) 
{
    z <- array(NA, c(dim(x), y), list(dimnames(x)[[1]], dimnames(x)[[2]], 
        paste("lag", 1:y - 1, sep = "")))
    for (i in 1:y) z[, , i] <- unlist(mat.lag(x, (i - 1) * w, 
        n))
    z
}

#' mat.to.last.Idx
#' 
#' the last row index for which we have data
#' @param x = a matrix/df
#' @keywords mat.to.last.Idx
#' @export
#' @family mat

mat.to.last.Idx <- function (x) 
{
    z <- dimnames(x)[[1]][dim(x)[1]]
    cat("Original data had", dim(x)[1], "rows ending at", z, 
        "...\n")
    z
}

#' mat.to.matrix
#' 
#' converts <x> to a matrix
#' @param x = a matrix/data-frame with 3 columns corresponding respectively with the rows, columns and entries of the resulting matrix
#' @keywords mat.to.matrix
#' @export
#' @family mat

mat.to.matrix <- function (x) 
{
    u.row <- vec.unique(x[, 1])
    u.col <- vec.unique(x[, 2])
    x <- vec.named(x[, 3], paste(x[, 1], x[, 2]))
    n.row <- length(u.row)
    n.col <- length(u.col)
    vec <- rep(u.row, n.col)
    vec <- paste(vec, rep(u.col, n.row)[order(rep(1:n.col, n.row))])
    vec <- as.numeric(map.rname(x, vec))
    z <- matrix(vec, n.row, n.col, F, list(u.row, u.col))
    z
}

#' mat.to.obs
#' 
#' Returns 0 if <x> is NA or 1 otherwise.
#' @param x = a vector/matrix/dataframe
#' @keywords mat.to.obs
#' @export
#' @family mat

mat.to.obs <- function (x) 
{
    fcn <- function(x) ifelse(is.na(x), 0, 1)
    z <- fcn.mat.vec(fcn, x, , T)
    z
}

#' mat.to.xlModel
#' 
#' prepends the trade open and close dates and re-indexes by data date (as needed)
#' @param x = a data frame indexed by data dates or trade open dates
#' @param y = number of days needed for flow data to be known
#' @param n = return horizon in weekdays
#' @param w = T/F depending on whether the index is data or trade-open date
#' @keywords mat.to.xlModel
#' @export
#' @family mat

mat.to.xlModel <- function (x, y = 2, n = 5, w = F) 
{
    z <- c("Open", "Close")
    z <- matrix(NA, dim(x)[1], length(z), F, list(dimnames(x)[[1]], 
        z))
    if (w) 
        z[, "Open"] <- yyyymm.lag(dimnames(z)[[1]], -y)
    if (!w) {
        z[, "Open"] <- dimnames(z)[[1]]
        dimnames(z)[[1]] <- yyyymm.lag(z[, "Open"], y)
    }
    z[, "Close"] <- yyyymm.lag(z[, "Open"], -n)
    if (all(nchar(dimnames(x)[[1]]) == 8)) {
        if (any(day.to.weekday(z[, "Open"]) != "5") | any(day.to.weekday(z[, 
            "Close"]) != "5")) {
            cat("WARNING: YOU ARE NOT TRADING FRIDAY TO FRIDAY!\n")
        }
    }
    z <- cbind(z, x)
    z <- z[order(dimnames(z)[[1]], decreasing = T), ]
    z
}

#' mat.write
#' 
#' Writes <x> as a <n>-separated file to <y>
#' @param x = any matrix/df
#' @param y = file intended to receive the output
#' @param n = the separator
#' @keywords mat.write
#' @export
#' @family mat

mat.write <- function (x, y = "C:\\temp\\write.csv", n = ",") 
{
    write.table(x, y, sep = n, col.names = NA, quote = F)
    invisible()
}

#' mk.1dFloMo
#' 
#' Returns a flow variable with the same row space as <n>
#' @param x = a single YYYYMMDD
#' @param y = a string vector of variables to build with the last element specifying the type of funds to use (All/Act/Num, defaults to "All")
#' @param n = list object containing the following items: a) classif - classif file b) conn - a connection, the output of odbcDriverConnect c) DB - any of StockFlows/Japan/CSI300/Energy
#' @keywords mk.1dFloMo
#' @export
#' @family mk

mk.1dFloMo <- function (x, y, n) 
{
    m <- length(y)
    if (all(y[m] != c("All", "Act", "Num", "CBE"))) {
        y <- c(y, "All")
        m <- m + 1
    }
    x <- yyyymmdd.lag(x, 2)
    if (y[1] == "FloDollar") {
        z <- sql.1dFloMo(x, y[m], n$DB)
        z <- txt.replace(z, "FloMo = 100 * ", "FloDollar = ")
        z <- txt.replace(z, "/sum(AssetsStart * HoldingValue/AssetsEnd)", 
            "")
        z <- txt.left(z, nchar(z) - nchar("having\n\tsum(AssetsStart * HoldingValue/AssetsEnd) > 0"))
    }
    else if (any(y[1] == c("FloMo", "FloMoCB"))) {
        z <- sql.1dFloMo(x, y[m], n$DB)
    }
    else if (any(y[1] == c("FloTrendPMA", "FloDiffPMA", "FloDiff2PMA"))) {
        z <- sql.1dFloTrend(x, y, 1, n$DB)
    }
    else if (any(y[1] == c("FloTrend", "FloDiff", "FloDiff2"))) {
        z <- sql.1dFloTrend(x, y, 26, n$DB)
    }
    else if (any(y[1] == c("FloTrendCB", "FloDiffCB", "FloDiff2CB"))) {
        z <- sql.1dFloTrend(x, y, 26, n$DB)
    }
    else if (any(y[1] == c("ActWtTrend", "ActWtDiff", "ActWtDiff2"))) {
        z <- sql.1dActWtTrend(x, y, n$DB)
    }
    else if (any(y[1] == c("FwtdIn0", "FwtdEx0", "SwtdIn0", "SwtdEx0"))) {
        z <- sql.1dFloMoAggr(x, y[-m], n$DB)
    }
    else if (any(y[1] == c("ION$", "ION%"))) {
        z <- sql.1dION(x, y, 26, n$DB)
    }
    else stop("Bad Argument")
    z <- sql.map.classif(z, y[-m], n$conn, n$classif)
    z
}

#' mk.1mAllocMo
#' 
#' Returns a flow variable with the same row space as <n>
#' @param x = a single YYYYMM
#' @param y = a string vector of variables to build with the last element specifying the type of funds to use (All/Act/Num, defaults to "All")
#' @param n = list object containing the following items: a) classif - classif file b) conn - a connection, the output of odbcDriverConnect c) DB - any of StockFlows/Japan/CSI300/Energy
#' @keywords mk.1mAllocMo
#' @export
#' @family mk

mk.1mAllocMo <- function (x, y, n) 
{
    m <- length(y)
    if (all(y[m] != c("All", "Act", "Num"))) {
        y <- c(y, "All")
        m <- m + 1
    }
    x <- yyyymm.lag(x, 1)
    if (y[1] == "AllocSkew") {
        sql.fcn <- "sql.1mAllocSkew"
    }
    else if (any(y[1] == paste("Alloc", c("Mo", "Trend", "Diff"), 
        sep = ""))) {
        sql.fcn <- "sql.1mAllocMo"
    }
    else stop("Bad Argument")
    sql.fcn <- get(sql.fcn)
    z <- sql.fcn(x, y, n$DB)
    z <- sql.map.classif(z, y[-m], n$conn, n$classif)
    z
}

#' mk.ActWt
#' 
#' Active weight
#' @param x = a single YYYYMM
#' @param y = a string vector of names of the portfolio and benchmark
#' @param n = list object containing the following items: a) classif - classif file b) fldr - stock-flows folder
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
#' @param x = a single YYYYMM
#' @param y = a string vector, the first two elements of which are universe and group to zScore on and within. This is then followed by a list of variables which are, in turn, followed by weights to put on variables
#' @param n = list object containing the following items: a) classif - classif file b) fldr - stock-flows folder
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
    wts <- renorm(as.numeric(y[seq(m/2 + 2, m)]))/100
    z <- fetch(vbls, x, 1, paste(n$fldr, "derived", sep = "\\"), 
        n$classif)
    z$grp <- n$classif[, grp.nm]
    z$mem <- fetch(univ, x, 1, paste(n$fldr, "\\data", sep = ""), 
        n$classif)
    for (j in vbls) z[, j] <- vec.zScore(z[, j], z$mem, z$grp)
    z <- z[, vbls]
    z <- zav(z)
    z <- as.matrix(z)
    z <- z %*% wts
    z <- as.numeric(z)
    z
}

#' mk.Alpha.daily
#' 
#' makes Alpha
#' @param x = a single YYYYMMDD
#' @param y = a string vector, the first two elements of which are universe and group to zScore on and within. This is then followed by a list of variables which are, in turn, followed by weights to put on variables and a logical vector indicating whether the variables are daily.
#' @param n = list object containing the following items: a) classif - classif file b) fldr - stock-flows folder
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
    wts <- renorm(as.numeric(y[seq((m + 7)/3, (2 * m + 2)/3)]))/100
    vbls <- vec.named(as.logical(y[seq((2 * m + 5)/3, m)]), y[seq(3, 
        (m + 4)/3)])
    vbls[univ] <- F
    z <- matrix(NA, dim(n$classif)[1], length(vbls), F, list(dimnames(n$classif)[[1]], 
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
    for (j in vbls) z[, j] <- vec.zScore(z[, j], z[, univ], z$grp)
    z <- z[, vbls]
    z <- zav(z)
    z <- as.matrix(z)
    z <- z %*% wts
    z <- as.numeric(z)
    z
}

#' mk.avail
#' 
#' Returns leftmost non-NA variable
#' @param x = a single YYYYMM or YYYYMMDD
#' @param y = a string vector, the elements of which are: 1) folder to fetch data from 2+) variables to fetch
#' @param n = list object containing the following items: a) classif - classif file b) fldr - stock-flows folder
#' @keywords mk.avail
#' @export
#' @family mk

mk.avail <- function (x, y, n) 
{
    avail(fetch(y[-1], x, 1, paste(n$fldr, y[1], sep = "\\"), 
        n$classif))
}

#' mk.beta
#' 
#' Computes monthly beta versus relevant benchmark
#' @param x = a single YYYYMM
#' @param y = a string vector, the elements of which are: 1) benchmark (e.g. "Eafe") 2) number of trailing months of returns (e.g. 12)
#' @param n = list object containing the following items: a) classif - classif file b) fldr - stock-flows folder
#' @keywords mk.beta
#' @export
#' @family mk

mk.beta <- function (x, y, n) 
{
    m <- as.numeric(y[2])
    univ <- y[1]
    w <- paste(dir.parameters("csv"), "IndexReturns-Monthly.csv", 
        sep = "\\")
    w <- mat.read(w)
    z <- fetch("Ret", x, m, paste(n$fldr, "data", sep = "\\"), 
        n$classif)
    vec <- map.rname(w, yyyymm.lag(x, m:1 - 1))[, univ]
    vec <- matrix(c(rep(1, m), vec), m, 2, F, list(1:m, c("Intercept", 
        univ)))
    z <- run.cs.reg(z, vec)
    z <- as.numeric(z[, univ])
    z
}

#' mk.FloAlphaLt.Ctry
#' 
#' Monthly Country Flow Alpha
#' @param x = a single YYYYMM
#' @param y = an object name (preceded by #) or the path to a ".csv" file
#' @param n = list object containing the following items: a) classif - classif file
#' @keywords mk.FloAlphaLt.Ctry
#' @export
#' @family mk

mk.FloAlphaLt.Ctry <- function (x, y, n) 
{
    z <- read.prcRet(y)
    z <- unlist(z[yyyymmdd.ex.yyyymm(x), ])
    z <- map.rname(z, n$classif$CCode)
    z <- as.numeric(z)
    z
}

#' mk.FundsMem
#' 
#' Returns a 1/0 vector with the same row space as <n> that is 1 whenever it has the right fund type as well as one-month forward return.
#' @param x = a single YYYYMM
#' @param y = a string vector, the elements of which are: 1) column to match in classif (e.g. "FundType") 2) column value (e.g. "E" or "B")
#' @param n = list object containing the following items: a) classif - classif file b) fldr - stock-flows folder
#' @keywords mk.FundsMem
#' @export
#' @family mk

mk.FundsMem <- function (x, y, n) 
{
    w <- is.element(n[, y[1]], y[2])
    z <- fetch("Ret", yyyymm.lag(x, -1), 1, paste(n$fldr, "data", 
        sep = "\\"), n$classif)
    z <- w & !is.na(z)
    z <- as.numeric(z)
    z
}

#' mk.isin
#' 
#' Looks up date from external file and maps on isin
#' @param x = a single YYYYMM or YYYYMMDD
#' @param y = a string vector, the elements of which are: 1) an object name (preceded by #) or the path to a ".csv" file 2) defaults to "isin"
#' @param n = list object containing the following items: a) classif - classif file
#' @keywords mk.isin
#' @export
#' @family mk

mk.isin <- function (x, y, n) 
{
    if (length(y) == 1) 
        y <- c(y, "isin")
    z <- read.prcRet(y[1])
    z <- vec.named(z[, x], dimnames(z)[[1]])
    z <- map.classif(z, n[["classif"]], y[2])
    z
}

#' mk.JensensAlpha.fund
#' 
#' Returns variable with the same row space as <n>
#' @param x = a single YYYYMM
#' @param y = number of months of trailing returns to use
#' @param n = list object containing the following items: a) classif - classif file b) fldr - stock-flows folder c) CATRETS - category returns
#' @keywords mk.JensensAlpha.fund
#' @export
#' @family mk

mk.JensensAlpha.fund <- function (x, y, n) 
{
    y <- as.numeric(y)
    fndR <- fetch("1mPrcMo", x, y, paste(n$fldr, "derived", sep = "\\"), 
        n$classif)
    fndR <- as.matrix(fndR)
    dimnames(fndR)[[2]] <- yyyymm.lag(x, y:1 - 1)
    catR <- n$CATRETS[, dimnames(fndR)[[2]]]
    w <- rep(T, dim(fndR)[1])
    for (i in dimnames(fndR)[[2]]) w <- w & !is.na(fndR[, i]) & 
        !is.na(catR[, i])
    z <- rep(NA, dim(fndR)[1])
    if (any(w)) {
        fndM <- rowMeans(fndR[w, ])
        catM <- rowMeans(catR[w, ])
        beta <- rowSums((catR[w, ] - catM) * (catR[w, ] - catM))
        beta <- rowSums((fndR[w, ] - fndM) * (catR[w, ] - catM))/nonneg(beta)
        z[w] <- fndM - beta * catM
    }
    z
}

#' mk.Mem
#' 
#' Returns a 1/0 membership vector
#' @param x = a single YYYYMM
#' @param y = a single FundId
#' @param n = list object containing the following items: a) classif - classif file b) conn - a connection, the output of odbcDriverConnect
#' @keywords mk.Mem
#' @export
#' @family mk

mk.Mem <- function (x, y, n) 
{
    y <- sql.and(list(A = sql.in("HFundId", sql.tbl("HFundId", 
        "FundHistory", paste("FundId =", y))), B = "ReportDate = @mo"))
    z <- c("Holdings t1", "inner join", "SecurityHistory t2 on t1.HSecurityId = t2.HSecurityId")
    z <- sql.unbracket(sql.tbl("SecurityId, Mem = sign(HoldingValue)", 
        z, y))
    z <- paste(c(sql.declare("@mo", "datetime", yyyymm.to.day(x)), 
        z), collapse = "\n")
    z <- sql.map.classif(z, "Mem", n$conn, n$classif)
    z <- zav(z)
    z
}

#' mk.sqlDump
#' 
#' Returns variable with the same row space as <n>
#' @param x = a single YYYYMM
#' @param y = a string vector, the elements of which are: 1) file to read from 2) variable to read 3) lag (defaults to zero)
#' @param n = list object containing the following items: a) fldr - stock-flows folder
#' @keywords mk.sqlDump
#' @export
#' @family mk

mk.sqlDump <- function (x, y, n) 
{
    if (length(y) > 2) 
        x <- yyyymm.lag(x, as.numeric(y[3]))
    z <- paste(n$fldr, "\\sqlDump\\", y[1], ".", x, ".r", sep = "")
    z <- readRDS(z)
    z <- z[, y[2]]
    z
}

#' mk.trail.sum.dly.vbl
#' 
#' Compounds/sums over some trailing period
#' @param x = a single YYYYMM
#' @param y = a vector of string, the elements of which are: 1) 1d variable to fetch (e.g. "1dFloMo") 2)  T to sum or F to compound (e.g. "F") 3) number of weekdays to compound over (e.g. "65") 4) number of days to lag (defaults to "0") 5) sub-folder to fetch basic variable from (defaults to "derived")
#' @param n = list object containing the following items: a) classif - classif file b) fldr - stock-flows folder
#' @keywords mk.trail.sum.dly.vbl
#' @export
#' @family mk

mk.trail.sum.dly.vbl <- function (x, y, n) 
{
    if (length(y) == 3) 
        y <- c(y, 0, "derived")
    if (length(y) == 4) 
        y <- c(y, "derived")
    m <- as.numeric(y[3])
    trail <- m + as.numeric(y[4])
    if (nchar(x) == 6) 
        x <- yyyymmdd.ex.yyyymm(x)
    z <- fetch(y[1], x, trail, paste(n$fldr, y[5], sep = "\\"), 
        n$classif)
    z <- z[, 1:m]
    z <- compound.stock.flows(z, as.logical(y[2]))
    z <- as.numeric(z)
    z
}

#' mk.trail.sum.mo.vbl
#' 
#' compounded variable over some trailing window
#' @param x = a single YYYYMM
#' @param y = a string vector, the elements of which are: 1) 1m variable to fetch (e.g. "AllocMo"/"AllocDiff"/"AllocTrend"/"Ret") 2) T to sum or F to compound (e.g. "T") 3) number of months to sum over (e.g. "11") 4) number of months to lag (defaults to "0") 5) sub-folder to fetch basic variable from (defaults to "derived")
#' @param n = list object containing the following items: a) classif - classif file b) fldr - stock-flows folder
#' @keywords mk.trail.sum.mo.vbl
#' @export
#' @family mk

mk.trail.sum.mo.vbl <- function (x, y, n) 
{
    if (length(y) == 3) 
        y <- c(y, 0, "derived")
    if (length(y) == 4) 
        y <- c(y, "derived")
    m <- as.numeric(y[3])
    trail <- m + as.numeric(y[4])
    z <- fetch(y[1], x, trail, paste(n$fldr, y[5], sep = "\\"), 
        n$classif)
    z <- z[, 1:m]
    z <- compound.stock.flows(z, as.logical(y[2]))
    z <- as.numeric(z)
    z
}

#' mk.vbl.chg
#' 
#' Makes the MoM change in the variable
#' @param x = a single YYYYMM
#' @param y = variable name
#' @param n = list object containing the following items: a) classif - classif file b) fldr - stock-flows folder
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
#' @param x = a single YYYYMM
#' @param y = a string vector, the elements of which are the variables being subtracted and subtracted from respectively.
#' @param n = list object containing the following items: a) classif - classif file b) fldr - stock-flows folder
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
#' @param x = a single YYYYMM
#' @param y = a string vector, the elements of which are: 1) the variable to be lagged 2) the lag in months 3) the sub-folder in which the variable lives
#' @param n = list object containing the following items: a) classif - classif file b) fldr - stock-flows folder
#' @keywords mk.vbl.lag
#' @export
#' @family mk

mk.vbl.lag <- function (x, y, n) 
{
    x <- yyyymm.lag(x, as.numeric(y[2]))
    z <- fetch(y[1], x, 1, paste(n$fldr, y[3], sep = "\\"), n$classif)
    z
}

#' mk.vbl.max
#' 
#' Computes the maximum of the two variables
#' @param x = a single YYYYMM
#' @param y = a string vector of names of two variables
#' @param n = list object containing the following items: a) classif - classif file b) fldr - stock-flows folder
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
#' @param x = a single YYYYMM
#' @param y = a string vector, the elements of which are the numerator and denominator respectively.
#' @param n = list object containing the following items: a) classif - classif file b) fldr - stock-flows folder
#' @keywords mk.vbl.ratio
#' @export
#' @family mk

mk.vbl.ratio <- function (x, y, n) 
{
    z <- fetch(y, x, 1, paste(n$fldr, "data", sep = "\\"), n$classif)
    z <- z[, 1]/nonneg(z[, 2])
    z
}

#' mk.Wt
#' 
#' Generates the SQL query to get monthly index weight for individual stocks
#' @param x = a single YYYYMM
#' @param y = FundId of the fund of interest (8275 for the S&P500)
#' @param n = list object containing the following items: a) classif - classif file b) conn - a connection, the output of odbcDriverConnect
#' @keywords mk.Wt
#' @export
#' @family mk

mk.Wt <- function (x, y, n) 
{
    z <- c(sql.label(sql.MonthlyAlloc("@allocDt"), "t1"), "inner join", 
        sql.label(sql.MonthlyAssetsEnd("@allocDt"), "t2"))
    z <- c(z, "\ton t2.HFundId = t1.HFundId", "inner join", "SecurityHistory id", 
        "\ton id.HSecurityId = t1.HSecurityId")
    z <- sql.unbracket(sql.tbl("SecurityId, IdxWt = 100 * HoldingValue/AssetsEnd", 
        z, "FundId = @fundId"))
    z <- paste(c(sql.declare(c("@allocDt", "@fundId"), c("datetime", 
        "int"), c(yyyymm.to.day(x), y)), z), collapse = "\n")
    z <- sql.map.classif(z, "IdxWt", n$conn, n$classif)
    z <- zav(z)
    z
}

#' multi.asset
#' 
#' Reads in data relevant to the multi-asset strategy
#' @param x = a vector of paths to files
#' @keywords multi.asset
#' @export

multi.asset <- function (x) 
{
    n <- length(x)
    i <- 1
    z <- mat.read(x[i])
    while (i < n) {
        i <- i + 1
        z <- mat.combine(intersect, z, mat.read(x[i]))
    }
    z
}

#' nameTo
#' 
#' pct name turnover between <x> and <y> if <x> is a vector or their rows otherwise
#' @param x = a logical vector/matrix/dataframe without NA's
#' @param y = a logical value, isomekic vector or isomekic isoplatic matrix/df without NA's
#' @keywords nameTo
#' @export

nameTo <- function (x, y) 
{
    fcn <- function(x, y) nameTo.underlying(sum(x), sum(y), sum(x & 
        y))
    z <- fcn.mat.num(fcn, x, y, F)
    z
}

#' nameTo.underlying
#' 
#' percent name turnover
#' @param x = a vector of counts over the current period
#' @param y = a vector of counts over the previous period
#' @param n = a vector of numbers of names common between current and previous periods
#' @keywords nameTo.underlying
#' @export

nameTo.underlying <- function (x, y, n) 
{
    100 - 100 * n/max(x, y)
}

#' nonneg
#' 
#' returns <x> if non-negative or NA otherwise
#' @param x = a vector/matrix/dataframe
#' @keywords nonneg
#' @export

nonneg <- function (x) 
{
    fcn <- function(x) ifelse(!is.na(x) & x > 0, x, NA)
    z <- fcn.mat.vec(fcn, x, , T)
    z
}

#' nyse.holidays
#' 
#' returns full day NYSE holidays from the year 2000 and after
#' @param x = either "yyyymmdd" or "reason"
#' @keywords nyse.holidays
#' @export

nyse.holidays <- function (x = "yyyymmdd") 
{
    z <- parameters("NyseHolidays")
    z <- scan(z, what = list(yyyymmdd = "", reason = ""), sep = "\t", 
        quote = "", quiet = T)
    z <- z[[x]]
    z
}

#' obj.diff
#' 
#' returns <x - y>
#' @param fcn = a function mapping objects to the number line
#' @param x = a vector
#' @param y = an isomekic isotypic vector
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
#' @param x = a vector of objects
#' @param y = an integer or vector of integers (if <x> and <y> are vectors then <y> isomekic)
#' @param n = a function mapping these objects to the number line
#' @param w = the bijective inverse of <n>
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
#' @param x = a SINGLE object
#' @param y = a SINGLE object of the same type as <x>
#' @param n = a function mapping these objects to the number line
#' @param w = the bijective inverse of <n>
#' @param h = a positive integer representing quantum size
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

#' parameters
#' 
#' returns full path to relevant parameters file
#' @param x = parameter type
#' @keywords parameters
#' @export

parameters <- function (x) 
{
    paste(dir.parameters("parameters"), "\\", x, ".txt", sep = "")
}

#' permutations
#' 
#' all possible permutations of <x>
#' @param x = a string vector without NA's
#' @keywords permutations
#' @export
#' @family permutations

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

#' permutations.buckets.many
#' 
#' all possible choices of one element from each vector
#' @param x = a list object of string vectors without NA's
#' @keywords permutations.buckets.many
#' @export
#' @family permutations

permutations.buckets.many <- function (x) 
{
    h <- length(x)
    y <- as.numeric(lapply(x, length))
    z <- round(product(y))
    z <- matrix("", z, h, F, list(1:z, 1:h))
    m <- 1
    n <- y[1]
    i <- 1
    while (i < h + 1) {
        z[, i] <- rep(rep(x[[i]], dim(z)[1]/n), m)[order(rep(seq(1, 
            dim(z)[1]/m), m))]
        i <- i + 1
        m <- m * y[i - 1]
        n <- n * y[i]
    }
    z
}

#' permutations.next
#' 
#' returns the next permutation in dictionary order
#' @param x = a vector of integers 1:length(<x>) in some order
#' @keywords permutations.next
#' @export
#' @family permutations

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

#' phone.list
#' 
#' Cat's phone list to the screen
#' @param x = number of desired columns
#' @keywords phone.list
#' @export

phone.list <- function (x = 4) 
{
    y <- parameters("PhoneList")
    y <- mat.read(y, "\t", NULL, F)
    y <- paste(y[, 1], y[, 2], sep = "\t")
    while (length(y)%%x != 0) y <- c(y, "")
    vec <- seq(0, length(y) - 1)
    z <- y[vec%%x == 0]
    if (x > 1) 
        for (j in 2:x - 1) z <- paste(z, y[vec%%x == j], sep = "\t\t")
    z <- paste(z, collapse = "\n")
    cat(z, "\n")
    invisible()
}

#' pivot
#' 
#' returns a table, the rows and columns of which are unique members of rowIdx and colIdx The cells of the table are the <fcn> of <x> whenever <y> and <n> take on their respective values
#' @param fcn = summary function to be applied
#' @param x = a numeric vector
#' @param y = a grouping vector
#' @param n = a grouping vector
#' @keywords pivot
#' @export

pivot <- function (fcn, x, y, n) 
{
    z <- aggregate(x = x, by = list(row = y, col = n), FUN = fcn)
    z <- mat.to.matrix(z)
    z
}

#' pivot.1d
#' 
#' returns a table, having the same column space of <x>, the rows of which are unique members of <grp> The cells of the table are the summ.fcn of <x> whenever <grp> takes on its respective value
#' @param fcn = summary function to be applied
#' @param x = a grouping vector
#' @param y = a numeric vector/matrix/data-frame
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
#' @param x = a vector
#' @param y = an isomekic vector
#' @keywords plurality.map
#' @export

plurality.map <- function (x, y) 
{
    w <- !is.na(x) & !is.na(y)
    x <- x[w]
    y <- y[w]
    z <- vec.count(paste(x, y))
    z <- data.frame(txt.parse(names(z), " "), z)
    names(z) <- c("x", "map", "obs")
    z <- z[order(-z$obs), ]
    z <- z[!duplicated(z$x), ]
    dimnames(z)[[1]] <- z$x
    z <- z[, dimnames(z)[[2]] != "x"]
    z$pct <- 100 * z$obs/map.rname(vec.count(x), dimnames(z)[[1]])
    z <- z[order(-z$pct), ]
    z
}

#' position.ActWtDiff2
#' 
#' Current and week-over-week change of ActWtDiff2 on R1 Materials
#' @param x = One of "StockFlows", "Quant" or "Regular"
#' @param y = last publication date
#' @keywords position.ActWtDiff2
#' @export
#' @family position

position.ActWtDiff2 <- function (x, y) 
{
    conn <- sql.connect(x)
    mo.end <- yyyymmdd.to.AllocMo(y, 26)
    w <- sql.and(list(A = "StyleSectorId = 101", B = "GeographicFocusId = 77", 
        C = "[Index] = 1"))
    w <- sql.in("HFundId", sql.tbl("HFundId", "FundHistory", 
        w))
    w <- list(A = w, B = paste("ReportDate = '", yyyymm.to.day(mo.end), 
        "'", sep = ""))
    z <- sql.in("HFundId", sql.tbl("HFundId", "FundHistory", 
        "FundId = 5152"))
    z <- sql.and(list(A = z, B = paste("ReportDate = '", yyyymm.to.day(mo.end), 
        "'", sep = "")))
    z <- sql.tbl("HSecurityId", "Holdings", z, "HSecurityId")
    w[["C"]] <- sql.in("HSecurityId", z)
    w <- sql.tbl("HSecurityId", "Holdings", sql.and(w), "HSecurityId")
    y <- yyyymmdd.lag(y, 19:0)
    z <- list()
    for (j in y) {
        x <- sql.1dActWtTrend.underlying(j, "All", w)
        x <- c(x, sql.1dActWtTrend.topline("ActWtDiff2"))
        for (i in x) x <- sqlQuery(conn, i)
        z[[j]] <- x
    }
    x <- NULL
    for (j in names(z)) x <- union(x, z[[j]][, "SecurityId"])
    for (j in names(z)) {
        dimnames(z[[j]])[[1]] <- z[[j]][, "SecurityId"]
        z[[j]] <- map.rname(z[[j]], x)[, "ActWtDiff2"]
    }
    z <- mat.ex.matrix(z)
    Current <- rowSums(z[, 6:20], na.rm = T)
    WoW.chg <- Current - rowSums(z[, 1:15], na.rm = T)
    z <- matrix(c(Current, WoW.chg), length(x), 2, F, list(x, 
        c("Current", "WoW.chg")))
    z <- mat.ex.matrix(z)
    z <- z[order(z$Current, decreasing = T), ]
    x <- paste(dimnames(z)[[1]], collapse = ", ")
    x <- sql.in("SecurityId", paste("(", x, ")", sep = ""))
    x <- sql.and(list(A = x, B = "t1.EndDate is null", C = "t3.SecurityCodeTypeId = 4"))
    y <- c("SecurityHistory t1", "inner join", "CompanyHistory t2 on t1.HCompanyId = t2.HCompanyId")
    y <- c(y, "inner join", "SecurityCodeMapping t3 on t1.HSecurityId = t3.HSecurityId")
    y <- c(y, "inner join", "SecurityCode t4 on SecurityCodeId = [Id]")
    x <- sql.tbl(c("SecurityId", "t4.SecurityCode", "t2.CompanyName"), 
        y, x)
    x <- paste(sql.unbracket(x), collapse = "\n")
    x <- sqlQuery(conn, x)
    close(conn)
    x <- x[!duplicated(x[, "SecurityId"]), ]
    dimnames(x)[[1]] <- x[, "SecurityId"]
    x <- map.rname(x, dimnames(z)[[1]])
    z$CompanyName <- x$CompanyName
    z$Ticker <- x$SecurityCode
    z <- z[!is.na(z$Ticker) & !duplicated(z$Ticker), ]
    dimnames(z)[[1]] <- z$Ticker
    z <- z[, c("CompanyName", "Current", "WoW.chg")]
    y <- vec.named(qtl.eq(z$Current), dimnames(z)[[1]])
    y <- mat.ex.vec(y, z$Current)
    z <- data.frame(z, y)
    z
}

#' position.floPct
#' 
#' Latest four-week flow percentage
#' @param x = strategy path
#' @param y = subset
#' @param n = last publication date
#' @keywords position.floPct
#' @export
#' @family position

position.floPct <- function (x, y, n) 
{
    x <- strategy.path(x, "daily")
    x <- multi.asset(x)
    if (all(n != dimnames(x)[[1]])) {
        cat("Date", n, "not recognized! No output will be published ...\n")
        z <- NULL
    }
    else {
        if (dimnames(x)[[1]][dim(x)[1]] != n) {
            cat("Warning: Latest data not being used! Proceeding regardless ...\n")
            x <- x[dimnames(x)[[1]] <= n, ]
        }
        if (missing(y)) 
            y <- dimnames(x)[[2]]
        else x <- mat.subset(x, y)
        z <- x[dim(x)[1] - 19:0, ]
        z <- vec.named(mat.compound(t(z)), y)
        z <- z[order(-z)]
        x <- x[dim(x)[1] - 19:0 - 5, ]
        x <- vec.named(mat.compound(t(x)), y)
        x <- z - map.rname(x, names(z))
        y <- vec.named(qtl.eq(z), names(z))
        y <- mat.ex.vec(y, z)
        z <- 0.01 * data.frame(z, x, y)
        dimnames(z)[[2]][1:2] <- c("Current", "WoW.chg")
    }
    z
}

#' principal.components
#' 
#' first <y> principal components
#' @param x = a matrix/df
#' @param y = number of principal components desired
#' @keywords principal.components
#' @export

principal.components <- function (x, y = 2) 
{
    x <- as.matrix(x)
    x <- x - matrix(colMeans(x), dim(x)[1], dim(x)[2], T, dimnames(x))
    z <- t(x) %*% x
    z <- svd(z)$v[, 1:y]
    z <- x %*% z
    z
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
#' @param x = latest output
#' @param y = path to output
#' @keywords production.write
#' @export

production.write <- function (x, y) 
{
    proceed <- !is.null(x)
    if (proceed) {
        w <- mat.read(y)
        proceed <- dim(w)[2] == dim(x)[[2]]
    }
    if (proceed) 
        proceed <- all(dimnames(w)[[2]] == dimnames(x)[[2]])
    if (proceed) 
        proceed <- dim(x)[1] > dim(w)[1]
    if (proceed) 
        proceed <- all(is.element(dimnames(w)[[1]], dimnames(x)[[1]]))
    if (proceed) 
        proceed <- all(colSums(mat.to.obs(x[dimnames(w)[[1]], 
            ])) == colSums(mat.to.obs(w)))
    if (proceed) 
        proceed <- all(unlist(zav(x[dimnames(w)[[1]], ]) == zav(w)))
    if (proceed) {
        mat.write(x, y)
        cat("Writing to", y, "...\n")
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
#' Converts <x>, if a vector, or the rows of <x> otherwise, to a ptile
#' @param x = a vector/matrix/data-frame
#' @keywords ptile
#' @export

ptile <- function (x) 
{
    fcn <- function(x) 100 * (rank(x) - 1)/(length(x) - 1)
    fcn2 <- function(x) fcn.nonNA(fcn, x)
    z <- fcn.mat.vec(fcn2, x, , F)
    z
}

#' publish.daily.last
#' 
#' date of last daily publication
#' @param x = a YYYYMMDD date
#' @keywords publish.daily.last
#' @export
#' @family publish

publish.daily.last <- function (x) 
{
    if (missing(x)) 
        x <- today()
    z <- yyyymmdd.lag(x, 2)
    z
}

#' publish.date
#' 
#' the date on which country/sector allocations are published
#' @param x = a vector of yyyymm months
#' @keywords publish.date
#' @export
#' @family publish

publish.date <- function (x) 
{
    z <- yyyymm.lag(x, -1)
    z <- paste(z, "23", sep = "")
    w <- day.to.weekday(z)
    z[w == 0] <- paste(txt.left(z[w == 0], 6), "24", sep = "")
    z[w == 6] <- paste(txt.left(z[w == 6], 6), "25", sep = "")
    z
}

#' publish.monthly.last
#' 
#' date of last monthly publication
#' @param x = a YYYYMMDD date
#' @keywords publish.monthly.last
#' @export
#' @family publish

publish.monthly.last <- function (x) 
{
    if (missing(x)) 
        x <- today()
    z <- yyyymmdd.lag(x, 1)
    z <- yyyymmdd.to.AllocMo(z)
    z <- yyyymm.to.day(z)
    z
}

#' publish.weekly.last
#' 
#' date of last weekly publication
#' @param x = a YYYYMMDD date
#' @keywords publish.weekly.last
#' @export
#' @family publish

publish.weekly.last <- function (x) 
{
    if (missing(x)) 
        x <- today()
    z <- as.numeric(day.to.weekday(x))
    if (any(z == 5:6)) 
        z <- z - 3
    else z <- z + 4
    z <- day.lag(x, z)
    z
}

#' qtl
#' 
#' performs an equal-weight binning on <x> so that the members of <mem> are divided into <n> equal bins within each group <w>
#' @param x = a vector
#' @param y = number of desired bins
#' @param n = a weight vector
#' @param w = a vector of groups (e.g. GSec)
#' @keywords qtl
#' @export
#' @family qtl

qtl <- function (x, y, n, w) 
{
    if (missing(n)) 
        n <- rep(1, length(x))
    if (missing(w)) 
        w <- rep(1, length(x))
    u.grp <- w[!is.na(x) & !is.na(w) & !is.na(n) & n > 0]
    u.grp <- u.grp[!duplicated(u.grp)]
    z <- rep(NA, length(x))
    for (i in u.grp) {
        w.i <- is.element(w, i)
        z[w.i] <- qtl.single.grp(x[w.i], y, n[w.i])
    }
    z
}

#' qtl.eq
#' 
#' performs an equal-weight binning on <x> if <x> is a vector or the rows of <x> otherwise
#' @param x = a vector/matrix/data-frame
#' @param y = number of desired bins
#' @keywords qtl.eq
#' @export
#' @family qtl

qtl.eq <- function (x, y = 5) 
{
    fcn.mat.vec(qtl, x, y, F)
}

#' qtl.single.grp
#' 
#' performs an equal-weight binning on <x> so that the members of <n> are divided into <y> equal bins
#' @param x = a vector
#' @param y = number of desired bins
#' @param n = a 1/0 membership vector
#' @keywords qtl.single.grp
#' @export
#' @family qtl

qtl.single.grp <- function (x, y, n) 
{
    z <- rep(NA, length(x))
    w <- !is.element(n, 0) & !is.na(n)
    w <- w & !is.na(x)
    if (any(w)) 
        z[w] <- qtl.underlying(x[w], n[w], y)
    w2 <- is.element(n, 0) | is.na(n)
    w2 <- w2 & !is.na(x)
    if (any(w) & any(w2)) 
        z[w2] <- qtl.zero.weight(x[w], z[w], x[w2], y)
    z
}

#' qtl.underlying
#' 
#' divided <x> into <n> equal bins of roughly equal weight (as defined by <y>)
#' @param x = a vector with no NA's
#' @param y = an isomekic vector lacking NA's or zeroes
#' @param n = a positive integer
#' @keywords qtl.underlying
#' @export
#' @family qtl

qtl.underlying <- function (x, y, n) 
{
    if (any(y < 0)) 
        stop("Can't handle negative weights!")
    if (n < 2) 
        stop("Can't do this either!")
    y <- y/sum(y)
    ord <- order(-x)
    x <- x[ord]
    y <- y[ord]
    if (all(y == y[1])) {
        qtl <- ceiling((length(x)/n) * (0:n) + 0.5) - 1
    }
    else {
        qtl <- 0
        for (i in 2:n - 1) qtl <- c(qtl, qtl.weighted(y, i/n))
        qtl <- c(qtl, length(x))
        qtl <- floor(qtl)
    }
    qtl <- qtl[-1] - qtl[-(n + 1)]
    z <- rep(1:n, qtl)
    z <- z[order(ord)]
    z
}

#' qtl.weighted
#' 
#' returns a number <z> so that the sum of x[1:z] is as close as possible to <y>.
#' @param x = an isomekic vector, lacking NA's or zeroes, that sums to unity
#' @param y = a number between zero and one
#' @keywords qtl.weighted
#' @export
#' @family qtl

qtl.weighted <- function (x, y) 
{
    beg <- 0
    end <- 1 + length(x)
    while (end > beg + 1) {
        z <- floor((beg + end)/2)
        if (sum(x[1:z]) - x[z]/2 >= y) 
            end <- z
        else beg <- z
    }
    z <- (beg + end)/2
    z
}

#' qtl.zero.weight
#' 
#' assigns the members of <x> to bins
#' @param x = a vector of variables
#' @param y = a corresponding vector of bin assignments
#' @param n = a vector of variables that are to be assigned to bins
#' @param w = number of bins to divide <x> into
#' @keywords qtl.zero.weight
#' @export
#' @family qtl

qtl.zero.weight <- function (x, y, n, w) 
{
    z <- approx(x, y, n, "constant", yleft = 1, yright = w)$y
    z <- ifelse(is.na(z), max(y), z)
    z
}

#' qtr.ex.int
#' 
#' returns a vector of <yyyymm> months
#' @param x = a vector of integers
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

#' qtr.seq
#' 
#' returns a sequence of QTR between (and including) x and y
#' @param x = a QTR
#' @param y = a QTR
#' @param n = quantum size in QTR
#' @keywords qtr.seq
#' @export
#' @family qtr

qtr.seq <- function (x, y, n = 1) 
{
    obj.seq(x, y, qtr.to.int, qtr.ex.int, n)
}

#' qtr.to.int
#' 
#' returns a vector of integers
#' @param x = a vector of <qtr>
#' @keywords qtr.to.int
#' @export
#' @family qtr

qtr.to.int <- function (x) 
{
    z <- as.numeric(substring(x, 1, 4))
    z <- 4 * z + as.numeric(substring(x, 6, 6))
    z
}

#' read.EPFR
#' 
#' reads in the file
#' @param x = a path to a file written by the dev team
#' @keywords read.EPFR
#' @export
#' @family read

read.EPFR <- function (x) 
{
    z <- read.table(x, T, "\t", row.names = NULL, quote = "", 
        as.is = T, na.strings = txt.na(), comment.char = "")
    names(z)[1] <- "ReportDate"
    z$ReportDate <- yyyymmdd.ex.txt(z$ReportDate)
    z
}

#' read.prcRet
#' 
#' returns the contents of the file
#' @param x = an object name (preceded by #) or the path to a ".csv" file
#' @keywords read.prcRet
#' @export
#' @family read

read.prcRet <- function (x) 
{
    if (txt.left(x, 1) == "#") {
        z <- substring(x, 2, nchar(x))
        z <- get(z)
    }
    else z <- mat.read(x)
    z
}

#' read.split.adj.prices
#' 
#' reads the split-adjusted prices that Matt provides
#' @param x = full path to a file that has the following columns: a) PRC containing raw prices b) CFACPR containing split factor that you divide PRC by c) CUSIP containing eight-digit cusip d) date containing date in yyyymmdd format
#' @param y = classif file
#' @keywords read.split.adj.prices
#' @export
#' @family read

read.split.adj.prices <- function (x, y) 
{
    z <- mat.read(x, , NULL)
    z$date <- as.character(z$date)
    z <- mat.subset(z, c("date", "CUSIP", "PRC", "CFACPR"))
    z$PRC <- z$PRC/nonneg(z$CFACPR)
    z <- mat.subset(z, c("CUSIP", "date", "PRC"))
    z <- mat.to.matrix(z)
    n <- paste("isin", 1:3, sep = "")
    w <- rep(y$CCode, length(n))
    n <- as.character(unlist(y[, n]))
    w <- is.element(w, c("US", "CA")) & nchar(n) == 12 & txt.left(n, 
        2) == w
    n <- n[w]
    n <- n[is.element(substring(n, 3, 10), dimnames(z)[[1]])]
    if (any(duplicated(substring(n, 3, 10)))) 
        stop("Haven't handled this")
    names(n) <- substring(n, 3, 10)
    z <- map.rname(z, names(n))
    dimnames(z)[[1]] <- as.character(n)
    z
}

#' refresh.predictors
#' 
#' refreshes the text file contains flows data from SQL
#' @param path = csv file containing the predictors
#' @param sql.query = query needed to get full history
#' @param sql.end.stub = last part of the query that goes after the date restriction
#' @param connection.type = one of StockFlows/Regular/Quant
#' @param ignore.data.changes = T/F depending on whether you want changes in data to be ignored
#' @param date.field = column corresponding to date in relevant sql table
#' @param publish.fcn = a function that returns the last complete publication period
#' @keywords refresh.predictors
#' @export
#' @family refresh

refresh.predictors <- function (path, sql.query, sql.end.stub, connection.type, ignore.data.changes, 
    date.field, publish.fcn) 
{
    last.date <- file.to.last(path)
    if (last.date < publish.fcn()) {
        z <- refresh.predictors.script(sql.query, sql.end.stub, 
            date.field, last.date)
        z <- sql.query(z, connection.type)
        x <- mat.read(path)
        z <- refresh.predictors.append(x, z, ignore.data.changes, 
            F)
    }
    else {
        cat("There is no need to update the data ...\n")
        z <- NULL
    }
    z
}

#' refresh.predictors.append
#' 
#' Appends new to old data after performing checks
#' @param x = old data
#' @param y = new data
#' @param n = T/F depending on whether you want changes in data to be ignored
#' @param w = T/F depending on whether the data already have row names
#' @keywords refresh.predictors.append
#' @export
#' @family refresh

refresh.predictors.append <- function (x, y, n = F, w = F) 
{
    if (!w) 
        y <- mat.index(y)
    if (dim(y)[2] != dim(x)[2]) 
        stop("Problem 3")
    if (any(!is.element(dimnames(y)[[2]], dimnames(x)[[2]]))) 
        stop("Problem 4")
    z <- y[, dimnames(x)[[2]]]
    w <- is.element(dimnames(z)[[1]], dimnames(x)[[1]])
    if (sum(w) != 1) 
        stop("Problem 5")
    m <- data.frame(unlist(z[w, ]), unlist(x[dimnames(z)[[1]][w], 
        ]))
    m <- correl(m[, 1], m[, 2])
    m <- zav(m)
    if (!n & m < 0.99) 
        stop("Problem: Correlation between new and old data is", 
            round(100 * m), "!")
    z <- rbind(x, z[!w, ])
    z <- z[order(dimnames(z)[[1]]), ]
    last.date <- dimnames(z)[[1]][dim(z)[1]]
    cat("Final data have", dim(z)[1], "rows ending at", last.date, 
        "...\n")
    z
}

#' refresh.predictors.daily
#' 
#' refreshes the text file contains flows data from SQL
#' @param x = csv file containing the predictors
#' @param y = query needed to get full history
#' @param n = last part of the query that goes after the date restriction
#' @param w = one of StockFlows/Regular/Quant
#' @param h = T/F depending on whether you want changes in data to be ignored
#' @keywords refresh.predictors.daily
#' @export
#' @family refresh

refresh.predictors.daily <- function (x, y, n, w, h = F) 
{
    refresh.predictors(x, y, n, w, h, "DayEnding", publish.daily.last)
}

#' refresh.predictors.monthly
#' 
#' refreshes the text file contains flows data from SQL
#' @param x = csv file containing the predictors
#' @param y = query needed to get full history
#' @param n = last part of the query that goes after the date restriction
#' @param w = one of StockFlows/Regular/Quant
#' @param h = when T, ignores the fact that data for the last row has changed
#' @keywords refresh.predictors.monthly
#' @export
#' @family refresh

refresh.predictors.monthly <- function (x, y, n, w, h) 
{
    refresh.predictors(x, y, n, w, h, "WeightDate", publish.monthly.last)
}

#' refresh.predictors.script
#' 
#' generates the SQL script to refresh predictors
#' @param x = query needed to get full history
#' @param y = last part of the query that goes after the date restriction
#' @param n = column corresponding to date in relevant sql table
#' @param w = last date for which you already have data
#' @keywords refresh.predictors.script
#' @export
#' @family refresh

refresh.predictors.script <- function (x, y, n, w) 
{
    paste(txt.left(x, nchar(x) - nchar(y)), "where\n\t", n, " >= '", 
        w, "'\n", y, sep = "")
}

#' refresh.predictors.weekly
#' 
#' refreshes the text file contains flows data from SQL
#' @param x = csv file containing the predictors
#' @param y = query needed to get full history
#' @param n = last part of the query that goes after the date restriction
#' @param w = one of StockFlows/Regular/Quant
#' @param h = T/F depending on whether you want changes in data to be ignored
#' @keywords refresh.predictors.weekly
#' @export
#' @family refresh

refresh.predictors.weekly <- function (x, y, n, w, h = F) 
{
    refresh.predictors(x, y, n, w, h, "WeekEnding", publish.weekly.last)
}

#' renorm
#' 
#' renormalizes, so the absolute weights sum to 100, <x>, if a vector, or the rows of <x> otherwise
#' @param x = a numeric vector
#' @keywords renorm
#' @export

renorm <- function (x) 
{
    fcn <- function(x) 100 * x/excise.zeroes(sum(abs(x)))
    fcn2 <- function(x) fcn.nonNA(fcn, x)
    z <- fcn.mat.vec(fcn2, x, , F)
    z
}

#' ret.ex.idx
#' 
#' computes return
#' @param x = a file of total return indices indexed so that time runs forward
#' @param y = number of periods over which the return is computed
#' @param n = if T simple positional lagging is used. If F, yyyymm.lag is invoked.
#' @param w = if T the result is labelled by the beginning of the period, else by the end.
#' @keywords ret.ex.idx
#' @export
#' @family ret

ret.ex.idx <- function (x, y, n, w) 
{
    z <- mat.lag(x, y, n)
    z <- 100 * x/z - 100
    if (w) 
        z <- mat.lag(z, -y, n)
    z
}

#' ret.idx.gaps.fix
#' 
#' replaces NA's by latest available total return index (i.e. zero return over that period)
#' @param x = a file of total return indices indexed by <yyyymmdd> dates so that time runs forward
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
#' @param x = a file of total returns indexed so that time runs forward
#' @keywords ret.to.idx
#' @export
#' @family ret

ret.to.idx <- function (x) 
{
    z <- x
    for (i in dimnames(z)[[2]]) {
        w <- !is.na(z[, i])
        n <- find.data(w, T)
        m <- find.data(w, F)
        if (n > 1) 
            n <- n - 1
        z[n, i] <- 100
        while (n < m) {
            n <- n + 1
            z[n, i] <- (1 + zav(z[n, i])/100) * z[n - 1, i]
        }
    }
    z
}

#' ret.to.log
#' 
#' converts to logarithmic return
#' @param x = a vector of returns
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
#' @param x = a vector of length three containing numbers between 0 and 256
#' @param y = a vector of length three containing numbers between 0 and 256
#' @keywords rgb.diff
#' @export

rgb.diff <- function (x, y) 
{
    z <- (x[1] + y[1])/2
    z <- c(z/256, 2, 1 - z/256) + 2
    z <- sqrt(sum(z * (x - y)^2))
    z
}

#' rrw
#' 
#' regression results
#' @param prdBeg = a first-return date in yyyymm format representing the first month of the backtest
#' @param prdEnd = a first-return date in yyyymm format representing the last month of the backtest
#' @param vbls = vector of variables against which return is to be regressed
#' @param univ = universe (e.g. "R1Mem")
#' @param grp.nm = neutrality group (e.g. "GSec")
#' @param ret.nm = return variable (e.g. "Ret")
#' @param fldr = stock-flows folder
#' @param orth.factor = factor to orthogonalize all variables to (e.g. "PrcMo")
#' @param classif = classif file
#' @keywords rrw
#' @export
#' @family rrw

rrw <- function (prdBeg, prdEnd, vbls, univ, grp.nm, ret.nm, fldr, orth.factor = NULL, 
    classif) 
{
    dts <- yyyymm.seq(prdBeg, prdEnd)
    df <- NULL
    for (i in dts) {
        if (txt.right(i, 2) == "01") 
            cat("\n", i, "")
        else cat(txt.right(i, 2), "")
        x <- rrw.underlying(i, vbls, univ, grp.nm, ret.nm, fldr, 
            orth.factor, classif)
        x <- mat.subset(x, c("ret", vbls))
        dimnames(x)[[1]] <- paste(i, dimnames(x)[[1]])
        if (is.null(df)) 
            df <- x
        else df <- rbind(df, x)
    }
    z <- list(value = map.rname(rrw.factors(df), vbls), corr = correl(df), 
        data = df)
    z
}

#' rrw.factors
#' 
#' Returns the t-values of factors that best predict return
#' @param x = a data frame, the first column of which has returns
#' @keywords rrw.factors
#' @export
#' @family rrw

rrw.factors <- function (x) 
{
    y <- dimnames(x)[[2]]
    names(y) <- fcn.vec.num(col.ex.int, 1:dim(x)[2])
    dimnames(x)[[2]] <- names(y)
    z <- summary(lm(txt.regr(dimnames(x)[[2]]), x))$coeff[-1, 
        "t value"]
    while (any(z < 0)) {
        x <- x[, !is.element(dimnames(x)[[2]], names(z)[order(z)][1])]
        z <- summary(lm(txt.regr(dimnames(x)[[2]]), x))$coeff[, 
            "t value"][-1]
    }
    names(z) <- map.rname(y, names(z))
    z
}

#' rrw.underlying
#' 
#' Runs regressions
#' @param prd = a first-return date in yyyymm format representing the return period of interest
#' @param vbls = vector of variables against which return is to be regressed
#' @param univ = universe (e.g. "R1Mem")
#' @param grp.nm = neutrality group (e.g. "GSec")
#' @param ret.nm = return variable (e.g. "Ret")
#' @param fldr = parent directory containing derived/data
#' @param orth.factor = factor to orthogonalize all variables to (e.g. "PrcMo")
#' @param classif = classif file
#' @keywords rrw.underlying
#' @export
#' @family rrw

rrw.underlying <- function (prd, vbls, univ, grp.nm, ret.nm, fldr, orth.factor, 
    classif) 
{
    z <- fetch(c(vbls, orth.factor), yyyymm.lag(prd, 1), 1, paste(fldr, 
        "\\derived", sep = ""), classif)
    z$grp <- classif[, grp.nm]
    z$mem <- fetch(univ, yyyymm.lag(prd, 1), 1, paste(fldr, "\\data", 
        sep = ""), classif)
    z$ret <- fetch(ret.nm, prd, 1, paste(fldr, "\\data", sep = ""), 
        classif)
    z <- mat.last.to.first(z)
    for (j in c(vbls, orth.factor)) z[, j] <- vec.zScore(z[, 
        j], z$mem, z$grp)
    z <- z[is.element(z$mem, 1) & !is.na(z$grp), ]
    if (!is.null(orth.factor)) {
        z[, orth.factor] <- zav(z[, orth.factor])
        for (j in vbls) {
            w <- !is.na(z[, j])
            z[w, j] <- as.numeric(summary(lm(txt.regr(c(j, orth.factor)), 
                z[w, ]))$residuals)
            z[, j] <- vec.zScore(z[, j], z$mem, z$grp)
        }
    }
    w <- rep(F, dim(z)[1])
    for (j in vbls) w <- w | !is.na(z[, j])
    w <- w & !is.na(z$ret)
    z <- z[w, ]
    z <- zav(z)
    z$ret <- z$ret - mean(z$ret)
    z
}

#' run.cs.reg
#' 
#' regresses each row of <x> on design matrix <y>
#' @param x = a matrix of n columns (usually stocks go down and returns go across)
#' @param y = a matrix of n rows (whatever vectors you're regressing on)
#' @keywords run.cs.reg
#' @export

run.cs.reg <- function (x, y) 
{
    y <- as.matrix(y)
    y <- solve(t(y) %*% y) %*% t(y)
    z <- y %*% t(x)
    z <- t(z)
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
    z <- proc.time()[["elapsed"]] - x
    z <- round(z)
    z <- base.ex.int(z, 60)
    n <- length(z)
    if (n > 3) {
        z <- c(base.to.int(z[3:n - 2], 60), z[n - 1:0])
        n <- 3
    }
    while (n < 3) {
        z <- c(0, z)
        n <- n + 1
    }
    z <- paste(txt.right(100 + z, 2), collapse = ":")
    z
}

#' sf
#' 
#' runs a stock-flows simulation
#' @param prdBeg = first-return date in YYYYMM
#' @param prdEnd = first-return date in YYYYMM after <prdBeg>
#' @param vbl.nm = variable
#' @param univ = membership (e.g. "EafeMem" or c("GemMem", 1))
#' @param grp.nm = group within which binning is to be performed
#' @param ret.nm = return variable
#' @param trails = number of trailing periods to compound/sum over
#' @param sum.flows = T/F depending on whether you want flows summed or compounded.
#' @param fldr = data folder
#' @param dly.vbl = if T then a daily predictor is assumed else a monthly one
#' @param vbl.lag = lags by <vbl.lag> weekdays or months depending on whether <dly.vbl> is true.
#' @param nBins = number of bins
#' @param reverse.vbl = T/F depending on whether you want the variable reversed
#' @param geom.comp = T/F depending on whether you want bin excess returns summarized geometrically or arithmetically
#' @param retHz = forward return horizon in months
#' @param classif = classif file
#' @keywords sf
#' @export
#' @family sf

sf <- function (prdBeg, prdEnd, vbl.nm, univ, grp.nm, ret.nm, trails, 
    sum.flows, fldr, dly.vbl = T, vbl.lag = 0, nBins = 5, reverse.vbl = F, 
    geom.comp = F, retHz = 1, classif) 
{
    n.trail <- length(trails)
    if (geom.comp) 
        summ.fcn <- bbk.bin.rets.geom.summ
    else summ.fcn <- bbk.bin.rets.summ
    for (j in 1:n.trail) {
        cat(trails[j], "")
        if (j%%10 == 0) 
            cat("\n")
        x <- sf.single.bsim(prdBeg, prdEnd, vbl.nm, univ, grp.nm, 
            ret.nm, fldr, dly.vbl, trails[j], sum.flows, vbl.lag, 
            T, nBins, reverse.vbl, retHz, classif)
        x <- t(map.rname(t(x), c(dimnames(x)[[2]], "TxB")))
        x[, "TxB"] <- x[, "Q1"] - x[, paste("Q", nBins, sep = "")]
        x <- mat.ex.matrix(x)
        if (j == 1) {
            z <- dimnames(summ.fcn(x, 12))[[1]]
            z <- array(NA, c(length(z), dim(x)[2], n.trail), 
                list(z, dimnames(x)[[2]], trails))
        }
        z[, , j] <- sf.summ(summ.fcn, x, retHz)
    }
    cat("\n")
    z
}

#' sf.bin.nms
#' 
#' returns bin names
#' @param x = number of bins
#' @param y = T/F depending on whether you want universe returns returned
#' @keywords sf.bin.nms
#' @export
#' @family sf

sf.bin.nms <- function (x, y) 
{
    z <- c(1:x, "na")
    z <- z[order(c(1:x, x/2 + 0.25))]
    z <- paste("Q", z, sep = "")
    if (y) 
        z <- c(z, "uRet")
    z
}

#' sf.daily
#' 
#' runs stock-flows simulation
#' @param prdBeg = first-return date in YYYYMMDD
#' @param prdEnd = first-return date in YYYYMMDD (must postdate <prdBeg>)
#' @param vbl.nm = variable
#' @param univ = membership (e.g. "EafeMem" or c("GemMem", 1))
#' @param grp.nm = group within which binning is to be performed
#' @param ret.nm = return variable
#' @param trail = number of trailing periods to compound/sum over
#' @param sum.flows = T/F depending on whether you want flows summed or compounded.
#' @param fldr = data folder
#' @param vbl.lag = lags by <vbl.lag> weekdays or months depending on whether <dly.vbl> is true.
#' @param dly.vbl = whether the predictor is daily or monthly
#' @param retHz = forward return horizon in days
#' @param classif = classif file
#' @keywords sf.daily
#' @export
#' @family sf

sf.daily <- function (prdBeg, prdEnd, vbl.nm, univ, grp.nm, ret.nm, trail, 
    sum.flows, fldr, vbl.lag, dly.vbl, retHz, classif) 
{
    grp <- classif[, grp.nm]
    dts <- yyyymm.seq(prdBeg, prdEnd)
    dts <- dts[!is.element(dts, nyse.holidays())]
    m <- length(dts)
    dts <- vec.named(c(yyyymmdd.diff(dts[seq(retHz + 1, m)], 
        dts[seq(1, m - retHz)]), rep(retHz, retHz)), dts)
    x <- sf.bin.nms(5, F)
    x <- matrix(NA, m, length(x), F, list(names(dts), x))
    for (i in 1:dim(x)[1]) {
        if (i%%10 == 0) 
            cat(dimnames(x)[[1]][i], "")
        if (i%%100 == 0) 
            cat("\n")
        i.dt <- dimnames(x)[[1]][i]
        vec <- sf.underlying(vbl.nm, univ, ret.nm, i.dt, trail, 
            sum.flows, grp, dly.vbl, 5, fldr, vbl.lag, F, F, 
            dts[i.dt], classif)
        vec <- map.rname(vec, dimnames(x)[[2]])
        x[i.dt, ] <- as.numeric(vec)
    }
    cat("\n")
    x <- mat.ex.matrix(x)
    x$TxB <- x[, 1] - x[, dim(x)[2]]
    x <- mat.last.to.first(x)
    if (retHz > 1) {
        y <- NULL
        for (offset in 1:retHz - 1) {
            w <- 1:dim(x)[1]%%retHz == offset
            z <- bbk.bin.rets.summ(x[w, ], 250/retHz)
            if (is.null(y)) 
                y <- array(NA, c(dim(z), retHz), list(dimnames(z)[[1]], 
                  dimnames(z)[[2]], 1:retHz - 1))
            y[, , as.character(offset)] <- unlist(z)
        }
        z <- apply(y, 1:2, mean)
    }
    else z <- bbk.bin.rets.summ(x, 250/retHz)
    z
}

#' sf.single.bsim
#' 
#' runs a single quintile simulation
#' @param prdBeg = first-return date in YYYYMM
#' @param prdEnd = first-return date in YYYYMM after <prdBeg>
#' @param vbl.nm = variable
#' @param univ = membership (e.g. "EafeMem" or c("GemMem", 1))
#' @param grp.nm = group within which binning is to be performed
#' @param ret.nm = return variable
#' @param fldr = data folder
#' @param dly.vbl = T/F depending on whether the variable used is daily or monthly
#' @param trail = number of trailing periods to compound/sum over
#' @param sum.flows = if T, flows get summed. Otherwise they get compounded.
#' @param vbl.lag = lags by <vbl.lag> weekdays or months depending on whether <dly.vbl> is true.
#' @param uRet = T/F depending on whether the equal-weight universe return is desired
#' @param nBins = number of bins
#' @param reverse.vbl = T/F depending on whether you want the variable reversed
#' @param retHz = forward return horizon in months
#' @param classif = classif file
#' @keywords sf.single.bsim
#' @export
#' @family sf

sf.single.bsim <- function (prdBeg, prdEnd, vbl.nm, univ, grp.nm, ret.nm, fldr, 
    dly.vbl = F, trail = 1, sum.flows = T, vbl.lag = 0, uRet = F, 
    nBins = 5, reverse.vbl = F, retHz = 1, classif) 
{
    grp <- classif[, grp.nm]
    z <- sf.bin.nms(nBins, uRet)
    dts <- yyyymm.seq(prdBeg, prdEnd)
    z <- matrix(NA, length(dts), length(z), F, list(dts, z))
    for (i in dimnames(z)[[1]]) {
        vec <- sf.underlying(vbl.nm, univ, ret.nm, i, trail, 
            sum.flows, grp, dly.vbl, nBins, fldr, vbl.lag, uRet, 
            reverse.vbl, retHz, classif)
        z[i, ] <- map.rname(vec, dimnames(z)[[2]])
    }
    z
}

#' sf.subset
#' 
#' Returns a 1/0 mem vector
#' @param x = membership (e.g. "EafeMem" or c("GemMem", 1))
#' @param y = a YYYYMM or YYYYMMDD
#' @param n = folder in which to find the data
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
    z <- as.numeric(z)
    z
}

#' sf.summ
#' 
#' summarizes the back test
#' @param fcn = a function that summarizes the data
#' @param x = a df of bin returns indexed by time
#' @param y = forward return horizon in months
#' @keywords sf.summ
#' @export
#' @family sf

sf.summ <- function (fcn, x, y) 
{
    if (y > 1) {
        z <- NULL
        for (offset in 1:y - 1) {
            w <- 1:dim(x)[1]%%y == offset
            df <- fcn(x[w, ], 12/y)
            if (is.null(z)) 
                z <- array(NA, c(dim(df), y), list(dimnames(df)[[1]], 
                  dimnames(df)[[2]], 1:y - 1))
            z[, , as.character(offset)] <- unlist(df)
        }
        z <- apply(z, 1:2, mean)
    }
    else z <- fcn(x, 12)
    z
}

#' sf.underlying
#' 
#' Creates bin excess returns for a single period
#' @param vbl.nm = variable
#' @param univ = membership (e.g. "EafeMem" or c("GemMem", 1))
#' @param ret.nm = return variable
#' @param ret.prd = the period for which you want returns
#' @param trail = number of trailing periods to compound/sum over
#' @param sum.flows = if T, flows get summed. Otherwise they get compounded.
#' @param grp = group within which binning is to be performed
#' @param dly.vbl = if T then a daily predictor is assumed else a monthly one
#' @param nBins = number of bins
#' @param fldr = data folder
#' @param vbl.lag = lags by <vbl.lag> weekdays or months depending on whether <dly.vbl> is true.
#' @param uRet = T/F depending on whether the equal-weight universe return is desired
#' @param reverse.vbl = T/F depending on whether you want the variable reversed
#' @param retHz = forward return horizon in months
#' @param classif = classif file
#' @keywords sf.underlying
#' @export
#' @family sf

sf.underlying <- function (vbl.nm, univ, ret.nm, ret.prd, trail, sum.flows, grp, 
    dly.vbl, nBins, fldr, vbl.lag, uRet = F, reverse.vbl = F, 
    retHz = 1, classif) 
{
    x <- sf.underlying.data(vbl.nm, univ, ret.nm, ret.prd, trail, 
        sum.flows, grp, dly.vbl, nBins, fldr, vbl.lag, reverse.vbl, 
        retHz, classif)
    z <- sf.underlying.summ(x$bin, x$ret, x$mem, nBins, uRet)
    z
}

#' sf.underlying.data
#' 
#' Gets data needed to back-test a single period
#' @param vbl.nm = variable
#' @param univ = membership (e.g. "EafeMem" or c("GemMem", 1))
#' @param ret.nm = return variable
#' @param ret.prd = the period for which you want returns
#' @param trail = number of trailing periods to compound/sum over
#' @param sum.flows = if T, flows get summed. Otherwise they get compounded.
#' @param grp = group within which binning is to be performed
#' @param dly.vbl = if T then a daily predictor is assumed else a monthly one
#' @param nBins = number of bins
#' @param fldr = data folder
#' @param vbl.lag = lags by <vbl.lag> weekdays or months depending on whether <dly.vbl> is true.
#' @param reverse.vbl = T/F depending on whether you want the variable reversed
#' @param retHz = forward return horizon in months
#' @param classif = classif file
#' @keywords sf.underlying.data
#' @export
#' @family sf

sf.underlying.data <- function (vbl.nm, univ, ret.nm, ret.prd, trail, sum.flows, grp, 
    dly.vbl, nBins, fldr, vbl.lag, reverse.vbl, retHz, classif) 
{
    mem <- sf.subset(univ, ret.prd, fldr, classif)
    vbl <- yyyymm.lag(ret.prd, 1)
    if (dly.vbl & nchar(ret.prd) == 6) 
        vbl <- yyyymmdd.ex.yyyymm(vbl)
    if (!dly.vbl & nchar(ret.prd) == 8) 
        vbl <- yyyymm.lag(yyyymmdd.to.yyyymm(vbl))
    if (vbl.lag > 0) 
        vbl <- yyyymm.lag(vbl, vbl.lag)
    vbl <- fetch(vbl.nm, vbl, trail, paste(fldr, "derived", sep = "\\"), 
        classif)
    if (reverse.vbl) 
        vbl <- -vbl
    if (trail > 1) 
        vbl <- compound.stock.flows(vbl, sum.flows)
    if (retHz == 1) {
        ret <- fetch(ret.nm, ret.prd, 1, paste(fldr, "data", 
            sep = "\\"), classif)
    }
    else {
        ret <- fetch(ret.nm, yyyymm.lag(ret.prd, 1 - retHz), 
            retHz, paste(fldr, "data", sep = "\\"), classif)
        ret <- mat.compound(ret)
    }
    bin <- qtl(vbl, nBins, mem, grp)
    bin <- ifelse(is.na(bin), "Qna", paste("Q", bin, sep = ""))
    z <- data.frame(vbl, bin, ret, mem, grp)
    dimnames(z)[[1]] <- dimnames(classif)[[1]]
    z
}

#' sf.underlying.summ
#' 
#' Returns a named vector of bin returns
#' @param x = vector of bins
#' @param y = corresponding numeric vector of forward returns
#' @param n = corresponding 1/0 universe membership vector
#' @param w = number of bins
#' @param h = T/F variable controlling whether universe return is returned
#' @keywords sf.underlying.summ
#' @export
#' @family sf

sf.underlying.summ <- function (x, y, n, w, h) 
{
    n <- is.element(n, 1) & !is.na(y)
    if (any(n)) {
        univ.eq.wt.ret <- mean(y[n])
        y <- y - univ.eq.wt.ret
        z <- pivot.1d(mean, x[n], y[n])
    }
    else {
        univ.eq.wt.ret <- NA
        z <- c(1:w, "na")
        z <- paste("Q", z, sep = "")
        z <- vec.named(rep(NA, length(z)), z)
    }
    if (h) 
        z["uRet"] <- univ.eq.wt.ret
    z
}

#' smear.Q1
#' 
#' Returns weights associated with ranks 1:x so that a) every position in the top quintile has an equal positive weight b) every position in the bottom 3 quintiles has an equal negative weight c) second quintile positions get a linear interpolation d) the weights sum to zero e) the positive weights sum to 100
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

#' sql.1dActWtTrend
#' 
#' the SQL query to get 1dActWtTrend
#' @param x = the YYYYMMDD for which you want flows (known one day later)
#' @param y = a string vector of factors to be computed, the last element of which is the type of fund used.
#' @param n = any of StockFlows/Japan/CSI300/Energy
#' @keywords sql.1dActWtTrend
#' @export
#' @family sql

sql.1dActWtTrend <- function (x, y, n) 
{
    m <- length(y)
    z <- sql.1dActWtTrend.underlying(x, y[m], sql.RDSuniv(n))
    z <- c(z, sql.1dActWtTrend.topline(y[-m]))
    z
}

#' sql.1dActWtTrend.Ctry.underlying
#' 
#' Generates the SQL query
#' @param x = a string vector indexed by allocation-table names
#' @param y = the SQL table from which you get flows (DailyData/MonthlyData)
#' @param n = one of Ctry/FX/Sector
#' @keywords sql.1dActWtTrend.Ctry.underlying
#' @export
#' @family sql

sql.1dActWtTrend.Ctry.underlying <- function (x, y, n) 
{
    z <- c(sql.label(sql.FundHistory("", "CBE", F, c("FundId", 
        "GeographicFocus")), "t0"), "inner join")
    z <- c(z, paste(y, " t1", sep = ""), "\ton t1.HFundId = t0.HFundId", 
        "inner join")
    z <- c(z, sql.label(sql.1dFloMo.Ctry.Allocations(x, n), "t2"), 
        "\ton t2.FundId = t0.FundId")
    if (y == "MonthlyData") {
        z <- c(z, paste("\t\tand t2.WeightDate =", sql.floTbl.to.Col(y, 
            F)))
    }
    else z <- c(z, paste("\t\tand", sql.datediff("WeightDate", 
        sql.floTbl.to.Col(y, F), 23)))
    z <- c(z, "inner join", sql.label(sql.1dFloMo.Ctry.Allocations.GF.avg(x, 
        n), "t3"))
    z <- c(z, "\ton t3.GeographicFocus = t0.GeographicFocus and t3.WeightDate = t2.WeightDate")
    z
}

#' sql.1dActWtTrend.topline
#' 
#' SQL query to get the select statement for 1dActWtTrend
#' @param x = a string vector of factors to be computed,
#' @keywords sql.1dActWtTrend.topline
#' @export
#' @family sql

sql.1dActWtTrend.topline <- function (x) 
{
    z <- "SecurityId"
    for (i in x) {
        if (i == "ActWtTrend") {
            z <- c(z, paste("ActWtTrend", sql.Trend("Flow * (hld.HoldingValue/aum.PortVal - FundWtdExcl0)")))
        }
        else if (i == "ActWtDiff") {
            z <- c(z, paste("ActWtDiff", sql.Diff("Flow", "hld.HoldingValue/aum.PortVal - FundWtdExcl0")))
        }
        else if (i == "ActWtDiff2") {
            z <- c(z, paste("ActWtDiff2", sql.Diff("hld.HoldingValue/aum.PortVal - FundWtdExcl0", 
                "Flow")))
        }
        else stop("Bad Argument")
    }
    w <- "HSecurityId, GeographicFocusId, FundWtdExcl0 = sum(HoldingValue)/sum(case when HoldingValue is not null then PortVal else NULL end)"
    x <- c("FundHistory t1", "inner join", "#HLD t2 on t2.HFundId = t1.HFundId", 
        "inner join", "#AUM t3 on t3.HFundId = t1.HFundId")
    h <- "sum(case when HoldingValue is not null then PortVal else NULL end) > 0"
    w <- sql.label(sql.tbl(w, x, , "HSecurityId, GeographicFocusId", 
        h), "mnW")
    x <- c("#FLO flo", "inner join", "FundHistory his on his.HFundId = flo.HFundId", 
        "inner join")
    x <- c(x, "#HLD hld on hld.FundId = his.FundId", "inner join", 
        "#AUM aum on aum.HFundId = hld.HFundId", "inner join")
    x <- c(x, "SecurityHistory id on id.HSecurityId = hld.HSecurityId", 
        "inner join")
    x <- c(x, w, "\ton mnW.HSecurityId = hld.HSecurityId and mnW.GeographicFocusId = his.GeographicFocusId")
    z <- paste(sql.unbracket(sql.tbl(z, x, , "SecurityId")), 
        collapse = "\n")
    z
}

#' sql.1dActWtTrend.underlying
#' 
#' the SQL query to get the data for 1dActWtTrend
#' @param x = the YYYYMMDD for which you want flows (known one day later)
#' @param y = the type of fund used in the computation
#' @param n = SQL query to subset to securities desired
#' @keywords sql.1dActWtTrend.underlying
#' @export
#' @family sql

sql.1dActWtTrend.underlying <- function (x, y, n) 
{
    mo.end <- yyyymmdd.to.AllocMo(x, 26)
    mo.end <- yyyymm.to.day(mo.end)
    z <- c(paste("drop table", c("#AUM", "#HLD", "#FLO")), "", 
        sql.DailyFlo(paste("'", x, "'", sep = ""), "#FLO"))
    z <- c(z, "", "create table #AUM (HFundId int not null, PortVal float not null)", 
        "create clustered index TempRandomIndex ON #AUM(HFundId)")
    w <- list(A = paste("ReportDate = '", mo.end, "'", sep = ""))
    if (y == "Act") 
        w[["B"]] <- sql.in("HFundId", sql.FundHistory("", "Act", 
            T))
    w <- sql.unbracket(sql.tbl("HFundId, PortVal = sum(AssetsEnd)", 
        "MonthlyData", sql.and(w), "HFundId", "sum(AssetsEnd) > 0"))
    z <- c(z, "insert into", "\t#AUM (HFundId, PortVal)", w)
    w <- sql.in("HFundId", sql.tbl("HFundId", "#FLO"))
    w <- sql.in("FundId", sql.tbl("FundId", "FundHistory", w))
    w <- list(A = w, B = sql.in("HSecurityId", n), C = paste("datediff(month, ReportDate, '", 
        mo.end, "') = 0", sep = ""))
    z <- c(z, "", sql.Holdings(sql.and(w), c("FundId", "HFundId", 
        "HSecurityId", "HoldingValue"), "#HLD"), "")
    z <- paste(z, collapse = "\n")
    z
}

#' sql.1dFloMo
#' 
#' Generates the SQL query to get the data for 1dFloMo for individual stocks
#' @param x = the date for which you want flows (known one day later)
#' @param y = either "All" or "Act" or "CBE"
#' @param n = any of StockFlows/Japan/CSI300/Energy
#' @keywords sql.1dFloMo
#' @export
#' @family sql

sql.1dFloMo <- function (x, y, n) 
{
    x <- sql.declare(c("@floDt", "@allocDt"), "datetime", c(x, 
        yyyymm.to.day(yyyymmdd.to.AllocMo(x, 26))))
    z <- c(sql.label(sql.FundHistory("", y, T, "FundId"), "t0"), 
        "inner join", sql.label(sql.MonthlyAlloc("@allocDt"), 
            "t1"))
    z <- c(z, "\ton t1.FundId = t0.FundId", "inner join", sql.label(sql.DailyFlo("@floDt"), 
        "t2"), "\ton t2.HFundId = t0.HFundId")
    z <- c(z, "inner join", sql.label(sql.MonthlyAssetsEnd("@allocDt"), 
        "t3"), "\ton t3.HFundId = t1.HFundId", "inner join")
    z <- c(z, "SecurityHistory id", "\ton id.HSecurityId = t1.HSecurityId")
    y <- paste("SecurityId, ", ifelse(y == "CBE", "FloMoCB", 
        "FloMo"), " ", sql.Mo("Flow", "AssetsStart", "HoldingValue/AssetsEnd", 
        F), sep = "")
    z <- sql.tbl(y, z, sql.in("t1.HSecurityId", sql.RDSuniv(n)), 
        "SecurityId", "sum(AssetsStart * HoldingValue/AssetsEnd) > 0")
    z <- paste(c(x, sql.unbracket(z)), collapse = "\n")
    z
}

#' sql.1dFloMo.Ctry
#' 
#' Generates the SQL query to get daily 1dFloMo for countries
#' @param x = Ctry/FX/Sector
#' @keywords sql.1dFloMo.Ctry
#' @export
#' @family sql

sql.1dFloMo.Ctry <- function (x) 
{
    w <- sql.1dFloMo.Ctry.List(x)
    z <- paste("[", w[!duplicated(w)], "]", sep = "")
    x <- sql.1dFloMo.Ctry.Allocations(w, x)
    z <- paste(z, sql.Mo("Flow", "AssetsStart", z, T))
    z <- c("DayEnding = convert(char(8), DayEnding, 112)", z)
    w <- c(sql.label(sql.FundHistory("", "CBE", F, "FundId"), 
        "t0"), "inner join", "DailyData t1 on t1.HFundId = t0.HFundId", 
        "inner join")
    w <- c(w, sql.label(x, "t2"), "\ton t2.FundId = t0.FundId", 
        paste("\tand ", sql.datediff("WeightDate", "DayEnding", 
            23), sep = ""))
    z <- paste(sql.unbracket(sql.tbl(z, w, , "DayEnding")), collapse = "\n")
    z
}

#' sql.1dFloMo.Ctry.Allocations
#' 
#' Generates the SQL query to get daily 1dFloMo for countries
#' @param x = a string vector indexed by allocation-table names
#' @param y = one of Ctry/FX/Sector
#' @keywords sql.1dFloMo.Ctry.Allocations
#' @export
#' @family sql

sql.1dFloMo.Ctry.Allocations <- function (x, y) 
{
    u.grp <- x[!duplicated(x)]
    z <- c("FundId", "WeightDate")
    for (i in u.grp) {
        w <- x == i
        if (sum(w) > 1) {
            z <- c(z, paste("[", x[w][1], "] = ", paste(paste("isnull(", 
                names(x)[w], ", 0)", sep = ""), collapse = " + "), 
                sep = ""))
        }
        else z <- c(z, paste("[", x[w], "] = ", names(x)[w], 
            sep = ""))
    }
    z <- sql.tbl(z, sql.AllocTbl(y))
    z
}

#' sql.1dFloMo.Ctry.Allocations.GF.avg
#' 
#' Generates the SQL query to get daily 1dFloMo for countries
#' @param x = a string vector indexed by allocation-table names
#' @param y = one of Ctry/FX/Sector
#' @keywords sql.1dFloMo.Ctry.Allocations.GF.avg
#' @export
#' @family sql

sql.1dFloMo.Ctry.Allocations.GF.avg <- function (x, y) 
{
    y <- c(paste(sql.AllocTbl(y), "x"), "inner join", "FundHistory y", 
        "\ton x.HFundId = y.HFundId")
    u.grp <- x[!duplicated(x)]
    z <- c("WeightDate", "GeographicFocus")
    for (i in u.grp) {
        w <- x == i
        if (sum(w) > 1) {
            z <- c(z, paste("[", x[w][1], "] = sum((", paste(paste("isnull(", 
                names(x)[w], ", 0)", sep = ""), collapse = " + "), 
                ") * FundSize)/sum(FundSize)", sep = ""))
        }
        else z <- c(z, paste("[", x[w], "] = sum(", names(x)[w], 
            " * FundSize)/sum(FundSize)", sep = ""))
    }
    z <- sql.tbl(z, y, "FundType = 'E'", "WeightDate, GeographicFocus")
    z
}

#' sql.1dFloMo.Ctry.List
#' 
#' Generates the SQL query to get daily 1dFloMo for countries
#' @param x = One of Ctry/FX/Sector/UBS/EMDM
#' @keywords sql.1dFloMo.Ctry.List
#' @export
#' @family sql

sql.1dFloMo.Ctry.List <- function (x) 
{
    EMU <- Ctry.msci.members("EMU", "")
    EM <- Ctry.msci.members("EM", "201706")
    EAFE <- Ctry.msci.members("EAFE", "201706")
    classif.type <- x
    if (x == "Ctry" | x == "EMDM") {
        z <- Ctry.msci.members.rng("ACWI", "200704", "201706")
        classif.type <- "Ctry"
    }
    else if (x == "FX") {
        z <- c(EAFE, EM, "CA", "US", "AR", "MA", "CY", "EE", 
            "LV", "LT", "SK", "SI")
        z <- setdiff(z, "AE")
        classif.type <- "Ctry"
    }
    else if (x == "UBS") {
        z <- c(EMU, EM, "CA", "US", "AU", "CH", "GB", "JP")
        classif.type <- "Ctry"
    }
    else if (x == "Commerzbank") {
        z <- c(EMU, EM, "US", "JP", "GB")
        classif.type <- "Ctry"
    }
    else if (x == "Sector") 
        z <- dimnames(mat.read(parameters("classif-GSec"), "\t"))[[1]]
    y <- parameters(paste("classif", classif.type, sep = "-"))
    y <- mat.read(y)
    y <- map.rname(y, z)
    if (x == "Ctry" | x == "Sector") {
        z <- vec.named(z, y$AllocTable)
    }
    else if (x == "EMDM") {
        w <- c("US", "CA", EAFE)
        z <- ifelse(is.element(z, w), "DM", "EM")
        z <- vec.named(z, y$AllocTable)
    }
    else if (x == "FX") {
        z <- vec.named(y$Curr, y$AllocTable)
    }
    else if (x == "UBS") {
        z <- ifelse(is.element(z, EMU), "EMU", z)
        z <- ifelse(is.element(z, EM), "EM", z)
        z <- vec.named(z, y$AllocTable)
    }
    else if (x == "Commerzbank") {
        z <- ifelse(is.element(z, EMU), "EuroZ", z)
        z <- ifelse(is.element(z, EM), "EM", z)
        z <- ifelse(z == "GB", "UK", z)
        z <- vec.named(z, y$AllocTable)
    }
    z
}

#' sql.1dFloMo.FI
#' 
#' Generates the SQL query to get daily 1dFloMo for fixed income
#' @keywords sql.1dFloMo.FI
#' @export
#' @family sql

sql.1dFloMo.FI <- function () 
{
    z <- "DayEnding = convert(char(8), DayEnding, 112)"
    for (i in c("GLOBEM", "WESEUR", "HYIELD", "FLOATS", "USTRIN", 
        "USTRLT", "USTRST", "CASH", "USMUNI", "GLOFIX")) {
        x <- paste("sum(case when grp = '", i, "' then AssetsStart else NULL end)", 
            sep = "")
        x <- sql.nonneg(x)
        z <- c(z, paste(i, " = 100 * sum(case when grp = '", 
            i, "' then Flow else NULL end)/", x, sep = ""))
    }
    z <- paste(sql.unbracket(sql.tbl(z, sql.1dFloMo.FI.underlying(), 
        , "DayEnding")), collapse = "\n")
    z
}

#' sql.1dFloMo.FI.underlying
#' 
#' Generates the SQL query to get daily 1dFloMo for fixed income
#' @keywords sql.1dFloMo.FI.underlying
#' @export
#' @family sql

sql.1dFloMo.FI.underlying <- function () 
{
    z <- c("HFundId", "grp =", "\tcase", "\twhen FundType = 'M' then 'CASH'", 
        "\twhen StyleSector = 130 then 'FLOATS'")
    z <- c(z, "\twhen StyleSector = 134 and GeographicFocus = 77 then 'USTRIN'", 
        "\twhen StyleSector = 137 and GeographicFocus = 77 then 'USTRLT'")
    z <- c(z, "\twhen StyleSector = 141 and GeographicFocus = 77 then 'USTRST'", 
        "\twhen StyleSector = 185 and GeographicFocus = 77 then 'USMUNI'")
    z <- c(z, "\twhen StyleSector = 125 and Category = '9' then 'HYIELD'", 
        "\twhen Category = '8' then 'WESEUR'")
    z <- c(z, "\twhen GeographicFocus = 31 then 'GLOBEM'", "\twhen GeographicFocus = 30 then 'GLOFIX'", 
        "\telse 'OTHER'", "\tend")
    z <- sql.label(sql.tbl(z, "FundHistory", "FundType in ('B', 'M')"), 
        "t2")
    z <- c("DailyData t1", "inner join", z, "\ton t2.HFundId = t1.HFundId")
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
    rgn <- c(4, 24, 43, 46, 55, 76, 77)
    names(rgn) <- c("AsiaXJP", "EurXGB", "Japan", "LatAm", "PacXJP", 
        "UK", "USA")
    z <- "DayEnding = convert(char(8), DayEnding, 112)"
    for (i in names(rgn)) {
        x <- paste("sum(case when grp = ", rgn[i], " then AssetsStart else NULL end)", 
            sep = "")
        x <- sql.nonneg(x)
        z <- c(z, paste(i, " = 100 * sum(case when grp = ", rgn[i], 
            " then Flow else NULL end)/", x, sep = ""))
    }
    y <- c("HFundId, grp = case when GeographicFocus in (6, 80, 35, 66) then 55 else GeographicFocus end")
    w <- sql.and(list(A = "FundType = 'E'", B = "Idx = 'N'", 
        C = sql.in("GeographicFocus", "(4, 24, 43, 46, 55, 76, 77, 6, 80, 35, 66)")))
    y <- c(sql.label(sql.tbl(y, "FundHistory", w), "t1"), "inner join", 
        "DailyData t2", "\ton t2.HFundId = t1.HFundId")
    z <- paste(sql.unbracket(sql.tbl(z, y, , "DayEnding")), collapse = "\n")
    z
}

#' sql.1dFloMoAggr
#' 
#' Generates the SQL query to get the data for aggregate 1dFloMo
#' @param x = the YYYYMMDD for which you want flows (known two days later)
#' @param y = one or more of FwtdIn0/FwtdEx0/SwtdIn0/SwtdEx0
#' @param n = any of StockFlows/Japan/CSI300/Energy
#' @keywords sql.1dFloMoAggr
#' @export
#' @family sql

sql.1dFloMoAggr <- function (x, y, n) 
{
    mo.end <- yyyymmdd.to.AllocMo(x, 26)
    mo.end <- yyyymm.to.day(mo.end)
    z <- list(A = paste("datediff(month, ReportDate, '", mo.end, 
        "') = ", 0, sep = ""), B = sql.in("HSecurityId", sql.RDSuniv(n)))
    z <- sql.Holdings(sql.and(z), c("ReportDate", "HFundId", 
        "HSecurityId", "HoldingValue"), "#HLDGS")
    h <- "GeographicFocusId, Flow = sum(Flow), AssetsStart = sum(AssetsStart)"
    w <- c("FundHistory t1", "inner join", "DailyData t2 on t2.HFundId = t1.HFundId")
    z <- c(z, "", sql.into(sql.tbl(h, w, paste("ReportDate = '", 
        x, "'", sep = ""), "GeographicFocusId", "sum(AssetsStart) > 0"), 
        "#FLOWS"))
    z <- c(z, "", sql.AggrAllocations(y, "#HLDGS", paste("'", 
        mo.end, "'", sep = ""), "GeographicFocusId", "#ALLOC"))
    y <- c("SecurityId", paste(y, " = 100 * sum(Flow * ", y, 
        ")/", sql.nonneg(paste("sum(AssetsStart * ", y, ")", 
            sep = "")), sep = ""))
    w <- c("#ALLOC t1", "inner join", "#FLOWS t2 on t1.GeographicFocusId = t2.GeographicFocusId")
    w <- c(w, "inner join", "SecurityHistory id on id.HSecurityId = t1.HSecurityId")
    w <- paste(sql.unbracket(sql.tbl(y, w, , "SecurityId")), 
        collapse = "\n")
    z <- paste(c(paste("drop table", c("#FLOWS", "#HLDGS", "#ALLOC")), 
        "", z), collapse = "\n")
    z <- c(z, w)
    z
}

#' sql.1dFloTrend
#' 
#' Generates the SQL query to get the data for 1dFloTrend
#' @param x = data date in YYYYMMDD (known two days later)
#' @param y = a string vector of factors to be computed,       the last element of which is the type of fund used.
#' @param n = the delay in knowing allocations
#' @param w = any of StockFlows/Japan/CSI300/Energy
#' @keywords sql.1dFloTrend
#' @export
#' @family sql

sql.1dFloTrend <- function (x, y, n, w) 
{
    m <- length(y)
    alloc.mo <- yyyymmdd.to.AllocMo(x, n)
    x <- sql.declare(c("@floDt", "@newDt", "@oldDt"), "datetime", 
        c(x, yyyymm.to.day(alloc.mo), yyyymm.to.day(yyyymm.lag(alloc.mo))))
    z <- "n1.SecurityId"
    for (i in y[-m]) {
        if (is.element(i, paste("FloTrend", c("", "CB", "PMA"), 
            sep = ""))) {
            z <- c(z, paste(i, " ", sql.Trend("Flow * (n1.HoldingValue/n2.AssetsEnd - o1.HoldingValue/o2.AssetsEnd)", 
                y[m]), sep = ""))
        }
        else if (is.element(i, paste("FloDiff", c("", "CB", "PMA"), 
            sep = ""))) {
            z <- c(z, paste(i, " ", sql.Diff("Flow", "n1.HoldingValue/n2.AssetsEnd - o1.HoldingValue/o2.AssetsEnd"), 
                sep = ""))
        }
        else if (is.element(i, paste("FloDiff2", c("", "CB", 
            "PMA"), sep = ""))) {
            z <- c(z, paste(i, " ", sql.Diff("n1.HoldingValue/n2.AssetsEnd - o1.HoldingValue/o2.AssetsEnd", 
                "Flow"), sep = ""))
        }
        else stop("Bad Argument")
    }
    z <- paste(c(x, "", sql.unbracket(sql.tbl(z, sql.1dFloTrend.underlying(y[m], 
        w), , "n1.SecurityId"))), collapse = "\n")
    z
}

#' sql.1dFloTrend.Ctry
#' 
#' For Ctry/FX generates the SQL query to get daily 1d a) FloDiff		= sql.1dFloTrend.Ctry("?", "Flo", "Diff") b) FloTrend		= sql.1dFloTrend.Ctry("?", "Flo", "Trend") c) ActWtDiff		= sql.1dFloTrend.Ctry("?", "ActWt", "Diff") d) ActWtTrend		= sql.1dFloTrend.Ctry("?", "ActWt", "Trend") e) FloDiff2		= sql.1dFloTrend.Ctry("?", "Flo", "Diff2") f) ActWtDiff2		= sql.1dFloTrend.Ctry("?", "ActWt", "Diff2") g) AllocMo		= sql.1dFloTrend.Ctry("?", "Flo", "AllocMo") h) AllocDiff		= sql.1dFloTrend.Ctry("?", "Flo", "AllocDiff") i) AllocTrend		= sql.1dFloTrend.Ctry("?", "Flo", "AllocTrend") j) AllocSkew		= sql.1dFloTrend.Ctry("?", "ActWt", "AllocSkew")
#' @param x = one of Ctry/FX/Sector
#' @param y = one of Flo/ActWt
#' @param n = one of Diff/Diff2/Trend/AllocMo/AllocDiff/AllocTrend
#' @keywords sql.1dFloTrend.Ctry
#' @export
#' @family sql

sql.1dFloTrend.Ctry <- function (x, y, n) 
{
    if (x == "Sector") 
        floTbl <- "WeeklyData"
    else floTbl <- "DailyData"
    if (is.element(n, c("AllocMo", "AllocDiff", "AllocTrend", 
        "AllocSkew"))) 
        floTbl <- "MonthlyData"
    ctry <- sql.1dFloMo.Ctry.List(x)
    z <- sql.1dFloTrend.Ctry.topline(n, ctry, floTbl)
    fcn <- get(paste("sql.1d", y, "Trend.Ctry.underlying", sep = ""))
    z <- paste(sql.unbracket(sql.tbl(z, fcn(ctry, floTbl, x), 
        , sql.floTbl.to.Col(floTbl, F))), collapse = "\n")
    z
}

#' sql.1dFloTrend.Ctry.topline
#' 
#' Generates the SQL query to get daily 1d Flo/ActWt Diff/Trend for Ctry/FX
#' @param x = one of Trend/Diff/Diff2/AllocMo/AllocDiff/AllocTrend/AllocSkew
#' @param y = country list
#' @param n = one of DailyData/WeeklyData/MonthlyData
#' @keywords sql.1dFloTrend.Ctry.topline
#' @export
#' @family sql

sql.1dFloTrend.Ctry.topline <- function (x, y, n) 
{
    if (x == "Trend") {
        fcn <- function(i) sql.Trend(paste("Flow * (t2.[", i, 
            "] - t3.[", i, "])", sep = ""))
    }
    else if (x == "Diff") {
        fcn <- function(i) sql.Diff("Flow", paste("t2.[", i, 
            "] - t3.[", i, "]", sep = ""))
    }
    else if (x == "Diff2") {
        fcn <- function(i) sql.Diff(paste("(t2.[", i, "] - t3.[", 
            i, "])", sep = ""), "Flow")
    }
    else if (x == "AllocDiff") {
        fcn <- function(i) sql.Diff("(AssetsStart + AssetsEnd)", 
            paste("t2.[", i, "] - t3.[", i, "]", sep = ""))
    }
    else if (x == "AllocTrend") {
        fcn <- function(i) sql.Trend(paste("(AssetsStart + AssetsEnd) * (t2.[", 
            i, "] - t3.[", i, "])", sep = ""))
    }
    else if (x == "AllocSkew") {
        fcn <- function(i) sql.Diff("AssetsEnd", paste("t3.[", 
            i, "] - t2.[", i, "]", sep = ""))
    }
    else if (x == "AllocMo") {
        fcn <- function(i) paste("= 2 * sum((AssetsStart + AssetsEnd) * (t2.[", 
            i, "] - t3.[", i, "]))", "/", sql.nonneg(paste("sum((AssetsStart + AssetsEnd) * (t2.[", 
                i, "] + t3.[", i, "]))", sep = "")), sep = "")
    }
    else stop("Unknown Computation")
    z <- sql.floTbl.to.Col(n, T)
    y <- y[!duplicated(y)]
    for (i in y) z <- c(z, paste("[", i, "] ", fcn(i), sep = ""))
    z
}

#' sql.1dFloTrend.Ctry.underlying
#' 
#' Generates the SQL query to get daily 1dFloMo for countries
#' @param x = a string vector indexed by allocation-table names
#' @param y = the SQL table from which you get flows (DailyData/MonthlyData)
#' @param n = one of Ctry/FX/Sector
#' @keywords sql.1dFloTrend.Ctry.underlying
#' @export
#' @family sql

sql.1dFloTrend.Ctry.underlying <- function (x, y, n) 
{
    z <- c(sql.label(sql.FundHistory("", "CBE", F, "FundId"), 
        "t0"), "inner join")
    z <- c(z, paste(y, " t1 on t1.HFundId = t0.HFundId", sep = ""), 
        "inner join")
    z <- c(z, paste(sql.1dFloMo.Ctry.Allocations(x, n), sep = ""))
    z <- c(sql.label(z, "t2"), "\ton t2.FundId = t0.FundId")
    if (y == "MonthlyData") {
        z <- c(z, paste("\t\tand t2.WeightDate =", sql.floTbl.to.Col(y, 
            F)))
    }
    else z <- c(z, paste("\t\tand", sql.datediff("WeightDate", 
        sql.floTbl.to.Col(y, F), 23)))
    z <- c(z, "inner join", sql.1dFloMo.Ctry.Allocations(x, n))
    z <- c(sql.label(z, "t3"), "\ton t3.FundId = t2.FundId and datediff(month, t3.WeightDate, t2.WeightDate) = 1")
    z
}

#' sql.1dFloTrend.underlying
#' 
#' Generates the SQL query to get the data for 1dFloTrend
#' @param x = either "All" or "Act" or "CBE"
#' @param y = any of StockFlows/Japan/CSI300/Energy
#' @keywords sql.1dFloTrend.underlying
#' @export
#' @family sql

sql.1dFloTrend.underlying <- function (x, y) 
{
    vec <- vec.named(c("@newDt", "@oldDt"), c("n", "o"))
    z <- c(sql.label(sql.FundHistory("", x, T, "FundId"), "his"), 
        "inner join", sql.DailyFlo("@floDt"))
    z <- c(sql.label(z, "flo"), "\ton flo.HFundId = his.HFundId")
    for (i in names(vec)) {
        w <- list(A = paste("ReportDate =", vec[i]))
        if (i == "n") 
            w[["B"]] <- sql.in("t.HSecurityId", sql.RDSuniv(y))
        y <- c("Holdings t", "inner join", "SecurityHistory id on id.HSecurityId = t.HSecurityId")
        y <- sql.label(sql.tbl("FundId, HFundId, SecurityId, HoldingValue", 
            y, sql.and(w)), paste(i, "1", sep = ""))
        z <- c(z, "inner join", y, paste("\ton ", i, "1.FundId = his.FundId", 
            sep = ""))
    }
    z <- c(z, "\tand o1.SecurityId = n1.SecurityId")
    for (i in names(vec)) {
        z <- c(z, "inner join", sql.MonthlyAssetsEnd(vec[i]))
        z <- c(sql.label(z, paste(i, "2", sep = "")), paste("\ton ", 
            i, "2.HFundId = ", i, "1.HFundId", sep = ""))
    }
    z
}

#' sql.1dFundRet
#' 
#' Generates the SQL query to get monthly AIS for countries
#' @param x = a list of fund identifiers
#' @keywords sql.1dFundRet
#' @export
#' @family sql

sql.1dFundRet <- function (x) 
{
    x <- sql.tbl("HFundId, FundId", "FundHistory", sql.in("FundId", 
        paste("(", paste(x, collapse = ", "), ")", sep = "")))
    x <- c("DailyData t1", "inner join", sql.label(x, "t2"), 
        "\ton t2.HFundId = t1.HFundId")
    z <- "DayEnding = convert(char(8), DayEnding, 112), FundId, FundRet = sum(PortfolioChange)/sum(AssetsStart)"
    z <- paste(sql.unbracket(sql.tbl(z, x, , "DayEnding, FundId", 
        "sum(AssetsStart) > 0")), collapse = "\n")
    z
}

#' sql.1dION
#' 
#' Generates the SQL query to get the data for 1dION$ & 1dION\%
#' @param x = data date (known two days later)
#' @param y = a vector of variables, the last element of which is ignored
#' @param n = the delay in knowing allocations
#' @param w = any of StockFlows/Japan/CSI300/Energy
#' @keywords sql.1dION
#' @export
#' @family sql

sql.1dION <- function (x, y, n, w) 
{
    m <- length(y)
    z <- "SecurityId"
    for (i in y[-m]) {
        if (i == "ION$") {
            z <- c(z, paste("[", i, "] ", sql.ION("Flow", "Flow * HoldingValue/AssetsEnd"), 
                sep = ""))
        }
        else if (i == "ION%") {
            z <- c(z, paste("[", i, "] ", sql.ION("Flow", "HoldingValue/AssetsEnd"), 
                sep = ""))
        }
        else stop("Bad Argument")
    }
    y <- c(sql.label(sql.FundHistory("", y[m], T, "FundId"), 
        "t0"), "inner join", sql.MonthlyAlloc("@allocDt"))
    y <- c(sql.label(y, "t1"), "\ton t1.FundId = t0.FundId", 
        "inner join", sql.DailyFlo("@floDt"))
    y <- c(sql.label(y, "t2"), "\ton t2.HFundId = t0.HFundId", 
        "inner join", sql.MonthlyAssetsEnd("@allocDt"))
    y <- c(sql.label(y, "t3"), "\ton t3.HFundId = t1.HFundId", 
        "inner join", "SecurityHistory id", "\ton id.HSecurityId = t1.HSecurityId")
    x <- sql.declare(c("@floDt", "@allocDt"), "datetime", c(x, 
        yyyymm.to.day(yyyymmdd.to.AllocMo(x, n))))
    z <- paste(c(x, sql.unbracket(sql.tbl(z, y, sql.in("t1.HSecurityId", 
        sql.RDSuniv(w)), "SecurityId"))), collapse = "\n")
    z
}

#' sql.1mActPas.Ctry
#' 
#' Generates the SQL query to get monthly AIS for countries
#' @keywords sql.1mActPas.Ctry
#' @export
#' @family sql

sql.1mActPas.Ctry <- function () 
{
    rgn <- c(as.character(sql.1dFloMo.Ctry.List("Ctry")), "LK", 
        "VE")
    z <- "WeightDate = convert(char(6), WeightDate, 112)"
    for (i in rgn) {
        x <- paste("avg(case when Idx = 'Y' then ", Ctry.info(i, 
            "AllocTable"), " else NULL end)", sep = "")
        x <- sql.nonneg(x)
        x <- paste("[", i, "] = avg(case when Idx = 'Y' then NULL else ", 
            Ctry.info(i, "AllocTable"), " end)/", x, sep = "")
        z <- c(z, paste(x, "- 1"))
    }
    x <- c(sql.label(sql.FundHistory("", "CBE", F, c("FundId", 
        "Idx")), "t1"), "inner join", "CountryAllocations t2 on t2.HFundId = t1.HFundId")
    z <- paste(sql.unbracket(sql.tbl(z, x, , "WeightDate")), 
        collapse = "\n")
    z
}

#' sql.1mActWt
#' 
#' Generates the SQL query to get the following active weights: a) EqlAct = equal weight average (incl 0) less the benchmark b) CapAct = fund weight average (incl 0) less the benchmark c) PosAct = fund weight average (incl 0) less the benchmark (positive flows only) d) NegAct = fund weight average (incl 0) less the benchmark (negative flows only)
#' @param x = the YYYYMM for which you want data (known 24 days later)
#' @param y = a string vector, the elements of which are: 1) FundId for the fund used as the benchmark 2) BenchIndexId of the benchmark
#' @keywords sql.1mActWt
#' @export
#' @family sql

sql.1mActWt <- function (x, y) 
{
    w <- c("Eql", "Cap", "Pos", "Neg")
    w <- c("SecurityId", paste(w, "Act = ", w, "Wt - BmkWt", 
        sep = ""))
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
#' Generates tail end of an SQL query
#' @param x = the month for which you want data (0 = latest, 1 = lagged one month, etc.)
#' @param y = characters you want put in front of the query
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
    z <- sql.label(paste("\t", sql.tbl("HSecurityId, BmkWt = HoldingValue/AssetsEnd", 
        z), sep = ""), "t0 -- Securities in the benchmark At Month End")
    w <- list(A = paste("datediff(month, ReportDate, @allocDt) =", 
        x))
    w[["B"]] <- sql.in("HFundId", sql.tbl("HFundId", "FundHistory", 
        "BenchIndexId = @bmkId"))
    w[["C"]] <- sql.in("HFundId", sql.Holdings(paste("datediff(month, ReportDate, @allocDt) =", 
        x), "HFundId"))
    w <- paste("\t", sql.tbl("HFundId, Flow = sum(Flow), AssetsEnd = sum(AssetsEnd)", 
        "MonthlyData", sql.and(w), "HFundId", "sum(AssetsEnd) > 0"), 
        sep = "")
    z <- c(z, "cross join", sql.label(w, "t1 -- Funds Reporting Both Monthly Flows and Allocations with the right benchmark"))
    z <- c(z, "left join", paste("\t", sql.Holdings(paste("datediff(month, ReportDate, @allocDt) =", 
        x), c("HSecurityId", "HFundId", "HoldingValue")), sep = ""))
    z <- c(sql.label(z, "t2"), "\t\ton t2.HFundId = t1.HFundId and t2.HSecurityId = t0.HSecurityId", 
        "inner join")
    z <- c(z, "\tSecurityHistory id on id.HSecurityId = t0.HSecurityId")
    z <- paste(y, z, sep = "")
    z
}

#' sql.1mAllocMo
#' 
#' Generates the SQL query to get the data for 1mAllocMo
#' @param x = the YYYYMM for which you want data (known 26 days later)
#' @param y = a string vector of factors to be computed, the last element of which is the type of fund used.
#' @param n = any of StockFlows/Japan/CSI300/Energy
#' @keywords sql.1mAllocMo
#' @export
#' @family sql

sql.1mAllocMo <- function (x, y, n) 
{
    m <- length(y)
    z <- "SecurityId"
    for (i in y[-m]) {
        if (i == "AllocMo") {
            w <- "AllocMo = 2 * sum((AssetsStart + AssetsEnd) * (n1.HoldingValue/AssetsEnd - o1.HoldingValue/AssetsStart))"
            if (y[m] != "Num") 
                w <- paste(w, "/", sql.nonneg("sum((AssetsStart + AssetsEnd) * (n1.HoldingValue/AssetsEnd + o1.HoldingValue/AssetsStart))"), 
                  sep = "")
        }
        else if (i == "AllocDiff") {
            w <- "AllocDiff = sum((AssetsStart + AssetsEnd) * sign(n1.HoldingValue/AssetsEnd - o1.HoldingValue/AssetsStart))"
            if (y[m] != "Num") 
                w <- paste(w, "/", sql.nonneg("sum(AssetsStart + AssetsEnd)"), 
                  sep = "")
        }
        else if (i == "AllocTrend") {
            w <- "AllocTrend = sum((AssetsStart + AssetsEnd) * (n1.HoldingValue/AssetsEnd - o1.HoldingValue/AssetsStart))"
            if (y[m] != "Num") 
                w <- paste(w, "/", sql.nonneg("sum(abs((AssetsStart + AssetsEnd) * (n1.HoldingValue/AssetsEnd - o1.HoldingValue/AssetsStart)))"), 
                  sep = "")
        }
        else stop("Bad Argument")
        z <- c(z, w)
    }
    w <- sql.1mAllocMo.underlying(y[m], n)
    z <- sql.unbracket(sql.tbl(z, w[["FROM"]], w[["WHERE"]], 
        "SecurityId"))
    z <- paste(c(sql.declare(c("@newDt", "@oldDt"), "datetime", 
        yyyymm.to.day(yyyymm.lag(x, 0:1))), z), collapse = "\n")
    z
}

#' sql.1mAllocMo.underlying
#' 
#' FROM and WHERE for 1mAllocMo
#' @param x = either "All" or "Act"
#' @param y = any of StockFlows/Japan/CSI300/Energy
#' @keywords sql.1mAllocMo.underlying
#' @export
#' @family sql

sql.1mAllocMo.underlying <- function (x, y) 
{
    z <- c(sql.label(sql.MonthlyAssetsEnd("@newDt", "", n = T), 
        "t"), "inner join", sql.MonthlyAlloc("@newDt"))
    z <- c(sql.label(z, "n1"), "\ton n1.HFundId = t.HFundId", 
        "inner join", sql.MonthlyAlloc("@oldDt"))
    z <- c(sql.label(z, "o1"), "\ton o1.FundId = n1.FundId", 
        "\tand o1.HSecurityId = n1.HSecurityId")
    z <- c(z, "inner join", "SecurityHistory id", "\ton id.HSecurityId = n1.HSecurityId")
    w <- list(A = sql.in("n1.HSecurityId", sql.RDSuniv(y)))
    if (x == "Act") 
        w[["B"]] <- sql.in("t.HFundId", sql.FundHistory("", "Act", 
            T))
    z <- list(FROM = z, WHERE = sql.and(w))
    z
}

#' sql.1mAllocSkew
#' 
#' Generates the SQL query to get the data for 1mAllocTrend
#' @param x = the YYYYMM for which you want data (known 24 days later)
#' @param y = a string vector of factors to be computed, the last element of which is the type of fund used.
#' @param n = any of StockFlows/Japan/CSI300/Energy
#' @keywords sql.1mAllocSkew
#' @export
#' @family sql

sql.1mAllocSkew <- function (x, y, n) 
{
    h <- length(y)
    w <- list(A = paste("ReportDate = '", yyyymm.to.day(x), "'", 
        sep = ""))
    if (y[h] == "Act") 
        w[["B"]] <- c("HFundId in", sql.FundHistory("\t", "Act", 
            T))
    w <- sql.into(sql.tbl("HFundId, PortVal = sum(AssetsEnd)", 
        "MonthlyData", sql.and(w), "HFundId", "sum(AssetsEnd) > 0"), 
        "#AUM")
    z <- c(paste("drop table", c("#AUM", "#HLD")), "", w, "")
    w <- list(A = paste("datediff(month, ReportDate, '", yyyymm.to.day(x), 
        "') = 0", sep = ""), B = sql.in("HSecurityId", sql.RDSuniv(n)))
    z <- c(z, sql.Holdings(sql.and(w), c("HFundId", "HSecurityId", 
        "HoldingValue"), "#HLD"), "")
    x <- "SecurityId"
    for (i in y[-h]) {
        if (i == "AllocSkew") {
            w <- "AllocSkew = sum(PortVal * sign(FundWtdExcl0 - n1.HoldingValue/PortVal))"
            x <- c(x, paste(w, "/", sql.nonneg("sum(PortVal)"), 
                sep = ""))
        }
        else stop("Bad Argument")
    }
    w <- c("HSecurityId", "GeographicFocusId", "FundWtdExcl0 = sum(HoldingValue)/sum(case when HoldingValue is not null then PortVal else NULL end)")
    y <- c("FundHistory t1", "inner join", "#HLD t2 on t2.HFundId = t1.HFundId", 
        "inner join", "#AUM t3 on t3.HFundId = t1.HFundId")
    w <- sql.tbl(w, y, , "HSecurityId, GeographicFocusId", "sum(case when HoldingValue is not null then PortVal else NULL end) > 0")
    w <- c("inner join", sql.label(w, "mnW"), "\ton mnW.GeographicFocusId = his.GeographicFocusId and mnW.HSecurityId = n1.HSecurityId")
    w <- c("inner join", "FundHistory his on his.HFundId = t.HFundId", 
        "inner join", "SecurityHistory id on id.HSecurityId = n1.HSecurityId", 
        w)
    w <- c("#AUM t", "inner join", "#HLD n1 on n1.HFundId = t.HFundId", 
        w)
    z <- c(paste(z, collapse = "\n"), paste(sql.unbracket(sql.tbl(x, 
        w, , "SecurityId")), collapse = "\n"))
    z
}

#' sql.1mChActWt
#' 
#' Generates the SQL query to get the following active weights: a) EqlChAct = equal weight average change in active weight b) BegChAct = beginning-of-period-asset weighted change in active weight c) EndChAct = end-of-period-asset weighted change in active weight d) BegPosChAct = beginning-of-period-asset weighted change in active weight (positive flows only) e) EndPosChAct = end-of-period-asset weighted change in active weight (positive flows only) f) BegNegChAct = beginning-of-period-asset weighted change in active weight (negative flows only) g) EndNegChAct = end-of-period-asset weighted change in active weight (negative flows only)
#' @param x = the YYYYMM for which you want data (known 24 days later)
#' @param y = a string vector, the elements of which are: 1) FundId for the fund used as the benchmark 2) BenchIndexId of the benchmark
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

#' sql.AggrAllocations
#' 
#' Generates the SQL query to get aggregate allocations for StockFlows
#' @param x = one of FwtdIn0/FwtdEx0/SwtdIn0/SwtdEx0
#' @param y = the name of the table containing Holdings (e.g. "#HLDGS")
#' @param n = a date of the form "@@allocDt" or "'20151231'"
#' @param w = the grouping column (e.g. "GeographicFocusId")
#' @param h = the temp table for output
#' @keywords sql.AggrAllocations
#' @export
#' @family sql

sql.AggrAllocations <- function (x, y, n, w, h) 
{
    z <- sql.tbl("ReportDate, HSecurityId", y, paste("ReportDate =", 
        n), "ReportDate, HSecurityId")
    z <- sql.label(z, "t0 -- Securities Held At Month End")
    tmp <- sql.and(list(A = "h.ReportDate = MonthlyData.ReportDate", 
        B = "h.HFundId = MonthlyData.HFundId"))
    tmp <- c("exists", paste("\t", sql.tbl("ReportDate, HFundId", 
        paste(y, "h"), tmp), sep = ""))
    n <- sql.and(list(A = paste("ReportDate =", n), B = tmp))
    n <- sql.tbl("HFundId, AssetsEnd = sum(AssetsEnd)", "MonthlyData", 
        n, "HFundId", "sum(AssetsEnd) > 0")
    z <- c(z, "cross join", sql.label(n, "t1 -- Funds Reporting Both Monthly Flows and Allocations"), 
        "inner join")
    z <- c(z, "FundHistory t2 on t1.HFundId = t2.HFundId", "left join", 
        paste(y, "t3"))
    n <- c(z, "\ton t3.HFundId = t1.HFundId and t3.HSecurityId = t0.HSecurityId and t3.ReportDate = t0.ReportDate")
    z <- c("t0.HSecurityId", w)
    for (i in x) {
        if (i == "SwtdEx0") {
            y <- "avg(HoldingValue/AssetsEnd)"
        }
        else if (i == "SwtdIn0") {
            y <- "sum(HoldingValue/AssetsEnd)/count(AssetsEnd)"
        }
        else if (i == "FwtdEx0") {
            y <- "sum(HoldingValue)/sum(case when HoldingValue is not null then AssetsEnd else NULL end)"
        }
        else if (i == "FwtdIn0") {
            y <- "sum(HoldingValue)/sum(AssetsEnd)"
        }
        else stop("Problem")
        z <- c(z, paste(i, "=", y))
    }
    z <- sql.into(sql.tbl(z, n, , paste("t0.HSecurityId", w, 
        sep = ", "), "sum(HoldingValue) > 0"), h)
    z
}

#' sql.AllocTbl
#' 
#' Finds the relevant allocation table
#' @param x = one of Ctry/FX/Sector
#' @keywords sql.AllocTbl
#' @export
#' @family sql

sql.AllocTbl <- function (x) 
{
    z <- "CountryAllocations"
    if (x == "Sector") 
        z <- "SectorAllocations"
    z
}

#' sql.and
#' 
#' and segment of an SQL statement
#' @param x = list object of string vectors
#' @param y = prependix
#' @param n = logical operator to use
#' @keywords sql.and
#' @export
#' @family sql

sql.and <- function (x, y = "", n = "and") 
{
    if (length(names(x)) > 1) {
        z <- paste("\t", x[[1]], sep = "")
        for (i in names(x)[-1]) z <- c(z, n, paste("\t", x[[i]], 
            sep = ""))
    }
    else z <- x[[1]]
    z
}

#' sql.bcp
#' 
#' code to bcp data out of server
#' @param x = SQL table to perform the bulk copy from
#' @param y = the location of the output file
#' @param n = One of "StockFlows", "Quant", "QuantSF" or "Regular"
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
    z <- is.element(dimnames(x)[[1]], n)
    if (sum(z) != 1) 
        stop("Bad type", n)
    if (sum(z) == 1) {
        z <- paste("-S", x[, "DB"], "-U", x[, "UID"], "-P", x[, 
            "PWD"])[z]
        z <- paste("bcp", h, "out", y, z, "-c")
    }
    z
}

#' sql.connect
#' 
#' Opens an SQL connection
#' @param x = One of "StockFlows", "Quant" or "Regular"
#' @keywords sql.connect
#' @export
#' @family sql
#' @@importFrom RODBC odbcDriverConnect

sql.connect <- function (x) 
{
    y <- mat.read(parameters("SQL"), "\t")
    if (all(dimnames(y)[[1]] != x)) 
        stop("Bad SQL connection!")
    z <- t(y)[c("PWD", "UID", "DSN"), x]
    z["Connection Timeout"] <- "0"
    z <- paste(paste(names(z), z, sep = "="), collapse = ";")
    z <- odbcDriverConnect(z, readOnlyOptimize = T)
    z
}

#' sql.cross.border
#' 
#' Returns a list object of cross-border Geo. Foci and their names
#' @param x = T/F depending on whether StockFlows data are being used
#' @keywords sql.cross.border
#' @export
#' @family sql

sql.cross.border <- function (x) 
{
    y <- parameters("classif-GeoId")
    y <- mat.read(y, "\t")
    y <- y[is.element(y$xBord, 1), ]
    if (x) 
        x <- "GeographicFocusId"
    else x <- "GeographicFocus"
    z <- list()
    for (i in dimnames(y)[[1]]) z[[y[i, "Abbrv"]]] <- paste(x, 
        "=", paste(i, y[i, "Name"], sep = "--"))
    z
}

#' sql.DailyFlo
#' 
#' Generates the SQL query to get the data for daily Flow
#' @param x = the date for which you want flows (known one day later)
#' @param y = the temp table to hold output
#' @keywords sql.DailyFlo
#' @export
#' @family sql

sql.DailyFlo <- function (x, y) 
{
    z <- c("HFundId, Flow = sum(Flow), AssetsStart = sum(AssetsStart)")
    z <- sql.tbl(z, "DailyData", paste("ReportDate =", x), "HFundId")
    if (!missing(y)) 
        z <- sql.into(z, y)
    z
}

#' sql.datediff
#' 
#' Before <n>, falls back two else one month
#' @param x = column in the monthly table
#' @param y = column in the daily table
#' @param n = calendar day on which previous month's data available
#' @keywords sql.datediff
#' @export
#' @family sql

sql.datediff <- function (x, y, n) 
{
    paste("datediff(month, ", x, ", ", y, ") = case when day(", 
        y, ") < ", n, " then 2 else 1 end", sep = "")
}

#' sql.declare
#' 
#' declare statement
#' @param x = variable names
#' @param y = variable types
#' @param n = values
#' @keywords sql.declare
#' @export
#' @family sql

sql.declare <- function (x, y, n) 
{
    c(paste("declare", x, y), paste("set ", x, " = '", n, "'", 
        sep = ""))
}

#' sql.Diff
#' 
#' SQL statement for diffusion
#' @param x = vector
#' @param y = isomekic vector
#' @keywords sql.Diff
#' @export
#' @family sql

sql.Diff <- function (x, y) 
{
    paste("= sum((", x, ") * sign(", y, "))", "/", sql.nonneg(paste("sum(abs(", 
        x, "))", sep = "")), sep = "")
}

#' sql.FloMo.Funds
#' 
#' Generates the SQL query to get monthly/daily data for Funds
#' @param x = the month/day for which you want \% flow, \% portfolio change, & assets end
#' @keywords sql.FloMo.Funds
#' @export
#' @family sql

sql.FloMo.Funds <- function (x) 
{
    if (nchar(x) == 6) {
        sql.table <- "MonthlyData"
        flo.dt <- yyyymm.to.day(x)
        dt.col <- "MonthEnding"
    }
    else {
        sql.table <- "DailyData"
        flo.dt <- x
        dt.col <- "DayEnding"
    }
    flo.dt <- sql.declare("@floDt", "datetime", flo.dt)
    z <- c("SecurityId = FundId", "PortfolioChangePct = 100 * sum(PortfolioChange)/sum(AssetsStart)")
    z <- c(z, "FlowPct = 100 * sum(Flow)/sum(AssetsStart)", "AssetsEnd = sum(AssetsEnd)")
    x <- c(sql.label(sql.table, "t1"), "inner join", "FundHistory t2 on t1.HFundId = t2.HFundId")
    z <- paste(sql.unbracket(sql.tbl(z, x, paste(dt.col, "= @floDt"), 
        "FundId", "sum(AssetsStart) > 0")), collapse = "\n")
    z
}

#' sql.floTbl.to.Col
#' 
#' derived the appropriate date column from the flow table name
#' @param x = one of DailyData/WeeklyData/MonthlyData
#' @param y = T/F depending on whether you want the date formatted.
#' @keywords sql.floTbl.to.Col
#' @export
#' @family sql

sql.floTbl.to.Col <- function (x, y) 
{
    n <- vec.named(c(8, 8, 6), c("DailyData", "WeeklyData", "MonthlyData"))
    z <- vec.named(c("DayEnding", "WeekEnding", "MonthEnding"), 
        names(n))
    z <- as.character(z[x])
    n <- as.numeric(n[x])
    if (y) 
        z <- paste(z, " = convert(char(", n, "), ", z, ", 112)", 
            sep = "")
    z
}

#' sql.FundHistory
#' 
#' SQL query to restrict to Global and Regional equity funds
#' @param x = characters to place before each line of the SQL query part
#' @param y = either "All" or "Act" or "CBE"
#' @param n = T/F depending on whether StockFlows data are being used
#' @param w = columns needed in addition to HFundId
#' @keywords sql.FundHistory
#' @export
#' @family sql

sql.FundHistory <- function (x, y, n, w) 
{
    if (missing(w)) 
        w <- "HFundId"
    else w <- c("HFundId", w)
    if (y == "All" & n) {
        z <- sql.tbl(w, "FundHistory")
    }
    else {
        if (y == "All") {
            y <- list(A = "FundType = 'E'")
        }
        else if (y == "Act" & n) {
            y <- list(A = "[Index] = 0")
        }
        else if (y == "Act" & !n) {
            y <- list(A = "(not Idx = 'Y' or Idx is NULL)", B = "FundType = 'E'")
        }
        else if (y == "CBE") {
            y <- sql.and(sql.cross.border(n), "", "or")
            if (n) 
                y <- list(A = y)
            else y <- list(A = c("(", y, ")"), B = "FundType = 'E'")
        }
        else stop("Bad Argument y =", y)
        z <- sql.tbl(w, "FundHistory", sql.and(y))
    }
    z <- paste(x, z, sep = "")
    z
}

#' sql.FundWtdExcl0
#' 
#' Generates the SQL query to get Geo Focus average weights
#' @param x = YYYYMM for which you want allocations (known 24 days after month end)
#' @keywords sql.FundWtdExcl0
#' @export
#' @family sql

sql.FundWtdExcl0 <- function (x) 
{
    w <- "FundWtdExcl0 = sum(HoldingValue)/sum(case when HoldingValue is not null then AssetsEnd else NULL end)"
    w <- c("HSecurityId", "GeographicFocusId", w)
    z <- c("FundHistory t1", "inner join", sql.MonthlyAlloc(x))
    z <- c(sql.label(z, "t2"), "\ton t2.HFundId = t1.HFundId", 
        "inner join", sql.MonthlyAssetsEnd(x))
    z <- c(sql.label(z, "t3"), "\ton t3.HFundId = t1.HFundId")
    z <- sql.tbl(w, z, , "HSecurityId, GeographicFocusId", "sum(case when HoldingValue is not null then AssetsEnd else NULL end) > 0")
    z <- paste(z, collapse = "\n")
    z
}

#' sql.Holdings
#' 
#' query to access stock-holdings data
#' @param x = where clause
#' @param y = columns you want fetched
#' @param n = the temp table for the output
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
#' <x> in <y>
#' @param x = column
#' @param y = SQL statement
#' @keywords sql.in
#' @export
#' @family sql

sql.in <- function (x, y) 
{
    c(paste(x, "in"), paste("\t", y, sep = ""))
}

#' sql.into
#' 
#' unbrackets and selects into <y>
#' @param x = SQL statement
#' @param y = the temp table for the output
#' @keywords sql.into
#' @export
#' @family sql

sql.into <- function (x, y) 
{
    z <- sql.unbracket(x)
    n <- length(z)
    w <- z == "from"
    if (sum(w) != 1) 
        stop("Failure in sql.into!")
    w <- c(1:n, (1:n)[w] + 1:2/3 - 1)
    z <- c(z, "into", paste("\t", y, sep = ""))[order(w)]
    z
}

#' sql.ION
#' 
#' sum(case when <x> > 0 then <y> else 0 end)/case when sum(abs(<y>)) > 0 then sum(abs(<y>)) else NULL end
#' @param x = bit of SQL string
#' @param y = bit of SQL string
#' @keywords sql.ION
#' @export
#' @family sql

sql.ION <- function (x, y) 
{
    z <- paste("= sum(case when ", x, " > 0 then ", y, " else 0 end)", 
        sep = "")
    z <- paste(z, "/", sql.nonneg(paste("sum(abs(", y, "))", 
        sep = "")), sep = "")
    z
}

#' sql.isin.old.to.new
#' 
#' Returns the latest isin
#' @param x = Historical Isin
#' @keywords sql.isin.old.to.new
#' @export
#' @family sql

sql.isin.old.to.new <- function (x) 
{
    z <- sql.tbl("Id", "SecurityCode", sql.and(list(A = "SecurityCodeTypeId = 1", 
        B = "SecurityCode = @isin")))
    z <- sql.tbl("HSecurityId", "SecurityCodeMapping", sql.in("SecurityCodeId", 
        z))
    z <- sql.tbl("SecurityId", "SecurityHistory", sql.in("HSecurityId", 
        z))
    z <- sql.tbl("HSecurityId", "SecurityHistory", sql.and(list(A = "EndDate is NULL", 
        B = sql.in("SecurityId", z))))
    z <- sql.tbl("SecurityCodeId", "SecurityCodeMapping", sql.and(list(A = "SecurityCodeTypeId = 1", 
        B = sql.in("HSecurityId", z))))
    z <- sql.tbl("SecurityCode", "SecurityCode", sql.and(list(A = "SecurityCodeTypeId = 1", 
        B = sql.in("Id", z))))
    z <- paste(c(sql.declare("@isin", "char(12)", x), z), collapse = "\n")
    z
}

#' sql.label
#' 
#' labels <x> as <y>
#' @param x = SQL statement
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
#' @param x = SQL queries to be submitted
#' @param y = names of factors to be returned
#' @param n = a connection, the output of odbcDriverConnect
#' @param w = classif file
#' @keywords sql.map.classif
#' @export
#' @family sql
#' @@importFrom RODBC sqlQuery

sql.map.classif <- function (x, y, n, w) 
{
    for (i in x) z <- sqlQuery(n, i)
    if (any(duplicated(z[, "SecurityId"]))) 
        stop("Problem...\n")
    dimnames(z)[[1]] <- z[, "SecurityId"]
    z <- map.rname(z, dimnames(w)[[1]])
    z <- z[, y]
    if (length(y) == 1) 
        z <- as.numeric(z)
    z
}

#' sql.Mo
#' 
#' SQL statement for momentum
#' @param x = vector of "flow"
#' @param y = isomekic vector of "assets"
#' @param n = isomekic vector of "weights"
#' @param w = T/F depending on whether to handle division by zero
#' @keywords sql.Mo
#' @export
#' @family sql

sql.Mo <- function (x, y, n, w) 
{
    z <- paste("sum(", y, " * ", n, ")", sep = "")
    if (w) 
        z <- sql.nonneg(z)
    z <- paste("= 100 * sum(", x, " * ", n, ")/", z, sep = "")
    z
}

#' sql.MonthlyAlloc
#' 
#' Generates the SQL query to get the data for monthly allocations for StockFlows
#' @param x = YYYYMM for which you want allocations (known 24 days after month end)
#' @param y = characters that get pasted in front of every line (usually tabs for indentation)
#' @keywords sql.MonthlyAlloc
#' @export
#' @family sql

sql.MonthlyAlloc <- function (x, y = "") 
{
    paste(y, sql.Holdings(paste("datediff(month, ReportDate, ", 
        x, ") = 0", sep = ""), c("FundId", "HFundId", "HSecurityId", 
        "HoldingValue")), sep = "")
}

#' sql.MonthlyAssetsEnd
#' 
#' Generates the SQL query to get the data for monthly Assets End
#' @param x = YYYYMMDD for which you want flows (known one day later)
#' @param y = characters that get pasted in front of every line (usually tabs for indentation)
#' @param n = T/F variable depending on whether you want AssetsStart/AssetsEnd or just AssetsEnd
#' @keywords sql.MonthlyAssetsEnd
#' @export
#' @family sql

sql.MonthlyAssetsEnd <- function (x, y = "", n = F) 
{
    w <- c("HFundId", "AssetsEnd = sum(AssetsEnd)")
    h <- "sum(AssetsEnd) > 0"
    if (n) {
        w <- c(w, "AssetsStart = sum(AssetsStart)")
        h <- sql.and(list(A = h, B = "sum(AssetsStart) > 0"))
    }
    z <- paste(y, sql.tbl(w, "MonthlyData", paste("ReportDate =", 
        x), "HFundId", h), sep = "")
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

#' sql.query
#' 
#' opens a connection, executes sql query, then closes the connection
#' @param x = query needed for the update
#' @param y = one of StockFlows/Regular/Quant
#' @keywords sql.query
#' @export
#' @family sql
#' @@importFrom RODBC sqlQuery

sql.query <- function (x, y) 
{
    myconn <- sql.connect(y)
    z <- sqlQuery(myconn, x)
    close(myconn)
    cat("Getting ", dim(z)[1], " new rows of data ...\n")
    z
}

#' sql.RDSuniv
#' 
#' Generates the SQL query to get the row space for a stock flows research data set
#' @param x = any of StockFlows/Japan/CSI300/Energy
#' @keywords sql.RDSuniv
#' @export
#' @family sql

sql.RDSuniv <- function (x) 
{
    if (any(x == c("StockFlows", "Japan", "CSI300"))) {
        if (x == "CSI300") {
            bmks <- "CSI300"
            names(bmks) <- 31873
        }
        else if (x == "Japan") {
            bmks <- c("Nikkei", "Topix")
            names(bmks) <- c(13667, 17558)
        }
        else if (x == "StockFlows") {
            bmks <- c("S&P500", "Eafe", "Gem", "R3", "EafeSc", 
                "GemSc", "Canada", "CanadaSc", "R1", "R2", "Nikkei", 
                "Topix", "CSI300")
            names(bmks) <- c(5164, 4430, 4835, 5158, 14602, 16621, 
                7744, 29865, 5152, 5155, 13667, 17558, 31873)
        }
        z <- sql.and(vec.to.list(paste("FundId =", paste(names(bmks), 
            bmks, sep = " --"))), n = "or")
        z <- sql.in("HFundId", sql.tbl("HFundId", "FundHistory", 
            z))
        z <- sql.tbl("HSecurityId", "Holdings", z, "HSecurityId")
    }
    else if (x == "Energy") {
        z <- "(340228, 696775, 561380, 656067, 308571, 420631, 902846, 673356, 911907, 763388,"
        z <- c(z, "\t98654, 664044, 742638, 401296, 308355, 588468, 612083, 682720, 836332, 143750)")
        z <- sql.tbl("HSecurityId", "SecurityHistory", sql.in("SecurityId", 
            z))
    }
    z
}

#' sql.stock.flows.wtd.avg
#' 
#' Computes Fund/Smpl weighted Incl/Excl zero for all names in the S&P
#' @param x = YYYYMM at the end of which allocations are desired
#' @param y = a string. Must be one of All/Etf/MF.
#' @keywords sql.stock.flows.wtd.avg
#' @export
#' @family sql

sql.stock.flows.wtd.avg <- function (x, y) 
{
    x <- sql.declare(c("@benchId", "@hFundId", "@geoId", "@allocDt"), 
        c("int", "int", "int", "datetime"), c(1487, 8068, 77, 
            yyyymm.to.day(x)))
    w <- list(A = "GeographicFocusId = @geoId", B = "BenchIndexId = @benchId", 
        C = "StyleSectorId in (108, 109, 110)")
    if (y == "Etf") {
        w[["D"]] <- "ETFTypeId is not null"
    }
    else if (y == "MF") {
        w[["D"]] <- "ETFTypeId is null"
    }
    else if (y != "All") 
        stop("Bad type argument")
    w <- list(A = sql.in("HFundId", sql.tbl("HFundId", "FundHistory", 
        sql.and(w))))
    w[["B"]] <- "ReportDate = @allocDt"
    w[["C"]] <- sql.in("HFundId", sql.Holdings("datediff(month, ReportDate, @allocDt) = 0", 
        "HFundId"))
    z <- sql.label(sql.tbl("HFundId, PortVal = sum(AssetsEnd)", 
        "MonthlyData", sql.and(w), "HFundId"), "t1")
    w <- sql.tbl("HSecurityId", "Holdings", sql.and(list(A = "ReportDate = @allocDt", 
        B = "HFundId = @hFundId")))
    z <- sql.label(sql.tbl("HFundId, HSecurityId, PortVal", c(z, 
        "cross join", sql.label(w, "t2"))), " t")
    z <- c(z, "inner join", "SecurityCodeMapping map on map.HSecurityId = t.HSecurityId")
    w <- sql.Holdings("datediff(month, ReportDate, @allocDt) = 0", 
        c("HSecurityId", "HFundId", "HoldingValue"))
    z <- c(z, "left join", sql.label(w, "t3"), "\ton t3.HFundId = t.HFundId and t3.HSecurityId = t.HSecurityId")
    w <- sql.tbl("Id, SecurityCode", "SecurityCode", "SecurityCodeTypeId = 1")
    w <- c(z, "left join", sql.label(w, "isin"), "\ton isin.Id = map.SecurityCodeId")
    z <- c("t.HSecurityId", "isin = isnull(isin.SecurityCode, '')", 
        "SmplWtdExcl0 = avg(HoldingValue/PortVal)")
    z <- c(z, "SmplWtdIncl0 = sum(HoldingValue/PortVal)/count(PortVal)")
    z <- c(z, "FundWtdExcl0 = sum(HoldingValue)/sum(case when HoldingValue is not null then PortVal else NULL end)")
    z <- c(z, "FundWtdIncl0 = sum(HoldingValue)/sum(PortVal)")
    z <- sql.unbracket(sql.tbl(z, w, , "t.HSecurityId, isnull(isin.SecurityCode, '')", 
        "sum(HoldingValue) > 0"))
    z <- paste(c(x, z), collapse = "\n")
    z
}

#' sql.tbl
#' 
#' Full SQL statement
#' @param x = needed columns
#' @param y = table
#' @param n = where segment
#' @param w = group by segment
#' @param h = having
#' @keywords sql.tbl
#' @export
#' @family sql

sql.tbl <- function (x, y, n, w, h) 
{
    m <- length(x)
    z <- paste("\t", x[1], sep = "")
    if (m > 1) {
        for (i in 2:m) {
            if (txt.left(x[i], 1) != "\t") 
                z[i - 1] <- paste(z[i - 1], ",", sep = "")
            z <- c(z, paste("\t", x[i], sep = ""))
        }
    }
    z <- c("(select", z)
    x <- txt.right(y, 5) == " join"
    x <- x & txt.left(c(y[-1], ""), 1) != "\t"
    x <- ifelse(x, "", "\t")
    z <- c(z, "from", paste(x, y, sep = ""))
    if (!missing(n)) 
        z <- c(z, "where", paste("\t", n, sep = ""))
    if (!missing(w)) 
        z <- c(z, "group by", paste("\t", w, sep = ""))
    if (!missing(h)) 
        z <- c(z, "having", paste("\t", h, sep = ""))
    z <- c(z, ")")
    z
}

#' sql.TopDownAllocs
#' 
#' Generates the SQL query to get Active/Passive Top-Down Allocations
#' @param x = the YYYYMM for which you want data (known 26 days later)
#' @param y = a string vector, first the element of which is 0/1 depending on whether you want Active/Passive, while the subsequent elements are the types of top-down allocation wanted
#' @param n = any of StockFlows/Japan/CSI300/Energy
#' @keywords sql.TopDownAllocs
#' @export
#' @family sql

sql.TopDownAllocs <- function (x, y, n) 
{
    x <- sql.declare(c("@allocDt", "@idx"), c("datetime", "int"), 
        c(yyyymm.to.day(x), y[1]))
    w <- list(A = "ReportDate = @allocDt", B = sql.in("HFundId", 
        sql.Holdings("datediff(month, ReportDate, @allocDt) = 0", 
            "HFundId")))
    w[["C"]] <- sql.in("HFundId", sql.tbl("HFundId", "FundHistory", 
        "[Index] = @idx"))
    z <- sql.label(sql.tbl("HFundId, AssetsEnd = sum(AssetsEnd)", 
        "MonthlyData", sql.and(w), "HFundId", "sum(AssetsEnd) > 0"), 
        "t1")
    w <- sql.tbl("HSecurityId", "Holdings", sql.and(list(A = "ReportDate = @allocDt", 
        B = sql.in("HSecurityId", sql.RDSuniv(n)))), "HSecurityId")
    z <- c(z, "cross join", sql.label(w, "t2"), "left join", 
        sql.label(sql.MonthlyAlloc("@allocDt"), "t3"))
    w <- c(z, "\ton t3.HFundId = t1.HFundId and t3.HSecurityId = t2.HSecurityId", 
        "inner join", "SecurityHistory id on id.HSecurityId = t2.HSecurityId")
    z <- "SecurityId"
    for (i in y[-1]) {
        if (i == "SwtdEx0") {
            z <- c(z, "SwtdEx0 = 100 * avg(HoldingValue/AssetsEnd)")
        }
        else if (i == "SwtdIn0") {
            z <- c(z, "SwtdIn0 = 100 * sum(HoldingValue/AssetsEnd)/count(t1.HFundId)")
        }
        else if (i == "FwtdEx0") {
            z <- c(z, "FwtdEx0 = 100 * sum(HoldingValue)/sum(case when HoldingValue is not null then AssetsEnd else NULL end)")
        }
        else if (i == "FwtdIn0") {
            z <- c(z, "FwtdIn0 = 100 * sum(HoldingValue)/sum(AssetsEnd)")
        }
        else stop("Bad Argument")
    }
    z <- paste(c(x, "", sql.unbracket(sql.tbl(z, w, , "SecurityId"))), 
        collapse = "\n")
    z
}

#' sql.Trend
#' 
#'  = sum(<x>)/case when sum(<x>) = 0 then NULL else sum(<x>) end
#' @param x = bit of SQL string
#' @param y = type of fund to use
#' @keywords sql.Trend
#' @export
#' @family sql

sql.Trend <- function (x, y = "All") 
{
    z <- paste("= sum(", x, ")", sep = "")
    if (y != "Num") 
        z <- paste(z, "/", sql.nonneg(paste("sum(abs(", x, "))", 
            sep = "")), sep = "")
    z
}

#' sql.unbracket
#' 
#' removes brackets around an SQL block
#' @param x = string vector
#' @keywords sql.unbracket
#' @export
#' @family sql

sql.unbracket <- function (x) 
{
    n <- length(x)
    if (txt.left(x[1], 1) != "(" | x[n] != ")") 
        stop("Can't unbracket!")
    x[1] <- txt.right(x[1], nchar(x[1]) - 1)
    z <- x[-n]
    z
}

#' strategy.dir
#' 
#' factor folder
#' @param x = "daily" or "weekly"
#' @keywords strategy.dir
#' @export
#' @family strategy

strategy.dir <- function (x) 
{
    paste(dir.parameters("data"), x, sep = "\\")
}

#' strategy.file
#' 
#' Returns the file in which the factor lives
#' @param x = name of the strategy (e.g. "FX" or "PremSec-JP")
#' @param y = "daily" or "weekly"
#' @keywords strategy.file
#' @export
#' @family strategy

strategy.file <- function (x, y) 
{
    paste(x, "-", y, ".csv", sep = "")
}

#' strategy.path
#' 
#' Returns the full path to the factor file
#' @param x = name of the strategy (e.g. "FX" or "PremSec-JP")
#' @param y = "daily" or "weekly"
#' @keywords strategy.path
#' @export
#' @family strategy

strategy.path <- function (x, y) 
{
    paste(strategy.dir(y), strategy.file(x, y), sep = "\\")
}

#' today
#' 
#' returns system date as a yyyymmdd
#' @keywords today
#' @export

today <- function () 
{
    z <- Sys.Date()
    z <- day.ex.date(z)
    z
}

#' txt.anagram
#' 
#' all possible anagrams
#' @param x = a SINGLE string
#' @param y = a file of potentially-usable capitzalized words
#' @param n = vector of minimum number of characters for first few words
#' @keywords txt.anagram
#' @export
#' @family txt

txt.anagram <- function (x, y, n = 0) 
{
    x <- toupper(x)
    x <- txt.to.char(x)
    x <- x[is.element(x, char.seq("A", "Z"))]
    x <- paste(x, collapse = "")
    if (missing(y)) 
        y <- paste(dir.parameters("data"), "EnglishWords.txt", 
            sep = "\\")
    y <- vec.read(y, F)
    y <- y[order(y, decreasing = T)]
    y <- y[order(nchar(y))]
    z <- txt.anagram.underlying(x, y, n)
    z
}

#' txt.anagram.underlying
#' 
#' all possible anagrams
#' @param x = a SINGLE string
#' @param y = potentially-usable capitalized words
#' @param n = vector of minimum number of characters for first few words
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

#' txt.core
#' 
#' renders with upper-case letters, spaces and numbers only
#' @param x = a vector
#' @keywords txt.core
#' @export
#' @family txt

txt.core <- function (x) 
{
    x <- toupper(x)
    m <- nchar(x)
    n <- max(m)
    while (n > 0) {
        w <- m >= n
        w[w] <- !is.element(substring(x[w], n, n), c(" ", char.seq("A", 
            "Z"), 0:9))
        h <- w & m == n
        if (any(h)) {
            x[h] <- txt.left(x[h], n - 1)
            m[h] <- m[h] - 1
        }
        h <- w & m > n
        if (any(h)) 
            x[h] <- paste(txt.left(x[h], n - 1), substring(x[h], 
                n + 1, m[h]))
        n <- n - 1
    }
    x <- txt.trim(x)
    z <- txt.itrim(x)
    z
}

#' txt.count
#' 
#' counts the number of occurences of <y> in each element of <x>
#' @param x = a vector of strings
#' @param y = a substring
#' @keywords txt.count
#' @export
#' @family txt

txt.count <- function (x, y) 
{
    z <- txt.replace(x, y, "")
    z <- nchar(z)
    z <- nchar(x) - z
    z <- z/nchar(y)
    z
}

#' txt.ex.file
#' 
#' reads in the file as a single string
#' @param x = path to a text file
#' @keywords txt.ex.file
#' @export
#' @family txt

txt.ex.file <- function (x) 
{
    paste(vec.read(x, F), collapse = "\n")
}

#' txt.excise
#' 
#' cuts out elements of <y> from <x> wherever found
#' @param x = a vector
#' @param y = a vector
#' @keywords txt.excise
#' @export
#' @family txt

txt.excise <- function (x, y) 
{
    z <- x
    for (j in y) {
        m <- nchar(j)
        j <- as.numeric(regexpr(j, z, fixed = T))
        n <- nchar(z)
        z <- ifelse(j == 1, substring(z, m + 1, n), z)
        z <- ifelse(j == n - m + 1, substring(z, 1, j - 1), z)
        z <- ifelse(j > 1 & j < n - m + 1, paste(substring(z, 
            1, j - 1), substring(z, j + m, n), sep = ""), z)
    }
    z
}

#' txt.expand
#' 
#' Returns all combinations OF <x> and <y> pasted together
#' @param x = a vector of strings
#' @param y = a vector of strings
#' @param n = paste separator
#' @param w = T/F variable controlling paste order
#' @keywords txt.expand
#' @export
#' @family txt

txt.expand <- function (x, y, n = "-", w = F) 
{
    i <- length(x)
    j <- length(y)
    y <- rep(y, i)
    x <- rep(x, j)
    if (!w) {
        m <- rep(1:i, j)
        x <- x[order(m)]
    }
    else {
        m <- rep(1:j, i)
        y <- y[order(m)]
    }
    z <- paste(x, y, sep = n)
    z
}

#' txt.has
#' 
#' the elements of <x> that contain <y> if <n> is F or a logical vector otherwise
#' @param x = a vector of strings
#' @param y = a single string
#' @param n = T/F depending on whether a logical vector is desired
#' @keywords txt.has
#' @export
#' @family txt

txt.has <- function (x, y, n = F) 
{
    z <- grepl(y, x, fixed = T)
    if (!n) 
        z <- x[z]
    z
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
    if (n%%2 == 1) {
        x <- paste(x, " ", sep = "")
        n <- n + 1
    }
    n <- 100 - n
    n <- n/2
    z <- paste(txt.space(n, "*"), x, txt.space(n, "*"), sep = "")
    z
}

#' txt.itrim
#' 
#' gets rid of multiple consecutive spaces
#' @param x = a vector of strings
#' @keywords txt.itrim
#' @export
#' @family txt

txt.itrim <- function (x) 
{
    z <- txt.replace(x, txt.space(2), txt.space(1))
    w <- z != x
    while (any(w)) {
        x[w] <- z[w]
        z[w] <- txt.replace(x[w], txt.space(2), txt.space(1))
        w[w] <- z[w] != x[w]
    }
    z
}

#' txt.left
#' 
#' Returns the left <y> characters
#' @param x = a vector of string
#' @param y = a positive integer
#' @keywords txt.left
#' @export
#' @family txt

txt.left <- function (x, y) 
{
    substring(x, 1, y)
}

#' txt.na
#' 
#' Returns a list of strings considered NA
#' @keywords txt.na
#' @export
#' @family txt

txt.na <- function () 
{
    c("#N/A", "NA", "NULL", "<NA>", "--", "#N/A N/A")
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
    if (any(txt.has(x, " ", T))) {
        z <- txt.parse(x, " ")
        z <- fcn.matrix(txt.name.format, z)
        x <- rep("", dim(z)[1])
        for (i in 1:dim(z)[2]) x <- paste(x, z[, i])
        z <- txt.trim(x)
    }
    else {
        x <- tolower(x)
        z <- txt.left(x, 1)
        x <- txt.right(x, nchar(x) - 1)
        z <- paste(toupper(z), x, sep = "")
    }
    z
}

#' txt.palindrome
#' 
#' short palindromes that reflect just before the first letter of <x>, or just after the last letter of <x>, or somewhere in-between.
#' @param x = a SINGLE string
#' @param y = potentially-usable capitalized words
#' @keywords txt.palindrome
#' @export
#' @family txt

txt.palindrome <- function (x, y) 
{
    tempus <- proc.time()[["elapsed"]]
    x <- toupper(x)
    x <- txt.to.char(x)
    x <- x[is.element(x, char.seq("A", "Z"))]
    x <- paste(x, collapse = "")
    if (missing(y)) 
        y <- paste(dir.parameters("data"), "EnglishWords.txt", 
            sep = "\\")
    y <- vec.read(y, F)
    y <- y[order(y)]
    y <- y[order(nchar(y), decreasing = T)]
    w <- txt.replace(x, " ", "")
    n <- seq(0.5, nchar(w) + 0.5, 0.5)
    x <- list(x = rep(x, length(n)), n = n, w = rep(w, length(n)))
    halt <- F
    while (!halt) {
        ord <- order(nchar(x$x))
        x <- lapply(x, function(x, y) x[y], ord)
        z <- txt.palindrome.underlying(x$x[1], y, x$n[1], x$w[1])
        if (length(z$z) > 0) 
            for (j in z$z) cat(paste(seconds.sho(tempus), j), 
                "\n")
        if (!is.null(z$rslt)) {
            for (j in names(x)) x[[j]] <- c(x[[j]][-1], z$rslt[[j]])
        }
        else if (length(x$x) == 1) {
            halt <- T
        }
        else x <- lapply(x, function(x) x[-1])
    }
    z <- z$z
    z
}

#' txt.palindrome.entire
#' 
#' words that entirely fit in the right/left tail
#' @param x = a SINGLE string
#' @param y = potentially-usable capitalized words
#' @param n = T/F depending on whether you want the right/left tail
#' @keywords txt.palindrome.entire
#' @export
#' @family txt

txt.palindrome.entire <- function (x, y, n) 
{
    m <- nchar(x)
    x <- paste(txt.to.char(x)[m:1], collapse = "")
    if (n) 
        z <- intersect(txt.left(x, m:1), y)
    else z <- intersect(txt.right(x, m:1), y)
    z
}

#' txt.palindrome.partial
#' 
#' single words that fit all of <x> in the right/left tail
#' @param x = a SINGLE string without spaces
#' @param y = potentially-usable capitalized words
#' @param n = T/F depending on whether you want the right/left tail
#' @keywords txt.palindrome.partial
#' @export
#' @family txt

txt.palindrome.partial <- function (x, y, n) 
{
    m <- nchar(x)
    x <- paste(txt.to.char(x)[m:1], collapse = "")
    if (n) 
        z <- y[txt.left(y, m) == x]
    else z <- y[txt.right(y, m) == x]
    z
}

#' txt.palindrome.tail
#' 
#' words that fit all of <x> in the right/left tail
#' @param x = a SINGLE string without spaces
#' @param y = potentially-usable capitalized words
#' @param n = T/F depending on whether you want the right/left tail
#' @keywords txt.palindrome.tail
#' @export
#' @family txt

txt.palindrome.tail <- function (x, y, n) 
{
    m <- nchar(x)
    h <- txt.palindrome.entire(x, y, n)
    n.h <- nchar(h)
    w.h <- n.h == m
    if (any(w.h)) 
        z <- h[w.h]
    else z <- NULL
    len.h <- sum(!w.h)
    if (len.h > 0) {
        h <- h[!w.h]
        n.h <- nchar(h)
        if (n) {
            for (j in 1:len.h) {
                w <- txt.palindrome.tail(substring(x, 1, m - 
                  n.h[j]), y, n)
                if (length(w) > 0) 
                  z <- c(z, paste(h[j], w))
            }
        }
        else {
            for (j in 1:len.h) {
                w <- txt.palindrome.tail(substring(x, n.h[j] + 
                  1, m), y, n)
                if (length(w) > 0) 
                  z <- c(z, paste(w, h[j]))
            }
        }
    }
    z <- union(z, txt.palindrome.partial(x, y, n))
    z
}

#' txt.palindrome.underlying
#' 
#' list object with the following elements: z) short palindromes that reflect on position <n> rslt) potential palnidromes that need more work
#' @param x = a SINGLE string
#' @param y = potentially-usable capitalized words
#' @param n = position of the reflection
#' @param w = <x> with spaces removed (for speed)
#' @keywords txt.palindrome.underlying
#' @export
#' @family txt

txt.palindrome.underlying <- function (x, y, n, w) 
{
    m <- nchar(w)
    if (n == floor(n)) {
        beg.n <- n - 1
        end.n <- n + 1
    }
    else {
        beg.n <- floor(n)
        end.n <- ceiling(n)
    }
    h <- min(beg.n, m - end.n + 1)
    proc.right <- proc.left <- F
    if (nchar(w) > 100) {
        rslt <- z <- NULL
    }
    else if (h > 0) {
        vec <- txt.to.char(w)
        if (all(vec[seq(beg.n, beg.n - h + 1)] == vec[seq(end.n, 
            end.n + h - 1)])) {
            proc.right <- end.n + h - 1 < m
            proc.left <- beg.n > h & !proc.right
            if (!proc.right & !proc.left) 
                z <- x
        }
        else rslt <- z <- NULL
    }
    else {
        proc.right <- beg.n == 0
        proc.left <- !proc.right
    }
    if (proc.right) {
        z <- txt.palindrome.tail(substring(w, end.n + h, m), 
            y, F)
        len.z <- length(z)
        if (len.z == 0) {
            rslt <- NULL
        }
        else {
            m <- m - end.n - h + 1
            h <- txt.replace(z, " ", "")
            n.h <- nchar(h)
            w.h <- n.h == m
            n <- n.h + n
            h <- paste(h, w, sep = "")
            z <- paste(z, x)
            if (any(w.h)) {
                z <- z[w.h]
                rslt <- NULL
            }
            else {
                rslt <- list(x = z, n = n, w = h)
                z <- NULL
            }
        }
    }
    else if (proc.left) {
        z <- txt.palindrome.tail(substring(w, 1, beg.n - h), 
            y, T)
        len.z <- length(z)
        if (len.z == 0) {
            rslt <- NULL
        }
        else {
            m <- beg.n - h
            h <- txt.replace(z, " ", "")
            w.h <- nchar(h) == m
            h <- paste(w, h, sep = "")
            z <- paste(x, z)
            if (any(w.h)) {
                z <- z[w.h]
                rslt <- NULL
            }
            else {
                rslt <- list(x = z, n = rep(n, len.z), w = h)
                z <- NULL
            }
        }
    }
    z <- list(z = z, rslt = rslt)
    z
}

#' txt.parse
#' 
#' breaks up string <x> by <y>
#' @param x = a vector of strings
#' @param y = a string that serves as a delimiter
#' @keywords txt.parse
#' @export
#' @family txt

txt.parse <- function (x, y) 
{
    if (any(is.na(x))) 
        stop("Bad")
    x0 <- x
    ctr <- 1
    z <- list()
    w <- as.numeric(regexpr(y, x, fixed = T))
    while (any(!is.element(w, -1))) {
        w <- ifelse(is.element(w, -1), 1 + nchar(x), w)
        vec <- ifelse(w > 1, substring(x, 1, w - 1), "")
        z[[paste("pos", ctr, sep = ".")]] <- vec
        x <- txt.right(x, nchar(x) - nchar(vec) - nchar(y))
        ctr <- ctr + 1
        w <- as.numeric(regexpr(y, x, fixed = T))
    }
    z[[paste("pos", ctr, sep = ".")]] <- x
    if (length(x0) > 1) {
        z <- mat.ex.matrix(z)
        if (all(!duplicated(x0))) 
            dimnames(z)[[1]] <- x0
    }
    else z <- unlist(z)
    z
}

#' txt.prepend
#' 
#' bulks up each string to have at least <y> characters by adding <n> to the beginning of each string
#' @param x = a vector of strings
#' @param y = number of characters to add
#' @param n = the characters to add at the beginning
#' @keywords txt.prepend
#' @export
#' @family txt

txt.prepend <- function (x, y, n) 
{
    z <- x
    w <- nchar(z) < y
    while (any(w)) {
        z[w] <- paste(n, z[w], sep = "")
        w <- nchar(z) < y
    }
    z
}

#' txt.regr
#' 
#' returns the string you need to regress the first column on the others
#' @param x = a vector of column names
#' @param y = T/F depending on whether regression has an intercept
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
#' replaces all instances of <txt.out> by <txt.by>
#' @param x = a vector of strings
#' @param y = a string to be swapped out
#' @param n = a string to replace <txt.out> with
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
#' @param x = vector of strings
#' @keywords txt.reverse
#' @export
#' @family txt

txt.reverse <- function (x) 
{
    fcn <- function(x) paste(txt.to.char(x)[nchar(x):1], collapse = "")
    z <- fcn.vec.num(fcn, x)
    z
}

#' txt.right
#' 
#' Returns the right <y> characters
#' @param x = a vector of string
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
#' @param x = any integer
#' @param y = a single character
#' @keywords txt.space
#' @export
#' @family txt

txt.space <- function (x, y = " ") 
{
    z <- ""
    while (x > 0) {
        z <- paste(z, y, sep = "")
        x <- x - 1
    }
    z
}

#' txt.to.char
#' 
#' a vector of the constitutent characters of <x>
#' @param x = a SINGLE string
#' @keywords txt.to.char
#' @export
#' @family txt

txt.to.char <- function (x) 
{
    strsplit(x, "")[[1]]
}

#' txt.trim
#' 
#' trims leading/trailing spaces
#' @param x = a vector of string
#' @param y = a vector of verboten strings, each of the same length
#' @keywords txt.trim
#' @export
#' @family txt

txt.trim <- function (x, y = " ") 
{
    txt.trim.right(txt.trim.left(x, y), y)
}

#' txt.trim.end
#' 
#' trims off leading or trailing elements of <y>
#' @param fcn = a function that returns characters from the bad end
#' @param x = a vector of string
#' @param y = a vector of verboten strings, each of the same length
#' @param n = a functon that returns characters from the opposite end
#' @keywords txt.trim.end
#' @export
#' @family txt

txt.trim.end <- function (fcn, x, y, n) 
{
    h <- nchar(y[1])
    z <- x
    w <- nchar(z) > h - 1 & is.element(fcn(z, h), y)
    while (any(w)) {
        z[w] <- n(z[w], nchar(z[w]) - h)
        w <- nchar(z) > h - 1 & is.element(fcn(z, h), y)
    }
    z
}

#' txt.trim.left
#' 
#' trims off leading elements of <y>
#' @param x = a vector of string
#' @param y = a vector of verboten strings, each of the same length
#' @keywords txt.trim.left
#' @export
#' @family txt

txt.trim.left <- function (x, y) 
{
    txt.trim.end(txt.left, x, y, txt.right)
}

#' txt.trim.right
#' 
#' trims off trailing elements of <y>
#' @param x = a vector of string
#' @param y = a vector of verboten strings, each of the same length
#' @keywords txt.trim.right
#' @export
#' @family txt

txt.trim.right <- function (x, y) 
{
    txt.trim.end(txt.right, x, y, txt.left)
}

#' variance.ratio.test
#' 
#' tests whether <x> follows a random walk (i.e. <x> independent of prior values)
#' @param x = vector
#' @param y = an integer greater than 1
#' @keywords variance.ratio.test
#' @export

variance.ratio.test <- function (x, y) 
{
    y <- as.numeric(y)
    if (is.na(y) | y == 1) 
        stop("Bad value of y ...")
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
#' @param x = a numeric vector
#' @keywords vec.count
#' @export
#' @family vec

vec.count <- function (x) 
{
    pivot.1d(sum, x, rep(1, length(x)))
}

#' vec.max
#' 
#' Returns the piecewise maximum of <x> and <y>
#' @param x = a vector/matrix/dataframe
#' @param y = a number/vector or matrix/dataframe with the same dimensions as <x>
#' @keywords vec.max
#' @export
#' @family vec

vec.max <- function (x, y) 
{
    fcn <- function(x, y) ifelse(!is.na(x) & !is.na(y) & x < 
        y, y, x)
    z <- fcn.mat.vec(fcn, x, y, T)
    z
}

#' vec.min
#' 
#' Returns the piecewise minimum of <x> and <y>
#' @param x = a vector/matrix/dataframe
#' @param y = a number/vector or matrix/dataframe with the same dimensions as <x>
#' @keywords vec.min
#' @export
#' @family vec

vec.min <- function (x, y) 
{
    fcn <- function(x, y) ifelse(!is.na(x) & !is.na(y) & x > 
        y, y, x)
    z <- fcn.mat.vec(fcn, x, y, T)
    z
}

#' vec.named
#' 
#' Returns a vector with values <x> and names <y>
#' @param x = a vector
#' @param y = an isomekic vector
#' @keywords vec.named
#' @export
#' @family vec

vec.named <- function (x, y) 
{
    if (missing(x)) 
        x <- rep(NA, length(y))
    z <- x
    names(z) <- y
    z
}

#' vec.read
#' 
#' reads into a vector
#' @param x = path to a vector
#' @param y = T/F depending on whether the elements are named
#' @keywords vec.read
#' @export
#' @family vec

vec.read <- function (x, y) 
{
    if (!y & !file.exists(x)) {
        stop("File ", x, " doesn't exist!\n")
    }
    else if (!y) {
        z <- scan(x, what = "", sep = "\n", quiet = T)
    }
    else z <- as.matrix(mat.read(x, w = F))[, 1]
    z
}

#' vec.same
#' 
#' T/F depending on whether <x> and <y> are identical
#' @param x = a vector
#' @param y = an isomekic vector
#' @keywords vec.same
#' @export
#' @family vec

vec.same <- function (x, y) 
{
    z <- all(is.na(x) == is.na(y))
    if (z) {
        w <- !is.na(x)
        if (any(w)) 
            z <- all(abs(x[w] - y[w]) < 1e-06)
    }
    z
}

#' vec.swap
#' 
#' swaps elements <y> and <n> of vector <x>
#' @param x = a vector
#' @param y = an integer between 1 and length(<x>)
#' @param n = an integer between 1 and length(<x>)
#' @keywords vec.swap
#' @export
#' @family vec

vec.swap <- function (x, y, n) 
{
    z <- x[y]
    x[y] <- x[n]
    x[n] <- z
    z <- x
    z
}

#' vec.to.lags
#' 
#' a data frame of <x> together with itself lagged 1, ..., <y> - 1 times
#' @param x = a numeric vector (time flows forward)
#' @param y = number of lagged values desired plus one
#' @keywords vec.to.lags
#' @export
#' @family vec

vec.to.lags <- function (x, y) 
{
    n <- length(x)
    z <- mat.ex.matrix(matrix(NA, n, y, F, list(1:n, paste("lag", 
        1:y - 1, sep = ""))))
    for (i in 1:y) z[i:n, i] <- x[i:n - (i - 1)]
    z
}

#' vec.to.list
#' 
#' list object
#' @param x = string vector
#' @keywords vec.to.list
#' @export
#' @family vec

vec.to.list <- function (x) 
{
    z <- list()
    for (i in 1:length(x)) z[[col.ex.int(i)]] <- x[i]
    z
}

#' vec.unique
#' 
#' returns unique values of <x> in ascending order
#' @param x = a numeric vector
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

#' vec.zScore
#' 
#' zScores <x>
#' @param x = a vector
#' @param y = a 1/0 membership vector
#' @param n = a vector of groups (e.g. GSec)
#' @keywords vec.zScore
#' @export
#' @family vec

vec.zScore <- function (x, y, n) 
{
    if (missing(y)) 
        y <- rep(1, length(x))
    if (missing(n)) 
        n <- rep(1, length(x))
    w <- !is.na(x) & !is.na(n) & is.element(y, 1)
    u.grp <- n[w]
    u.grp <- u.grp[!duplicated(u.grp)]
    z <- rep(NA, length(x))
    for (i in u.grp) {
        w <- !is.na(x) & is.element(n, i) & is.element(y, 1)
        if (sum(w) > 1) {
            mx <- mean(x[w])
            sx <- sd(x[w])
            w <- !is.na(x) & is.element(n, i)
            z[w] <- (x[w] - mx)/sx
        }
    }
    z
}

#' weekday.to.name
#' 
#' Converts to 0 = Sun, 1 = Mon, ..., 6 = Sat
#' @param x = a vector of numbers between 0 and 6
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

#' yyyy.ex.yy
#' 
#' returns a vector of YYYY
#' @param x = a vector of non-negative integers
#' @keywords yyyy.ex.yy
#' @export

yyyy.ex.yy <- function (x) 
{
    x <- as.numeric(x)
    z <- ifelse(x < 100, ifelse(x < 50, 2000, 1900), 0) + x
    z
}

#' yyyymm.diff
#' 
#' returns <x - y> in terms of YYYYMM
#' @param x = a vector of YYYYMM
#' @param y = an isomekic vector of YYYYMM
#' @keywords yyyymm.diff
#' @export
#' @family yyyymm

yyyymm.diff <- function (x, y) 
{
    obj.diff(yyyymm.to.int, x, y)
}

#' yyyymm.ex.int
#' 
#' returns a vector of <yyyymm> months
#' @param x = a vector of integers
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
#' returns quarter end in yyyymm
#' @param x = a vector of quarters
#' @keywords yyyymm.ex.qtr
#' @export
#' @family yyyymm

yyyymm.ex.qtr <- function (x) 
{
    z <- qtr.to.int(x)
    z <- yyyymm.ex.int(z * 3)
    z
}

#' yyyymm.lag
#' 
#' lags <x> by <y> months
#' @param x = a vector of <yyyymm> months or <yyyymmdd> days
#' @param y = an integer or an isomekic vector of integers
#' @keywords yyyymm.lag
#' @export
#' @family yyyymm

yyyymm.lag <- function (x, y = 1) 
{
    if (nchar(x[1]) == 8) 
        yyyymmdd.lag(x, y)
    else obj.lag(x, y, yyyymm.to.int, yyyymm.ex.int)
}

#' yyyymm.seq
#' 
#' returns a sequence of YYYYMM or YYYYMMDD between (and including) x and y
#' @param x = a YYYYMM or YYYYMMDD
#' @param y = an isotypic element
#' @param n = quantum size in YYYYMM or YYYYMMDD
#' @keywords yyyymm.seq
#' @export
#' @family yyyymm

yyyymm.seq <- function (x, y, n = 1) 
{
    if (nchar(x) == 8) 
        yyyymmdd.seq(x, y, n)
    else obj.seq(x, y, yyyymm.to.int, yyyymm.ex.int, n)
}

#' yyyymm.to.day
#' 
#' Returns the last day in the month whether weekend or not.
#' @param x = a vector of months in yyyymm format
#' @keywords yyyymm.to.day
#' @export
#' @family yyyymm

yyyymm.to.day <- function (x) 
{
    day.lag(paste(yyyymm.lag(x, -1), "01", sep = ""), 1)
}

#' yyyymm.to.int
#' 
#' returns a vector of integers
#' @param x = a vector of <yyyymm> months
#' @keywords yyyymm.to.int
#' @export
#' @family yyyymm

yyyymm.to.int <- function (x) 
{
    z <- as.numeric(substring(x, 1, 4))
    z <- 12 * z + as.numeric(substring(x, 5, 6))
    z
}

#' yyyymm.to.qtr
#' 
#' returns associated quarters
#' @param x = a vector of yyyymm
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
#' @param x = a vector of dates in yyyymm format
#' @keywords yyyymm.to.yyyy
#' @export
#' @family yyyymm

yyyymm.to.yyyy <- function (x) 
{
    z <- as.numeric(x)
    z <- z%/%100
    z
}

#' yyyymmdd.bulk
#' 
#' Eliminates YYYYMMDD gaps
#' @param x = a matrix/df indexed by YYYYMMDD
#' @keywords yyyymmdd.bulk
#' @export
#' @family yyyymmdd

yyyymmdd.bulk <- function (x) 
{
    z <- dimnames(x)[[1]]
    z <- yyyymm.seq(z[1], z[dim(x)[1]])
    w <- !is.element(z, dimnames(x)[[1]])
    if (any(w)) 
        err.raise(z[w], F, "Following weekdays missing from data")
    z <- map.rname(x, z)
    z
}

#' yyyymmdd.diff
#' 
#' returns <x - y> in terms of YYYYMMDD
#' @param x = a vector of YYYYMMDD
#' @param y = an isomekic vector of YYYYMMDD
#' @keywords yyyymmdd.diff
#' @export
#' @family yyyymmdd

yyyymmdd.diff <- function (x, y) 
{
    obj.diff(yyyymmdd.to.int, x, y)
}

#' yyyymmdd.ex.AllocMo
#' 
#' Returns an object indexed by flow dates
#' @param x = an object indexed by allocation months
#' @keywords yyyymmdd.ex.AllocMo
#' @export
#' @family yyyymmdd

yyyymmdd.ex.AllocMo <- function (x) 
{
    y <- dimnames(x)[[1]]
    y <- y[order(y)]
    begPrd <- yyyymmdd.ex.yyyymm(y[1], F)[1]
    endPrd <- yyyymmdd.ex.yyyymm(yyyymm.lag(y[dim(x)[1]], -2), 
        T)
    y <- yyyymmdd.seq(begPrd, endPrd)
    y <- vec.named(yyyymmdd.to.AllocMo(y), y)
    y <- y[is.element(y, dimnames(x)[[1]])]
    z <- map.rname(x, y)
    dimnames(z)[[1]] <- names(y)
    z
}

#' yyyymmdd.ex.day
#' 
#' Falls back to the closest YYYYMMDD
#' @param x = a vector of calendar dates
#' @keywords yyyymmdd.ex.day
#' @export
#' @family yyyymmdd

yyyymmdd.ex.day <- function (x) 
{
    z <- day.to.int(x)
    z <- z - vec.max(z%%7 - 4, 0)
    z <- day.ex.int(z)
    z
}

#' yyyymmdd.ex.int
#' 
#' YYYYMMDD
#' @param x = an integer or vector of integers
#' @keywords yyyymmdd.ex.int
#' @export
#' @family yyyymmdd

yyyymmdd.ex.int <- function (x) 
{
    day.ex.int(x + 2 * (x%/%5))
}

#' yyyymmdd.ex.txt
#' 
#' returns a vector of YYYYMMDD (formerly UIDate2yyyymmdd)
#' @param x = a vector of dates in some format
#' @param y = separators used within <x>
#' @param n = order in which month, day and year are represented
#' @keywords yyyymmdd.ex.txt
#' @export
#' @family yyyymmdd

yyyymmdd.ex.txt <- function (x, y = "/", n = "MDY") 
{
    m <- as.numeric(regexpr(" ", x))
    m <- ifelse(m == -1, 1 + nchar(x), m)
    x <- substring(x, 1, m - 1)
    z <- list()
    z[[txt.left(n, 1)]] <- substring(x, 1, as.numeric(regexpr(y, 
        x)) - 1)
    x <- substring(x, 2 + nchar(z[[1]]), nchar(x))
    z[[substring(n, 2, 2)]] <- substring(x, 1, as.numeric(regexpr(y, 
        x)) - 1)
    z[[substring(n, 3, 3)]] <- substring(x, 2 + nchar(z[[2]]), 
        nchar(x))
    x <- yyyy.ex.yy(z[["Y"]])
    z <- 10000 * x + 100 * as.numeric(z[["M"]]) + as.numeric(z[["D"]])
    z <- as.character(z)
    z
}

#' yyyymmdd.ex.yyyymm
#' 
#' Returns the last trading day or all trading days
#' @param x = a SINGLE month in yyyymm format
#' @param y = T/F variable depending on whether the last or all trading days in that month are desired
#' @keywords yyyymmdd.ex.yyyymm
#' @export
#' @family yyyymmdd

yyyymmdd.ex.yyyymm <- function (x, y = T) 
{
    z <- paste(yyyymm.lag(x, -1), "01", sep = "")
    z <- yyyymmdd.ex.day(z)
    w <- yyyymmdd.to.yyyymm(z) != x
    if (any(w)) 
        z[w] <- yyyymm.lag(z[w])
    if (!y & length(x) > 1) 
        stop("You can't do this ...\n")
    if (!y) {
        x <- paste(x, "01", sep = "")
        x <- yyyymmdd.ex.day(x)
        if (yyyymmdd.to.yyyymm(x) != yyyymmdd.to.yyyymm(z)) 
            x <- yyyymm.lag(x, -1)
        z <- yyyymm.seq(x, z)
    }
    z
}

#' yyyymmdd.exists
#' 
#' returns T if <x> is YYYYMMDD
#' @param x = a vector of calendar dates
#' @keywords yyyymmdd.exists
#' @export
#' @family yyyymmdd

yyyymmdd.exists <- function (x) 
{
    is.element(day.to.weekday(x), 1:5)
}

#' yyyymmdd.lag
#' 
#' lags <x> by <y> YYYYMMDD.
#' @param x = a vector of yyyymmdd-dates that happen to fall on a weekday
#' @param y = a number
#' @keywords yyyymmdd.lag
#' @export
#' @family yyyymmdd

yyyymmdd.lag <- function (x, y) 
{
    obj.lag(x, y, yyyymmdd.to.int, yyyymmdd.ex.int)
}

#' yyyymmdd.seq
#' 
#' returns a sequence of YYYYMMDD between (and including) x and y
#' @param x = a single YYYYMMDD
#' @param y = a single YYYYMMDD
#' @param n = quantum size in YYYYMMDD
#' @keywords yyyymmdd.seq
#' @export
#' @family yyyymmdd

yyyymmdd.seq <- function (x, y, n = 1) 
{
    if (any(!yyyymmdd.exists(c(x, y)))) 
        stop("Some of your 'weekdays' fall on Sat/Sun!")
    z <- obj.seq(x, y, yyyymmdd.to.int, yyyymmdd.ex.int, n)
    z
}

#' yyyymmdd.to.AllocMo
#' 
#' Returns the month for which you need to get allocations Flows as of the 23rd of each month are known by the 24th. By this time allocations from the previous month are known
#' @param x = the date for which you want flows (known one day later)
#' @param y = calendar day in the next month when allocations are known (usually 24 for countries)
#' @keywords yyyymmdd.to.AllocMo
#' @export
#' @family yyyymmdd

yyyymmdd.to.AllocMo <- function (x, y = 23) 
{
    n <- txt.right(x, 2)
    n <- as.numeric(n)
    n <- ifelse(n < y, 2, 1)
    z <- yyyymmdd.to.yyyymm(x)
    z <- yyyymm.lag(z, n)
    z
}

#' yyyymmdd.to.CalYrDyOfWk
#' 
#' Converts to 0 = Sun, 1 = Mon, ..., 6 = Sat
#' @param x = a vector of dates in yyyymmdd format
#' @keywords yyyymmdd.to.CalYrDyOfWk
#' @export
#' @family yyyymmdd

yyyymmdd.to.CalYrDyOfWk <- function (x) 
{
    z <- day.to.weekday(x)
    z <- as.numeric(z)
    z <- z/10
    x <- substring(x, 1, 4)
    x <- as.numeric(x)
    z <- x + z
    z
}

#' yyyymmdd.to.int
#' 
#' Number of week days since Monday, 12/30/46
#' @param x = a vector of YYYYMMDD
#' @keywords yyyymmdd.to.int
#' @export
#' @family yyyymmdd

yyyymmdd.to.int <- function (x) 
{
    z <- day.to.int(x)
    z <- z - 2 * (z%/%7)
    z
}

#' yyyymmdd.to.unity
#' 
#' returns a vector of 1's corresponding to the length of <x>
#' @param x = a vector of dates in yyyymmdd format
#' @keywords yyyymmdd.to.unity
#' @export
#' @family yyyymmdd

yyyymmdd.to.unity <- function (x) 
{
    rep(1, length(x))
}

#' yyyymmdd.to.weekofmonth
#' 
#' returns 1 if the date fell in the first week of the month, 2 if it fell in the second, etc.
#' @param x = a vector of dates in yyyymmdd format
#' @keywords yyyymmdd.to.weekofmonth
#' @export
#' @family yyyymmdd

yyyymmdd.to.weekofmonth <- function (x) 
{
    z <- substring(x, 7, 8)
    z <- as.numeric(z)
    z <- (z - 1)%/%7 + 1
    z
}

#' yyyymmdd.to.yyyymm
#' 
#' Converts to yyyymm format
#' @param x = a vector of dates in yyyymmdd format
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
#' Coverts NA's to zero
#' @param x = a vector/matrix/dataframe
#' @keywords zav
#' @export

zav <- function (x) 
{
    fcn <- function(x) ifelse(is.na(x), 0, x)
    z <- fcn.mat.vec(fcn, x, , T)
    z
}

#' zScore
#' 
#' Converts <x>, if a vector, or the rows of <x> otherwise, to a zScore
#' @param x = a vector/matrix/data-frame
#' @keywords zScore
#' @export

zScore <- function (x) 
{
    fcn.mat.vec(vec.zScore, x, , F)
}
