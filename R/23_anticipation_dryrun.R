# 23_anticipation_dryrun.R -----------------------------------------------------
# FEASIBILITY TEST BEFORE APPLYING FOR HOUSEHOLD MICRO DATA.
#
# Script 22 established that the decile panel works and that the UNANTICIPATED
# series has too little variation to drive it: the tax surprise carries a sixth
# of the information that GDP growth does, and its minimum detectable gradient
# is 10 to 21 per cent of gross income between the top and bottom decile.
#
# But the surprise series is not the only one, and it is the wrong one for the
# question this project is actually about. Quarterly standard deviations:
#
#     era        unanticipated   announcement-dated
#     1961-79        0.223             0.153
#     1980-99        0.158             0.125
#     2000-18        0.046             0.142
#
# The surprise series loses four-fifths of its amplitude. The announcement-dated
# series does not decline at all, and in the modern period carries three times
# the variation. Announcement events rise from 47 to 187 to 328 across the three
# eras. Paper 2 has been identifying off the scarce series while the abundant
# one sits unused.
#
# WHAT THIS SCRIPT TESTS, AND WHAT IT DOES NOT. It asks whether the
# announcement-dated series can move a distributional gradient at all, and
# whether it survives the falsification that destroyed the implementation-dated
# version in script 22. That is a POWER test and an EXOGENEITY test.
#
# It is NOT a test of the smoothing hypothesis. That hypothesis is about the
# TIMING of consumption for households that can and cannot act on advance
# notice, and the ETB tables carry income, not consumption. Only household micro
# data can test it. What this script can do is tell us whether the announcement
# series is worth a year of work before we spend the year.
#
# WHY ANNOUNCEMENT DATES MAY BE CLEAN WHERE IMPLEMENTATION DATES ARE NOT.
# Script 22 rejected the implementation-dated anticipated series because a
# Chancellor chooses when a measure takes effect, and Paper 1 shows that choice
# tracks the electoral cycle. The announcement date is Budget day, which is set
# by the parliamentary calendar rather than by the measure. The endogeneity that
# killed ant_imp does not obviously apply to ant_news, and the paper already
# treats them as separate instruments.

source("R/00_setup.R")
msg("== 23_anticipation_dryrun ==")

d <- readRDS(file.path(DERIVED, "p2_decile_panel.rds"))
p <- readRDS(file.path(DERIVED, "p2_panel.rds")); p <- p[order(p$date), ]
qkey <- p$year * 10L + p$quarter
ND <- 10; HMAX <- 4

yrs <- unique(d[, c("y0", "shock")]); yrs <- yrs[order(yrs$y0), ]
fis <- vapply(yrs$y0, function(y) any(grepl("-", d$sheet[d$y0 == y])), logical(1))
ov  <- function(v, f = sum) over_ons_year(v, qkey, yrs$y0, fis, f)
yrs$ant_news <- ov(p$ant_news)
yrs$ant_imp  <- ov(p$ant_imp)
yrs$U        <- ov(p$Unemployment, mean); yrs$dU <- c(NA, diff(yrs$U))
yrs$gY       <- c(NA, 100 * diff(ov(p$lrgdp, mean)))

msg("\nannual variation over the %d ONS years, %% of GDP:", nrow(yrs))
for (v in c("shock", "ant_news", "ant_imp"))
  msg("  %-9s sd %.3f | mean|x| %.3f | %d nonzero years",
      v, sd(yrs[[v]], na.rm = TRUE), mean(abs(yrs[[v]]), na.rm = TRUE),
      sum(yrs[[v]] != 0, na.rm = TRUE))
msg("  corr(surprise, announcement) %+.2f  <- separate instruments, as intended",
    cor(yrs$shock, yrs$ant_news, use = "complete.obs"))

for (v in c("ant_news", "ant_imp", "dU", "gY"))
  d[[v]] <- yrs[[v]][match(d$y0, yrs$y0)]
d$rank_c <- 5.5 - d$decile
d <- d[order(d$decile, d$y0), ]

