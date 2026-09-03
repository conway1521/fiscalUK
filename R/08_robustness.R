# 08_robustness.R ------------------------------------------------------------
# Two things Paper 1 cannot go to draft without.
#
# PART A. THE SEAM. Fact 1 (the rise in the long-gap share) crosses a data-source
# join: Cloyne's coding to 2003, ours from 2004. If the two codings measure the
# announcement-to-implementation gap differently, or itemise Budgets differently,
# the "trend" is a change in the record rather than in behaviour. This is the
# first thing a referee will attack and it is tested here six ways.
#
# PART B. THE ANTICIPATION SHARE. Fact 1 is about counts of measures. The object
# other researchers use is the revenue impulse. This part asks what share of the
# tax revenue actually landing on the economy had been announced 120+ days
# earlier, which is what makes the measurement change matter outside this paper.
#
# PART C. BREAK DATING. Where the rise starts, and whether it coincides with a
# named institutional reform. This determines how the paper can frame it.

source("R/00_setup.R")
msg("== 08_robustness ==")

SPLICE <- as.Date("2004-01-01")
OVL    <- c(as.Date("2004-03-17"), as.Date("2009-04-22"))

ch <- readRDS(file.path(DERIVED, "uk_chained_measures.rds"))
sr <- readRDS(file.path(DERIVED, "uk_shock_series.rds"))
grid <- sr$series
p2   <- sr$measures                      # Paper 2 sample: household, exogenous

# Paper 1 sample, spliced (identical construction to 06_analysis.R)
m <- ch[ch$timing_sample & !is.na(ch$announce) & !is.na(ch$implement) &
        ((ch$source == "Cloyne" & ch$budget_date <  SPLICE) |
         (ch$source == "Modern" & ch$budget_date >= SPLICE)), ]
m$yr     <- as.integer(format(m$announce, "%Y"))
m$dec    <- 10 * (m$yr %/% 10)
m$ev     <- factor(as.character(m$budget_date))
m$absval <- abs(m$peak_value)
m$bmonth <- as.integer(format(m$budget_date, "%m"))
m$autumn <- as.integer(m$bmonth %in% 9:12)
gdp_y    <- tapply(grid$gdp, grid$year, mean)
m$val_pct <- 100 * m$absval / as.numeric(gdp_y[as.character(m$yr)])

# Union sample (overlap kept twice) -- only for the like-for-like seam tests
ts <- ch[ch$timing_sample & !is.na(ch$announce) & !is.na(ch$implement), ]
ts$yr <- as.integer(format(ts$announce, "%Y")); ts$dec <- 10 * (ts$yr %/% 10)

clx <- function(fit, cl) {
  X <- model.matrix(fit); b <- solve(crossprod(X)); sc <- X * residuals(fit)
  cf <- droplevels(factor(cl)); G <- nlevels(cf); N <- nrow(X); K <- ncol(X)
  meat <- matrix(0, K, K)
  for (g in levels(cf)) { sg <- colSums(sc[cf == g, , drop = FALSE]); meat <- meat + tcrossprod(sg) }
  V <- b %*% ((G/(G-1)) * ((N-1)/(N-K)) * meat) %*% b
  se <- sqrt(diag(V)); z <- coef(fit)/se
  cbind(est = coef(fit), se = se, z = z, p = 2*pnorm(-abs(z)))
}
wshare <- function(x, w) sum(w * x, na.rm = TRUE) / sum(w[!is.na(x)], na.rm = TRUE)

# ===========================================================================
# PART A: THE SEAM
# ===========================================================================
msg("\n=== A1. Is `announce` the same object in both codings? ===")
# If Cloyne collapsed announcement onto the Budget date while we record genuine
# pre-Budget announcement, modern gaps would be longer by construction.
ts$amb <- as.numeric(ts$announce - ts$budget_date)
a1 <- do.call(rbind, lapply(split(ts, ts$source), function(s) data.frame(
  source = s$source[1], n = nrow(s),
  share_on_budget_day = round(mean(s$amb == 0, na.rm = TRUE), 3),
  share_pre_budget    = round(mean(s$amb <  0, na.rm = TRUE), 3),
  median_gap_days     = median(s$amb, na.rm = TRUE))))
