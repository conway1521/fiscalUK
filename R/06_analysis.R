# 06_analysis.R --------------------------------------------------------------
# Paper 1 results, all on the PRIMARY outcome `long` (gap of 120+ days).
#
# Why this outcome: see RESULTS.md section 0. `lag_quarters` is degenerate
# (42% of mass at zero, variance 1.04 in the 1940s against 11.25 in the 2010s);
# `deferred` is partly artefactual, since a March Budget implementing on 6 April
# crosses the fiscal-year boundary on three weeks' notice, and the share of such
# cases drifts from 0.72 in the 1980s to 0.11 in the 2010s.
#
# All inference is UNWEIGHTED and CLUSTERED on the Budget event. Revenue
# weighting collapses the effective sample from 2,252 to 251 and is used only
# for descriptive magnitudes.

source("R/00_setup.R")
msg("== 06_analysis ==")

SPLICE <- as.Date("2004-01-01")
ch <- readRDS(file.path(DERIVED, "uk_chained_measures.rds"))
m  <- ch[ch$timing_sample & !is.na(ch$announce) & !is.na(ch$implement) &
         ((ch$source == "Cloyne" & ch$budget_date <  SPLICE) |
          (ch$source == "Modern" & ch$budget_date >= SPLICE)), ]
m$yr   <- as.integer(format(m$announce, "%Y"))
m$dec  <- 10 * (m$yr %/% 10)
m$rise <- m$peak_value > 0
m$ev   <- factor(as.character(m$budget_date))
msg("analysis sample: %d measures, %d Budget events, %d-%d",
    nrow(m), nlevels(m$ev), min(m$yr), max(m$yr))

#' Cluster-robust (CR1) coefficient table for lm.
clx <- function(fit, cluster) {
  X <- model.matrix(fit); b <- solve(crossprod(X)); sc <- X * residuals(fit)
  cf <- droplevels(factor(cluster)); G <- nlevels(cf); N <- nrow(X); K <- ncol(X)
  meat <- matrix(0, K, K)
  for (g in levels(cf)) { sg <- colSums(sc[cf == g, , drop = FALSE]); meat <- meat + tcrossprod(sg) }
  V  <- b %*% ((G/(G-1)) * ((N-1)/(N-K)) * meat) %*% b
  se <- sqrt(diag(V)); z <- coef(fit)/se
  cbind(est = coef(fit), se = se, z = z, p = 2*pnorm(-abs(z)),
        lo = coef(fit) - 1.96*se, hi = coef(fit) + 1.96*se)
}

# --- FACT 1: the trend ------------------------------------------------------
msg("\n--- FACT 1: share of measures with a 120+ day gap ---")
tr <- do.call(rbind, lapply(split(m, m$dec), function(s) data.frame(
  decade = s$dec[1], n = nrow(s), events = nlevels(droplevels(s$ev)),
  long = round(mean(s$long, na.rm = TRUE), 3))))
print(tr, row.names = FALSE)
write.csv(tr, file.path(OUTPUT, "fact1_trend.csv"), row.names = FALSE)

blk <- do.call(rbind, lapply(split(m, 5*(m$yr %/% 5)), function(s) data.frame(
  block = 5*(s$yr[1] %/% 5), n = nrow(s), long = mean(s$long, na.rm = TRUE))))
write.csv(blk, file.path(OUTPUT, "fact1_trend_5yr.csv"), row.names = FALSE)

# --- FACT 2: instruments, within Budget -------------------------------------
msg("\n--- FACT 2: instrument effects, Budget-event fixed effects ---")
i <- m[!is.na(m$tax_h), ]
i$tax_h <- relevel(factor(i$tax_h), ref = "Excise and duties")
fi <- lm(long ~ tax_h + ev, data = i)
ri <- clx(fi, i$ev); ri <- ri[grep("^tax_h", rownames(ri)), , drop = FALSE]
rownames(ri) <- sub("^tax_h", "", rownames(ri))
ri <- ri[order(-ri[, "est"]), ]
print(round(ri[, c("est","se","z","p")], 3))
f0 <- lm(long ~ ev, data = i)
an <- anova(f0, fi)
msg("joint F for instrument within Budget: F = %.1f on %d df, p = %.3g",
    an$F[2], an$Df[2], an$`Pr(>F)`[2])
msg("R2: Budget FE alone %.3f, + instrument %.3f", summary(f0)$r.squared, summary(fi)$r.squared)
write.csv(data.frame(instrument = rownames(ri), ri), file.path(OUTPUT, "fact2_instruments.csv"), row.names = FALSE)

# --- FACT 3: the mechanism, conditional on the Budget calendar --------------
# A measure pinned to 6 April sits three weeks from a March Budget but five
# months from a November one. So the fiscal-year clock produces a LONG gap only
# when the Budget falls late in the year. Tested directly on April-pinned
# measures.
#
# NOTE: an earlier version of this claim, that parameter changes are inherently
# slower, holds on `deferred` (+0.54, z 10.2) but NOT on the primary outcome
# (+0.042, p 0.46). It was a fiscal-year-boundary artefact. See RESULTS.md R6.
msg("\n--- FACT 3: mechanism. The fiscal-year clock, conditional on Budget season ---")
m$bmonth <- as.integer(format(m$budget_date, "%m"))
m$autumn <- as.integer(m$bmonth %in% 9:12)
p <- m[m$fy_boundary == 1, ]
msg("April-pinned measures (implement 1-7 April): n = %d", nrow(p))
msg("  long-gap rate: spring Budget %.3f, autumn Budget %.3f",
    mean(p$long[p$autumn == 0]), mean(p$long[p$autumn == 1]))
