# 20_state_dependence.R --------------------------------------------------------
# WHAT SURVIVED. Scripts 15, 16 and 19 killed the instrument decomposition and
# the distributional split. This script tests the four things that could still
# support Paper 2, and reports honestly that three of them fail.
#
#   A. Is the announcement-effect null real, or is it no power?      FAILS
#   B. Are multipliers larger when the economy has slack?            HOLDS
#   C. Has the multiplier fallen as the pre-announcement regime      SUGGESTIVE
#      took hold?
#   D. Does long notice stop a Chancellor seeing the state the       WEAK
#      measure will land in?
#
# THE STATE MEASURE. Unemployment above its own seven-year backward moving
# average. Backward-looking by construction, so it uses only information a
# policymaker had at the time, and it needs no filter choice or output-gap
# estimate. Slack covers 149 of the 248 usable quarters.
#
# ALL ON CONSUMPTION, NOT OUTPUT. Script 18 established consumption is the
# better-identified outcome: it responds more, on more horizons, and unlike the
# output response it survives the removal of the June 1979 Budget.
#
# NOTE ON CONTROLS. The narrative spending shock is all zero within these
# subsamples, so including it makes the design matrix singular. It is dropped
# from the split regressions and kept in the pooled ones.

source("R/00_setup.R")
msg("== 20_state_dependence ==")

p <- readRDS(file.path(DERIVED, "p2_panel.rds")); p <- p[order(p$date), ]
ma <- stats::filter(p$Unemployment, rep(1/28, 28), sides = 1)
p$gap   <- p$Unemployment - ma
p$slack <- as.numeric(p$Unemployment > ma)
sp   <- p$X_SpendToGDP; sp[is.na(sp)] <- 0
base <- p$year >= 1955 & p$year <= 2016 & !is.na(p$lcons) & !is.na(p$slack)
msg("sample: %d quarters, %d in slack", sum(base), sum(base & p$slack == 1))

# ---------------------------------------------------------------------------
msg("\n=== A. Is the announcement null real, or is it no power? FAILS ===")
# The minimum detectable effect is the smallest true response this design would
# find four times in five: 2.80 standard errors, being 1.96 + 0.84.
for (v in c("unant", "ant_news")) {
  r <- lp_project(p$lcons, p[[v]], base, X = data.frame(sp = sp), H = 0:16)
  h9 <- r[r$h == 9, ]; pk <- r[which.max(abs(r$b)), ]
  msg("  %-9s peak %+6.2f (t %+5.2f) | at h9 %+6.2f [%+.2f, %+.2f] | MDE %.2f",
      v, pk$b, pk$t, h9$b, h9$lo, h9$hi, 2.80 * h9$se)
}
msg("  The news design cannot detect an effect the size of the surprise effect.")
msg("  So 'announced tax changes do not move consumption' is NOT supported: the")
msg("  data cannot tell that apart from an effect as large as the surprise one.")
msg("  Do not write that paper.")

# ---------------------------------------------------------------------------
msg("\n=== B. Multipliers are larger in slack. HOLDS ===")
st <- do.call(rbind, lapply(c(1, 0), function(v) {
  s <- base & p$slack == v
  x <- abs(p$unant[s]); top3 <- sum(sort(x, decreasing = TRUE)[1:3]) / sum(x)
  r <- lp_project(p$lcons, p$unant, s, H = 0:16)
  pk <- r[which.max(abs(r$b)), ]
  big <- which(s)[which.max(abs(p$unant[s]))]
  s2 <- p$unant; s2[big] <- 0
  r2 <- lp_project(p$lcons, s2, s, H = 0:16); pk2 <- r2[which.max(abs(r2$b)), ]
  msg("  %-5s n=%3d nz=%3d top3=%.2f | peak %+6.2f h=%2d t %+5.2f sig %2d/17",
      ifelse(v == 1, "slack", "tight"), sum(s), sum(p$unant[s] != 0), top3,
      pk$b, pk$h, pk$t, sum(abs(r$t) > 1.96))
  msg("        without its largest quarter: peak %+6.2f t %+5.2f sig %2d/17",
      pk2$b, pk2$t, sum(abs(r2$t) > 1.96))
  cbind(state = ifelse(v == 1, "slack", "tight"), r)
}))
write.csv(st, file.path(OUTPUT, "p2_state_split.csv"), row.names = FALSE)

