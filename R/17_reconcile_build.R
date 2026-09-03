# 17_reconcile_build.R ---------------------------------------------------------
# Reconciles our shock construction against Cloyne's published one by rebuilding
# from his raw file with his conventions switched on one at a time, and
# correlating each variant with his published 1955-2009 surprise series.
#
# HIS CONVENTIONS, taken from CloyneAERTaxShocks.do on his website:
#   drop if ImplementationDate == . ; drop if Excluded == 1
#   TaxData "" or "*" becomes 0
#   ImplementationDate_ExclRetro = Announcement where implementation precedes it
#   AdjustedImplDate = ImplementationDate_ExclRetro + 45 days, then take the
#     calendar quarter of that
#   collapse (sum) by motive, year, quarter
#   shock = Taxseries * 100 / NominalGDP, where his NominalGDP sheet column G is
#     already the ANNUALISED quarterly figure
#   the surprise variant keeps measures implemented within 90 days of
#     announcement
#
# OURS DIFFERS IN FOUR PLACES, and the point of this script is to price each:
#   quarter rule   we push a date past the 15th of a month into the next month,
#                  he adds 45 days
#   threshold      we use 120 days from Paper 1, he uses 90
#   retroactivity  we keep the raw implementation date and flag the measure,
#                  he replaces it with the announcement date
#   GDP vintage    we use the JPE panel, he used ONS YBHA as at August 2010
#
# The target is his published series. Anything we then change from his baseline
# is a deliberate choice we have to defend, not an unexplained gap.

source("R/00_setup.R")
msg("== 17_reconcile_build ==")

aer_p <- file.path(DERIVED, "external", "cloyne2013_surprises.xls")
raw_p <- file.path(DATA, "CloyneNarrativeDataset-2.xlsx")
if (!file.exists(aer_p)) stop("Run R/16_reconcile.R first to fetch the published series.")

# --- his published surprise series ------------------------------------------
a <- as.data.frame(rx(aer_p, skip = 2))
v <- suppressWarnings(as.numeric(a[[1]])); v <- v[!is.na(v)]
pub <- data.frame(date = seq(as.Date("1955-01-01"), by = "3 months",
                             length.out = length(v)), pub = v)

# --- his GDP sheet, column G, already annualised ----------------------------
g <- as.data.frame(rx(raw_p, sheet = "Nominal GDP", skip = 2))
g <- g[, c(2, 3, 7)]; names(g) <- c("year", "quarter", "gdp_his")
g <- g[!is.na(g$year) & !is.na(g$quarter) & !is.na(g$gdp_his), ]
g$year <- as.integer(g$year); g$quarter <- as.integer(g$quarter)

# our GDP, from the JPE panel, annualised the same way
p <- readRDS(file.path(DERIVED, "p2_panel.rds"))
g <- merge(g, p[, c("year","quarter","gdp_ann")], by = c("year","quarter"), all.x = TRUE)
msg("GDP vintages: median absolute difference %.1f%%",
    100 * median(abs(g$gdp_his / g$gdp_ann - 1), na.rm = TRUE))

# --- his raw measures --------------------------------------------------------
cl <- as.data.frame(rx(raw_p, sheet = "TaxData"))
d <- data.frame(
  budget    = as.Date(cl$Date),
  announce  = excel_date(cl$AnnouncementDate),
  implement = excel_date(cl$ImplementationDate),
  major     = trimws(as.character(cl$Major)),
  excluded  = suppressWarnings(as.integer(cl$Excluded)),
  value     = suppressWarnings(as.numeric(cl$TaxData)),
  stringsAsFactors = FALSE)
d$value[is.na(d$value)] <- 0
d <- d[!is.na(d$implement), ]
d <- d[is.na(d$excluded) | d$excluded != 1, ]
msg("his raw measures after his two drops: %d", nrow(d))

# --- switchable conventions --------------------------------------------------
#' @param qrule   "his45" adds 45 days before taking the quarter; "ours15"
#'                pushes a date past the 15th into the next month
#' @param retro   TRUE replaces the implementation date with the announcement
#'                date where implementation comes first
#' @param thresh  gap in days at or below which a measure counts as a surprise
#' @param gdpcol  which nominal GDP vintage to divide by
#' @param exog    restrict to Major == "X"
variant <- function(qrule = "his45", retro = TRUE, thresh = 90,
                    gdpcol = "gdp_his", exog = TRUE) {
  z <- d
  imp <- z$implement
  if (retro) imp <- as.Date(ifelse(!is.na(z$announce) & z$implement < z$announce,
                                   z$announce, z$implement), origin = "1970-01-01")
  gap <- as.numeric(imp - z$announce)
  keep <- !is.na(gap) & gap <= thresh
  if (exog) keep <- keep & z$major %in% "X"
  z <- z[keep, ]; imp <- imp[keep]
  if (qrule == "his45") {
    sh <- imp + 45
    yr <- as.integer(format(sh, "%Y")); qt <- (as.integer(format(sh, "%m")) - 1L) %/% 3L + 1L
  } else {
    aq <- assign_quarter(imp, "calendar"); yr <- aq$year; qt <- aq$quarter
  }
  s <- aggregate(list(val = z$value), list(year = yr, quarter = qt), sum)
  out <- merge(g, s, by = c("year","quarter"), all.x = TRUE)
  out$val[is.na(out$val)] <- 0
  out$shock <- 100 * out$val / out[[gdpcol]]
  out$date <- as.Date(sprintf("%d-%02d-01", out$year, 3 * out$quarter - 2))
  out[order(out$date), c("date","shock")]
}

score <- function(lbl, ...) {
  s <- variant(...)
  m <- merge(pub, s, by = "date")
  r <- cor(m$pub, m$shock)
  msg("  %-52s corr %.4f | sd %.3f vs %.3f | max diff %.2f",
      lbl, r, sd(m$shock), sd(m$pub), max(abs(m$shock - m$pub)))
  invisible(c(corr = r))
}

msg("\n--- target: his published surprise series, sd %.3f ---", sd(pub$pub))
msg("\n1. His conventions exactly")
score("his45 + retro + 90d + his GDP + exogenous only", )
score("  ... but all measures, not exogenous only", exog = FALSE)

msg("\n2. Change one convention at a time from his baseline")
score("quarter rule -> ours (past the 15th)", qrule = "ours15")
score("threshold    -> 120 days",             thresh = 120)
score("retroactivity-> ours (keep raw date)", retro = FALSE)
score("GDP vintage  -> JPE panel",            gdpcol = "gdp_ann")

msg("\n3. Our conventions, all four together")
score("ours15 + no retro fix + 120d + JPE GDP",
      qrule = "ours15", retro = FALSE, thresh = 120, gdpcol = "gdp_ann")

msg("\n--- which single change costs the most? read the drop in corr above ---")

# --- write the reconciled series ---------------------------------------------
best <- variant()
m <- merge(pub, best, by = "date")
msg("\nreconciled series vs published: corr %.4f over %d quarters",
    cor(m$pub, m$shock), nrow(m))
bad <- m[order(-abs(m$shock - m$pub)), ][1:5, ]
msg("largest remaining discrepancies:")
for (i in seq_len(nrow(bad)))
  msg("  %s  ours %+.3f  his %+.3f  diff %+.3f",
      format(bad$date[i], "%YQ") , bad$shock[i], bad$pub[i], bad$shock[i] - bad$pub[i])
write.csv(m, file.path(OUTPUT, "p2_reconciled_series.csv"), row.names = FALSE)
msg("\nwritten: output/p2_reconciled_series.csv")
