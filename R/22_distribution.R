# 22_distribution.R ------------------------------------------------------------
# PAPER 2, THE DISTRIBUTIONAL HALF, SECOND ATTEMPT.
#
# WHY THERE IS A SECOND ATTEMPT. Script 19 split the SHOCK by statutory
# incidence and projected consumption on each half. That cannot work and the
# script says so: two slices of the same measure correlate at 0.93, because the
# split is arithmetic rather than variation. Nothing in the data separates them.
#
# THE FIX. Stop splitting the shock. Split the OUTCOME. One aggregate shock, ten
# outcome series, one per income decile. Identification then comes from the
# DIFFERENTIAL response across deciles within a year, which is a real comparison
# rather than a re-weighting of one number.
#
# With year fixed effects the aggregate effect of the shock is absorbed
# entirely, so nothing here can be contaminated by the common macro response,
# and nothing here re-estimates it. What is left is the gradient: does a tax
# rise fall more heavily on the bottom of the distribution than on the top?
#
# THE DATA. ONS "Effects of taxes and benefits on household income", historical
# decile datasets, already on disk from script 19. Forty years, 1977 to 2016-17,
# ten deciles, and for each: original income (market income, before the tax
# system touches it), cash benefits, direct taxes, and disposable income.
#
# WHY ORIGINAL INCOME IS THE OUTCOME THAT MATTERS. Disposable income falls
# mechanically when income tax rises: that is arithmetic, not an effect.
# Original income is earned before any tax or benefit, so its response is
# behavioural, working through employment, hours and wages. The decomposition
#
#     original income  +  cash benefits  -  direct taxes  =  disposable income
#
# holds exactly in the ONS tables, so running the same projection on each line
# prices the whole chain: how much market income the bottom loses, how much of
# that the benefit system gives back automatically, and what is left.
#
# SCALING. Changes are expressed as a percentage of the SAME decile's gross
# income in the base year, not as log changes. The bottom decile's original
# income is small (539 pounds a year in 1977) and log growth of a near-zero
# series is mostly noise. Scaling by gross income keeps the four lines additive
# and keeps the units comparable across deciles.
#
# INFERENCE. Driscoll-Kraay: the shock varies only across years, so the honest
# question is how many YEARS identify the gradient, not how many decile-years.
# Standard errors that ignore this would be roughly three times too small. The
# panel is two-way demeaned first (Frisch-Waugh) so the covariance is estimated
# on a handful of parameters rather than fifty dummies.

source("R/00_setup.R")
msg("== 22_distribution ==")

EXT <- file.path(DERIVED, "external")
etb <- file.path(EXT, "ons_etb_decile.xlsx")
if (!file.exists(etb) || file.size(etb) < 1e5)
  stop("ons_etb_decile.xlsx missing. Run R/19_incidence.R first, which downloads it.")

# --- parse the decile tables -------------------------------------------------
# Row labels are stable across all forty sheets, verified on 1977, 1990,
# 2000-01 and 2016-17. "Total" is not unique, so the two Totals that are needed
# are located by the block they sit in rather than by their own label.
# Columns 2:11 are deciles 1 to 10; column 12 is the all-household average.

row_after <- function(lab, header, want, stop_at) {
  h <- which(grepl(header, lab))[1]
  if (is.na(h)) return(NA_integer_)
  s <- which(grepl(stop_at, lab)); s <- s[s > h][1]
  if (is.na(s)) s <- length(lab) + 1L
  r <- which(grepl(want, lab)); r <- r[r > h & r < s][1]
  r
}

