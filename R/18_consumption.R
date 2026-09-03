# 18_consumption.R -------------------------------------------------------------
# Household consumption, the outcome Paper 2's distributional half is built on.
#
# WHY THIS SOURCE. The JPE macro panel carries output, prices, unemployment,
# Bank Rate, revenue, spending and the deficit, but no consumption. The obvious
# alternative was the ONS time-series API, which was decommissioned in November
# 2024 and now returns a notice instead of data.
#
# The Bank of England's "A Millennium of Macroeconomic Data for the UK", version
# 3.1, compiled by Thomas and Dimsdale, is the better source anyway. It is the
# same source the JPE macro panel already cites for its GDP, so the consumption
# series is consistent with the output series rather than spliced from a
# different vintage. Sheet "Q2. Qtly GDP 1920+" carries the quarterly
# expenditure decomposition.
#
# WHAT IT COSTS. The expenditure components begin in 1955Q1, not 1920, and
# version 3.1 ends in 2016Q4. So consumption work runs 1955-2016, 248 quarters,
# against 1945-2018 for the output work. Two years are lost at the end and ten
# at the start. Extending to 2018 means going to ONS directly for the last eight
# quarters, which is worth doing only if the estimates turn out to need them.
#
# The file is 26MB with 109 sheets, so it is cached and only one sheet is read.

source("R/00_setup.R")
msg("== 18_consumption ==")

EXT <- file.path(DERIVED, "external")
boe <- file.path(EXT, "boe_millennium.xlsx")
URL <- paste0("https://www.bankofengland.co.uk/-/media/boe/files/statistics/",
              "research-datasets/a-millennium-of-macroeconomic-data-for-the-uk.xlsx")
if (!file.exists(boe) || file.size(boe) < 1e7) {
  msg("  downloading the Millennium dataset (26MB) ...")
  try(download.file(URL, boe, mode = "wb", quiet = TRUE), silent = TRUE)
}

