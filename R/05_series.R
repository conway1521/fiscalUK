# 05_series.R ----------------------------------------------------------------
# Build the quarterly narrative tax shock series, 1945Q1 - 2018Q4.
#
# TWO series, both as a share of nominal GDP:
#   implementation-dated  the convention in the literature; the benchmark
#   announcement-dated    when the information actually reached households
#
# Shape-weighted variants are deliberately NOT built here: they need the
# multi-year phase-in profiles, which exist only from 2004, so they cannot span
# the sample. They belong in Paper 1 as a 2004-2018 exercise.
#
# NOTE ON GRANULARITY: the revenue-weighting that Paper 1's descriptive medians
# require is irrelevant here. A shock series sums money by quarter, so 11 rows
# adding to GBP 1bn and 4 rows adding to GBP 1bn give the same quarter. The
# Cloyne-vs-modern itemisation difference cancels itself.

source("R/00_setup.R")
msg("== 05_series ==")

SPLICE <- as.Date("2004-01-01")   # Cloyne before, modern coding from here
Q_START <- 1945; Q_END <- 2018

# ---------------------------------------------------------------------------
# 1. Quarterly nominal GDP, 1945Q1 onwards
#    Cloyne's workbook carries ONS series YBHA at quarterly frequency, annual
#    rate, 1945Q1-2010Q1. Extended to 2018Q4 with OBR fiscal-year growth,
#    compounded quarterly. The two are cross-checked on their 1981-2010 overlap.
# ---------------------------------------------------------------------------
g <- rx(file.path(DATA, "CloyneNarrativeDataset-2.xlsx"), sheet = "Nominal GDP")
gy <- suppressWarnings(as.integer(unlist(g[, 2])))
gq <- suppressWarnings(as.integer(unlist(g[, 3])))
gv <- suppressWarnings(as.numeric(unlist(g[, 7])))
ok <- !is.na(gy) & !is.na(gq) & !is.na(gv)
gdp <- data.frame(year = gy[ok], quarter = gq[ok], gdp = gv[ok])
gdp <- gdp[order(gdp$year, gdp$quarter), ]
msg("Cloyne GDP (ONS YBHA, annual rate): %dQ%d to %dQ%d, %d quarters",
    gdp$year[1], gdp$quarter[1], tail(gdp$year,1), tail(gdp$quarter,1), nrow(gdp))

# OBR fiscal-year growth factors, used to extend beyond Cloyne's last quarter
o    <- rx(file.path(DATA, "NomGDPgrowth_OBR.xlsx"))
ofy  <- as.integer(substr(colnames(o)[-1], 1, 4))
ogr  <- as.numeric(o[1, -1])
olev <- as.numeric(o[2, -1])

# Cross-check the two GDP sources. They are different ONS vintages: Cloyne
# downloaded YBHA in August 2010, the OBR file is a 2021 vintage, and UK nominal
# GDP has been revised substantially since (ESA2010 alone added several per
# cent). Levels therefore differ materially and MUST NOT be spliced.
# The extension below uses OBR *growth rates* only, applied to Cloyne's last
# level, so the series stays on a single vintage throughout. Growth rates are
# far more stable across vintages than levels.
cy <- tapply(gdp$gdp, gdp$year, mean)
chk <- data.frame(fy = ofy, obr = olev)
chk$cloyne <- as.numeric(cy[as.character(chk$fy)])
chk <- chk[!is.na(chk$obr) & !is.na(chk$cloyne), ]
msg("GDP vintage check on %d overlapping years: median level gap %.1f%% (expected;",
    nrow(chk), 100 * median(abs(chk$obr / chk$cloyne - 1)))
msg("  levels are never spliced - only OBR growth rates are used to extend)")
gr_chk <- chk$obr[-1] / chk$obr[-nrow(chk)]
cl_chk <- chk$cloyne[-1] / chk$cloyne[-nrow(chk)]
msg("  growth-rate agreement across vintages: median gap %.2f pp",
    100 * median(abs(gr_chk - cl_chk), na.rm = TRUE))

# extend quarterly to 2018Q4
last_y <- tail(gdp$year, 1); last_q <- tail(gdp$quarter, 1); last_v <- tail(gdp$gdp, 1)
ext <- list()
y <- last_y; q <- last_q; v <- last_v
repeat {
  q <- q + 1L; if (q > 4L) { q <- 1L; y <- y + 1L }
  if (y > Q_END) break
  fy <- if (q >= 2L) y else y - 1L                 # fiscal year containing this quarter
  gr <- ogr[match(fy, ofy)]
  if (is.na(gr)) gr <- 1
  v <- v * gr^(1/4)
  ext[[length(ext) + 1]] <- data.frame(year = y, quarter = q, gdp = v)
}
if (length(ext)) gdp <- rbind(gdp, do.call(rbind, ext))
gdp <- gdp[gdp$year >= Q_START & gdp$year <= Q_END, ]
msg("extended to %dQ%d (%d quarters total); %d quarters imputed from OBR growth",
    tail(gdp$year,1), tail(gdp$quarter,1), nrow(gdp), length(ext))