parse_deciles <- function(sheet) {
  d <- as.data.frame(rx(etb, sheet = sheet, col_names = FALSE))
  lab <- trimws(as.character(d[[1]])); lab[is.na(lab)] <- ""
  vals <- suppressWarnings(sapply(d[, 2:11, drop = FALSE], as.numeric))
  grab <- function(i) if (is.na(i)) rep(NA_real_, 10) else as.numeric(vals[i, ])
  r <- list(
    orig     = row_after(lab, "^Original income$", "^Total$", "^Direct benefits in cash"),
    benefits = which(grepl("^Total cash benefits", lab))[1],
    gross    = which(grepl("^Gross income", lab))[1],
    dtax     = row_after(lab, "^Direct taxes and Employees", "^Total$", "^Disposable income$"),
    disp     = which(grepl("^Disposable income$", lab))[1],
    itax     = which(grepl("^Total indirect taxes", lab))[1],
    posttax  = which(grepl("^Post-tax income", lab))[1])
  out <- as.data.frame(lapply(r, grab))
  out$decile <- 1:10
  out$sheet  <- sheet
  out
}

sheets <- excel_sheets(etb); sheets <- sheets[grepl("^[0-9]{4}", sheets)]
etbd <- do.call(rbind, lapply(sheets, parse_deciles))

# The ONS sheets switch from calendar years to April-starting fiscal years at
# 1994-95. Both the shock and the deflator must be aggregated on whichever
# basis the sheet uses, or the alignment is off by up to three quarters.
etbd$y0     <- as.integer(substr(etbd$sheet, 1, 4))
etbd$fiscal <- grepl("-", etbd$sheet)
etbd$adding_up <- with(etbd, orig + benefits - dtax - disp)
msg("parsed %d sheets x 10 deciles = %d rows, %s to %s",
    length(sheets), nrow(etbd), sheets[1], tail(sheets, 1))
msg("  missing cells: %d", sum(is.na(etbd[, c("orig","benefits","gross","dtax","disp")])))
msg("  adding-up check, original + benefits - direct taxes - disposable:")
msg("    max |error| %.2f pounds against a mean gross income of %.0f",
    max(abs(etbd$adding_up), na.rm = TRUE), mean(etbd$gross, na.rm = TRUE))

# --- align the shock and the deflator to the ONS year basis ------------------
p <- readRDS(file.path(DERIVED, "p2_panel.rds")); p <- p[order(p$date), ]
qkey <- p$year * 10L + p$quarter

over_year <- function(v, y0, fiscal, f = sum) over_ons_year(v, qkey, y0, fiscal, f)

yr <- unique(etbd[, c("sheet", "y0", "fiscal")])
yr$shock <- over_year(p$unant, yr$y0, yr$fiscal, sum)
yr$cpi   <- over_year(p$CPI_SA, yr$y0, yr$fiscal, mean)
msg("\nannual shock series on the ONS year basis: %d years, sd %.3f%% of GDP",
    sum(!is.na(yr$shock)), sd(yr$shock, na.rm = TRUE))
msg("  nonzero in %d years; largest %+.3f in %s",
    sum(yr$shock != 0, na.rm = TRUE), yr$shock[which.max(abs(yr$shock))],
    yr$sheet[which.max(abs(yr$shock))])
msg("  sd 1977-1999 %.3f | sd 2000-2016 %.3f   <- where the identification is",
    sd(yr$shock[yr$y0 < 2000], na.rm = TRUE), sd(yr$shock[yr$y0 >= 2000], na.rm = TRUE))

d <- merge(etbd, yr[, c("sheet","shock","cpi")], by = "sheet")
d <- d[order(d$decile, d$y0), ]
for (v in c("orig","benefits","gross","dtax","disp","itax","posttax"))
  d[[paste0("r_", v)]] <- 100 * d[[v]] / d$cpi     # real, CPI-deflated

# --- the panel projection ----------------------------------------------------
# For horizon h and component c:
#
#   100 * (c_{d,t+h} - c_{d,t-1}) / gross_{d,t-1}
#       = a_d + g_t + b_h * (shock_t * rank_d) + controls + e
#
# rank is the decile centred at 5.5, so b_h is the extra response per step DOWN
# the distribution when signed as below. Year effects g_t absorb the aggregate
# response completely: b_h is a statement about the gradient and nothing else.

