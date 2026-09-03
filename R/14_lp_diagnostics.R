# 14_lp_diagnostics.R ---------------------------------------------------------
# Script 13 found a POSITIVE and significant output response to anticipated tax
# rises dated by implementation, peaking at +1.0 per cent at five quarters. A
# tax rise raising output is the wrong sign, and there are three candidate
# explanations. This script is built to tell them apart.
#
#   H1 FORESIGHT. Agents learned of the measure at announcement, so by
#      implementation it is not news. The regressor is predictable from the
#      information set and the coefficient is not a causal response.
#   H2 SCHEDULING. Anticipated rises are deliberately timed to land in expected
#      good years. The regressor then correlates with expected growth.
#   H3 COMPOSITION. Anticipated measures are disproportionately social security
#      and income tax; surprise measures excise and capital gains. The contrast
#      is between instruments, not between anticipation states.
#
# FOUR TESTS.
#
#   A. PLACEBO HORIZONS, h = -8 to -2. A valid shock can have no effect before
#      it lands. Movement at negative horizons is decisive against the
#      coefficient being causal, though it does not separate H1 from H2.
#   B. PREDICTABILITY FROM MACRO. Regress each shock on four lags of output
#      growth, unemployment and Bank Rate. A valid shock is unforecastable.
#      `unant` is the control: if it is also predictable the problem is the
#      whole design and not the anticipated series.
#   C. PREDICTABILITY FROM PAST NEWS. Regress `ant_imp` on eight lags of
#      `ant_news`. Note what this is and is not. That the two are related is
#      mechanical, since they are the same measures dated twice, so a high R2 is
#      not a discovery. What it supplies is the MAGNITUDE: how much of what the
#      literature treats as a tax shock was public information up to two years
#      earlier. `unant` is again the control.
#   D. WITHIN INCOME TAX. Income tax supplies 38 per cent of anticipated and 31
#      per cent of surprise measures, so both series can be rebuilt inside one
#      instrument. If the contrast survives there, H3 is dead.
#
# Postwar sample throughout: the interwar block carries no instrument field and
# test D cannot use it.

source("R/00_setup.R")
msg("== 14_lp_diagnostics ==")

p <- readRDS(file.path(DERIVED, "p2_panel.rds"))
p <- p[order(p$date), ]
SAMP <- c(1945, 2018)
ok   <- p$year >= SAMP[1] & p$year <= SAMP[2]
sp   <- p$X_SpendToGDP; sp[is.na(sp)] <- 0
SER  <- c(unant = "Unanticipated", ant_news = "Anticipated, news-dated",
          ant_imp = "Anticipated, implementation-dated")

# ---------------------------------------------------------------------------
# A. PLACEBO HORIZONS
# ---------------------------------------------------------------------------
msg("\n=== A. Placebo horizons. What was output doing BEFORE the shock? ===")
# Two construction points. h = -1 is dropped: y[t-1] - y[t-1] is identically
# zero. And the outcome growth lags are dropped (nlag_y = 0), because at a
# negative horizon the dependent variable is minus the sum of growth over the
# intervening quarters and would be spanned by them, forcing the coefficient to
# zero whatever the truth. Shock lags and the spending control are kept.
pre <- do.call(rbind, lapply(names(SER), function(v) {
  r <- lp_project(p$lrgdp, p[[v]], ok, X = data.frame(sp = sp),
                  H = -8:-2, nlag_y = 0)
  cbind(series = SER[[v]], r)
}))
for (lab in unique(pre$series)) {
  z <- pre[pre$series == lab, ]
  msg("  %-34s %s", lab,
      paste(sprintf("h%d %+.2f%s", z$h, z$b, ifelse(abs(z$t) > 1.96, "*", "")),
            collapse = "  "))
  msg("  %-34s significant: %d of %d", "", sum(abs(z$t) > 1.96, na.rm = TRUE), nrow(z))
}
write.csv(pre, file.path(OUTPUT, "p2_placebo.csv"), row.names = FALSE)

# ---------------------------------------------------------------------------
# B. PREDICTABILITY
# ---------------------------------------------------------------------------
msg("\n=== B. Is the shock forecastable from lagged macro data? ===")
dg  <- c(NA, 100 * diff(p$lrgdp))
Z   <- cbind(lag_mat(dg, 4), lag_mat(p$Unemployment, 4), lag_mat(p$BankRate, 4))
colnames(Z) <- paste0("z", seq_len(ncol(Z)))
prd <- do.call(rbind, lapply(names(SER), function(v) {
  df <- data.frame(s = p[[v]], Z)[ok, ]
  df <- df[complete.cases(df), ]
  f  <- lm(s ~ ., data = df)
  a  <- anova(lm(s ~ 1, data = df), f)
  data.frame(series = SER[[v]], n = nrow(df), r2 = round(summary(f)$r.squared, 3),
             F = round(a$F[2], 2), p = signif(a$`Pr(>F)`[2], 3))
}))
print(prd, row.names = FALSE)
msg("  A valid shock is unforecastable, so R2 near zero and p above 0.05.")
write.csv(prd, file.path(OUTPUT, "p2_predictability.csv"), row.names = FALSE)

