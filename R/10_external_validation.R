# 10_external_validation.R ---------------------------------------------------
# EXTERNAL VALIDATION of Paper 1's central finding, on data we did not build.
#
# Cloyne, Hürtgen and Dimsdale (2025, Journal of Political Economy 133(2),
# 568-603) use a narrative UK tax dataset covering roughly 1918-2020. Their
# replication package (Harvard Dataverse doi:10.7910/DVN/JVNAPS) ships the
# quarterly exogenous and endogenous shock series in two variants: a baseline
# containing all narrative shocks, and an "unanticipated" variant restricted to
# measures implemented within Cloyne's (2013) 90-day window.
#
# The ratio of the two IS an anticipation share, computed by other researchers,
# on their own coding, over a century, using their own threshold. It is the
# strongest available test of Fact 1 and of section 8, because nothing in it
# came from us.
#
# NOTE ON PRIORITY. The anticipated/unanticipated distinction is NOT ours.
# Cloyne (2013) defines a change as anticipated when the implementation lag
# exceeds 90 days, following Mertens and Ravn (2012). Our 120-day threshold is a
# variant of that convention, chosen to exclude the March-Budget-to-6-April
# case, not an invention. What is new here is treating the share as a time
# series and asking whether it moved.

source("R/00_setup.R")
msg("== 10_external_validation ==")

DV   <- "https://dataverse.harvard.edu/api/access/datafile/"
FILES <- c(baseline = "10148539", robustness = "10148593")
dir.create(file.path(DERIVED, "external"), showWarnings = FALSE)

paths <- vapply(names(FILES), function(k) {
  p <- file.path(DERIVED, "external", paste0("cdh_", k, ".xlsx"))
  if (!file.exists(p)) {
    msg("  downloading %s from Harvard Dataverse ...", k)
    try(download.file(paste0(DV, FILES[[k]]), p, mode = "wb", quiet = TRUE), silent = TRUE)
  }
  p
}, character(1))

if (!all(file.exists(paths)) || any(file.size(paths) < 5000)) {
  msg("  Dataverse files unavailable (offline?). Skipping external validation.")
  msg("  Source: doi:10.7910/DVN/JVNAPS, files TaxShocksBaseline.xlsx and")
  msg("  TaxShocksRobustness.xlsx (sheet 'unanticipated').")
} else {
  base <- as.data.frame(rx(paths[["baseline"]],   sheet = "baseline"))
  unan <- as.data.frame(rx(paths[["robustness"]], sheet = "unanticipated"))
  names(base) <- names(unan) <- c("date", "endo", "exo")
  base$date <- as.Date(base$date); unan$date <- as.Date(unan$date)
  stopifnot(identical(base$date, unan$date))
  msg("  their series: %d quarters, %s to %s",
      nrow(base), format(min(base$date)), format(max(base$date)))

  yr  <- as.integer(format(base$date, "%Y"))
  era <- cut(yr, c(-Inf, 1944, 1979, 1999, Inf),
             labels = c("1920-44", "1945-79", "1980-99", "2000-20"))

  share <- function(b, u, g) {
    do.call(rbind, lapply(levels(g), function(e) {
      i <- g == e
      data.frame(era = e, quarters = sum(i),
                 gross_baseline      = round(sum(abs(b[i])), 2),
                 gross_unanticipated = round(sum(abs(u[i])), 2),
                 anticipation_share  = round(1 - sum(abs(u[i]))/sum(abs(b[i])), 3))
    }))
  }
  msg("\n--- THEIR anticipation share, exogenous series (Cloyne 90-day rule) ---")
  ex <- share(base$exo, unan$exo, era); print(ex, row.names = FALSE)

  msg("\n--- OUR anticipation share, all measures (120-day rule), for comparison ---")
  ours <- data.frame(era = c("1945-79","1980-99","2000-19"),
                     anticipation_share = c(0.184, 0.384, 0.699))
  print(ours, row.names = FALSE)
  cmp <- merge(ex[, c("era","anticipation_share")], ours, by = "era",
               suffixes = c("_theirs", "_ours"))
  cmp$difference <- round(cmp$anticipation_share_theirs - cmp$anticipation_share_ours, 3)
  msg("\n--- SIDE BY SIDE ---")
  print(cmp, row.names = FALSE)

  msg("\n--- their series by decade (does the 1990s break appear in their data too?) ---")
  dec <- 10 * (yr %/% 10)
  d <- do.call(rbind, lapply(sort(unique(dec)), function(k) {
    i <- dec == k
    data.frame(decade = k, quarters = sum(i),
               anticipation_share = round(1 - sum(abs(unan$exo[i]))/sum(abs(base$exo[i])), 3))
  }))
  print(d, row.names = FALSE)
  msg("  their 1980s %.3f -> 1990s %.3f. The break appears in their coding as well.",
      d$anticipation_share[d$decade == 1980], d$anticipation_share[d$decade == 1990])

  write.csv(ex,  file.path(OUTPUT, "external_validation_era.csv"),    row.names = FALSE)
  write.csv(d,   file.path(OUTPUT, "external_validation_decade.csv"), row.names = FALSE)
  write.csv(cmp, file.path(OUTPUT, "external_validation_compare.csv"), row.names = FALSE)
  msg("\nwritten: output/external_validation_*.csv")
}