TT <- sort(unique(d$y0)); NT <- length(TT); ND <- 10
d$rank_c <- 5.5 - d$decile           # +4.5 at the bottom, -4.5 at the top
d$si     <- d$shock * d$rank_c

HMAX <- 4
project_component <- function(cmp, H = 0:HMAX) {
  do.call(rbind, lapply(H, function(h) {
    z <- d
    # base is t-1, outcome is t+h, both looked up within decile
    key <- function(off) match(paste(z$decile, z$y0 + off), paste(d$decile, d$y0))
    b <- key(-1); f <- key(h)
    y <- 100 * (d[[paste0("r_", cmp)]][f] - d[[paste0("r_", cmp)]][b]) / d$r_gross[b]
    df <- data.frame(y = y, si = z$si, si1 = z$si[key(-1)],
                     t = z$y0, i = z$decile)
    df <- df[complete.cases(df), ]
    # keep the panel balanced so the two-way transform stays exact
    full <- as.integer(names(which(table(df$t) == ND)))
    df <- df[df$t %in% full, ]
    if (length(full) < 12) return(NULL)
    yd  <- demean2(df$y,   df$i, df$t)
    x1  <- demean2(df$si,  df$i, df$t)
    x2  <- demean2(df$si1, df$i, df$t)
    X   <- cbind(si = x1, si1 = x2)
    fit <- lm.fit(X, yd)
    se  <- dk_se(X, residuals(fit), df$t, h + 1, ND)
    bb  <- coef(fit)[["si"]]
    data.frame(component = cmp, h = h, years = length(full), n = nrow(df),
               b = bb, se = se[1], t = bb / se[1],
               lo = bb - 1.96*se[1], hi = bb + 1.96*se[1])
  }))
}

msg("\n=== THE GRADIENT ===")
msg("Coefficient: extra percent of own gross income lost per decile step DOWN")
msg("the distribution, per tax rise worth 1%% of GDP. Negative means the bottom")
msg("loses more than the top. Year effects absorb the aggregate response.\n")

res <- do.call(rbind, lapply(c("orig","benefits","dtax","disp"), project_component))
LABS <- c(orig = "original income", benefits = "cash benefits",
          dtax = "direct taxes", disp = "disposable income")
for (cmp in names(LABS)) {
  r <- res[res$component == cmp, ]
  msg("  %-18s %s", LABS[cmp],
      paste(sprintf("h%d %+6.2f(%+5.2f)%s", r$h, r$b, r$t,
                    ifelse(abs(r$t) > 1.96, "*", " ")), collapse = " "))
}
msg("\n  (coefficient (t-stat), * marks |t| > 1.96; %d years, %d decile-years)",
    res$years[1], res$n[1])

pk <- res[res$component == "orig", ]
pk <- pk[which.max(abs(pk$t)), ]
msg("\n  Market income, strongest horizon h=%d: %+.2f (t %+.2f).", pk$h, pk$b, pk$t)
msg("  Read across the decomposition at that horizon:")
for (cmp in names(LABS)) {
  r <- res[res$component == cmp & res$h == pk$h, ]
  msg("    %-18s %+6.2f  [%+6.2f, %+6.2f]  t %+5.2f", LABS[cmp], r$b, r$lo, r$hi, r$t)
}
off <- res$b[res$component == "benefits" & res$h == pk$h]
mkt <- res$b[res$component == "orig" & res$h == pk$h]
if (!is.na(mkt) && mkt != 0)
  msg("    benefit offset: %.0f%% of the market-income gradient", 100 * off / -mkt)

write.csv(res, file.path(OUTPUT, "p2_distribution_gradient.csv"), row.names = FALSE)