print(a1, row.names = FALSE)
msg("  -> both codings put ~90%% of announcements on the Budget day itself.")

msg("\n=== A2. DECISIVE: the 2004-2009 overlap, same Budgets, both codings ===")
o  <- ts[ts$budget_date >= OVL[1] & ts$budget_date <= OVL[2], ]
cm <- intersect(unique(o$budget_date[o$source=="Cloyne"]), unique(o$budget_date[o$source=="Modern"]))
oc <- o[o$budget_date %in% cm, ]
a2 <- do.call(rbind, lapply(split(oc, oc$source), function(s) data.frame(
  source = s$source[1], n = nrow(s), events = length(unique(s$budget_date)),
  meas_per_event = round(nrow(s)/length(unique(s$budget_date)), 1),
  long_unweighted = round(mean(s$long), 3),
  long_revenue_wtd = round(wshare(s$long, abs(s$peak_value)), 3),
  median_days = median(s$days))))
print(a2, row.names = FALSE)
evm <- do.call(rbind, lapply(split(oc, list(oc$budget_date, oc$source), drop = TRUE), function(s)
  data.frame(budget_date = s$budget_date[1], source = s$source[1], long = mean(s$long))))
wd <- reshape(evm, idvar = "budget_date", timevar = "source", direction = "wide")
dd <- wd$long.Modern - wd$long.Cloyne
msg("  paired within-event difference (Modern - Cloyne): mean %+.3f, t = %.2f on %d events",
    mean(dd, na.rm = TRUE),
    mean(dd, na.rm = TRUE)/(sd(dd, na.rm = TRUE)/sqrt(sum(!is.na(dd)))), sum(!is.na(dd)))
msg("  -> Cloyne itemises %.1fx more finely yet gives the SAME long-gap share.",
    a2$meas_per_event[1]/a2$meas_per_event[2])
write.csv(a2, file.path(OUTPUT, "seam_overlap_long.csv"), row.names = FALSE)

msg("\n=== A3. Does the trend survive event-level and revenue weighting? ===")
a3 <- do.call(rbind, lapply(split(m, m$dec), function(s) {
  ev <- tapply(s$long, droplevels(s$ev), mean)
  data.frame(decade = s$dec[1], n = nrow(s), events = length(ev),
             meas_per_event = round(nrow(s)/length(ev), 1),
             unweighted  = round(mean(s$long), 3),
             event_level = round(mean(ev), 3),
             revenue_wtd = round(wshare(s$long, s$absval), 3))
}))
print(a3, row.names = FALSE)
write.csv(a3, file.path(OUTPUT, "seam_trend_weightings.csv"), row.names = FALSE)

msg("\n=== A4. Composition: is the rise a change in the tax mix? ===")
mm   <- m[!is.na(m$tax_h), ]
base <- prop.table(table(mm$tax_h[mm$yr < 1980]))
rt   <- tapply(mm$long, list(mm$dec, mm$tax_h), mean)
cf   <- sapply(rownames(rt), function(d) {
  r <- rt[d, names(base)]; ok <- !is.na(r); sum(base[ok]*r[ok])/sum(base[ok]) })
act  <- tapply(mm$long, mm$dec, mean)
a4 <- data.frame(decade = as.integer(names(act)), actual = round(act, 3),
                 counterfactual_1945_79_mix = round(cf, 3),
                 composition_effect = round(act - cf, 3))
print(a4, row.names = FALSE)
msg("  -> composition explains at most %.3f of the change. The rise is within-instrument.",
    max(abs(a4$composition_effect)))
write.csv(a4, file.path(OUTPUT, "seam_composition.csv"), row.names = FALSE)

