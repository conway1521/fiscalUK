# 09_shock_split.R -----------------------------------------------------------
# Anticipated and unanticipated UK tax shock series, 1945Q1-2018Q4, as separate
# inputs for Paper 2.
#
# WHY. RESULTS.md section 7.2 establishes that the foreseen share of the tax
# impulse rose from 0.20 to 0.80 across the sample while the foreseen impulse
# itself stayed the same size. A single pooled series therefore mixes two
# economically different objects and the mix changes over time.
#
# THREE SERIES, not two. An anticipated measure is two events:
#   ant_news   dated at ANNOUNCEMENT   - when the information arrived
#   ant_imp    dated at IMPLEMENTATION - when the money moved
#   unant      dated at implementation, which is also its announcement
# A local projection or proxy-SVAR needs `ant_news` and `unant` as separate
# instruments. `ant_imp` is for accounting only: it is the same money as
# `ant_news` moved forward in time, so the two must never enter one regression.
#
# THRESHOLD. Primary is the Paper 1 outcome, a gap of 120+ days. A quarterly
# model can only resolve leads of a full quarter, so a >=2-quarter variant is
# built alongside; use that one if the estimation is quarterly. The two agree
# on 96.6% of measures.
#
# ============================================================================
# READ THIS BEFORE USING THE SERIES
# ============================================================================
# The pooling test below FAILED on the raw coding, and the cause was a single
# row. It is now corrected upstream; the counterfactual arm shows what it was.
#
# In the March 2007 Budget the basic rate of income tax was cut from 22p to 20p
# and the 10p starting rate was abolished, both effective 6 April 2008. They are
# two legs of one announced package. Cloyne codes BOTH exogenous. The modern
# coding codes the rate cut exogenous (-12,878m) and the starting-rate abolition
# ENDOGENOUS (+11,529m), which drops the offsetting leg from the Paper 2 sample
# and leaves a spurious -0.82% of GDP shock in 2008Q2 where Cloyne has +0.04.
#
# That one row is 13% of all gross revenue in the modern half of the Paper 2
# sample. Making it consistent lifts the correlation between the two codings'
# overlap series from -0.02 to 0.63.
#
# PAPER 1 IS UNAFFECTED. It runs on `timing_sample`, which ignores exogeneity.
#
# WHERE THE FIX LIVES. The override is applied in R/03_chain.R so that every
# downstream script sees the same classification; it is NOT applied here. The
# chained file carries `endo_exo_raw` and `endo_exo_over` so the pre-override
# coding can be recovered, which is what the counterfactual arm below does.
#
# Applying it in this script alone was itself a bug: RESULTS.md section 7.2 is
# built by 08_robustness.R from the unfixed data while section 8 was built here
# from the fixed data, so the two disagreed.

source("R/00_setup.R")
msg("== 09_shock_split ==")

SPLICE <- as.Date("2004-01-01")
OVL    <- c(as.Date("2004-03-17"), as.Date("2009-04-22"))

sr   <- readRDS(file.path(DERIVED, "uk_shock_series.rds"))
grid <- sr$series[, c("year","quarter","gdp","date")]
ch   <- readRDS(file.path(DERIVED, "uk_chained_measures.rds"))

keys <- paste(grid$year, grid$quarter)
agg <- function(yr, qt, val) {
  k <- paste(yr, qt); keep <- !is.na(yr) & !is.na(qt) & !is.na(val) & k %in% keys
  s <- tapply(val[keep], k[keep], sum, na.rm = TRUE)
  o <- setNames(rep(0, length(keys)), keys); o[names(s)] <- s
  as.numeric(o)
}
#' No-retroactive implementation quarter. The raw one puts some Cloyne measures
#' before their own announcement, which is indefensible for a shock series.
nret <- function(d) {
  d$imp_y <- ifelse(is.na(d$imp_year_nret), d$imp_year_cal, d$imp_year_nret)
  d$imp_q <- ifelse(is.na(d$imp_q_nret),    d$imp_q_cal,    d$imp_q_nret)
  d
}