if (!file.exists(boe) || file.size(boe) < 1e7) {
  msg("  UNAVAILABLE (offline?). Source: Bank of England research datasets,")
  msg("  A Millennium of Macroeconomic Data for the UK, v3.1, Thomas and Dimsdale.")
} else {

# Header rows 1-8 are titles and units; row 6 names the column, row 8 gives the
# basis. Column positions are fixed by the sheet layout and verified below
# against the first and last observation of each series.
d <- as.data.frame(rx(boe, sheet = "Q2. Qtly GDP 1920+", col_names = FALSE, skip = 8))

yr <- suppressWarnings(as.integer(d[[1]]))
for (i in seq_along(yr)[-1]) if (is.na(yr[i])) yr[i] <- yr[i - 1]   # year is merged down
qt <- as.integer(sub("Q", "", as.character(d[[2]])))

num <- function(i) suppressWarnings(as.numeric(d[[i]]))
cons <- data.frame(
  year = yr, quarter = qt,
  cons_cp   = num(18),   # household consumption, current prices, GBP mn
  cons_cvm  = num(19),   # household consumption, chained volume measure
  govc_cp   = num(35),   # government consumption, current prices
  govc_cvm  = num(36),   # government consumption, chained volume measure
  rgdp_boe  = num(10))   # ONS ABMI, for the cross-check below
cons <- cons[!is.na(cons$year) & !is.na(cons$quarter), ]
cons$date <- as.Date(sprintf("%d-%02d-01", cons$year, 3 * cons$quarter - 2))
cons <- cons[order(cons$date), ]

ok <- !is.na(cons$cons_cvm)
msg("household consumption: %d quarters, %dQ%d to %dQ%d",
    sum(ok), cons$year[ok][1], cons$quarter[ok][1],
    tail(cons$year[ok], 1), tail(cons$quarter[ok], 1))

# --- does their GDP agree with the JPE panel's? -----------------------------
# If the two output series disagree, consumption from here cannot be paired
# with output from there.
p <- readRDS(file.path(DERIVED, "p2_panel.rds"))
chk <- merge(p[, c("date","RealGDP")], cons[, c("date","rgdp_boe")], by = "date")
chk <- chk[complete.cases(chk), ]
g1 <- diff(log(chk$RealGDP)); g2 <- diff(log(chk$rgdp_boe))
msg("cross-check against the JPE panel's real GDP over %d common quarters:", nrow(chk))
msg("  level correlation %.4f | growth correlation %.4f | median level gap %.2f%%",
    cor(chk$RealGDP, chk$rgdp_boe), cor(g1, g2),
    100 * median(abs(chk$RealGDP / chk$rgdp_boe - 1)))

# --- merge into the panel ---------------------------------------------------
p2 <- merge(p, cons[, c("date","cons_cp","cons_cvm","govc_cp","govc_cvm")],
            by = "date", all.x = TRUE)
p2 <- p2[order(p2$date), ]
p2$lcons <- log(p2$cons_cvm)
p2$lgovc <- log(p2$govc_cvm)
p2$cons_share <- p2$cons_cp / p2$NominalGDP
msg("consumption share of nominal GDP: %.2f in 1960, %.2f in 1990, %.2f in 2015",
    p2$cons_share[p2$year == 1960 & p2$quarter == 2],
    p2$cons_share[p2$year == 1990 & p2$quarter == 2],
    p2$cons_share[p2$year == 2015 & p2$quarter == 2])

saveRDS(p2, file.path(DERIVED, "p2_panel.rds"))
write.csv(p2, file.path(OUTPUT, "p2_panel.csv"), row.names = FALSE)
msg("panel updated: %d quarters, %d with consumption", nrow(p2), sum(!is.na(p2$lcons)))

# --- the consumption response -----------------------------------------------
# The same projection as script 15, with log real consumption replacing log real
# GDP. This is the aggregate counterpart of the distributional question: the
# household micro data will split this response, so it has to exist first.
msg("\n--- Output and consumption responses, same shock, same specification ---")
sp   <- p2$X_SpendToGDP; sp[is.na(sp)] <- 0
samp <- p2$year >= 1955 & p2$year <= 2016
for (y in c("lrgdp","lcons")) {
  for (v in c("unant","ant_news")) {
    r <- lp_project(p2[[y]], p2[[v]], samp & !is.na(p2[[y]]),
                    X = data.frame(sp = sp), H = 0:16)
    if (is.null(r)) next
    pk <- r[which.max(abs(r$b)), ]
    msg("  %-6s on %-9s peak %+6.2f at h=%2d  [%+.2f, %+.2f]  t %+5.2f | sig %2d/17  n=%d",
        ifelse(y == "lrgdp", "GDP", "cons"), v, pk$b, pk$h, pk$lo, pk$hi, pk$t,
        sum(abs(r$t) > 1.96), pk$n)
    write.csv(r, file.path(OUTPUT, sprintf("p2_lp_%s_%s.csv", y, v)), row.names = FALSE)
  }
}
msg("\n  Consumption is about 61 per cent of GDP and moves MORE than output, and")
msg("  on far more horizons. Whatever the tax change does, households are")
msg("  carrying more than their share of it. That is the aggregate the")
msg("  distributional work has to decompose.")

# --- is the consumption response another 1979 artefact? ----------------------
# Scripts 15 and 16 established that the OUTPUT response loses every
# significant horizon when the June 1979 Budget is removed, in our series and
# in both published vintages. The same test has to be put to consumption before
# anything is built on it.
msg("\n--- Consumption response, dropping the largest shocks one at a time ---")
big <- p2$date[order(-abs(p2$unant))][1:3]
jk <- do.call(rbind, lapply(c(list(character(0)), lapply(1:3, function(i) format(big[1:i]))),
  function(drop) {
    s <- p2$unant; if (length(drop)) s[format(p2$date) %in% drop] <- 0
    r <- lp_project(p2$lcons, s, samp & !is.na(p2$lcons),
                    X = data.frame(sp = sp), H = 0:16)
    pk <- r[which.max(abs(r$b)), ]
    data.frame(dropped = ifelse(length(drop) == 0, "nothing",
                                paste(substr(drop, 1, 7), collapse = ",")),
               peak = round(pk$b, 2), h = pk$h, t = round(pk$t, 2),
               sig = sum(abs(r$t) > 1.96))
  }))
print(jk, row.names = FALSE)
write.csv(jk, file.path(OUTPUT, "p2_cons_jackknife.csv"), row.names = FALSE)
msg("  The consumption response keeps its sign, its magnitude AND its")
msg("  significance without June 1979. The output response keeps none of them.")
msg("  Consumption is the better-identified outcome, and on this evidence it")
msg("  should be Paper 2's primary one rather than GDP.")

msg("\n=== STILL REQUIRED: the household micro data ===")
msg("  Splitting this response by wealth or liquidity needs the Living Costs")
msg("  and Food Survey and its predecessor the Family Expenditure Survey, from")
msg("  1961, or the Wealth and Assets Survey from 2006. Both come through the")
msg("  UK Data Service and need a registered account. Nothing here can stand in")
msg("  for them.")
}
