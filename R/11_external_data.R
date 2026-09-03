# 11_external_data.R ----------------------------------------------------------
# Paper 2's outcome data and the interwar extension, both from public
# replication archives. Nothing here is our own coding.
#
# TWO SOURCES.
#
# A. Cloyne, Hurtgen and Dimsdale (2025, JPE), Harvard Dataverse
#    doi:10.7910/DVN/JVNAPS. Beyond the tax shock series used in script 10, the
#    deposit ships the macro data the paper is estimated on: quarterly UK real
#    and nominal GDP, the deflator, unemployment, Bank Rate, the exchange rate,
#    CPI, tax revenue, government expenditure and the deficit, 1918-2020, from
#    Thomas and Dimsdale (2017), Lennard (2020) and ONS. It also ships narrative
#    GOVERNMENT SPENDING shocks over the same span, which Paper 2 needs as a
#    control and which we have no way to build ourselves.
#
#    Using their outcome data rather than assembling our own is deliberate: it
#    makes every comparison with the published estimates like for like.
#
# B. Cloyne, Dimsdale and Postel-Vinay (2023, ReStud), Zenodo
#    doi:10.5281/zenodo.8097025, CC-BY-4.0. The MEASURE-LEVEL interwar narrative
#    record, 228 measures 1918-1938, carrying announcement AND implementation
#    dates on the same N/X motive scheme we already chain on.
#
#    This matters for Paper 2 specifically. Paper 1 established that the
#    unanticipated impulse collapses: its standard deviation falls from 0.240%
#    of GDP in 1945-79 to 0.044% in 2000-18. An estimator identified off
#    surprises is starved in the modern data. The interwar block is the opposite
#    regime, with a long-notice share near 0.14, so it restores the variation
#    the modern sample has lost.
#
# WHAT THE INTERWAR BLOCK CANNOT DO. It carries no tax-type field. The record is
# dates, motive and value, with no instrument. So it extends the anticipated /
# unanticipated split back to 1918 but CANNOT enter any instrument-composition
# analysis. Do not pool it into a specification carrying tax_h.
#
# The 1939-1944 war years are absent from both sources. Cloyne (2013) begins in
# October 1945. The gap is real and must be handled in estimation, not patched.

source("R/00_setup.R")
msg("== 11_external_data ==")

EXT <- file.path(DERIVED, "external")
dir.create(EXT, showWarnings = FALSE)

DV <- "https://dataverse.harvard.edu/api/access/datafile/"
DV_FILES <- c(MainMacroData = "10148545", SpendShocks = "10148573")
ZEN <- "https://zenodo.org/records/8097025/files/CDPVReplicationPackage.zip?download=1"

#' Download once, then reuse. Returns the path, or NA if unavailable.
fetch <- function(url, dest, min_bytes = 5000) {
  if (!file.exists(dest) || file.size(dest) < min_bytes) {
    msg("  downloading %s ...", basename(dest))
    try(download.file(url, dest, mode = "wb", quiet = TRUE), silent = TRUE)
  }
  if (file.exists(dest) && file.size(dest) >= min_bytes) dest else NA_character_
}

# ---------------------------------------------------------------------------
# A. THE MACRO OUTCOME PANEL
# ---------------------------------------------------------------------------
msg("\n--- A. Macro outcomes, Cloyne, Hurtgen and Dimsdale (2025) ---")

macro_p <- fetch(paste0(DV, DV_FILES[["MainMacroData"]]),
                 file.path(EXT, "cdh_MainMacroData.xlsx"))
spend_p <- fetch(paste0(DV, DV_FILES[["SpendShocks"]]),
                 file.path(EXT, "cdh_SpendShocks.xlsx"))

macro <- NULL
if (is.na(macro_p)) {
  msg("  UNAVAILABLE (offline?). Source: doi:10.7910/DVN/JVNAPS, MainMacroData.xlsx")
} else {
  m <- as.data.frame(rx(macro_p, sheet = "QuarterlyData"))
  names(m)[1:2] <- c("year", "quarter")
  m$year <- as.integer(m$year); m$quarter <- as.integer(m$quarter)
  m$date <- as.Date(sprintf("%d-%02d-01", m$year, 3 * m$quarter - 2))
  m <- m[order(m$date), ]

  # Real GDP enters the projections in logs; keep the level too.
  m$lrgdp <- log(m$RealGDP)
  m$ldefl <- log(m$GDPdeflator)
  m$lcpi  <- log(m$CPI_SA)

  msg("  quarterly panel: %d rows, %d Q%d to %d Q%d",
      nrow(m), m$year[1], m$quarter[1], m$year[nrow(m)], m$quarter[nrow(m)])
  cov <- sapply(m[, c("RealGDP","NominalGDP","GDPdeflator","Unemployment",
                      "BankRate","CPI_SA","TaxRev_ANBV_SA","GovExp_ETD",
                      "Deficit_SA")], function(x) sum(!is.na(x)))
  msg("  non-missing by series: %s",
      paste(sprintf("%s=%d", names(cov), cov), collapse = ", "))

  if (!is.na(spend_p)) {
    sp <- as.data.frame(rx(spend_p, sheet = "spending"))
    sp$Date <- as.Date(sp$Date)
    names(sp)[names(sp) == "Date"] <- "date"
    m <- merge(m, sp, by = "date", all.x = TRUE)
    m <- m[order(m$date), ]
    msg("  merged narrative SPENDING shocks: %d columns, %d non-zero quarters",
        ncol(sp) - 1, sum(sp$X_SpendToGDP != 0, na.rm = TRUE))
  }
  macro <- m
  saveRDS(macro, file.path(DERIVED, "macro_quarterly.rds"))
  write.csv(macro, file.path(DERIVED, "macro_quarterly.csv"), row.names = FALSE)
  msg("  written: data-derived/macro_quarterly.{rds,csv}")
}