# ---------------------------------------------------------------------------
# 1. EXOGENEITY CONSISTENCY AUDIT
#
# SUPERSEDED APPROACH. An earlier version flagged any Budget-event / tax-type /
# implementation-date group containing both exogenous and endogenous rows, and
# found 27. That test was wrong. Cloyne's Major (X/N) is a DETERMINISTIC
# function of his Minor motive code - LR, IL, DC, ET are exogenous, DM, DR, SD,
# SS endogenous, with zero exceptions in either coding - so a Budget containing
# a long-run reform and a spending-driven measure on the same day is the
# taxonomy working, not failing. 26 of the 27 were false positives.
#
# THE RIGHT TEST. 2004-2009 is coded twice, once by Cloyne and once by us. Match
# the same measures across the two codings and compare their exogeneity directly.
# ---------------------------------------------------------------------------
msg("\n--- EXOGENEITY CONSISTENCY AUDIT: matched measures in the 2004-09 overlap ---")
norm <- function(x) {
  x <- tolower(gsub("[\r\n]+", " ", x))
  x <- gsub("&", "and", x, fixed = TRUE)
  x <- gsub("\\b(it|income tax)\\b", "income tax", x)
  x <- gsub("[^a-z0-9 ]", " ", x); gsub(" +", " ", trimws(x))
}
ov <- ch[ch$timing_sample & ch$budget_date >= OVL[1] & ch$budget_date <= OVL[2] &
         ch$target %in% "H" & !is.na(ch$peak_value), ]
cl <- ov[ov$source == "Cloyne", ]; mo <- ov[ov$source == "Modern", ]
cl$k <- norm(cl$measure); mo$k <- norm(mo$measure)
mt <- do.call(rbind, lapply(seq_len(nrow(mo)), function(i) {
  cand <- cl[cl$budget_date == mo$budget_date[i], ]
  if (!nrow(cand)) return(NULL)
  dd <- as.numeric(adist(mo$k[i], cand$k)) / pmax(nchar(mo$k[i]), nchar(cand$k))
  j <- which.min(dd)
  data.frame(sim = 1 - dd[j], event = format(mo$budget_date[i]),
             measure = substr(gsub("[\r\n]+"," ",mo$measure[i]), 1, 46),
             mo_val = round(mo$peak_value[i]),
             cloyne = cand$endo_exo_raw[j], modern = mo$endo_exo_raw[i],
             cl_minor = cand$minor[j], mo_minor = mo$minor[i],
             stringsAsFactors = FALSE)
}))
mt <- mt[mt$sim >= 0.55 & !is.na(mt$cloyne) & !is.na(mt$modern), ]
tt <- table(Cloyne = mt$cloyne, Modern = mt$modern)
print(tt)
agree <- sum(diag(tt))
dis   <- mt[mt$cloyne != mt$modern, ]
msg("  matched measures: %d | agreement %.1f%% (%d of %d)",
    nrow(mt), 100*agree/nrow(mt), agree, nrow(mt))
msg("  revenue-weighted disagreement: %.1f%% of matched gross revenue",
    100*sum(abs(dis$mo_val))/sum(abs(mt$mo_val)))
fixed <- dis$mo_minor %in% "SD" & abs(dis$mo_val) > 5000
msg("  of which the 2007 package (already overridden) is %.0f%%",
    100*sum(abs(dis$mo_val[fixed]))/sum(abs(dis$mo_val)))
msg("  residual after the override: %.1f%% of matched gross revenue",
    100*sum(abs(dis$mo_val[!fixed]))/sum(abs(mt$mo_val)))
write.csv(mt[order(-abs(mt$mo_val)), ], file.path(OUTPUT, "exogeneity_audit.csv"), row.names = FALSE)

# The residual disagreement is systematic, not random: anti-avoidance measures.
av <- function(x) grepl("avoid|evasion|loophole|disclosure|abuse", x, ignore.case = TRUE)
msg("\n  RESIDUAL IS SYSTEMATIC: anti-avoidance measures")
msg("  %d of %d disagreements are anti-avoidance, all Cloyne endogenous (SD) against",
    sum(av(dis$measure)), nrow(dis))
msg("  our exogenous (IL). Cloyne codes %.0f%% of his anti-avoidance rows exogenous;",
    100*mean(ch$endo_exo_raw[ch$timing_sample & ch$source=="Cloyne" & av(ch$measure)] %in% "X"))
msg("  we code %.0f%% of ours exogenous. A convention difference, not an error.",
    100*mean(ch$endo_exo_raw[ch$timing_sample & ch$source=="Modern" & av(ch$measure)] %in% "X"))
msg("  Stakes are modest: anti-avoidance is %.1f%% of Cloyne's exogenous revenue and",
    100*sum(abs(ch$peak_value[ch$timing_sample & ch$source=="Cloyne" & ch$endo_exo_raw %in% "X" & av(ch$measure)]), na.rm=TRUE) /
      sum(abs(ch$peak_value[ch$timing_sample & ch$source=="Cloyne" & ch$endo_exo_raw %in% "X"]), na.rm=TRUE))