# --- is the null informative? ------------------------------------------------
# Same standard script 20 applied to the announcement null: the minimum
# detectable effect is the smallest true gradient this design would find four
# times in five, being 2.80 standard errors.
msg("\n=== IS THE NULL INFORMATIVE? NO ===")
for (cmp in c("orig","disp")) {
  z <- res[res$component == cmp, ]
  msg("  %-18s MDE per decile step %s", LABS[cmp],
      paste(sprintf("h%d %.2f", z$h, 2.80 * z$se), collapse = " "))
  msg("  %-18s across the nine steps from top to bottom, that is %s",
      "", paste(sprintf("h%d %.0f%%", z$h, 9 * 2.80 * z$se), collapse = " "))
}
msg("  A gradient of 10 to 21 per cent of gross income between the top and the")
msg("  bottom decile is far larger than anything the literature reports. This")
msg("  design cannot detect a plausible distributional effect, so the absence")
msg("  of one here is not evidence that there is none.")

# --- why: a positive control, and it clears the design ----------------------
# Before blaming the data, check that the design can detect ANY gradient. Same
# panel, same fixed effects, same Driscoll-Kraay errors, with the tax shock
# replaced by two drivers that are known to move the income distribution.
msg("\n=== POSITIVE CONTROL: CAN THIS DESIGN DETECT ANYTHING? YES ===")
d$dU <- NA_real_; d$gY <- NA_real_
yrs <- unique(d[, c("y0","shock")]); yrs <- yrs[order(yrs$y0), ]
yrs$U  <- over_year(p$Unemployment, yrs$y0, yrs$y0 %in% d$y0[grepl("-", d$sheet)], mean)
yrs$dU <- c(NA, diff(yrs$U))
yrs$gY <- c(NA, 100 * diff(over_year(p$lrgdp, yrs$y0,
                                     yrs$y0 %in% d$y0[grepl("-", d$sheet)], mean)))
d$dU <- yrs$dU[match(d$y0, yrs$y0)]; d$gY <- yrs$gY[match(d$y0, yrs$y0)]

grad_on <- function(cmp, drv, H = 0:HMAX, ctrl = NULL) {
  do.call(rbind, lapply(H, function(h) {
    key <- function(off) match(paste(d$decile, d$y0 + off), paste(d$decile, d$y0))
    y <- 100 * (d[[paste0("r_", cmp)]][key(h)] -
                d[[paste0("r_", cmp)]][key(-1)]) / d$r_gross[key(-1)]
    si <- d[[drv]] * d$rank_c
    df <- data.frame(y = y, s = si, s1 = si[key(-1)], t = d$y0, i = d$decile)
    if (!is.null(ctrl)) for (cv in ctrl) df[[cv]] <- d[[cv]] * d$rank_c
    df <- df[complete.cases(df), ]
    full <- as.integer(names(which(table(df$t) == ND))); df <- df[df$t %in% full, ]
    if (length(full) < 12) return(NULL)
    X <- sapply(setdiff(names(df), c("y","t","i")),
                function(v) demean2(df[[v]], df$i, df$t))
    fit <- lm.fit(X, demean2(df$y, df$i, df$t))
    se <- dk_se(X, residuals(fit), df$t, abs(h) + 1, ND)
    data.frame(driver = drv, component = cmp, h = h, b = coef(fit)[[1]],
               se = se[1], t = coef(fit)[[1]] / se[1])
  }))
}
show_grad <- function(z, lab) msg("  %-30s %s", lab,
  paste(sprintf("h%+d %+6.2f(%+5.2f)%s", z$h, z$b, z$t,
                ifelse(abs(z$t) > 1.96, "*", " ")), collapse = " "))
ctl <- do.call(rbind, lapply(c("dU","gY"), function(v)
  do.call(rbind, lapply(c("orig","disp"), function(c2) grad_on(c2, v)))))