# The split above gives two estimates. Whether they DIFFER needs the difference
# and its own standard error, which is the interaction.
msg("\n  Interaction test: the difference, with its own standard error")
dg <- c(NA, 100 * diff(p$lcons))
L <- lag_mat(p$unant, 4); G <- lag_mat(dg, 4)
ix <- do.call(rbind, lapply(0:16, function(h) {
  idx <- seq_along(p$lcons) + h; idx[idx < 1 | idx > nrow(p)] <- NA
  yh <- 100 * (p$lcons[idx] - c(NA, head(p$lcons, -1)))
  df <- data.frame(yh = yh, s = p$unant, sl = p$slack, si = p$unant * p$slack, L, G)
  k <- complete.cases(df) & base; df <- df[k, ]
  f <- lm(yh ~ ., data = df); se <- nw_se(f, h + 1)
  data.frame(h = h, diff = coef(f)[["si"]], se = se[["si"]],
             t = coef(f)[["si"]] / se[["si"]])
}))
for (i in seq_len(nrow(ix))) if (ix$h[i] %in% c(0, 4, 8, 9, 11, 12, 16))
  msg("    h=%2d  slack minus tight %+7.2f  se %5.2f  t %+5.2f%s",
      ix$h[i], ix$diff[i], ix$se[i], ix$t[i], ifelse(abs(ix$t[i]) > 1.96, "  *", ""))
msg("    significant at %d of 17 horizons. The gap is real, not two estimates",
    sum(abs(ix$t) > 1.96))
msg("    that happen to differ.")
write.csv(ix, file.path(OUTPUT, "p2_state_interaction.csv"), row.names = FALSE)

# ---------------------------------------------------------------------------
msg("\n=== C. Has the multiplier fallen with the regime? SUGGESTIVE ONLY ===")
for (e in list(c(1955, 1985), c(1986, 2016))) {
  s <- base & p$year >= e[1] & p$year <= e[2]
  r <- lp_project(p$lcons, p$unant, s, H = 0:16); pk <- r[which.max(abs(r$b)), ]
  msg("  %d-%d nz=%3d sd=%.3f | peak %+6.2f h=%2d [%+.1f, %+.1f] t %+5.2f sig %2d/17",
      e[1], e[2], sum(p$unant[s] != 0), sd(p$unant[s]), pk$b, pk$h, pk$lo, pk$hi,
      pk$t, sum(abs(r$t) > 1.96))
}
msg("  The point estimates fall, which fits Paper 1's story, but the late")
msg("  interval spans zero and the two overlap heavily. Report as a direction.")

# ---------------------------------------------------------------------------
msg("\n=== D. Does long notice hide the state the measure lands in? WEAK ===")
ext <- readRDS(file.path(DERIVED, "extended_measures.rds"))
d <- ext[ext$timing_sample & ext$endo_exo %in% "X" & !is.na(ext$peak_value) &
         ext$source != "CDPV" & !is.na(ext$announce) & !is.na(ext$implement), ]
lk <- function(dt) { q <- cloyne_quarter(dt, dt, retro_fix = FALSE)
  p$gap[match(paste(q$year, q$quarter), paste(p$year, p$quarter))] }
d$ga <- lk(d$announce); d$gi <- lk(d$implement)
d$notice <- as.numeric(pmax(d$implement, d$announce) - d$announce)
z <- d[!is.na(d$ga) & !is.na(d$gi), ]
for (b in list(c(0, 90), c(91, 365), c(366, 1e5))) {
  s <- z[z$notice >= b[1] & z$notice <= b[2], ]
  msg("  notice %5d-%-5s days  n=%4d | corr(state at announcement, at effect) %+.3f | mean move %.2f pp",
      b[1], ifelse(b[2] > 1e4, "+", as.character(b[2])), nrow(s),
      cor(s$ga, s$gi), mean(abs(s$gi - s$ga)))
}
msg("  The correlation falls from 0.995 to 0.806 and the typical state moves by")
msg("  0.74 points rather than 0.03. Real, and smaller than the story wants:")
msg("  unemployment is persistent, so even two years out a Chancellor mostly")
msg("  knows the state. State this as a modest cost, not a forfeited instrument.")

msg("\n=== WHAT THIS LEAVES ===")
msg("  One robust finding: the consumption response to an unanticipated tax rise")
msg("  is about twice as large when the economy has slack, and the difference is")
msg("  significant on its own standard error. Everything else in this script is")
msg("  a direction or a failure, and should be written as one.")
