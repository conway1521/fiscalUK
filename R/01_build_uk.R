# 01_build_uk.R --------------------------------------------------------------
# Build the modern UK measure-level dataset (Budget 2004 - Autumn 2018).
#
# Authoritative classification source is UK_classification.xlsx sheet
# "Narrative2021" (334 household measures, fully coded). NarrativeClassif.xlsx
# is the 630-row superset but is stale: 34 household rows still carry the
# literal string "NA" in endo_exo. We take classification from the former and
# row-align the costing profiles from taxData.xlsx via the latter.

source("R/00_setup.R")

msg("== 01_build_uk ==")

# --- load -------------------------------------------------------------------
sup <- rx(file.path(DATA, "NarrativeClassif.xlsx"))                       # 630 rows
tax <- rx(file.path(DATA, "taxData.xlsx"))                                # 630 x 20
cls <- rx(file.path(DATA, "Budgetary data/UK/UK_classification.xlsx"),
          sheet = "Narrative2021")                                        # 334 rows

FY <- 2004:2023                                    # fiscal years 2004-05 .. 2023-24
stopifnot(ncol(tax) == length(FY))

hh <- which(sup$target == "H")
if (length(hh) != nrow(cls) ||
    !identical(as.character(sup$measure[hh]), as.character(cls$measure))) {
  stop("Row alignment between NarrativeClassif and UK_classification has broken.")
}
msg("household rows aligned: %d of %d total", length(hh), nrow(sup))

# --- build ALL measures, not just the household subset -----------------------
#
# Paper 1 asks how long the policy process takes. That is descriptive, so it has
# no endogeneity to purge and no reason to drop the 296 firm/other measures
# whose exogeneity was never coded. Restricting to exogenous households would
# discard 74% of the modern sample for no methodological gain, and would lose
# corporation tax and business rates from the instrument map entirely.
#
# Exogeneity is still carried, because Paper 2 needs it and because the
# exogenous/endogenous contrast is itself a Paper 1 result.
d <- data.frame(
  id          = seq_len(nrow(sup)),
  row_super   = seq_len(nrow(sup)),
  event       = as.character(sup$event),
  measure     = fix_encoding(as.character(sup$measure)),
  tax_type    = tidy_tax_type(as.character(sup$tax_type)),
  endo_exo    = as.character(sup$endo_exo),
  minor       = as.character(sup$minor1),
  reason      = NA_character_,
  quote       = NA_character_,
  cloyne_note = NA_character_,
  target      = as.character(sup$target),
  stringsAsFactors = FALSE
)

# Overwrite the household rows from the authoritative file. NarrativeClassif is
# stale for 34 of them (literal "NA" strings in endo_exo).
stale <- sum(sup$endo_exo[hh] == "NA", na.rm = TRUE)
d$endo_exo[hh]    <- as.character(cls$endo_exo)
d$reason[hh]      <- as.character(cls$reason)
d$quote[hh]       <- as.character(cls$quote)
d$cloyne_note[hh] <- as.character(cls$`Cloyne diff`)
d$endo_exo[!(d$endo_exo %in% c("X", "N"))] <- NA_character_   # "NA" string -> real NA
msg("stale 'NA' endo_exo rows resolved from UK_classification: %d", stale)
msg("exogeneity coded: %d of %d rows (firm measures were never coded)",
    sum(!is.na(d$endo_exo)), nrow(d))
d$group <- map_group(d$tax_type)

if (any(is.na(d$group))) {
  warning("unmapped tax types: ", paste(unique(d$tax_type[is.na(d$group)]), collapse = ", "))
}

# --- dates ------------------------------------------------------------------
# Dates come from the superset, overridden by UK_classification for household
# rows. The two never disagree where both carry a date (0 conflicts in 321
# announce and 318 implement comparisons), but UK_classification is more
# complete: it supplies 11 announce and 11 implement dates the superset lacks.
d$announce  <- excel_date(sup$announce)
d$implement <- excel_date(sup$implement)
d$stop      <- excel_date(sup$stop)
d$budget_date <- as.Date(sup$budg_date)

ca <- excel_date(cls$announce); ci <- excel_date(cls$implement); cs <- excel_date(cls$stop)
conflict <- sum(!is.na(ca) & !is.na(d$announce[hh])  & ca != d$announce[hh]) +
            sum(!is.na(ci) & !is.na(d$implement[hh]) & ci != d$implement[hh])