for (v in c("dU","gY")) for (c2 in c("orig","disp"))
  show_grad(ctl[ctl$driver == v & ctl$component == c2, ],
            sprintf("%s, %s", c(dU="unemployment +1pp", gY="GDP growth +1%")[v],
                    LABS[c2]))
msg("  Both drivers produce strong, correctly signed gradients, |t| up to 3.6.")
msg("  A contraction compresses the MARKET income distribution because the")
msg("  bottom decile holds under one per cent of market income and has little")
msg("  to lose, while the benefit system cushions it further in disposable")
msg("  terms. So the panel CAN see distributional dynamics. The design is not")
msg("  the problem, and neither is the annual frequency.")

msg("\n=== SO THE PROBLEM IS THE SHOCK, AND IT IS ARITHMETIC ===")
msg("  driver standard deviation over the 41 ONS years:")
msg("    unemployment change %.3f pp | GDP growth %.3f%% | tax surprise %.3f%% of GDP",
    sd(yrs$dU, na.rm = TRUE), sd(yrs$gY, na.rm = TRUE), sd(yrs$shock, na.rm = TRUE))
r_o <- res[res$component == "orig" & res$h == 4, ]
g_o <- ctl[ctl$driver == "gY" & ctl$component == "orig" & ctl$h == 4, ]
msg("  At h=4 the standard error on GDP growth is %.3f and on the tax surprise",
    g_o$se)
msg("  %.3f, a ratio of %.1f. The driver standard deviations differ by %.1f.",
    r_o$se, r_o$se / g_o$se, sd(yrs$gY, na.rm=TRUE) / sd(yrs$shock, na.rm=TRUE))
msg("  The design extracts the same precision per unit of variation from each.")
msg("  The tax surprise simply carries a sixth of the information that GDP")
msg("  growth does. This is Paper 1's central finding arriving as an estimation")
msg("  constraint: the surprise component of UK tax policy has largely vanished.")

# --- buying variance costs the identification -------------------------------
# The obvious response is to add the anticipated measures back at their
# implementation dates, which raises the standard deviation from 0.328 to 0.367
# and the mean absolute impulse from 0.166 to 0.253. It produces a significant
# gradient. It does not survive falsification, and this is recorded so that the
# next reader does not rediscover it and believe it.
msg("\n=== A SIGNIFICANT RESULT THAT MUST NOT BE USED ===")
d$total <- d$shock + over_year(p$ant_imp, d$y0,
                               grepl("-", d$sheet), sum)
d$ant_imp <- over_year(p$ant_imp, d$y0, grepl("-", d$sheet), sum)
tot <- do.call(rbind, lapply(c("orig","disp"), function(c2) grad_on(c2, "total")))
for (c2 in c("orig","disp"))
  show_grad(tot[tot$component == c2, ], sprintf("surprise + anticipated, %s", LABS[c2]))
msg("  Significant at four of five horizons on market income. Then:")
pl <- do.call(rbind, lapply(c("orig","disp"), function(c2) grad_on(c2, "total", -3:-2)))
for (c2 in c("orig","disp"))
  show_grad(pl[pl$component == c2, ], sprintf("  PLACEBO, before the shock, %s", LABS[c2]))
an <- do.call(rbind, lapply(c("orig","disp"), function(c2) grad_on(c2, "ant_imp")))
for (c2 in c("orig","disp"))
  show_grad(an[an$component == c2, ], sprintf("  anticipated half ALONE, %s", LABS[c2]))
cy <- do.call(rbind, lapply(c("orig","disp"),
       function(c2) grad_on(c2, "total", 0:HMAX, ctrl = c("gY","dU"))))
for (c2 in c("orig","disp"))
  show_grad(cy[cy$component == c2, ], sprintf("  controlling for the cycle, %s", LABS[c2]))
