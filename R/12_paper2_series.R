# 12_paper2_series.R ----------------------------------------------------------
# Paper 2's estimation panel: three shock series and the outcomes, 1918-2018.
#
# THE THREE SERIES. An anticipated measure is two events, and they must never
# enter one regression:
#   unant     gap at or under 90 days, dated by IMPLEMENTATION. Announcement
#             and effect nearly coincide, so there is one event and one date.
#   ant_news  gap over 90 days, dated by ANNOUNCEMENT. When the information
#             arrived.
#   ant_imp   the same measures, dated by IMPLEMENTATION. When the money moved.
# `ant_news` and `ant_imp` are the same pounds shifted in time. `ant_news` and
# `unant` are disjoint sets of measures and are the pair that can serve as
# separate instruments.
#
# SCALE AND DATING FOLLOW CLOYNE (2013) EXACTLY. 100 * GBP million / annualised
# nominal GDP; the implementation date pushed forward 45 days before its quarter
# is taken; an implementation date preceding its own announcement replaced by
# the announcement; a 90-day surprise threshold. Script 17 rebuilds his
# published series from his raw file under these rules and returns it at a
# correlation of 1.0000 with a maximum difference of zero over 220 quarters.
#
# The alternative was Paper 1's own convention, which pushes a date past the
# 15th of a month into the next month and uses a 120-day threshold. It is
# defensible and Paper 1 keeps it, but here comparability with the published
# multiplier literature is the point, and the difference is not small: on Paper
# 1's rules the correlation with Cloyne's published series is 0.864. The
# threshold costs the most of the three, then the quarter rule, then
# retroactivity; the GDP vintage is irrelevant. Both are built, the second under
# the _p1 suffix.
#
# SAMPLE: EXOGENOUS, ALL MEASURES. Paper 1's shock split restricted to
# household-relevant measures, which forced reliance on Cloyne's `Group` field,
# a field his own README disclaims. The interwar block has no target field at
# all, so that restriction cannot be carried back. Dropping it is the better
# choice on three grounds: it removes the dependence on a disclaimed field, it
# matches the construction of Cloyne's own published exogenous series, and it is
# the only definition available across all three blocks. The household-restricted
# variant is built alongside for the postwar span so the choice can be tested.
#
# THE HOLE. 1939-1944 has no datable measure in any source, and quarterly GDP
# begins in 1920Q1. The usable span is 1920-1938 and 1945-2018, and no
# specification may treat it as continuous.

source("R/00_setup.R")
msg("== 12_paper2_series ==")

ext_p   <- file.path(DERIVED, "extended_measures.rds")
macro_p <- file.path(DERIVED, "macro_quarterly.rds")
if (!file.exists(ext_p) || !file.exists(macro_p))
  stop("Run R/11_external_data.R first.")

ext   <- readRDS(ext_p)
macro <- readRDS(macro_p)

# --- the estimation sample --------------------------------------------------
d <- ext[ext$timing_sample & ext$endo_exo %in% "X" & !is.na(ext$peak_value), ]
msg("exogenous datable measures: %d (%s to %s)", nrow(d),
    format(min(d$budget_date)), format(max(d$budget_date)))
msg("  by block: %s", paste(sprintf("%s=%d", names(table(d$source)),
                                    table(d$source)), collapse = ", "))

# --- quarterly grid and the annualised GDP denominator ----------------------
grid <- macro[!is.na(macro$NominalGDP), c("date","year","quarter","NominalGDP")]
grid$gdp_ann <- 4 * grid$NominalGDP
msg("GDP grid: %d quarters, %dQ%d to %dQ%d", nrow(grid),
    grid$year[1], grid$quarter[1], grid$year[nrow(grid)], grid$quarter[nrow(grid)])

key  <- paste(grid$year, grid$quarter)
#' Sum measure values into quarters of the grid, returning a zero-filled vector.
agg <- function(yr, qt, val) {
  k <- paste(yr, qt); ok <- !is.na(yr) & !is.na(qt) & !is.na(val) & k %in% key
  s <- tapply(val[ok], k[ok], sum)
  out <- setNames(rep(0, length(key)), key); out[names(s)] <- s
  as.numeric(out)
}
cnt <- function(yr, qt, val) {
  k <- paste(yr, qt); ok <- !is.na(yr) & !is.na(qt) & !is.na(val) & k %in% key
  s <- tapply(val[ok], k[ok], length)
  out <- setNames(rep(0, length(key)), key); out[names(s)] <- s
  as.numeric(out)
}

#' Split a measure frame into anticipated and surprise, on a dating convention.
#'
#' "cloyne" reproduces Cloyne (2013) exactly: the implementation date is pushed
#' forward 45 days before its quarter is taken, an implementation date preceding
#' its own announcement is replaced by the announcement, and the surprise
#' threshold is 90 days. Script 17 verifies this returns his published series at
#' a correlation of 1.0000 with a maximum difference of zero over 220 quarters.
#' "paper1" is our own convention, kept so the choice can be tested.
split_conv <- function(z, conv) {
  if (conv == "cloyne") {
    imp <- z$implement
    swap <- !is.na(z$announce) & !is.na(imp) & imp < z$announce
    imp[swap] <- z$announce[swap]
    iq  <- cloyne_quarter(z$implement, z$announce, retro_fix = TRUE)
    aq  <- cloyne_quarter(z$announce,  z$announce, retro_fix = FALSE)
    gap <- as.numeric(imp - z$announce)
    list(iq = iq, aq = aq, lo = !is.na(gap) & gap > 90)
  } else {
    list(iq = data.frame(year = z$imp_year_cal, quarter = z$imp_q_cal),
         aq = data.frame(year = z$ann_year_cal, quarter = z$ann_q_cal),
         lo = z$long %in% 1)
  }
}