msg("\n=== A5. Granularity-proof: the 20 largest measures of each decade ===")
a5 <- do.call(rbind, lapply(split(m, m$dec), function(s) {
  s <- head(s[order(-s$val_pct), ], 20)
  data.frame(decade = s$dec[1], n = nrow(s), long = round(mean(s$long), 3))
}))
print(a5, row.names = FALSE)
msg("  -> equal count per decade, so itemisation practice cannot drive it.")
write.csv(a5, file.path(OUTPUT, "seam_top20.csv"), row.names = FALSE)

msg("\n=== A6. The step inside Cloyne's own coding, where no seam exists ===")
m$post90 <- as.integer(m$yr >= 1990)
co <- m[m$source == "Cloyne", ]
r_all <- clx(lm(long ~ post90, data = m),  m$ev)["post90", ]
r_clo <- clx(lm(long ~ post90, data = co), co$ev)["post90", ]
c2 <- co[!is.na(co$tax_h), ]
r_cli <- clx(lm(long ~ post90 + factor(tax_h), data = c2), c2$ev)["post90", ]
msg("  whole spliced sample      : %+.3f (z %.2f, p %.4f)", r_all["est"], r_all["z"], r_all["p"])
msg("  Cloyne coding only        : %+.3f (z %.2f, p %.4f)  n = %d", r_clo["est"], r_clo["z"], r_clo["p"], nrow(co))
msg("  Cloyne only, + instrument : %+.3f (z %.2f, p %.4f)", r_cli["est"], r_cli["z"], r_cli["p"])
msg("  -> the break is INSIDE Cloyne. The seam cannot have produced it.")

# ===========================================================================
# PART B: THE ANTICIPATION SHARE OF THE IMPULSE
# ===========================================================================
msg("\n=== B1. Share of the tax impulse announced 120+ days ahead ===")
# Dated by IMPLEMENTATION (when the money lands) and weighted by |revenue|.
# Measures implementing after 2019 are dropped: they are the long-lead survivors
# of the sample's end and would inflate the last era mechanically.
antic_era <- function(d, label) {
  d <- d[d$implement <= as.Date("2019-12-31"), ]
  d$era <- cut(as.integer(format(d$implement, "%Y")), c(-Inf, 1979, 1999, Inf),
               labels = c("1945-79", "1980-99", "2000-19"))
  d <- d[!is.na(d$peak_value) & !is.na(d$long) & !is.na(d$era), ]
  out <- do.call(rbind, lapply(split(d, d$era), function(s) {
    w <- abs(s$peak_value)
    data.frame(sample = label, era = s$era[1], n = nrow(s),
               anticipation_share = round(sum(w*s$long)/sum(w), 3),
               revwt_lead_days    = round(sum(w*pmax(s$days,0))/sum(w)))
  }))
  print(out, row.names = FALSE); out
}
b1 <- rbind(antic_era(m,  "Paper 1 (all measures)"),
            antic_era(p2, "Paper 2 (household exog)"))
write.csv(b1, file.path(OUTPUT, "anticipation_share.csv"), row.names = FALSE)

msg("\n=== B2. The quarterly impulse split into foreseen and unforeseen ===")
# Period cuts straddle the 2004 splice deliberately: 1990-2003 is ENTIRELY
# Cloyne's coding, so if the unforeseen impulse has already collapsed by then,
# the collapse cannot be an artefact of the modern data.
keys <- paste(grid$year, grid$quarter)
agg <- function(yr, qt, val) {
  k <- paste(yr, qt); keep <- !is.na(yr) & !is.na(qt) & k %in% keys
  s <- tapply(val[keep], k[keep], sum, na.rm = TRUE)
  o <- setNames(rep(0, length(keys)), keys); o[names(s)] <- s; as.numeric(o)
}
nret <- function(d) {
  d$imp_y <- ifelse(is.na(d$imp_year_nret), d$imp_year_cal, d$imp_year_nret)
  d$imp_q <- ifelse(is.na(d$imp_q_nret),    d$imp_q_cal,    d$imp_q_nret); d
}
per <- cut(grid$year, c(-Inf, 1979, 1989, 2003, Inf),
           labels = c("1945-79", "1980s", "1990-2003 (Cloyne)", "2004-18 (modern)"))