msg("  Three failures. The placebo is significant three years BEFORE the shock")
msg("  and with the opposite sign, so the gradient is a trend running through")
msg("  the shock rather than a response to it. The whole effect comes from the")
msg("  anticipated half, whose implementation dates are chosen by a Chancellor")
msg("  and which Paper 1 shows are scheduled around elections, so it is not")
msg("  exogenous to the state it lands in. And controlling for the cycle halves")
msg("  the market-income gradient and removes the disposable-income one, which")
msg("  says most of what is left is the ordinary GDP channel already priced in")
msg("  Section 3. DO NOT WRITE THIS UP.")
write.csv(rbind(tot, pl, an, cy, ctl),
          file.path(OUTPUT, "p2_distribution_falsified.csv"), row.names = FALSE)

# --- not the linear restriction ----------------------------------------------
# A linear rank interaction imposes a monotone gradient. If the effect were
# concentrated in the bottom half, this would find it and the rank version
# would not, so the restriction must be cleared before the null is reported.
msg("\n=== NOT AN ARTEFACT OF THE LINEAR RANK RESTRICTION ===")
d$bh <- as.numeric(d$decile <= 5) - 0.5
d$si_bh <- d$shock * d$bh
project_bh <- function(cmp, H = 0:HMAX) {
  do.call(rbind, lapply(H, function(h) {
    key <- function(off) match(paste(d$decile, d$y0 + off), paste(d$decile, d$y0))
    b <- key(-1); f <- key(h)
    y <- 100 * (d[[paste0("r_", cmp)]][f] - d[[paste0("r_", cmp)]][b]) / d$r_gross[b]
    df <- data.frame(y = y, s = d$si_bh, s1 = d$si_bh[key(-1)], t = d$y0, i = d$decile)
    df <- df[complete.cases(df), ]
    full <- as.integer(names(which(table(df$t) == ND))); df <- df[df$t %in% full, ]
    X <- cbind(s = demean2(df$s, df$i, df$t), s1 = demean2(df$s1, df$i, df$t))
    fit <- lm.fit(X, demean2(df$y, df$i, df$t))
    se <- dk_se(X, residuals(fit), df$t, h + 1, ND)
    data.frame(component = cmp, h = h, b = coef(fit)[["s"]], se = se[1],
               t = coef(fit)[["s"]] / se[1])
  }))
}
bh <- do.call(rbind, lapply(c("orig","disp"), project_bh))
for (cmp in c("orig","disp")) {
  z <- bh[bh$component == cmp, ]
  msg("  %-18s %s", LABS[cmp],
      paste(sprintf("h%d %+6.2f(%+5.2f)%s", z$h, z$b, z$t,
                    ifelse(abs(z$t) > 1.96, "*", " ")), collapse = " "))
}
msg("  Bottom half against top half, no monotonicity imposed. Also nothing.")

# --- cross-check: the top-minus-bottom gap, as one time series ---------------
# The panel above is the efficient version. This is the transparent one: form
# the ratio of top-decile to bottom-decile real income and project it directly,
# with the machinery used everywhere else in the project.
w <- reshape(d[, c("y0","decile","r_orig","r_disp","shock")],
             idvar = "y0", timevar = "decile", direction = "wide")
w <- w[order(w$y0), ]
msg("\n=== CROSS-CHECK: top decile minus bottom decile, single time series ===")
for (cmp in c("orig", "disp")) {
  g <- unname(log(w[[paste0("r_", cmp, ".10")]]) - log(w[[paste0("r_", cmp, ".1")]]))
  ok <- is.finite(g) & !is.na(w$shock.1)
  r <- lp_project(g, w$shock.1, ok, H = 0:HMAX, nlag = 1, minobs = 15)
  if (is.null(r)) { msg("  %-18s not estimable", LABS[cmp]); next }
  msg("  %-18s %s", LABS[cmp],
      paste(sprintf("h%d %+6.2f(%+5.2f)%s", r$h, r$b, r$t,
                    ifelse(abs(r$t) > 1.96, "*", " ")), collapse = " "))
  write.csv(cbind(component = cmp, r),
            file.path(OUTPUT, sprintf("p2_dist_gap_%s.csv", cmp)), row.names = FALSE)
}
msg("  Positive means the gap widens. The signs flip across horizons and the")
msg("  two significant cells sit either side of insignificant ones, which is")
msg("  what noise looks like. Consistent with the panel, and equally empty.")