if (conflict > 0) stop(sprintf("date sources conflict on %d household rows", conflict))
fill <- function(target, idx, src) {
  v <- as.numeric(target)
  v[idx] <- ifelse(is.na(src), v[idx], as.numeric(src))
  as.Date(v, origin = "1970-01-01")
}
d$announce  <- fill(d$announce,  hh, ca)
d$implement <- fill(d$implement, hh, ci)
d$stop      <- fill(d$stop,      hh, cs)

aq <- assign_quarter(d$announce,  "calendar"); d$ann_year_cal <- aq$year; d$ann_q_cal <- aq$quarter
iq <- assign_quarter(d$implement, "calendar"); d$imp_year_cal <- iq$year; d$imp_q_cal <- iq$quarter
fq <- assign_quarter(d$implement, "fiscal");   d$imp_year_fis <- fq$year; d$imp_q_fis <- fq$quarter

d$lag_months <- as.numeric(d$implement - d$announce) / 30.4375
d$imp_fy     <- fiscal_year(d$implement)

# Lag in QUARTERS, floored at zero. This is the unit used for the headline.
#
# Day-level lags are contaminated by the tax-year convention: a Budget on 17
# April implementing "from 6 April" scores as -11 days, which reads as
# retroactive but is not economically meaningful. That convention was far more
# common in the early post-war decades than later, i.e. it varies in the same
# direction as the trend being measured, so it must not enter the headline.
# Cloyne ships a "no retroactive component" quarter for the same reason.
d$lag_quarters <- pmax(0, 4 * (d$imp_year_cal - d$ann_year_cal) +
                          (d$imp_q_cal - d$ann_q_cal))
d$is_retro     <- (4 * (d$imp_year_cal - d$ann_year_cal) +
                      (d$imp_q_cal - d$ann_q_cal)) < 0

msg("dates parsed: announce %d NA, implement %d NA", sum(is.na(d$announce)), sum(is.na(d$implement)))

# --- reversals ---------------------------------------------------------------
# 'REVERSE' rows undo an earlier measure. They are real fiscal actions and are
# kept, but flagged so the phase-in analysis can exclude them (their profile is
# mechanically the mirror of the parent measure).
d$is_reversal <- grepl("^\\s*REVERSE", d$measure, ignore.case = TRUE)
d$has_stop    <- !is.na(d$stop)
msg("reversal rows: %d   rows with stop date: %d", sum(d$is_reversal), sum(d$has_stop))

# --- costing profiles --------------------------------------------------------
# Anchor on the IMPLEMENTATION fiscal year, not the first non-missing costing.
# Only 39 of 165 coincide: OBR scorecards begin in the Budget year, so aligning
# on first-non-missing measures the announcement year and understates year one.
TX <- as.matrix(tax); mode(TX) <- "numeric"
colnames(TX) <- FY
H <- 10L

imp_col <- match(d$imp_fy, FY)
prof <- matrix(NA_real_, nrow(d), H,
               dimnames = list(NULL, paste0("y", seq_len(H))))
for (i in seq_len(nrow(d))) {
  j <- imp_col[i]
  if (is.na(j)) next
  take <- j:(j + H - 1L)
  keep <- take <= ncol(TX)                 # no clamping: past the data edge is NA
  prof[i, keep] <- TX[i, take[keep]]
}

# peak (largest absolute effect) used as the normaliser
peak_idx <- apply(prof, 1, function(v) if (all(is.na(v))) NA_integer_ else which.max(abs(v)))
peak_val <- vapply(seq_len(nrow(prof)), function(i)
  if (is.na(peak_idx[i])) NA_real_ else prof[i, peak_idx[i]], numeric(1))
peak_val[!is.na(peak_val) & peak_val == 0] <- NA_real_

d$peak_value    <- peak_val                          # GBP million, + raises revenue
d$years_to_peak <- peak_idx - 1L
d$n_costings    <- rowSums(!is.na(prof))
d$window        <- rowSums(!is.na(prof))

# --- three flags the profile analysis must respect -------------------------
#
# (1) SIGN FLIP. Normalising by the peak assumes one sign throughout. Seven
#     measures switch sign (e.g. a duty freeze costing money, then an escalator
#     raising it). Their normalised values go negative and averaging them into
#     a mean profile is meaningless: -0.4 and +0.4 cancel to zero.
d$sign_flip <- apply(prof, 1, function(v) {
  v <- v[!is.na(v)]; length(v) > 0 && any(v > 0) && any(v < 0)
})

