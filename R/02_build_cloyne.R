# 02_build_cloyne.R ----------------------------------------------------------
# Cloyne (2013, American Economic Review) UK narrative dataset, 1945-2009.
#
# Note the asymmetry with the modern data: Cloyne records ONE revenue figure per
# measure, not a multi-year profile. So the chained series supports the
# anticipation-lag analysis back to 1945 but the phase-in analysis only from
# 2004. This is a property of the source, not something we can engineer around.

source("R/00_setup.R")

msg("== 02_build_cloyne ==")

cl <- rx(file.path(DATA, "CloyneNarrativeDataset-2.xlsx"), sheet = "TaxData")

c_group <- trimws(as.character(cl$Group))
c_group[c_group == "capital"] <- "Capital"       # single lower-case stray
c_group[c_group == "?"] <- NA_character_

d <- data.frame(
  id        = seq_len(nrow(cl)),
  event     = format(as.Date(cl$Date), "%Y-%m-%d"),
  measure   = as.character(cl$`Description (as reported in FSBR)`),
  tax_type  = trimws(as.character(cl$`Tax Type`)),
  sub_type  = trimws(as.character(cl$`Sub Type`)),
  group     = c_group,
  endo_exo  = trimws(as.character(cl$Major)),
  minor     = trimws(as.character(cl$Minor)),
  excluded  = as.integer(cl$Excluded),
  stringsAsFactors = FALSE
)

d$budget_date <- as.Date(cl$Date)
d$announce    <- excel_date(cl$AnnouncementDate)
d$implement   <- excel_date(cl$ImplementationDate)
d$stop        <- excel_date(cl$EndDate)

aq <- assign_quarter(d$announce,  "calendar"); d$ann_year_cal <- aq$year; d$ann_q_cal <- aq$quarter
iq <- assign_quarter(d$implement, "calendar"); d$imp_year_cal <- iq$year; d$imp_q_cal <- iq$quarter
fq <- assign_quarter(d$implement, "fiscal");   d$imp_year_fis <- fq$year; d$imp_q_fis <- fq$quarter

d$lag_months  <- as.numeric(d$implement - d$announce) / 30.4375
d$imp_fy      <- fiscal_year(d$implement)

# Lag in QUARTERS using Cloyne's own no-retroactive implementation quarter.
#
# He ships two implementation concepts: `ImplementationDate`, which includes
# retroactive components, and "Quarter/Year Implemeneted (No retroactive
# component)". The distinction matters here because retroactivity was common
# early and rare late, i.e. it varies in the same direction as the trend, and
# would bias the early decades downward if left in. They differ for 22% of
# measures. The no-retroactive field is the one to use.
nq <- suppressWarnings(as.integer(cl$`Quarter Implemeneted (No retroactive component)`))
ny <- suppressWarnings(as.integer(cl$`Year Implemeneted (No retroactive component)`))
d$imp_year_nret <- ny
d$imp_q_nret    <- nq
d$lag_quarters  <- pmax(0, 4 * (ny - d$ann_year_cal) + (nq - d$ann_q_cal))
d$is_retro      <- (4 * (d$imp_year_cal - d$ann_year_cal) +
                       (d$imp_q_cal - d$ann_q_cal)) < 0
d$peak_value  <- as.numeric(cl$TaxData)          # GBP million, single figure
d$is_reversal <- grepl("^\\s*REVERSE", d$measure, ignore.case = TRUE)
d$has_stop    <- !is.na(d$stop)

# Cloyne has no household/firm target field. The closest harmonised concept is
# his Group: everything other than "Business" is household-relevant. The modern
# data maps to the same categories via map_group().
d$target <- ifelse(is.na(d$group), NA_character_,
                   ifelse(d$group == "Business", "F", "H"))

# `timing_sample`: Paper 1. Every datable, non-reversal measure regardless of
#                  exogeneity. A descriptive question about how long the policy
#                  process takes has no endogeneity to purge, and requiring
#                  exogeneity discards 41% of Cloyne's datable measures.
# `usable`       : Paper 2. Exogenous only, because a causal estimate does need
#                  the identifying restriction.
d$timing_sample <- d$excluded == 0 & !d$is_reversal &
  !is.na(d$announce) & !is.na(d$implement) & !is.na(d$peak_value) &
  !is.na(d$lag_quarters)
d$usable <- d$timing_sample & d$endo_exo %in% "X"

msg("rows: %d  |  exogenous: %d  |  excluded flagged: %d",
    nrow(d), sum(d$endo_exo == "X", na.rm = TRUE), sum(d$excluded != 0))
msg("timing sample (Paper 1, all measures): %d", sum(d$timing_sample))
msg("  of which exogenous: %d, endogenous: %d, uncoded: %d",
    sum(d$timing_sample & d$endo_exo %in% "X"),
    sum(d$timing_sample & d$endo_exo %in% "N"),
    sum(d$timing_sample & !(d$endo_exo %in% c("X","N"))))
msg("exogenous (Paper 2): %d  |  of which household-relevant: %d",
    sum(d$usable), sum(d$usable & d$target == "H", na.rm = TRUE))
msg("date range: %s to %s", format(min(d$budget_date, na.rm = TRUE)),
    format(max(d$budget_date, na.rm = TRUE)))

saveRDS(d, file.path(DERIVED, "cloyne_measures.rds"))
write.csv(d, file.path(DERIVED, "cloyne_measures.csv"), row.names = FALSE)
msg("written: data-derived/cloyne_measures.{rds,csv}")