# ---------------------------------------------------------------------------
# 2. Splice the measures. The chained file is a UNION that keeps the 2004-2009
#    overlap twice for the validation gate; aggregating it directly would
#    double-count five years.
# ---------------------------------------------------------------------------
ch <- readRDS(file.path(DERIVED, "uk_chained_measures.rds"))
m <- ch[ch$usable &
        ((ch$source == "Cloyne" & ch$budget_date <  SPLICE) |
         (ch$source == "Modern" & ch$budget_date >= SPLICE)), ]
msg("")
msg("spliced at %s: %d Cloyne + %d modern = %d measures",
    format(SPLICE), sum(m$source == "Cloyne"), sum(m$source == "Modern"), nrow(m))
msg("dropped as overlap duplicates: %d", sum(ch$usable) - nrow(m))

# ---------------------------------------------------------------------------
# 3. Aggregate to quarterly and scale by GDP
# ---------------------------------------------------------------------------
grid <- expand.grid(quarter = 1:4, year = Q_START:Q_END)[, c("year","quarter")]
grid <- merge(grid, gdp, by = c("year","quarter"), all.x = TRUE)
grid <- grid[order(grid$year, grid$quarter), ]
grid$date <- as.Date(sprintf("%d-%02d-01", grid$year, 3 * grid$quarter - 2))

agg <- function(yr, qt, val) {
  keys <- paste(grid$year, grid$quarter)
  k <- paste(yr, qt)
  keep <- !is.na(yr) & !is.na(qt) & k %in% keys      # ignore anything off-grid
  s <- tapply(val[keep], k[keep], sum, na.rm = TRUE)
  out <- setNames(rep(0, length(keys)), keys)
  out[names(s)] <- s
  as.numeric(out)
}

grid$shock_imp_m   <- agg(m$imp_year_cal, m$imp_q_cal, m$peak_value)
grid$shock_ann_m   <- agg(m$ann_year_cal, m$ann_q_cal, m$peak_value)
grid$shock_imp_pct <- 100 * grid$shock_imp_m / grid$gdp
grid$shock_ann_pct <- 100 * grid$shock_ann_m / grid$gdp
grid$n_imp <- agg(m$imp_year_cal, m$imp_q_cal, rep(1, nrow(m)))
grid$n_ann <- agg(m$ann_year_cal, m$ann_q_cal, rep(1, nrow(m)))

msg("")
msg("--- series summary (%% of nominal GDP, + = raises revenue) ---")
print(round(rbind(
  implementation = summary(grid$shock_imp_pct),
  announcement   = summary(grid$shock_ann_pct)), 3))
msg("")
msg("quarters with any measure: implementation %d, announcement %d (of %d)",
    sum(grid$n_imp > 0), sum(grid$n_ann > 0), nrow(grid))
msg("correlation between the two datings: %.3f",
    cor(grid$shock_imp_pct, grid$shock_ann_pct, use = "complete.obs"))
msg("measures accounted for: implementation %d, announcement %d (of %d)",
    sum(grid$n_imp), sum(grid$n_ann), nrow(m))

# ---------------------------------------------------------------------------
# 4. Sanity check: the largest shocks should be recognisable historical events
# ---------------------------------------------------------------------------
msg("")
msg("--- ten largest implementation-dated shocks (should be identifiable) ---")
top <- grid[order(-abs(grid$shock_imp_pct)), ][1:10, ]
for (i in seq_len(nrow(top))) {
  k <- m$imp_year_cal == top$year[i] & m$imp_q_cal == top$quarter[i]
  k[is.na(k)] <- FALSE
  big <- m$measure[k][which.max(abs(m$peak_value[k]))]
  msg("  %dQ%d  %+6.2f%% of GDP  (%d measures)  largest: %s",
      top$year[i], top$quarter[i], top$shock_imp_pct[i], top$n_imp[i],
      substr(gsub("[\r\n]+", " ", big), 1, 60))
}

write.csv(grid, file.path(OUTPUT, "uk_tax_shocks_quarterly.csv"), row.names = FALSE)
saveRDS(list(series = grid, measures = m), file.path(DERIVED, "uk_shock_series.rds"))
msg("")
msg("written: output/uk_tax_shocks_quarterly.csv, data-derived/uk_shock_series.rds")