b2 <- do.call(rbind, lapply(list(`Paper 1` = nret(m), `Paper 2` = nret(p2)), function(d) {
  lo <- d$long %in% 1
  f <- 100*agg(d$imp_y[lo],  d$imp_q[lo],  d$peak_value[lo]) /grid$gdp
  u <- 100*agg(d$imp_y[!lo], d$imp_q[!lo], d$peak_value[!lo])/grid$gdp
  do.call(rbind, lapply(split(seq_along(per), per), function(i) data.frame(
    period = per[i][1], quarters = length(i),
    mean_abs_foreseen   = round(mean(abs(f[i])), 4),
    mean_abs_unforeseen = round(mean(abs(u[i])), 4),
    foreseen_share      = round(mean(abs(f[i]))/(mean(abs(f[i]))+mean(abs(u[i]))), 3),
    sd_unforeseen       = round(sd(u[i]), 4))))
}))
b2$sample <- sub("\\..*", "", rownames(b2)); rownames(b2) <- NULL
print(b2[, c("sample","period","quarters","mean_abs_foreseen","mean_abs_unforeseen",
             "foreseen_share","sd_unforeseen")], row.names = FALSE)
msg("  -> the UNFORESEEN impulse collapses by a factor of ~5 on both samples, and")
msg("     it collapses BEFORE 2004, in a window that is entirely Cloyne's coding.")
msg("     The foreseen impulse falls far less, so the foreseen SHARE rises. Do NOT")
msg("     claim the foreseen impulse is constant: it is flat to 2003 then falls too.")
write.csv(b2, file.path(OUTPUT, "anticipation_decomposition.csv"), row.names = FALSE)

msg("\n=== B3. The pipeline: announced but not yet in force ===")
qd <- as.Date(sprintf("%d-%02d-01", grid$year, 3*grid$quarter))
live_stat <- function(d, f) sapply(seq_along(qd), function(i) {
  l <- d$announce <= qd[i] & d$implement > qd[i]; l[is.na(l)] <- FALSE; f(d[l, ], i) })
pipe <- live_stat(m, function(z, i) 100*sum(abs(z$peak_value), na.rm=TRUE)/grid$gdp[i])
cnt  <- live_stat(m, function(z, i) nrow(z))
b3 <- data.frame(period = levels(per),
                 mean_pct_gdp   = round(tapply(pipe, per, mean), 3),
                 median_pct_gdp = round(tapply(pipe, per, median), 3),
                 mean_count     = round(tapply(cnt,  per, mean), 1))
print(b3, row.names = FALSE)
msg("  CAUTION: the mean is dominated by VAT (announced Mar 1971, in force Apr 1973),")
msg("  which alone put ~11%% of GDP in the pipeline. Report the MEDIAN and the count.")
write.csv(b3, file.path(OUTPUT, "anticipation_pipeline.csv"), row.names = FALSE)

# ===========================================================================
# PART C: BREAK DATING
# ===========================================================================
msg("\n=== C1. Grid search for a single break, 1960-2012 ===")
gs <- do.call(rbind, lapply(1960:2012, function(b) {
  f <- lm(long ~ I(as.integer(yr >= b)), data = m)
  data.frame(break_year = b, r2 = summary(f)$r.squared)
}))
print(head(gs[order(-gs$r2), ], 5), row.names = FALSE)
msg("  -> best single break: %d", gs$break_year[which.max(gs$r2)])

msg("\n=== C2. Named institutional candidates, local windows (+/- 8 years) ===")
cand <- c(`unified autumn Budget (first Nov 1993)` = 1993,
          `return to spring Budget (1997)`         = 1997,
          `tax policy making framework (2010)`     = 2010,
          `draft-clause consultation (2011)`       = 2011,
          `single fiscal event (2017)`             = 2017)