# ---------------------------------------------------------------------------
# B. THE INTERWAR MEASURE-LEVEL RECORD
# ---------------------------------------------------------------------------
msg("\n--- B. Interwar measures, Cloyne, Dimsdale and Postel-Vinay (2023) ---")

zip_p <- fetch(ZEN, file.path(EXT, "cdpv_replication.zip"), min_bytes = 100000)
iw_x  <- file.path(EXT, "CDPVReplicationPackage",
                   "RawTaxData", "CDPV_NarrativeTaxData.xlsx")
if (!is.na(zip_p) && !file.exists(iw_x)) {
  utils::unzip(zip_p, exdir = EXT,
               files = "CDPVReplicationPackage/RawTaxData/CDPV_NarrativeTaxData.xlsx")
}

cdpv <- NULL
if (!file.exists(iw_x)) {
  msg("  UNAVAILABLE (offline?). Source: doi:10.5281/zenodo.8097025, CC-BY-4.0")
} else {
  iw <- as.data.frame(rx(iw_x, sheet = "MainData"))

  d <- data.frame(
    id          = seq_len(nrow(iw)),
    event       = format(as.Date(iw$Date), "%Y-%m-%d"),
    measure     = as.character(iw$Description),
    tax_type    = NA_character_,   # absent from the source, see header
    sub_type    = NA_character_,
    group       = NA_character_,
    endo_exo    = trimws(as.character(iw$`Motive 1 Major`)),
    minor       = trimws(as.character(iw$`Motive 1 Minor`)),
    stringsAsFactors = FALSE)

  d$budget_date <- as.Date(iw$Date)
  d$announce    <- as.Date(iw$Announcement)
  d$implement   <- as.Date(iw$`Implementation Date`)
  d$stop        <- as.Date(iw$`End date`)
  d$peak_value  <- as.numeric(iw$`Tax series`)      # GBP million, as Cloyne

  aq <- assign_quarter(d$announce,  "calendar"); d$ann_year_cal <- aq$year; d$ann_q_cal <- aq$quarter
  iq <- assign_quarter(d$implement, "calendar"); d$imp_year_cal <- iq$year; d$imp_q_cal <- iq$quarter
  fq <- assign_quarter(d$implement, "fiscal");   d$imp_year_fis <- fq$year; d$imp_q_fis <- fq$quarter

  # No no-retroactive field is published for the interwar record, so the
  # calendar implementation quarter is the only one available. Cloyne's 1945-
  # 2009 data shows the two differ for 22% of measures, and retroactivity was
  # MORE common early, so the interwar lag is if anything overstated here.
  # Flag it rather than adjust it.
  d$imp_year_nret <- d$imp_year_cal
  d$imp_q_nret    <- d$imp_q_cal
  d$lag_quarters  <- pmax(0, 4 * (d$imp_year_cal - d$ann_year_cal) +
                             (d$imp_q_cal - d$ann_q_cal))
  d$is_retro <- (4 * (d$imp_year_cal - d$ann_year_cal) +
                    (d$imp_q_cal - d$ann_q_cal)) < 0
  d$lag_months <- as.numeric(d$implement - d$announce) / 30.4375
  d$imp_fy     <- fiscal_year(d$implement)

  # Identical outcome construction to 02_build_cloyne.R.
  d$days     <- as.numeric(d$implement - d$announce)
  d$long     <- as.integer(d$days >= 120)
  d$fy_gap   <- pmax(0, fiscal_year(d$implement) - fiscal_year(d$announce))
  d$deferred <- as.integer(d$fy_gap >= 1)
  d$far      <- as.integer(d$fy_gap >= 2)
  d$imp_day  <- format(d$implement, "%m-%d")
  d$on_budget_day <- as.integer(d$implement == d$budget_date)
  d$fy_boundary   <- as.integer(d$imp_day %in% c("04-01","04-05","04-06","04-07"))
  d$is_reversal   <- grepl("^\\s*REVERSE", d$measure, ignore.case = TRUE)
  d$has_stop      <- !is.na(d$stop)
  d$target        <- NA_character_   # no household/firm field in the source
  d$source        <- "CDPV"
  # Postwar-only fields, carried as NA so the extended frame keeps them rather
  # than dropping tax_h and losing instrument analysis for 1945-2018 as well.
  d$tax_h         <- NA_character_
  d$has_profile   <- FALSE
  d$endo_exo_raw  <- d$endo_exo
  d$endo_exo_over <- NA_character_

  d$timing_sample <- !d$is_reversal & !is.na(d$announce) &
    !is.na(d$implement) & !is.na(d$peak_value) & !is.na(d$lag_quarters)
  d$usable <- d$timing_sample & d$endo_exo %in% "X"

  msg("  rows: %d | datable: %d | exogenous datable: %d",
      nrow(d), sum(d$timing_sample), sum(d$usable))
  msg("  span: %s to %s", format(min(d$budget_date, na.rm = TRUE)),
      format(max(d$budget_date, na.rm = TRUE)))
  ts <- d[d$timing_sample, ]
  msg("  long-notice share: %.3f (count) | median gap %.0f days | retroactive %d",
      mean(ts$long), median(ts$days), sum(ts$is_retro))
  msg("  motive: %s", paste(sprintf("%s=%d", names(table(ts$endo_exo)),
                                    table(ts$endo_exo)), collapse = ", "))

  cdpv <- d
  saveRDS(cdpv, file.path(DERIVED, "cdpv_measures.rds"))
  write.csv(cdpv, file.path(DERIVED, "cdpv_measures.csv"), row.names = FALSE)
  msg("  written: data-derived/cdpv_measures.{rds,csv}")
}

