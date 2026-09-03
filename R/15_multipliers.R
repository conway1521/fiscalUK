# 15_multipliers.R -------------------------------------------------------------
# PAPER 2, THE ACTUAL QUESTION. If the government raises a pound in tax, how
# much does output fall, and does the answer depend on WHICH tax.
#
# The coefficient b_h from the projection is already the object wanted: the per
# cent response of real GDP at horizon h to a tax change worth one per cent of
# annual GDP. That is the multiplier in the Romer and Romer (2010) sense, and
# it is directly comparable with Cloyne's (2013) UK estimate of roughly -2.5
# within three years.
#
# WHY THE SHOCK IS THE UNANTICIPATED SERIES AND NOT THE USUAL ONE. Script 14
# established that the conventional implementation-dated series carries a large
# stale component: 73 per cent of the anticipated part is predictable from
# announcements made up to two years earlier, and a projection on it returns a
# wrong-signed response that survives conditioning on instrument. Whatever that
# coefficient is, it is not a multiplier. So the multipliers here are estimated
# on measures whose announcement and effect coincide, and the announcement-dated
# news series is reported beside them as the other half of the impulse.
#
# This is a construction decision, not the paper's argument. It belongs in the
# data section, and the diagnostics in script 14 are its justification.
#
# WHAT IS STILL MISSING FOR THE DISTRIBUTIONAL HALF. Two things, neither of
# which is in the repository or in the JPE deposit:
#   1. Aggregate household consumption. The JPE macro panel carries output,
#      prices, unemployment, Bank Rate, revenue, spending and the deficit, but
#      no consumption series. ONS publishes quarterly household final
#      consumption back to 1955.
#   2. Household micro data, to split the response by wealth or liquidity. The
#      Living Costs and Food Survey and its predecessor the Family Expenditure
#      Survey run back to 1961; the Wealth and Assets Survey begins in 2006.
#      Both come through the UK Data Service and need a registered account.
# Until those arrive this script answers the "which tax" half only.

source("R/00_setup.R")
msg("== 15_multipliers ==")

p   <- readRDS(file.path(DERIVED, "p2_panel.rds")); p <- p[order(p$date), ]
ext <- readRDS(file.path(DERIVED, "extended_measures.rds"))
SAMP <- c(1945, 2018)
ok   <- p$year >= SAMP[1] & p$year <= SAMP[2]
sp   <- p$X_SpendToGDP; sp[is.na(sp)] <- 0
key  <- paste(p$year, p$quarter)

agg <- function(yr, qt, val) {
  k <- paste(yr, qt); i <- !is.na(yr) & !is.na(qt) & k %in% key
  s <- tapply(val[i], k[i], sum)
  o <- setNames(rep(0, length(key)), key); o[names(s)] <- s; as.numeric(o)
}

#' Unanticipated and news-dated series for a subset of measures.
series_for <- function(z) {
  lo <- z$long == 1
  list(unant = 100 * agg(z$imp_year_cal[!lo], z$imp_q_cal[!lo], z$peak_value[!lo]) / p$gdp_ann,
       news  = 100 * agg(z$ann_year_cal[lo],  z$ann_q_cal[lo],  z$peak_value[lo])  / p$gdp_ann)
}

#' Peak response and the horizon it occurs at, with the whole path retained.
summarise <- function(r, label, kind, n_meas, nz) {
  if (is.null(r)) return(NULL)
  pk <- r[which.max(abs(r$b)), ]
  msg("  %-22s %-9s n=%4d nz=%3d | peak %+6.2f at h=%2d  [%+.2f, %+.2f]  t %+5.2f | sig %d/%d",
      label, kind, n_meas, nz, pk$b, pk$h, pk$lo, pk$hi, pk$t,
      sum(abs(r$t) > 1.96), nrow(r))
  cbind(instrument = label, kind = kind, n_measures = n_meas, nonzero_q = nz, r)
}

# ---------------------------------------------------------------------------
# 1. THE AGGREGATE MULTIPLIER
# ---------------------------------------------------------------------------
msg("\n=== 1. Aggregate, all exogenous measures ===")
all_x <- ext[ext$timing_sample & ext$endo_exo %in% "X" & !is.na(ext$peak_value) &
             ext$source != "CDPV", ]
s_all <- series_for(all_x)
out <- list()
for (k in c("unant","news")) {
  r <- lp_project(p$lrgdp, s_all[[k]], ok, X = data.frame(sp = sp), H = 0:16)
  out[[length(out)+1]] <- summarise(r, "All measures", k,
                                    sum(if (k == "unant") all_x$long == 0 else all_x$long == 1),
                                    sum(s_all[[k]] != 0))
}

# ---------------------------------------------------------------------------
# 2. BY INSTRUMENT
# ---------------------------------------------------------------------------
# Estimated where the cell can carry it. Social security has 9 surprise
# measures and capital gains 9 anticipated ones, so those cells are reported as
# unavailable rather than estimated on nothing.
MINMEAS <- 40
msg("\n=== 2. By instrument (cells with at least %d measures) ===", MINMEAS)
inst <- names(sort(table(all_x$tax_h), decreasing = TRUE))
for (ti in inst) {
  z <- all_x[all_x$tax_h %in% ti, ]
  s <- series_for(z)
  for (k in c("unant","news")) {
    nm <- sum(if (k == "unant") z$long == 0 else z$long == 1)
    if (nm < MINMEAS) { msg("  %-22s %-9s n=%4d  too few to estimate", ti, k, nm); next }
    r <- lp_project(p$lrgdp, s[[k]], ok, X = data.frame(sp = sp), H = 0:16)
    out[[length(out)+1]] <- summarise(r, ti, k, nm, sum(s[[k]] != 0))
  }
}

res <- do.call(rbind, out)
write.csv(res, file.path(OUTPUT, "p2_multipliers.csv"), row.names = FALSE)

# ---------------------------------------------------------------------------
# 3. WHAT CARRIES THE AGGREGATE
# ---------------------------------------------------------------------------
# Script 14 found the income-tax surprise series returns nothing while the
# pooled surprise series peaks near -2.4. Something else is carrying it. This
# is the check that names it.
msg("\n=== 3. Which instrument carries the pooled surprise response? ===")
u <- res[res$kind == "unant", ]
pk <- do.call(rbind, lapply(split(u, u$instrument), function(z) {
  q <- z[which.max(abs(z$b)), ]
  data.frame(instrument = q$instrument, n = q$n_measures, peak = round(q$b, 2),
             h = q$h, t = round(q$t, 2), sig = sum(abs(z$t) > 1.96))
}))
print(pk[order(pk$peak), ], row.names = FALSE)
msg("  A negative peak is the expected sign: a tax rise contracting output.")

msg("\n=== STILL REQUIRED FOR THE DISTRIBUTIONAL HALF ===")
msg("  Aggregate household consumption, quarterly. ONS, public, not yet pulled.")
msg("  Household micro data by wealth or liquidity. LCF and its predecessor the")
msg("  FES run from 1961, WAS from 2006, both via the UK Data Service, which")
msg("  needs a registered account. Neither is in this repository.")

msg("\nwritten: output/p2_multipliers.csv")