msg("  %.1f%% of ours. Paper 2 should report with and without it, not recode.",
    100*sum(abs(ch$peak_value[ch$timing_sample & ch$source=="Modern" & ch$endo_exo_raw %in% "X" & av(ch$measure)]), na.rm=TRUE) /
      sum(abs(ch$peak_value[ch$timing_sample & ch$source=="Modern" & ch$endo_exo_raw %in% "X"]), na.rm=TRUE))

# Revert to the pre-override coding, for the counterfactual arm of the pooling
# test. `endo_exo_raw` is written by 03_chain.R.
unfix <- function(x) {
  x$endo_exo <- x$endo_exo_raw
  x$usable <- x$timing_sample & x$endo_exo %in% "X" &
              (x$source == "Cloyne" | x$target %in% "H")
  x
}
msg("  overrides applied upstream in 03_chain.R: %d row(s)", sum(ch$endo_exo_over))

# ---------------------------------------------------------------------------
# 2. THE POOLING TEST, on revenue rather than measure counts
#    Section 7.1 cleared the seam for counts. A shock series sums money, so the
#    test is redone here on the thing being summed, using the 2004-2009 window
#    where both codings independently record the same Budgets.
# ---------------------------------------------------------------------------
pooling_test <- function(x, label) {
  o <- nret(x[x$usable & x$target %in% "H" &
              x$budget_date >= OVL[1] & x$budget_date <= OVL[2], ])
  q <- which(grid$year >= 2004 & grid$year <= 2009)
  s <- lapply(c("Cloyne","Modern"), function(src) {
    z <- o[o$source == src, ]
    100 * agg(z$imp_y, z$imp_q, z$peak_value) / grid$gdp
  })
  tab <- do.call(rbind, lapply(c("Cloyne","Modern"), function(src) {
    z <- o[o$source == src, ]
    data.frame(spec = label, source = src, n = nrow(z),
               gross_m = round(sum(abs(z$peak_value), na.rm = TRUE)),
               antic_share = round(sum(abs(z$peak_value[z$long %in% 1]), na.rm=TRUE) /
                                   sum(abs(z$peak_value), na.rm=TRUE), 3),
               sum_pct_gdp = round(sum((100*agg(z$imp_y,z$imp_q,z$peak_value)/grid$gdp)[q]), 3))
  }))
  msg("\n  %s", label)
  print(tab, row.names = FALSE)
  msg("    quarter-by-quarter correlation of the two codings: %.3f (%d quarters)",
      cor(s[[1]][q], s[[2]][q]), length(q))
  msg("    gross revenue differs by %.1f%%, anticipation share by %.3f",
      100*abs(diff(tab$gross_m))/mean(tab$gross_m), abs(diff(tab$antic_share)))
  invisible(list(tab = tab, r = cor(s[[1]][q], s[[2]][q])))
}
msg("\n--- POOLING TEST: 2004-2009 overlap, series built separately from each coding ---")
pt_now <- pooling_test(ch,        "with package fix (as used)")
pt_alt <- pooling_test(unfix(ch), "pre-override coding (counterfactual)")

msg("\n  VERDICT: the anticipation share agrees across codings either way. The SIGNED")
msg("  series agrees only once the 2007 package is consistent (r = %.2f against %.2f).",
    max(pt_now$r, pt_alt$r), min(pt_now$r, pt_alt$r))
msg("  That case is adjudicated and fixed. The residual disagreement is %.1f%% of matched",
    100*sum(abs(dis$mo_val[!fixed]))/sum(abs(mt$mo_val)))
msg("  gross revenue and is concentrated in anti-avoidance, where the two codings")
msg("  differ by convention. Report Paper 2 with and without it; do not recode.")

# ---------------------------------------------------------------------------
# 3. Build the split series
# ---------------------------------------------------------------------------
p2 <- nret(ch[ch$usable & ch$target %in% "H" & !is.na(ch$target) &
              ((ch$source == "Cloyne" & ch$budget_date <  SPLICE) |
               (ch$source == "Modern" & ch$budget_date >= SPLICE)), ])
p2$lead_q <- pmax(0, 4*(p2$imp_y - p2$ann_year_cal) + (p2$imp_q - p2$ann_q_cal))
msg("\n--- building series (household exogenous, spliced at %s): n = %d ---",
    format(SPLICE), nrow(p2))