print(round(clx(lm(long ~ autumn + factor(dec), data = p), p$ev)["autumn", c("est","se","z","p")], 4))

msg("\n  BUT the calendar explains cross-sectional variation, not the trend:")
a <- lm(long ~ factor(dec), data = m)
b <- lm(long ~ factor(dec) + autumn + fy_boundary, data = m)
msg("  R2 %.3f -> %.3f; 2010s decade coefficient %.2f -> %.2f (%.0f%% absorbed)",
    summary(a)$r.squared, summary(b)$r.squared,
    coef(a)["factor(dec)2010"], coef(b)["factor(dec)2010"],
    100*(1 - coef(b)["factor(dec)2010"]/coef(a)["factor(dec)2010"]))

msg("\n  implementation date migration and Budget season, by decade:")
clock <- do.call(rbind, lapply(split(m, m$dec), function(s) data.frame(
  decade = s$dec[1],
  apr6 = round(mean(s$imp_day == "04-06"), 3),
  apr1 = round(mean(s$imp_day == "04-01"), 3),
  budget_day = round(mean(s$on_budget_day, na.rm = TRUE), 3),
  autumn_budget = round(mean(s$autumn), 3))))
print(clock, row.names = FALSE)
write.csv(clock, file.path(OUTPUT, "fact3_clock.csv"), row.names = FALSE)
season <- data.frame(
  decade = rep(sort(unique(m$dec)), 2),
  season = rep(c("spring","autumn"), each = length(unique(m$dec))),
  long = c(tapply(m$long[m$autumn==0], m$dec[m$autumn==0], mean)[as.character(sort(unique(m$dec)))],
           tapply(m$long[m$autumn==1], m$dec[m$autumn==1], mean)[as.character(sort(unique(m$dec)))]),
  n = c(tapply(m$long[m$autumn==0], m$dec[m$autumn==0], length)[as.character(sort(unique(m$dec)))],
        tapply(m$long[m$autumn==1], m$dec[m$autumn==1], length)[as.character(sort(unique(m$dec)))]))
write.csv(season, file.path(OUTPUT, "fact3_season.csv"), row.names = FALSE)

# --- FACT 4: elections ------------------------------------------------------
msg("\n--- FACT 4: are tax rises scheduled past the next election? ---")
EL <- as.Date(c("1945-07-05","1950-02-23","1951-10-25","1955-05-26","1959-10-08","1964-10-15",
"1966-03-31","1970-06-18","1974-02-28","1974-10-10","1979-05-03","1983-06-09","1987-06-11",
"1992-04-09","1997-05-01","2001-06-07","2005-05-05","2010-05-06","2015-05-07","2017-06-08",
"2019-12-12"))   # 2019 was missing: without it the 56 measures announced after
                 # June 2017 got next_el = NA and dropped out of the test entirely.
nx <- sapply(m$announce, function(a) { z <- EL[EL > a]; if (!length(z)) NA else z[1] })
m$next_el <- as.Date(nx, origin = "1970-01-01")
m$mths_to_el  <- as.numeric(m$next_el - m$announce)/30.44
m$lands_after <- as.integer(m$implement > m$next_el)
for (lo in c(0, 6)) {
  d <- m[!is.na(m$next_el) & m$mths_to_el <= 24 & m$mths_to_el >= lo & !is.na(m$rise), ]
  fe <- lm(lands_after ~ rise + ev, data = d)
  r  <- clx(fe, d$ev)["riseTRUE", ]
  msg("  announced %d-24 months out: n=%d, events=%d | cuts %.3f, rises %.3f | est %+.3f (z %.2f, p %.3f)",
      lo, nrow(d), nlevels(droplevels(d$ev)),
      mean(d$lands_after[!d$rise]), mean(d$lands_after[d$rise]),
      r["est"], r["z"], r["p"])
}
d <- m[!is.na(m$next_el) & m$mths_to_el <= 24 & m$mths_to_el >= 6 & !is.na(m$rise), ]
write.csv(data.frame(sign = c("cut","rise"),
                     rate = c(mean(d$lands_after[!d$rise]), mean(d$lands_after[d$rise])),
                     n    = c(sum(!d$rise), sum(d$rise))),
          file.path(OUTPUT, "fact4_elections.csv"), row.names = FALSE)

# --- NEGATIVE: crises -------------------------------------------------------
msg("\n--- NEGATIVE: crises do not speed policy up ---")
m$crisis <- (m$yr %in% 1974:1976) | (m$yr %in% 1992:1993) | (m$yr %in% 2008:2009)
for (g in c("N","X")) {
  s <- m[m$endo_exo %in% g, ]
  r <- clx(lm(long ~ crisis + factor(dec), data = s), s$ev)["crisisTRUE", ]
  msg("  %-10s n=%4d crisis=%3d | in %.3f out %.3f | est %+.3f (p %.3f)",
      ifelse(g=="N","endogenous","exogenous"), nrow(s), sum(s$crisis),
      mean(s$long[s$crisis]), mean(s$long[!s$crisis]), r["est"], r["p"])
}

saveRDS(m, file.path(DERIVED, "paper1_analysis.rds"))
msg("\nwritten: output/fact{1,2,3,4}_*.csv, data-derived/paper1_analysis.rds")
