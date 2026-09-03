# 00_setup.R -----------------------------------------------------------------
# Paths, libraries and shared helpers. Sourced by every other script.
# Data lives OUTSIDE the repo; nothing here writes to the data directory.

.libPaths(c(path.expand("~/Rlibs"), .libPaths()))
suppressMessages({
  library(readxl)
})

# --- paths ------------------------------------------------------------------
# All scripts are run from the repository root (see run_all.R).
REPO <- getwd()
if (!dir.exists(file.path(REPO, "R")))
  stop("Run from the repository root: setwd() to the folder containing R/")
DATA <- normalizePath(file.path(REPO, "..", "Data"), mustWork = TRUE)
DERIVED <- file.path(REPO, "data-derived")
OUTPUT  <- file.path(REPO, "output")
dir.create(DERIVED, showWarnings = FALSE)
dir.create(OUTPUT,  showWarnings = FALSE)

# --- helpers ----------------------------------------------------------------
rx <- function(...) suppressWarnings(suppressMessages(readxl::read_excel(...)))

#' Excel serial date strings -> Date. Returns NA for anything unparseable.
excel_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXct")) return(as.Date(x))
  n <- suppressWarnings(as.numeric(x))
  out <- as.Date(rep(NA_real_, length(x)), origin = "1970-01-01")
  ok <- !is.na(n) & n > 1000 & n < 60000
  out[ok] <- as.Date(n[ok], origin = "1899-12-30")
  # fall back to parsing anything that looks like an ISO date string
  bad <- is.na(out) & !is.na(x) & is.character(x) &
    grepl("^\\d{4}-\\d{2}-\\d{2}", as.character(x))
  if (any(bad)) {
    out[bad] <- suppressWarnings(as.Date(substr(as.character(x[bad]), 1, 10)))
  }
  out
}

#' UK fiscal year starting April. Returns the START year (2010 => FY 2010-11).
fiscal_year <- function(d) {
  y <- as.integer(format(d, "%Y")); m <- as.integer(format(d, "%m"))
  ifelse(is.na(d), NA_integer_, ifelse(m >= 4L, y, y - 1L))
}

#' Quarter assignment. Mid-month rule: days after the 15th roll into the next
#' quarter. `basis = "calendar"` starts quarters in January, `"fiscal"` in April.
#' Returns a data.frame(year, quarter) where `year` is the quarter's own year
#' (calendar) or the fiscal-year start (fiscal).
assign_quarter <- function(d, basis = c("calendar", "fiscal")) {
  basis <- match.arg(basis)
  y <- as.integer(format(d, "%Y")); m <- as.integer(format(d, "%m")); dd <- as.integer(format(d, "%d"))
  # shift into the "effective month": second half of a month belongs to the next
  em <- m + as.integer(dd > 15L)
  ey <- y + as.integer(em > 12L)
  em <- ifelse(em > 12L, 1L, em)
  if (basis == "calendar") {
    q <- ((em - 1L) %/% 3L) + 1L
    qy <- ey
  } else {
    # fiscal quarters: Apr-Jun = 1, Jul-Sep = 2, Oct-Dec = 3, Jan-Mar = 4
    fm <- ((em - 4L) %% 12L)           # 0 for April
    q  <- (fm %/% 3L) + 1L
    qy <- ifelse(em >= 4L, ey, ey - 1L)
  }
  data.frame(year = ifelse(is.na(d), NA_integer_, qy),
             quarter = ifelse(is.na(d), NA_integer_, q))
}

#' Harmonised policy group, matching Cloyne's `Group` field.
map_group <- function(tax_type) {
  t <- tolower(trimws(tax_type))
  business <- c("apprenticeship levy","bank levy","bank surcharge","business rates","ccl",
                "climate change levy","digital services tax","diverted profits tax","eu ets",
                "landfill tax","north sea taxes","on-shore ct","onshore ct","pcgos",
                "probate fees","soft drinks levy","ct","corporation tax")
  capital  <- c("cgt","council tax","iht","stamp duty","capital gains","inheritance")
  consump  <- c("alcohol duty","apd","betting","fuel duty","fuel duties","gambling",
                "immigration health surcharge","ipt","pay to stay","tobacco duty","vat","ved",
                "insurance premium tax","air passenger duty","vehicle excise duty")
  out <- rep(NA_character_, length(t))
  out[t %in% business] <- "Business"
  out[t %in% capital]  <- "Capital"
  out[t %in% consump]  <- "Consumption"
  out[t %in% c("income tax","income")]  <- "Income"
  out[t %in% c("nics","ni","national insurance")] <- "Social Security"
  out[t %in% c("other tax","other")] <- "Other"
  out
}