# --- the gradient, on each series --------------------------------------------
grad_on <- function(cmp, drv, H = 0:HMAX, ctrl = NULL, dat = d) {
  do.call(rbind, lapply(H, function(h) {
    key <- function(off) match(paste(dat$decile, dat$y0 + off),
                               paste(dat$decile, dat$y0))
    y <- 100 * (dat[[paste0("r_", cmp)]][key(h)] -
                dat[[paste0("r_", cmp)]][key(-1)]) / dat$r_gross[key(-1)]
    si <- dat[[drv]] * dat$rank_c
    df <- data.frame(y = y, s = si, s1 = si[key(-1)], t = dat$y0, i = dat$decile)
    if (!is.null(ctrl)) for (cv in ctrl) df[[cv]] <- dat[[cv]] * dat$rank_c
    df <- df[complete.cases(df), ]
    full <- as.integer(names(which(table(df$t) == ND))); df <- df[df$t %in% full, ]
    if (length(full) < 12) return(NULL)
    X <- sapply(setdiff(names(df), c("y", "t", "i")),
                function(v) demean2(df[[v]], df$i, df$t))
    fit <- lm.fit(X, demean2(df$y, df$i, df$t))
    se  <- dk_se(X, residuals(fit), df$t, abs(h) + 1, ND)
    data.frame(driver = drv, component = cmp, h = h, years = length(full),
               b = coef(fit)[[1]], se = se[1], t = coef(fit)[[1]] / se[1])
  }))
}
LABS <- c(orig = "market income", disp = "disposable income")
shw <- function(z, lab) if (!is.null(z)) msg("  %-38s %s", lab,
  paste(sprintf("h%+d %+6.2f(%+5.2f)%s", z$h, z$b, z$t,
                ifelse(abs(z$t) > 1.96, "*", " ")), collapse = " "))

msg("\n=== THE GRADIENT, SURPRISE AGAINST ANNOUNCEMENT ===")
msg("Per decile step DOWN the distribution, per 1%% of GDP. Positive means the")
msg("bottom loses less than the top. Year effects absorb the aggregate.\n")
main <- do.call(rbind, lapply(c("shock", "ant_news", "ant_imp"), function(v)
  do.call(rbind, lapply(c("orig", "disp"), function(c2) grad_on(c2, v)))))
DNAME <- c(shock = "surprise", ant_news = "ANNOUNCEMENT", ant_imp = "implementation (rejected)")
for (v in c("shock", "ant_news", "ant_imp")) for (c2 in c("orig", "disp"))
  shw(main[main$driver == v & main$component == c2, ],
      sprintf("%s, %s", DNAME[v], LABS[c2]))

# --- falsification, the same battery that killed ant_imp ---------------------
msg("\n=== FALSIFICATION OF THE ANNOUNCEMENT SERIES ===")
msg("  1. PLACEBO. A response before the news arrives is not a response.")
for (c2 in c("orig", "disp")) shw(grad_on(c2, "ant_news", -3:-2), sprintf("     %s", LABS[c2]))

msg("  2. CYCLE CONTROLS. Is it more than the ordinary GDP channel?")
for (c2 in c("orig", "disp"))
  shw(grad_on(c2, "ant_news", 0:HMAX, ctrl = c("gY", "dU")), sprintf("     %s", LABS[c2]))

msg("  3. DROP THE LARGEST ANNOUNCEMENT YEAR (%s).",
    yrs$y0[which.max(abs(yrs$ant_news))])
big <- yrs$y0[which.max(abs(yrs$ant_news))]
for (c2 in c("orig", "disp"))
  shw(grad_on(c2, "ant_news", dat = d[d$y0 != big, ]), sprintf("     %s", LABS[c2]))

msg("  4. HORSE RACE. Both series at once. They correlate at %+.2f, so this is",
    cor(yrs$shock, yrs$ant_news, use = "complete.obs"))
msg("     estimable, and it asks which one the data actually wants.")
for (c2 in c("orig", "disp"))
  shw(grad_on(c2, "ant_news", 0:HMAX, ctrl = "shock"), sprintf("     %s", LABS[c2]))

