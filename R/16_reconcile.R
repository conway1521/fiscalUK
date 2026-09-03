# 16_reconcile.R ---------------------------------------------------------------
# BLOCKING CHECK FOR PAPER 2. Before any multiplier is reported, our shock
# series has to reproduce the published one. It does not, and this script
# records by how much and where.
#
# THREE SERIES ARE COMPARED, all over 1955-2009 with the same specification:
#   ours       the unanticipated exogenous series built in script 12
#   AER 2013   Cloyne's own published surprise series, from his website
#   JPE 2025   the unanticipated exogenous series in the Dataverse deposit
#
# WHAT PROMPTED THIS. Script 15 found instrument-level multipliers of -8.5 for
# corporation tax and -5.0 for VAT, which are not credible magnitudes, and a
# VAT response significant at every horizon. The concentration diagnostic
# explains it: 84 per cent of the absolute variation in the VAT surprise series
# sits in three quarters and the largest single one is 1979Q3, the Howe Budget
# raising VAT to 15 per cent. Most instrument cells are one or two events.
#
# WHAT THE COMPARISON THEN SHOWED. The fragility is not ours alone. Cloyne's own
# published series has 1979Q3 as its largest observation at +1.596, and dropping
# that one quarter takes his aggregate response from t = -2.45 with four
# significant horizons to t = -1.46 with none. The published UK narrative tax
# multiplier rests heavily on a single Budget.
#
# OURS WAS ONCE WORSE. On the construction this script was first written
# against, dropping 1979Q3 flipped our estimate to +2.86 while his stayed
# negative. Script 17 traced that to three convention differences and script 12
# now adopts his: the 45-day quarter shift, the 90-day threshold and the
# retroactivity replacement. Our series behaves like his as a result, and the
# numbers below are from the reconciled construction.

source("R/00_setup.R")
msg("== 16_reconcile ==")

EXT <- file.path(DERIVED, "external")
aer_p <- file.path(EXT, "cloyne2013_surprises.xls")
if (!file.exists(aer_p)) {
  msg("  downloading Cloyne (2013) published surprise series ...")
  try(download.file("https://jamescloyne.com/uploads/Cloyne2013AERTaxSurprises.xls",
                    aer_p, mode = "wb", quiet = TRUE), silent = TRUE)
}
if (!file.exists(aer_p)) {
  msg("  UNAVAILABLE. Source: jamescloyne.com, Cloyne2013AERTaxSurprises.xls")
} else {

p <- readRDS(file.path(DERIVED, "p2_panel.rds")); p <- p[order(p$date), ]

a <- as.data.frame(rx(aer_p, skip = 2))
v <- suppressWarnings(as.numeric(a[[1]])); v <- v[!is.na(v)]
aer <- data.frame(date = seq(as.Date("1955-01-01"), by = "3 months",
                             length.out = length(v)), aer = v)

jpe_p <- file.path(EXT, "cdh_robustness.xlsx")
jpe <- as.data.frame(rx(jpe_p, sheet = "unanticipated"))
names(jpe) <- c("date","endo","jpe"); jpe$date <- as.Date(jpe$date)

m <- merge(merge(p[, c("date","lrgdp","unant")], aer, by = "date"),
           jpe[, c("date","jpe")], by = "date")
m <- m[order(m$date), ]
msg("common window: %s to %s, %d quarters",
    format(min(m$date)), format(max(m$date)), nrow(m))

# --- how alike are they? ----------------------------------------------------
msg("\n--- pairwise correlation ---")
cm <- round(cor(m[, c("unant","aer","jpe")]), 3)
print(cm)

msg("\n--- concentration: share of absolute variation in the top three quarters ---")
for (v2 in c("unant","aer","jpe")) {
  x <- abs(m[[v2]]); o <- order(-x)[1:3]
  msg("  %-6s sd %.3f | top3 %.2f | %s", v2, sd(m[[v2]]), sum(x[o])/sum(x),
      paste(sprintf("%sQ%d:%+.2f", format(m$date[o], "%Y"),
                    (as.integer(format(m$date[o], "%m")) - 1) %/% 3 + 1, m[[v2]][o]),
            collapse = " "))
}

msg("\n--- the June 1979 Budget, as each source records it ---")
i <- format(m$date) == "1979-07-01"
msg("  ours %+.3f | Cloyne AER 2013 %+.3f | Cloyne-Hurtgen-Dimsdale JPE 2025 %+.3f",
    m$unant[i], m$aer[i], m$jpe[i])
msg("  The 2025 revision cuts the same Budget to roughly a quarter of the 2013")
msg("  figure. Which vintage is used changes the largest observation in the")
msg("  postwar sample by a factor of four.")

# --- and what that does to the multiplier -----------------------------------
msg("\n--- peak output response, dropping one quarter at a time ---")
ok <- rep(TRUE, nrow(m))
grid <- expand.grid(series = c("unant","aer","jpe"),
                    drop = c("none","1979-07-01"), stringsAsFactors = FALSE)
tab <- do.call(rbind, lapply(seq_len(nrow(grid)), function(k) {
  s <- m[[grid$series[k]]]
  if (grid$drop[k] != "none") s[format(m$date) == grid$drop[k]] <- 0
  r <- lp_project(m$lrgdp, s, ok, H = 0:16)
  pk <- r[which.max(abs(r$b)), ]
  data.frame(series = grid$series[k], dropped = grid$drop[k],
             peak = round(pk$b, 2), h = pk$h, t = round(pk$t, 2),
             sig = sum(abs(r$t) > 1.96))
}))
print(tab[order(tab$series, tab$dropped), ], row.names = FALSE)
write.csv(tab, file.path(OUTPUT, "p2_reconcile.csv"), row.names = FALSE)

msg("\n  VERDICT. All three series now behave the same way. Each keeps its sign")
msg("  and rough magnitude without 1979Q3 and each loses every significant")
msg("  horizon. The statistical significance of the UK narrative tax multiplier,")
msg("  in our data and in both published vintages, rests on the June 1979")
msg("  Budget. That is a fact about the literature, and it has to be stated")
msg("  rather than estimated around.")
}