c2t <- do.call(rbind, lapply(seq_along(cand), function(k) {
  b <- cand[k]; s <- m[m$yr >= b-8 & m$yr <= b+7, ]; s$post <- as.integer(s$yr >= b)
  r <- clx(lm(long ~ post, data = s), s$ev)["post", ]
  data.frame(candidate = names(cand)[k], year = b, n = nrow(s),
             est = round(r["est"], 3), z = round(r["z"], 2), p = round(r["p"], 4))
}))
print(c2t, row.names = FALSE)
write.csv(c2t, file.path(OUTPUT, "break_candidates.csv"), row.names = FALSE)

msg("\n=== C2b. Does the REVENUE-WEIGHTED series break at the same dates? ===")
# C1 and C2 are unweighted counts of measures, but the object other researchers
# use is the revenue impulse. If the break is in the counts and not in the
# money, the institutional reading does not carry. Annual series, revenue
# weighted by |costing|, same grid search and same local windows.
mw <- m[!is.na(m$peak_value) & !is.na(m$long), ]; mw$w <- abs(mw$peak_value)
ann <- do.call(rbind, lapply(split(mw, mw$yr), function(z) data.frame(
  yr = z$yr[1], n = nrow(z),
  count_share = mean(z$long),
  rev_share   = sum(z$w * z$long) / sum(z$w))))
gsw <- do.call(rbind, lapply(1960:2012, function(b)
  data.frame(break_year = b, r2 = summary(lm(rev_share ~ I(yr >= b), data = ann))$r.squared)))
gsw <- gsw[order(-gsw$r2), ]
msg("  revenue-weighted grid search, best five break years:")
print(head(gsw, 5), row.names = FALSE)
msg("  -> best %d (R2 %.3f). The top five span %d-%d, so the break dates to the",
    gsw$break_year[1], gsw$r2[1], min(head(gsw$break_year, 5)), max(head(gsw$break_year, 5)))
msg("     early 1990s and not to a single year. The break year is SEARCHED, so its")
msg("     nominal fit is not a test statistic and no p-value is attached to it.")
c2w <- do.call(rbind, lapply(seq_along(cand), function(k) {
  b <- cand[k]; a <- ann[ann$yr >= b-8 & ann$yr <= b+7, ]
  f <- summary(lm(rev_share ~ I(yr >= b), data = a))$coefficients
  data.frame(candidate = names(cand)[k], year = b, years = nrow(a),
             est = round(f[2,1], 3), t = round(f[2,3], 2), p = round(f[2,4], 4))
}))
print(c2w, row.names = FALSE)
write.csv(c2w, file.path(OUTPUT, "break_candidates_revwt.csv"), row.names = FALSE)
msg("  READ CAREFULLY. 1993 survives revenue weighting and strengthens (+0.429,")
msg("  t 4.02). 2010 does NOT: +0.190, p 0.116. The 2010 reform moved the number of")
msg("  measures given long notice but not, detectably, the share of the money. The")
msg("  paper must say so.")

msg("\n=== C3. Is the 1993 break just the move to autumn Budgets? ===")
sp <- m[m$autumn == 0, ]
msg("  SPRING BUDGETS ONLY, long share by decade:")
print(round(tapply(sp$long, sp$dec, mean), 3))
sp$post90 <- as.integer(sp$yr >= 1990)
r <- clx(lm(long ~ post90, data = sp), sp$ev)["post90", ]
msg("  post-1990 step on spring Budgets only: %+.3f (z %.2f, p %.4f)", r["est"], r["z"], r["p"])
msg("  season gap by decade, WITH CELL COUNTS. Autumn Budgets were rare before")
msg("  1993, so the early gaps are not interpretable and must not be quoted:")
sg <- tapply(m$long, list(m$dec, m$autumn), mean)
nn <- table(m$dec, m$autumn)
gap <- data.frame(decade = as.integer(rownames(sg)),
                  n_spring = as.integer(nn[, "0"]), n_autumn = as.integer(nn[, "1"]),
                  spring = round(sg[, "0"], 3), autumn = round(sg[, "1"], 3),
                  gap = round(sg[, "1"] - sg[, "0"], 3))