# --- the aggregate, for reference --------------------------------------------
msg("\n=== AGGREGATE RESPONSE TO THE ANNOUNCEMENT SERIES ===")
w <- reshape(d[, c("y0", "decile", "r_orig", "r_disp")],
             idvar = "y0", timevar = "decile", direction = "wide")
w <- w[order(w$y0), ]
agg <- do.call(rbind, lapply(c("orig", "disp"), function(cmp) {
  g <- unname(log(rowSums(w[, paste0("r_", cmp, ".", 1:10)])))
  r <- lp_project(g, yrs$ant_news, rep(TRUE, nrow(w)), H = 0:HMAX, nlag = 1, minobs = 15)
  msg("  real household %-20s %s", LABS[cmp],
      paste(sprintf("h%d %+6.2f(%+5.2f)%s", r$h, r$b, r$t,
                    ifelse(abs(r$t) > 1.96, "*", " ")), collapse = " "))
  cbind(driver = "ant_news", component = cmp, r)
}))

write.csv(main, file.path(OUTPUT, "p2_anticipation_gradient.csv"), row.names = FALSE)
msg("\nwritten: output/p2_anticipation_gradient.csv")

# --- verdict -----------------------------------------------------------------
msg("\n=== VERDICT: THE POWER QUESTION IS ANSWERED YES, THE REST IS NOT ===")
msg("")
msg("  WHAT PASSES.")
msg("  Variance. The announcement series produces t-statistics of 3 to 5 on the")
msg("  market-income gradient where the surprise series managed 1.2 on the same")
msg("  panel, same outcome, same errors. That was the open question before this")
msg("  script ran, and it is settled: the announcement-dated series is strong")
msg("  enough to identify a distributional design.")
msg("")
msg("  The placebo is clean. Nothing at h-3 or h-2 on either outcome, against")
msg("  the implementation-dated series which was significant at h-3 with the")
msg("  opposite sign. The distinction drawn in this script's header holds up:")
msg("  Budget day is not chosen the way an effective date is chosen.")
msg("")
msg("  The horse race favours it. Entering both series together strengthens the")
msg("  announcement gradient rather than weakening it, and brings disposable")
msg("  income to significance at four of five horizons.")
msg("")
msg("  WHAT FAILS, AND IT IS ENOUGH TO STOP THIS BEING A RESULT.")
msg("  Dropping 2008, the largest announcement year, removes significance")
msg("  everywhere: market income falls from t = 4.97 to 1.76. A gradient that")
msg("  rests on the one year when fiscal announcements and a financial crisis")
msg("  coincide is not separating the two.")
msg("")
msg("  Cycle controls absorb it entirely. That objection is weaker than it")
msg("  looks, because GDP growth is itself a consequence of the tax change, so")
msg("  controlling for it is controlling for the mechanism. But combined with")
msg("  the 2008 fragility it is not something to argue past.")
msg("")
msg("  And the announcement series moves no aggregate here at all, at any")
msg("  horizon on either outcome. A distributional gradient with no aggregate")
msg("  behind it is redistribution between deciles for no reason, which is not")
msg("  a story anyone should believe on this evidence.")
msg("")
msg("  DO NOT WRITE THIS UP either. It is a feasibility test, and it did its job.")
msg("")
msg("  WHAT IT MEANS FOR THE MICRO-DATA DECISION. Two things.")
msg("  First, the constraint identified in script 22 was specific to the")
msg("  surprise series, not general. The abundant series is estimable. A")
msg("  distributional paper built on announcements is not doomed on power the")
msg("  way one built on surprises is, and that is the fact that justifies the")
msg("  UK Data Service application.")
msg("")
msg("  Second, income is the wrong outcome and this script cannot fix that. The")
msg("  hypothesis is about WHEN consumption moves for households that can and")
msg("  cannot act on advance notice. The ETB tables carry income, so the test")
msg("  here is a proxy for a proxy. Consumption has to do the work, which means")
msg("  the Living Costs and Food Survey, which means the application.")

saveRDS(yrs, file.path(DERIVED, "p2_ons_year_shocks.rds"))