#' Repair UTF-8 read as latin1 ("¬£85,000" -> "£85,000"). 50 modern measure
#' descriptions are affected; cosmetic, but they would surface in any published
#' appendix or dataset release.
fix_encoding <- function(x) {
  x <- gsub("¬£", "£", x)   # ¬£ -> £
  x <- gsub("Â£", "£", x)   # Â£ -> £
  x <- gsub("â", "'", x)  # curly apostrophe
  x <- gsub("â|â", "\"", x)
  x
}

#' Tidy tax-type labels (fixes the capitalisation/plural drift in the source).
tidy_tax_type <- function(x) {
  x <- trimws(x)
  x[x == "income tax"]     <- "Income tax"
  x[x == "Alcohol Duty"]   <- "Alcohol duty"
  x[x == "Business Rates"] <- "Business rates"
  x[x == "Fuel duty"]      <- "Fuel duties"
  x
}

#' Common tax-type taxonomy spanning both codings.
#' Cloyne and the modern coding itemise at different granularity: Cloyne uses a
#' single "Duty" catch-all where the modern data splits fuel / alcohol / tobacco
#' / APD / VED, and labels differ ("NI" vs "NICs", "SDLT" vs "Stamp duty").
#' Any chained analysis by instrument must run on this harmonised field.
harmonise_tax_type <- function(x) {
  t <- tolower(trimws(x))
  # Unrecognised labels stay NA. Defaulting them to "Other" would hand a
  # confident category to the very rows the Cloyne salvage deliberately
  # refused to classify.
  out <- rep(NA_character_, length(t))
  out[t %in% c("income", "income tax")] <- "Income"
  out[t %in% c("ni", "nics", "national insurance", "social security")] <- "Social security"
  out[t %in% c("vat")] <- "VAT"
  out[t %in% c("duty", "duties", "fuel duty", "fuel duties", "alcohol duty",
               "tobacco duty", "apd", "air passenger duty", "ved",
               "vehicle excise duty", "betting", "gambling", "ipt",
               "insurance premium tax", "soft drinks levy")] <- "Excise and duties"
  out[t %in% c("cgt", "capital gains")] <- "Capital gains"
  out[t %in% c("iht", "inheritance", "estate duty", "estate")] <- "Inheritance"
  out[t %in% c("stamp duty", "sdlt", "stamp")] <- "Property transaction"
  out[t %in% c("ct", "on-shore ct", "onshore ct", "corporation tax",
               "business rates", "bank levy", "bank surcharge",
               "diverted profits tax", "digital services tax",
               "apprenticeship levy")] <- "Corporate"
  out[t %in% c("oil", "north sea taxes", "prt")] <- "Oil and North Sea"
  out[t %in% c("council tax")] <- "Property recurrent"
  out[t %in% c("other tax", "other")] <- "Other"
  out[is.na(t)] <- NA_character_
  out
}

#' Revenue-weighted median. This is the workhorse for any statistic compared
#' across the Cloyne and modern codings: the two itemise Budgets at different
#' granularity (Cloyne ~11 measures per event, modern ~4) but cover the same
#' money, so weighting by |revenue| makes them commensurable. Validated on the
#' 2004-2009 overlap, where it drives the two codings to the same answer.
weighted_median <- function(x, w) {
  ok <- !is.na(x) & !is.na(w) & w > 0
  if (!any(ok)) return(NA_real_)
  x <- x[ok]; w <- w[ok]
  o <- order(x); x <- x[o]; w <- w[o]
  x[which(cumsum(w) / sum(w) >= 0.5)[1]]
}

msg <- function(...) cat(sprintf(...), "\n", sep = "")

# --- local projection machinery (scripts 13, 14) ----------------------------