# (2) CENSORED PEAK. Costings stop at FY2023-24, so a measure implemented in
#     2017 has only a 7-year window. If its effect is still growing at the edge,
#     the observed "peak" is a lower bound and the normalised year-one share is
#     biased UP. 68% of measures peak in their last observed year.
d$peak_censored <- !is.na(d$years_to_peak) & d$years_to_peak == (d$window - 1L) & d$window < H

# (3) FULL WINDOW. Measures with all ten years observed. Headline profile
#     statistics run on these; the full sample is reported as robustness.
d$full_window <- d$window == H

prof_norm <- prof / peak_val
colnames(prof_norm) <- paste0("n", seq_len(H))

# years from implementation until at least half the full effect is delivered
d$years_to_half <- vapply(seq_len(nrow(prof_norm)), function(i) {
  w <- which(abs(prof_norm[i, ]) >= 0.5)
  if (!length(w)) NA_real_ else w[1] - 1
}, numeric(1))
d$months_ann_to_half <- d$lag_months + 12 * d$years_to_half
d$year1_share <- prof_norm[, 1]

# --- analysis flags ----------------------------------------------------------
# `usable`        : the lag sample. Profile quality is irrelevant here.
# `profile_usable`: the phase-in sample. Excludes sign-flipping measures, whose
#                   normalised profiles are not averageable.
# `timing_sample`: Paper 1. Every datable, non-reversal measure. Exogeneity is
#                  irrelevant to a descriptive question about the policy process,
#                  and requiring it would discard 74% of the modern rows.
# `usable`       : Paper 2. Exogenous household measures only, because a causal
#                  estimate does need the identifying restriction.
# `profile_usable`: phase-in analysis. Excludes sign-flipping costings, whose
#                  normalised profiles are not averageable.
d$timing_sample <- !d$is_reversal &
  !is.na(d$announce) & !is.na(d$implement) & !is.na(d$peak_value)
d$usable <- d$timing_sample & d$endo_exo %in% "X" & d$target %in% "H"
d$profile_usable <- d$timing_sample & !d$sign_flip

msg("timing sample (Paper 1, all measures): %d", sum(d$timing_sample))
msg("exogenous household sample (Paper 2): %d", sum(d$usable))
msg("  excluded from the PROFILE sample:")
msg("    sign-flipping costings: %d", sum(d$usable & d$sign_flip))
msg("  profile sample: %d, of which full 10-year window: %d",
    sum(d$profile_usable), sum(d$profile_usable & d$full_window))
msg("  peak is censored (last observed year, short window): %d (%.1f%%)",
    sum(d$profile_usable & d$peak_censored),
    100 * mean(d$peak_censored[d$profile_usable]))
msg("  -> years_to_peak is NOT reportable as a statistic; use the fixed-horizon profile")

pu <- d$profile_usable
msg("")
msg("mean normalised profile, years 1-6:")
msg("  full window only (n=%d): %s", sum(pu & d$full_window),
    paste(sprintf("%.2f", colMeans(prof_norm[pu & d$full_window, , drop = FALSE], na.rm = TRUE)[1:6]), collapse = " "))
msg("  all profile-usable (n=%d): %s", sum(pu),
    paste(sprintf("%.2f", colMeans(prof_norm[pu, , drop = FALSE], na.rm = TRUE)[1:6]), collapse = " "))
msg("  (the gap is truncation bias: censored peaks inflate the year-one share)")

uk <- list(measures = d, profile = prof, profile_norm = prof_norm, fy = FY)
saveRDS(uk, file.path(DERIVED, "uk_measures.rds"))
write.csv(cbind(d, prof, prof_norm), file.path(DERIVED, "uk_measures.csv"), row.names = FALSE)
msg("written: data-derived/uk_measures.{rds,csv}")

# The modern coding has no no-retroactive field; retroactivity is negligible
# here (1 measure of 163 at quarterly resolution), so the raw implementation
# quarter serves, floored at the announcement quarter for consistency with the
# Cloyne side.
d$imp_year_nret <- d$imp_year_cal
d$imp_q_nret    <- d$imp_q_cal
fix <- which(!is.na(d$lag_quarters) & d$is_retro %in% TRUE)
d$imp_year_nret[fix] <- d$ann_year_cal[fix]
d$imp_q_nret[fix]    <- d$ann_q_cal[fix]
uk <- list(measures = d, profile = prof, profile_norm = prof_norm, fy = FY)
saveRDS(uk, file.path(DERIVED, "uk_measures.rds"))
write.csv(cbind(d, prof, prof_norm), file.path(DERIVED, "uk_measures.csv"), row.names = FALSE)