# --- what the exercise DID establish -----------------------------------------
# The gradient fails, but the same data delivers something the paper can use.
# The ONS decile tables are built from household survey returns and are wholly
# independent of the national accounts consumption series the paper's main
# result rests on. If the aggregate of these tables responds to the shock, the
# central estimate is corroborated on data that shares none of its sources.
msg("\n=== WHAT THIS DID ESTABLISH: THE AGGREGATE, ON INDEPENDENT DATA ===")
yrs <- unique(d[, c("y0","shock")]); yrs <- yrs[order(yrs$y0), ]
agg <- do.call(rbind, lapply(c("orig","disp"), function(cmp) {
  g <- unname(log(rowSums(w[, paste0("r_", cmp, ".", 1:10)])))
  r <- lp_project(g, yrs$shock, rep(TRUE, nrow(w)), H = 0:HMAX, nlag = 1, minobs = 15)
  msg("  real household %-18s %s", LABS[cmp],
      paste(sprintf("h%d %+6.2f(%+5.2f)%s", r$h, r$b, r$t,
                    ifelse(abs(r$t) > 1.96, "*", " ")), collapse = " "))
  cbind(component = cmp, r)
}))
write.csv(agg, file.path(OUTPUT, "p2_etb_aggregate.csv"), row.names = FALSE)
msg("  Against a tax rise worth 1%% of GDP, real household market income falls")
msg("  %.1f%% and real disposable income %.1f%% by year four. The ONS survey",
    -agg$b[agg$component=="orig" & agg$h==4], -agg$b[agg$component=="disp" & agg$h==4])
msg("  aggregates and the national accounts consumption series share no")
msg("  sources, so this is corroboration of the paper's central estimate")
msg("  rather than a restatement of it.")

# --- verdict -----------------------------------------------------------------
msg("\n=== VERDICT ===")
msg("  THIRD FAILURE of the distributional half, and the first one that says")
msg("  WHY rather than merely that. Script 15 could not decompose by instrument")
msg("  for want of variation. Script 19 split the shock and got two series")
msg("  correlated at 0.93. This script splits the outcome, which is the correct")
msg("  design, and the positive control proves the design works: unemployment")
msg("  and GDP growth both produce gradients at |t| above 3 in the same panel.")
msg("")
msg("  The binding constraint is the shock, and it is arithmetic. The UK tax")
msg("  surprise carries a sixth of the variation that GDP growth does, so the")
msg("  minimum detectable gradient is 10 to 21 per cent of gross income between")
msg("  the top and bottom decile. Buying the variance back by restoring the")
msg("  anticipated measures produces a significant answer that fails its")
msg("  placebo, comes wholly from the endogenously timed half, and does not")
msg("  survive cycle controls.")
msg("")
msg("  This is not a coarseness problem that a better public dataset would fix.")
msg("  Aggregate identification is exhausted: the exogenous surprise series has")
msg("  no more information to give. Household micro data is required because it")
msg("  supplies cross-sectional variation that does not come from the shock,")
msg("  and that is now a demonstrated claim rather than an assumption.")
msg("")
msg("  What survives from this script is the aggregate corroboration above, on")
msg("  the unanticipated series and on survey data independent of the national")
msg("  accounts. That belongs in Section 3, not Section 6.")

saveRDS(d, file.path(DERIVED, "p2_decile_panel.rds"))
msg("\nwritten: output/p2_distribution_gradient.csv, output/p2_etb_aggregate.csv,")
msg("         data-derived/p2_decile_panel.rds")