#' Build the three series for a given subsample.
build <- function(z, tag, conv = "cloyne") {
  k <- split_conv(z, conv); lo <- k$lo; iq <- k$iq; aq <- k$aq
  out <- data.frame(
    ant_news = 100 * agg(aq$year[lo],  aq$quarter[lo],  z$peak_value[lo])  / grid$gdp_ann,
    ant_imp  = 100 * agg(iq$year[lo],  iq$quarter[lo],  z$peak_value[lo])  / grid$gdp_ann,
    unant    = 100 * agg(iq$year[!lo], iq$quarter[!lo], z$peak_value[!lo]) / grid$gdp_ann,
    n_news   = cnt(aq$year[lo],  aq$quarter[lo],  z$peak_value[lo]),
    n_unant  = cnt(iq$year[!lo], iq$quarter[!lo], z$peak_value[!lo]))
  names(out) <- paste0(names(out), tag)
  out
}

# Baseline is Cloyne's convention, so Paper 2's estimates are comparable with
# the published multiplier literature. Paper 1's convention is carried alongside
# under the _p1 suffix so the difference is reported rather than assumed.
ser <- cbind(grid[, c("date","year","quarter","gdp_ann")],
             build(d, "", "cloyne"), build(d, "_p1", "paper1"))

# Household-restricted variant, postwar only, to test what the restriction costs.
dh <- d[d$target %in% "H", ]
ser <- cbind(ser, build(dh, "_hh", "cloyne"))
msg("household-restricted variant: %d of %d measures carry target = H",
    nrow(dh), nrow(d))

# --- merge outcomes ---------------------------------------------------------
keep <- c("date","RealGDP","NominalGDP","GDPdeflator","Unemployment","BankRate",
          "ExchangeRate","CPI_SA","TaxRev_ANBV_SA","GovExp_ETD","Deficit_SA",
          "lrgdp","ldefl","lcpi","N_SpendToGDP","X_SpendToGDP")
panel <- merge(ser, macro[, intersect(keep, names(macro))], by = "date", all.x = TRUE)
panel <- panel[order(panel$date), ]

# Usable window: a datable measure exists and real GDP exists.
panel$usable <- !is.na(panel$RealGDP) &
  ((panel$year >= 1920 & panel$year <= 1938) | (panel$year >= 1945 & panel$year <= 2018))
panel$block  <- ifelse(panel$year <= 1938, "interwar",
                ifelse(panel$year <= 1944, "war", "postwar"))
msg("panel: %d quarters, %d usable", nrow(panel), sum(panel$usable))

# --- diagnostics ------------------------------------------------------------
msg("\n--- identifying variation by era (exogenous, all measures) ---")
u <- panel[panel$usable, ]
u$era <- cut(u$year, c(-Inf,1938,1979,1999,Inf),
             labels = c("1920-38","1945-79","1980-99","2000-18"))
tab <- do.call(rbind, lapply(levels(u$era), function(e) { z <- u[u$era == e, ]
  data.frame(era = e, quarters = nrow(z),
             sd_news  = round(sd(z$ant_news), 3),  nz_news  = sum(z$ant_news != 0),
             sd_unant = round(sd(z$unant), 3),     nz_unant = sum(z$unant != 0),
             sd_ant_imp = round(sd(z$ant_imp), 3)) }))
print(tab, row.names = FALSE)
write.csv(tab, file.path(OUTPUT, "p2_variation_by_era.csv"), row.names = FALSE)

msg("\n  correlation news vs unant: %+.3f (needs to be near zero for separate instruments)",
    cor(u$ant_news, u$unant))
msg("  correlation news vs ant_imp: %+.3f (same money, shifted; never in one regression)",
    cor(u$ant_news, u$ant_imp))

msg("\n  WHAT THE INTERWAR BLOCK ADDS. Surprise variation, sd %.3f on %d nonzero",
    tab$sd_unant[1], tab$nz_unant[1])
msg("  quarters, against sd %.3f on %d in 2000-18. It roughly %s the pooled",
    tab$sd_unant[4], tab$nz_unant[4],
    ifelse(sd(u$unant[u$year>=1945]) < sd(u$unant), "raises", "leaves"))
msg("  surprise variance: sd %.3f postwar only against %.3f including interwar.",
    sd(u$unant[u$year >= 1945]), sd(u$unant))

# --- the confound Paper 1 created -------------------------------------------
# Paper 1 showed anticipation is determined by instrument and by Budget season.
# So comparing responses to anticipated against unanticipated measures risks
# comparing an NIC multiplier with a duty multiplier. Quantify the overlap
# before designing around it.
msg("\n--- INSTRUMENT CONFOUND: what distinguishes anticipated from surprise measures? ---")
pw <- d[d$source != "CDPV" & !is.na(d$tax_h), ]
mix <- round(prop.table(table(pw$tax_h, ifelse(pw$long == 1, "anticipated", "surprise")), 2), 3)
print(mix[order(-mix[, "anticipated"]), , drop = FALSE])
msg("  Read the two columns as competing compositions. If they differ sharply,")
msg("  an anticipated-vs-surprise contrast is partly an instrument contrast and")
msg("  the specification must condition on tax_h or exploit Budget-season")
msg("  variation in notice instead. Postwar only: the interwar block has no")
msg("  instrument field.")

saveRDS(panel, file.path(DERIVED, "p2_panel.rds"))
write.csv(panel, file.path(OUTPUT, "p2_panel.csv"), row.names = FALSE)
msg("\nwritten: data-derived/p2_panel.rds, output/p2_panel.csv")