# ---------------------------------------------------------------------------
# C. CONDITIONING THE IMPLEMENTATION-DATED SERIES ON PAST NEWS
# ---------------------------------------------------------------------------
msg("\n=== C. How much of the implementation-dated series is old news? ===")
# Adding lags of `ant_news` as controls does not work: they are the same money
# shifted, so the regression is collinear and the standard errors explode
# without settling anything. The informative version asks the question
# directly. If `ant_imp` is well predicted by past announcements then it is not
# a shock, and a coefficient estimated on it is not an impulse response.
NEWSLAG <- 8
Ln <- as.data.frame(lag_mat(p$ant_news, NEWSLAG))
names(Ln) <- paste0("Ln", seq_len(NEWSLAG))
predfit <- function(v) {
  df <- data.frame(s = p[[v]], Ln)[ok, ]; df <- df[complete.cases(df), ]
  f <- lm(s ~ ., data = df); a <- anova(lm(s ~ 1, data = df), f)
  data.frame(series = SER[[v]], n = nrow(df), r2 = round(summary(f)$r.squared, 3),
             F = round(a$F[2], 2), p = signif(a$`Pr(>F)`[2], 3))
}
newsp <- do.call(rbind, lapply(c("ant_imp","unant"), predfit))
print(newsp, row.names = FALSE)
msg("  `unant` is the control. It should not be predictable from past news.")
write.csv(newsp, file.path(OUTPUT, "p2_news_predicts.csv"), row.names = FALSE)

# ---------------------------------------------------------------------------
# D. WITHIN INCOME TAX
# ---------------------------------------------------------------------------
msg("\n=== D. Within income tax, where both states are well populated ===")
ext <- readRDS(file.path(DERIVED, "extended_measures.rds"))
d   <- ext[ext$timing_sample & ext$endo_exo %in% "X" & !is.na(ext$peak_value) &
           ext$source != "CDPV" & ext$tax_h %in% "Income", ]
msg("  income tax exogenous measures: %d (%d anticipated, %d surprise)",
    nrow(d), sum(d$long == 1), sum(d$long == 0))

key <- paste(p$year, p$quarter)
agg <- function(yr, qt, val) {
  k <- paste(yr, qt); i <- !is.na(yr) & !is.na(qt) & k %in% key
  s <- tapply(val[i], k[i], sum)
  o <- setNames(rep(0, length(key)), key); o[names(s)] <- s; as.numeric(o)
}
lo <- d$long == 1
inc_news  <- 100 * agg(d$ann_year_cal[lo],  d$ann_q_cal[lo],  d$peak_value[lo])  / p$gdp_ann
inc_imp   <- 100 * agg(d$imp_year_cal[lo],  d$imp_q_cal[lo],  d$peak_value[lo])  / p$gdp_ann
inc_unant <- 100 * agg(d$imp_year_cal[!lo], d$imp_q_cal[!lo], d$peak_value[!lo]) / p$gdp_ann
msg("  nonzero quarters: news %d, ant_imp %d, unant %d | sd %.3f / %.3f / %.3f",
    sum(inc_news != 0), sum(inc_imp != 0), sum(inc_unant != 0),
    sd(inc_news), sd(inc_imp), sd(inc_unant))

inc <- do.call(rbind, lapply(
  list(c("inc_unant","Income, unanticipated"),
       c("inc_news","Income, news-dated"),
       c("inc_imp","Income, implementation-dated")),
  function(z) {
    r <- lp_project(p$lrgdp, get(z[1]), ok, X = data.frame(sp = sp), H = 0:16)
    if (is.null(r)) return(NULL)
    cbind(series = z[2], r)
  }))
for (lab in unique(inc$series)) {
  z <- inc[inc$series == lab, ]
  pk <- z[which.max(abs(z$b)), ]
  msg("  %-32s peak %+6.3f at h=%2d (t %+5.2f), %d of %d horizons significant",
      lab, pk$b, pk$h, pk$t, sum(abs(z$t) > 1.96), nrow(z))
}
write.csv(inc, file.path(OUTPUT, "p2_lp_income.csv"), row.names = FALSE)

msg("\nwritten: output/p2_{placebo,predictability,news_conditioned,lp_income}.csv")
