# 19_incidence.R ---------------------------------------------------------------
# PAPER 2, THE DISTRIBUTIONAL HALF, on public data only.
#
# THE IDEA. We cannot observe whose consumption falls, because that needs
# household micro data from the UK Data Service. We CAN observe whose pound is
# being taken, because the ONS "Effects of taxes and benefits on household
# income" tables report, for every year from 1977, what each income decile pays
# in income tax, National Insurance, council tax, VAT and each duty.
#
# So instead of splitting the RESPONSE by household type, split the SHOCK by
# where its burden falls, and compare the aggregate consumption response to the
# two halves. A regressive tax rise and a progressive one of the same size are
# then two different shocks, and the question is whether the economy answers
# them differently. That is testable now, on data already on disk.
#
# CONSTRUCTION. For each instrument the ONS tables give the average payment per
# household in each decile. Deciles hold equal numbers of households, so a
# decile's share of the total burden of a tax is its average payment over the
# sum across deciles. The bottom-half share is the first five deciles' share,
# and it measures relative concentration rather than regressivity in the usual
# share-of-income sense: no tax exceeds 0.5, because richer households pay more
# of everything in cash, so what the numbers rank is which taxes lean furthest
# down the distribution.
#
# Each narrative measure is then assigned the incidence of its instrument in the
# nearest available year, and its value is split into a bottom-borne and a
# top-borne part. Two shock series result, and they sum to the original.
#
# WHAT THIS IS NOT. It is statutory cash incidence, not economic incidence: no
# behavioural response, no shifting, no lifetime perspective. Corporation tax,
# capital gains, inheritance and North Sea measures cannot be placed at all,
# because the ONS tables do not allocate them to households, so those measures
# are excluded and the share of value that costs is reported.
#
# The ETB tables are annual and financial-year dated from 1994-95. Incidence
# moves slowly, so a measure is matched to the nearest year rather than
# interpolated.

source("R/00_setup.R")
msg("== 19_incidence ==")

EXT <- file.path(DERIVED, "external")
etb <- file.path(EXT, "ons_etb_decile.xlsx")
URL <- paste0("https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/",
              "personalandhouseholdfinances/incomeandwealth/datasets/",
              "theeffectsoftaxesandbenefitsonhouseholdincomehistoricaldatasets/",
              "incometaxandbenefitdatabyincomedecileforallhouseholds/",
              "incometaxandbenefitdatabyincomedecileforallhouseholds.xlsx")
if (!file.exists(etb) || file.size(etb) < 1e5) {
  msg("  downloading the ONS ETB decile tables ...")
  try(download.file(URL, etb, mode = "wb", quiet = TRUE), silent = TRUE)
}