#' Newey-West HAC standard errors for lm, Bartlett kernel, bandwidth L.
#' Local projections overlap h steps, so L = h + 1 is the usual choice.
nw_se <- function(fit, L) {
  X <- model.matrix(fit); u <- residuals(fit); n <- nrow(X); k <- ncol(X)
  XtXi <- solve(crossprod(X))
  S <- crossprod(X * u)
  if (L > 0) for (l in seq_len(L)) {
    w <- 1 - l/(L + 1)
    G <- crossprod(X[(l+1):n, , drop = FALSE] * u[(l+1):n],
                   X[1:(n-l), , drop = FALSE] * u[1:(n-l)])
    S <- S + w * (G + t(G))
  }
  sqrt(diag(XtXi %*% S %*% XtXi * (n/(n - k))))
}

#' k lags of x as a matrix.
lag_mat <- function(x, k) sapply(seq_len(k), function(i) c(rep(NA, i), head(x, -i)))

#' Jorda local projections of a log level `y` on shock `s`.
#'
#' Horizons may be NEGATIVE. A negative horizon is a placebo: it asks what
#' output was doing BEFORE the shock landed, and a valid shock must show
#' nothing there.
#'
#' @param y      log level of the outcome
#' @param s      the shock series
#' @param ok     logical, which observations are in the estimation sample
#' @param X      optional data.frame of extra regressors, contemporaneous
#' @param H      horizons
#' @param nlag   lags of the shock and of outcome growth to include
#' @param minobs refuse to estimate below this many observations
#' @param nlag_y  lags of outcome growth. MUST be 0 for placebo (negative)
#'   horizons: y[t+h] - y[t-1] with h negative is exactly minus the sum of
#'   growth over the intervening quarters, so for |h| <= nlag_y the dependent
#'   variable is spanned by the included growth lags and the shock coefficient
#'   is driven to zero by construction.
lp_project <- function(y, s, ok, X = NULL, H = 0:16, nlag = 4, minobs = 40,
                       nlag_y = nlag) {
  dg <- c(NA, 100 * diff(y))
  base <- data.frame(s = s, lag_mat(s, nlag))
  names(base) <- c("s", paste0("Ls", seq_len(nlag)))
  if (nlag_y > 0) {
    G <- as.data.frame(lag_mat(dg, nlag_y))
    names(G) <- paste0("Lg", seq_len(nlag_y))
    base <- cbind(base, G)
  }
  if (!is.null(X)) base <- cbind(base, X)
  do.call(rbind, lapply(H, function(h) {
    idx <- seq_along(y) + h
    idx[idx < 1 | idx > length(y)] <- NA
    yh <- 100 * (y[idx] - c(NA, head(y, -1)))
    df <- cbind(yh = yh, base)
    keep <- complete.cases(df) & ok
    df <- df[keep, , drop = FALSE]
    if (nrow(df) < minobs) return(NULL)
    f  <- lm(yh ~ ., data = df)
    b  <- coef(f)[["s"]]; se <- nw_se(f, abs(h) + 1)[["s"]]
    data.frame(h = h, n = nrow(df), b = b, se = se,
               lo = b - 1.96*se, hi = b + 1.96*se, t = b/se)
  }))
}

#' Cloyne's (2013) quarter assignment: shift the implementation date forward 45
#' days, then take the calendar quarter of the result. His stated rationale is
#' that action in the second half of a quarter belongs to the next one.
#'
#' This is NOT the same as `assign_quarter`, which pushes a date past the 15th
#' of a month into the next month. The two disagree often enough to matter:
#' rebuilding his published surprise series with our rule instead of his drops
#' the correlation with it from 1.000 to 0.932. Paper 1 uses `assign_quarter`
#' and stays on it; Paper 2 uses this, because comparability with the published
#' multiplier literature is the point there.
#'
#' @param retro_fix replace an implementation date that precedes its own
#'   announcement with the announcement date, as he does.
cloyne_quarter <- function(implement, announce = NULL, retro_fix = TRUE) {
  imp <- implement
  if (retro_fix && !is.null(announce)) {
    swap <- !is.na(announce) & !is.na(imp) & imp < announce
    imp[swap] <- announce[swap]
  }
  sh <- imp + 45
  data.frame(year    = as.integer(format(sh, "%Y")),
             quarter = (as.integer(format(sh, "%m")) - 1L) %/% 3L + 1L)
}