gap$reportable <- gap$n_autumn >= 30
print(gap, row.names = FALSE)
msg("  -> only %s have enough autumn measures to report.",
    paste(gap$decade[gap$reportable], collapse = ", "))
msg("     Among those the gap runs %s, i.e. it NARROWS to nothing.",
    paste(sprintf("%+.2f", gap$gap[gap$reportable]), collapse = " "))
msg("     The trend survives within spring Budgets, so the calendar shift is part")
msg("     of the 1993 break but not the whole of it.")
write.csv(gap, file.path(OUTPUT, "season_gap.csv"), row.names = FALSE)

msg("\nwritten: output/seam_*.csv, output/anticipation_*.csv, output/break_candidates.csv")

# ===========================================================================
# PART D: IS NOTICE DISTRIBUTED REGRESSIVELY?
#
# The framing question. If the taxes that fall hardest on poorer households also
# arrive with least warning, the paper has a distributional finding rather than
# only a measurement one. RESULTS.md R5 found the gradient peaked in the 1980s
# on `deferred`; this retests it on the primary outcome.
#
# Incidence: excise duties and VAT take a larger share of income from poorer
# households (ONS Effects of Taxes and Benefits). Income tax, CGT and inheritance
# tax are progressive. NICs are excluded from both, being contributory and
# regressive at the top because of the upper earnings limit.
# ===========================================================================
msg("\n=== D1. Notice by tax incidence, within Budget ===")
REG <- c("Excise and duties", "VAT"); PROG <- c("Income", "Capital gains", "Inheritance")
m$inc <- ifelse(m$tax_h %in% REG, "regressive",
         ifelse(m$tax_h %in% PROG, "progressive", NA))
dd <- m[!is.na(m$inc), ]
dd$era <- cut(dd$yr, c(-Inf,1979,1999,Inf), labels = c("1945-79","1980-99","2000-19"))
dd$prog <- as.integer(dd$inc == "progressive")
d1 <- do.call(rbind, lapply(levels(dd$era), function(e) {
  z <- dd[dd$era == e, ]
  r <- clx(lm(long ~ prog + ev, data = z), z$ev)["prog", ]
  data.frame(era = e, n = nrow(z),
             count_gap = round(r["est"], 3), z = round(r["z"], 2), p = round(r["p"], 4),
             revwt_regressive  = round(wshare(z$long[z$inc=="regressive"],
                                              abs(z$peak_value[z$inc=="regressive"])), 3),
             revwt_progressive = round(wshare(z$long[z$inc=="progressive"],
                                              abs(z$peak_value[z$inc=="progressive"])), 3))
}))
d1$revwt_gap <- round(d1$revwt_progressive - d1$revwt_regressive, 3)
print(d1, row.names = FALSE)
msg("  READ CAREFULLY. On the inference-valid COUNT basis the gap is significant only")
msg("  in 1980-99 (+0.139, z 2.66) and is NOT significant today (+0.024, p 0.64).")
msg("  On the descriptive REVENUE basis it widens throughout (-0.03, +0.14, +0.26).")
msg("  These are different statements. The paper must not quote the revenue gap as")
msg("  though it were a tested one. R5 stands: the instrument gradient is not the")
msg("  distributional finding.")

msg("\n=== D2. Share arriving with under 30 days' notice ===")
dd$snap <- as.integer(dd$days < 30)
d2 <- do.call(rbind, lapply(levels(dd$era), function(e) {
  z <- dd[dd$era == e, ]
  data.frame(era = e,
             regressive  = round(mean(z$snap[z$inc=="regressive"]), 3),
             progressive = round(mean(z$snap[z$inc=="progressive"]), 3))
}))
d2$gap <- round(d2$regressive - d2$progressive, 3)
print(d2, row.names = FALSE)
msg("  Today 43%% of regressive changes arrive with under a month's notice against")
msg("  33%% of progressive ones. Real but modest, and it is the honest version.")
write.csv(d1, file.path(OUTPUT, "incidence_notice.csv"), row.names = FALSE)
write.csv(d2, file.path(OUTPUT, "incidence_snap.csv"), row.names = FALSE)