# ---------------------------------------------------------------------------
# C. CHAIN THE INTERWAR BLOCK ONTO THE EXISTING RECORD
# ---------------------------------------------------------------------------
msg("\n--- C. Extended measure record, 1918-2018 ---")

ch_p <- file.path(DERIVED, "uk_chained_measures.rds")
if (is.null(cdpv) || !file.exists(ch_p)) {
  msg("  skipped: need both cdpv_measures and uk_chained_measures.")
} else {
  ch <- readRDS(ch_p)
  keep <- union(names(ch), names(cdpv))
  for (nm in setdiff(keep, names(cdpv))) cdpv[[nm]] <- NA
  for (nm in setdiff(keep, names(ch)))   ch[[nm]]   <- NA
  ext  <- rbind(cdpv[, keep, drop = FALSE], ch[, keep, drop = FALSE])
  ext  <- ext[order(ext$budget_date), ]
  ext$era_block <- ifelse(ext$source == "CDPV", "interwar", "postwar")

  msg("  columns in the extended frame: %d. Nothing is dropped; the interwar",
      length(keep))
  msg("  block carries NA where the source has no field, notably tax_h.")

  ts <- ext[ext$timing_sample, ]
  ts$yr <- as.integer(format(ts$announce, "%Y"))
  sp <- split(ts, cut(ts$yr, c(-Inf,1938,1979,1999,Inf),
                      labels = c("1918-38","1945-79","1980-99","2000-18")))
  blk <- do.call(rbind, lapply(names(sp), function(k) { z <- sp[[k]]
    data.frame(block = k, n = nrow(z),
               exog = sum(z$endo_exo %in% "X"),
               long_share = round(mean(z$long), 3),
               has_taxtype = round(mean(!is.na(z$tax_h)), 2)) }))
  print(blk, row.names = FALSE)

  # The war gap is a property of the sources, not of this join.
  yrs <- sort(unique(ts$yr))
  gap <- setdiff(seq(min(yrs), max(yrs)), yrs)
  if (length(gap)) {
    runs <- split(gap, cumsum(c(1, diff(gap) != 1)))
    msg("  years with no datable measure: %s",
        paste(vapply(runs, function(r)
          if (length(r) == 1) as.character(r) else sprintf("%d-%d", min(r), max(r)),
          character(1)), collapse = ", "))
  }

  saveRDS(ext, file.path(DERIVED, "extended_measures.rds"))
  write.csv(ext, file.path(DERIVED, "extended_measures.csv"), row.names = FALSE)
  msg("  written: data-derived/extended_measures.{rds,csv}")

  msg("\n  WHAT THIS BUYS. The interwar block adds %d datable measures of which",
      sum(cdpv$timing_sample))
  msg("  %d are exogenous, in a regime where only %.0f%% carried long notice.",
      sum(cdpv$usable), 100 * mean(cdpv$long[cdpv$timing_sample]))
  msg("  That is the surprise variation the post-2000 sample has lost.")
  msg("  WHAT IT DOES NOT BUY. No tax-type field, so the interwar block cannot")
  msg("  enter instrument-composition work. And 1939-1944 is absent from both")
  msg("  sources, so any 1918-2018 specification carries a six-year hole.")
}