if (!file.exists(etb) || file.size(etb) < 1e5) {
  msg("  UNAVAILABLE (offline?). Source: ONS, Effects of taxes and benefits on")
  msg("  household income, historical household-level datasets, decile edition.")
} else {

# --- parse one year ----------------------------------------------------------
# Labels repeat: the duties appear again lower down under intermediate taxes,
# which are employer-borne. Everything below "Employers' NI contributions"
# belongs to that block and must be ignored.
WANT <- list(
  income   = "^Income [Tt]ax$",
  nic      = "^Employees' NI contributions$",
  counciltax = "^Council [Tt]ax",
  vat      = "^VAT$",
  duty     = "^(Duty on|Vehicle Excise Duty|Customs duties|Betting taxes)",
  stampduty = "^Stamp Duty")

parse_year <- function(sheet) {
  d <- as.data.frame(rx(etb, sheet = sheet, col_names = FALSE))
  lab <- as.character(d[[1]])
  stop_at <- which(!is.na(lab) & grepl("^Employers' NI contributions", lab))[1]
  if (is.na(stop_at)) stop_at <- nrow(d)
  # decile columns: the block of numeric columns after the label column, taking
  # the first ten, since the last column is the all-household average.
  vals <- suppressWarnings(sapply(d[, -1, drop = FALSE], as.numeric))
  ncol_ok <- min(10, ncol(vals))
  out <- lapply(WANT, function(p) {
    r <- which(!is.na(lab) & grepl(p, lab) & seq_along(lab) < stop_at)
    if (!length(r)) return(rep(NA_real_, ncol_ok))
    m <- vals[r, seq_len(ncol_ok), drop = FALSE]
    colSums(m, na.rm = TRUE)
  })
  # council tax is reported gross with a rebate line immediately after
  reb <- which(!is.na(lab) & grepl("less: Council [Tt]ax", lab) & seq_along(lab) < stop_at)
  if (length(reb)) out$counciltax <- out$counciltax -
      as.numeric(vals[reb[1], seq_len(ncol_ok)])
  as.data.frame(out)
}

sheets <- excel_sheets(etb)
sheets <- sheets[grepl("^[0-9]{4}", sheets)]
inc <- do.call(rbind, lapply(sheets, function(s) {
  z <- parse_year(s)
  # bottom-half share of each tax's total burden
  data.frame(sheet = s, year = as.integer(substr(s, 1, 4)),
             t(sapply(z, function(x) sum(x[1:5]) / sum(x))))
}))
names(inc)[-(1:2)] <- names(WANT)
msg("parsed %d ETB years, %s to %s", nrow(inc), sheets[1], tail(sheets, 1))
msg("\n--- share of each tax's cash burden borne by the bottom five deciles ---")
show <- inc[inc$year %in% c(1977, 1990, 2000, 2010, 2017), ]
print(round(show[, -1], 3), row.names = FALSE)
msg("  These are CASH shares, and none exceeds 0.5, because richer households")
msg("  spend and earn more in absolute terms. What matters is the ordering:")
msg("  duties are more than twice as concentrated on the bottom half as income")
msg("  tax, which is the gradient the split below exploits.")
write.csv(inc, file.path(OUTPUT, "p2_incidence_shares.csv"), row.names = FALSE)

# --- map our instruments onto the ONS categories -----------------------------
MAP <- c("Income" = "income", "Social security" = "nic", "VAT" = "vat",
         "Excise and duties" = "duty", "Property transaction" = "stampduty",
         "Property recurrent" = "counciltax")
msg("\n--- instruments that can and cannot be placed ---")
ext <- readRDS(file.path(DERIVED, "extended_measures.rds"))
d <- ext[ext$timing_sample & ext$endo_exo %in% "X" & !is.na(ext$peak_value) &
         ext$source != "CDPV", ]
d$etb <- MAP[d$tax_h]
pl <- sum(abs(d$peak_value[!is.na(d$etb)])); un <- sum(abs(d$peak_value[is.na(d$etb)]))
msg("  placed:   %4d measures, %.0f%% of gross value", sum(!is.na(d$etb)), 100*pl/(pl+un))
msg("  unplaced: %4d measures, %.0f%% (%s)", sum(is.na(d$etb)), 100*un/(pl+un),
    paste(sort(unique(d$tax_h[is.na(d$etb)])), collapse = ", "))

# --- split each measure into bottom-borne and top-borne ----------------------
d <- d[!is.na(d$etb) & !is.na(d$announce), ]
d$ay <- as.integer(format(d$announce, "%Y"))
d$bshare <- mapply(function(cat, y) {
  inc[[cat]][which.min(abs(inc$year - y))]
}, d$etb, d$ay)
msg("\n  bottom-half share by instrument (mean across measures):")
print(round(tapply(d$bshare, d$tax_h, mean), 3))

p <- readRDS(file.path(DERIVED, "p2_panel.rds")); p <- p[order(p$date), ]
key <- paste(p$year, p$quarter)
agg <- function(yr, qt, v) {
  k <- paste(yr, qt); i <- !is.na(yr) & !is.na(qt) & k %in% key
  s <- tapply(v[i], k[i], sum)
  o <- setNames(rep(0, length(key)), key); o[names(s)] <- s; as.numeric(o)
}
imp <- d$implement
swap <- !is.na(d$announce) & imp < d$announce; imp[swap] <- d$announce[swap]
iq  <- cloyne_quarter(d$implement, d$announce, retro_fix = TRUE)
lo  <- as.numeric(imp - d$announce) > 90            # anticipated
u   <- !lo                                          # the valid shock
p$sh_bottom <- 100 * agg(iq$year[u], iq$quarter[u], d$peak_value[u] * d$bshare[u]) / p$gdp_ann
p$sh_top    <- 100 * agg(iq$year[u], iq$quarter[u], d$peak_value[u] * (1 - d$bshare[u])) / p$gdp_ann

msg("\n--- the two shock series ---")
w <- p$year >= 1955 & p$year <= 2016
msg("  bottom-borne: sd %.3f, %d nonzero quarters", sd(p$sh_bottom[w]), sum(p$sh_bottom[w] != 0))
msg("  top-borne   : sd %.3f, %d nonzero quarters", sd(p$sh_top[w]), sum(p$sh_top[w] != 0))
msg("  correlation between them: %+.3f", cor(p$sh_bottom[w], p$sh_top[w]))
msg("  NOTE. They are two slices of the same measures, so they are highly")
msg("  correlated by construction and CANNOT be entered in one regression.")

# --- do they move consumption differently? -----------------------------------
msg("\n--- consumption response, per pound, to each half ---")
sp <- p$X_SpendToGDP; sp[is.na(sp)] <- 0
samp <- w & !is.na(p$lcons)
res <- do.call(rbind, lapply(c("sh_bottom","sh_top"), function(v) {
  r <- lp_project(p$lcons, p[[v]], samp, X = data.frame(sp = sp), H = 0:16)
  pk <- r[which.max(abs(r$b)), ]
  sdv <- sd(p[[v]][samp])
  msg("  %-10s peak %+7.2f at h=%2d  [%+.2f, %+.2f]  t %+5.2f | sig %2d/17",
      v, pk$b, pk$h, pk$lo, pk$hi, pk$t, sum(abs(r$t) > 1.96))
  msg("             a one-sd shock is %.3f%% of GDP, so that peak is %+.2f%% of",
      sdv, pk$b * sdv)
  msg("             consumption; the printed coefficient extrapolates %.0f sd.",
      1 / sdv)
  cbind(series = v, sd_shock = sdv, r)
}))
write.csv(res, file.path(OUTPUT, "p2_lp_incidence.csv"), row.names = FALSE)

msg("\n  READ THIS BEFORE THE NUMBERS ABOVE. Both coefficients are per pound of")
msg("  burden and so are comparable in principle, and the point estimates say a")
msg("  pound taken from the bottom half costs roughly three times the")
msg("  consumption of a pound taken from the top. Three things stop that being")
msg("  a result.")
msg("   1. The bottom-borne interval includes zero and is enormous. The two")
msg("      responses are not statistically distinguishable.")
msg("   2. The two series correlate at %.2f, because they are slices of the",
    cor(p$sh_bottom[w], p$sh_top[w]))
msg("      SAME measures rather than different ones. Nothing in the data")
msg("      separates them; the split is arithmetic, not variation.")
msg("   3. Only 15 to 36 per cent of any measure lands on the bottom half, so")
msg("      the bottom-borne series has a quarter of the amplitude and the")
msg("      per-pound coefficient is a long extrapolation.")
msg("  The fix is to compare measures that DIFFER in incidence rather than")
msg("  slices of the same measure, which means the instrument decomposition,")
msg("  and script 15 showed that is not identified either. On public data this")
msg("  is as far as the distributional question goes.")

saveRDS(p, file.path(DERIVED, "p2_panel.rds"))
msg("\nwritten: output/p2_incidence_shares.csv, output/p2_lp_incidence.csv")
}