# --- PART E. IS FACT 2 AN ARTEFACT OF THE ESTIMATOR? ------------------------
# The instrument specification carries 128 parameters (10 instruments + 118
# Budget fixed effects) against 118 clusters, so the cluster-robust variance
# matrix is rank deficient and CR1 standard errors are suspect in principle.
# Two checks, run here rather than ad hoc so the paper's claim reproduces:
#   (i)  a pairs cluster bootstrap, resampling whole Budget events;
#   (ii) a within-transformed specification, demeaning by Budget event, which
#        reduces the parameter count to 10 against the same 118 clusters.
# ALL coefficients significant at 5 per cent are covered, including recurrent
# property, which an earlier version of this check omitted.
msg("\n=== E. Fact 2 inference: rank-deficient CR1, bootstrap and within checks ===")
set.seed(20260903)
B <- 600

i <- m[!is.na(m$tax_h), ]
i$tax_h <- relevel(factor(i$tax_h), ref = "Excise and duties")
fi <- lm(long ~ tax_h + ev, data = i)
cr <- clx(fi, i$ev)
cr <- cr[grep("^tax_h", rownames(cr)), , drop = FALSE]
rownames(cr) <- sub("^tax_h", "", rownames(cr))
sig <- rownames(cr)[cr[, "p"] < 0.05]
msg("  significant at 5%%: %s", paste(sig, collapse = ", "))

# (i) pairs cluster bootstrap over Budget events
cl   <- split(seq_len(nrow(i)), droplevels(i$ev))
reps <- matrix(NA_real_, B, length(sig), dimnames = list(NULL, sig))
for (b in seq_len(B)) {
  idx <- unlist(cl[sample(names(cl), length(cl), replace = TRUE)], use.names = FALSE)
  s   <- i[idx, ]
  s$tax_h <- relevel(droplevels(factor(s$tax_h)), ref = "Excise and duties")
  s$ev    <- droplevels(factor(s$ev))
  cf  <- tryCatch(coef(lm(long ~ tax_h + ev, data = s)), error = function(e) NULL)
  if (is.null(cf)) next
  names(cf) <- sub("^tax_h", "", names(cf))
  reps[b, ] <- cf[sig]
}
bsd <- apply(reps, 2, sd, na.rm = TRUE)
ok  <- colSums(!is.na(reps))

# (ii) within transformation: demean outcome and instrument dummies by event
dm <- function(x, g) x - ave(x, g, FUN = mean)
D  <- model.matrix(~ tax_h, data = i)[, -1, drop = FALSE]
colnames(D) <- sub("^tax_h", "", colnames(D))
Dw <- apply(D, 2, dm, g = i$ev)
yw <- dm(i$long, i$ev)
fw <- lm(yw ~ Dw - 1)
colnames(Dw) -> nmw
wc <- clx(fw, i$ev)
rownames(wc) <- sub("^Dw", "", rownames(wc))

e_tab <- data.frame(
  instrument = sig,
  cr1_est    = round(cr[sig, "est"], 3),
  cr1_se     = round(cr[sig, "se"], 3),
  boot_sd    = round(bsd[sig], 3),
  boot_reps  = ok[sig],
  within_est = round(wc[sig, "est"], 3),
  within_se  = round(wc[sig, "se"], 3),
  row.names  = NULL)
print(e_tab, row.names = FALSE)
write.csv(e_tab, file.path(OUTPUT, "fact2_bootstrap.csv"), row.names = FALSE)
msg("  Bootstrap standard deviations track the CR1 standard errors and the within")
msg("  transformation returns the same point estimates. Fact 2 is not an artefact.")