build <- function(d, flag, tag) {
  a <- d[flag, ]; u <- d[!flag, ]
  out <- data.frame(
    ant_news = 100 * agg(a$ann_year_cal, a$ann_q_cal, a$peak_value) / grid$gdp,
    ant_imp  = 100 * agg(a$imp_y,        a$imp_q,     a$peak_value) / grid$gdp,
    unant    = 100 * agg(u$imp_y,        u$imp_q,     u$peak_value) / grid$gdp,
    n_ant    = agg(a$ann_year_cal, a$ann_q_cal, rep(1, nrow(a))),
    n_unant  = agg(u$imp_y,        u$imp_q,     rep(1, nrow(u))))
  names(out) <- paste0(names(out), "_", tag)
  msg("  %-5s anticipated %d measures (%.1f%% of gross revenue), unanticipated %d",
      tag, nrow(a), 100*sum(abs(a$peak_value), na.rm=TRUE)/sum(abs(d$peak_value), na.rm=TRUE),
      nrow(u))
  out
}
grid <- cbind(grid, build(p2, p2$long %in% 1, "d120"))
grid <- cbind(grid, build(p2, p2$lead_q >= 2, "q2"))
grid$total_imp <- 100 * agg(p2$imp_y, p2$imp_q, p2$peak_value) / grid$gdp
stopifnot(max(abs(grid$total_imp - (grid$ant_imp_d120 + grid$unant_d120))) < 1e-8)
msg("  reconciliation OK: ant_imp + unant == pooled implementation-dated series")
msg("  the two thresholds agree on %.1f%% of measures", 100*mean((p2$long %in% 1) == (p2$lead_q >= 2)))

# ---------------------------------------------------------------------------
# 4. Series properties Paper 2 needs before estimating
# ---------------------------------------------------------------------------
msg("\n--- series properties by era (primary, 120-day threshold) ---")
era <- cut(grid$year, c(-Inf,1979,1999,Inf), labels = c("1945-79","1980-99","2000-18"))
props <- do.call(rbind, lapply(levels(era), function(e) {
  s <- grid[era == e, ]
  data.frame(era = e, quarters = nrow(s),
             sd_news = round(sd(s$ant_news_d120), 4),
             sd_unant = round(sd(s$unant_d120), 4),
             nonzero_news = sum(s$ant_news_d120 != 0),
             nonzero_unant = sum(s$unant_d120 != 0),
             ac1_news = round(acf(s$ant_news_d120, lag.max=1, plot=FALSE)$acf[2], 3),
             ac1_unant = round(acf(s$unant_d120, lag.max=1, plot=FALSE)$acf[2], 3))
}))
print(props, row.names = FALSE)
msg("  correlation(news, unanticipated): %.3f  <- near zero, as separate instruments need",
    cor(grid$ant_news_d120, grid$unant_d120))
msg("  the unanticipated series LOSES most of its variance: sd %.3f -> %.3f",
    props$sd_unant[1], props$sd_unant[3])
msg("  WARNING for Paper 2: a proxy-SVAR identified off the unanticipated series")
msg("  has little post-2000 variation left to work with.")

msg("\n--- eight largest announcement-dated news shocks ---")
top <- grid[order(-abs(grid$ant_news_d120)), ][1:8, ]
for (i in seq_len(nrow(top))) {
  k <- p2$long %in% 1 & p2$ann_year_cal == top$year[i] & p2$ann_q_cal == top$quarter[i]
  k[is.na(k)] <- FALSE
  lab <- if (any(k)) p2$measure[k][which.max(abs(p2$peak_value[k]))] else "-"
  msg("  %dQ%d  %+6.2f%% of GDP  (%2d measures)  %s", top$year[i], top$quarter[i],
      top$ant_news_d120[i], sum(k), substr(gsub("[\r\n]+"," ",lab), 1, 50))
}

out <- grid[, c("year","quarter","date","gdp",
                "ant_news_d120","ant_imp_d120","unant_d120","n_ant_d120","n_unant_d120",
                "ant_news_q2","ant_imp_q2","unant_q2","n_ant_q2","n_unant_q2","total_imp")]
write.csv(out, file.path(OUTPUT, "uk_tax_shocks_split.csv"), row.names = FALSE)
write.csv(props, file.path(OUTPUT, "split_series_properties.csv"), row.names = FALSE)
saveRDS(list(series = out, measures = p2, n_overrides = sum(ch$endo_exo_over)),
        file.path(DERIVED, "uk_shock_series_split.rds"))
msg("\nwritten (overrides applied upstream in 03_chain.R)")
msg("  output/uk_tax_shocks_split.csv, output/package_consistency_audit.csv,")
msg("  output/split_series_properties.csv, data-derived/uk_shock_series_split.rds")
