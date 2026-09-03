# 13_lp.R ---------------------------------------------------------------------
# First-pass local projections, Jorda (2005). The question is whether an
# anticipated tax change moves output when it is ANNOUNCED or when it TAKES
# EFFECT, and whether either response resembles the response to a surprise.
#
# SPECIFICATION. For horizon h,
#   100 * (log y_{t+h} - log y_{t-1}) = a_h + b_h * shock_t + controls + e_{t+h}
# with four lags of quarterly GDP growth, four lags of the shock, and the
# contemporaneous narrative government SPENDING shock from the JPE deposit,
# which is the one control we could not build ourselves. Newey-West standard
# errors with bandwidth h + 1, which is the usual choice given the h-step
# overlap induced by the projection.
#
# b_h is the response of real GDP, in per cent, to a tax change worth one per
# cent of annual GDP. The sign convention follows the source: a positive shock
# is a tax RISE, so a contractionary effect appears as b_h < 0.
#
# THREE REGRESSIONS, NEVER POOLED. `ant_news` and `ant_imp` are the same money
# dated twice and must not appear together. `unant` is a disjoint set of
# measures. Each is run alone.
#
# BASELINE SAMPLE IS 1945-2018. The interwar block is reported separately: it
# contributes 89 exogenous measures, 14 quarters of non-zero surprise and almost
# no news variation at all, and including it forces a six-year war hole through
# the middle of every projection window. It is an extension, not the sample.

source("R/00_setup.R")
msg("== 13_lp ==")

p <- readRDS(file.path(DERIVED, "p2_panel.rds"))
p <- p[order(p$date), ]

H     <- 0:16
NLAG  <- 4
SAMP  <- c(1945, 2018)

#' Newey-West HAC variance for lm, bandwidth L (Bartlett kernel).
nw <- function(fit, L) {
  X <- model.matrix(fit); u <- residuals(fit); n <- nrow(X); k <- ncol(X)
  XtXi <- solve(crossprod(X))
  S <- crossprod(X * u)
  if (L > 0) for (l in seq_len(L)) {
    w <- 1 - l/(L + 1)
    G <- crossprod(X[(l+1):n, , drop = FALSE] * u[(l+1):n],
                   X[1:(n-l), , drop = FALSE] * u[1:(n-l)])
    S <- S + w * (G + t(G))
  }
  V <- XtXi %*% S %*% XtXi * (n/(n - k))
  sqrt(diag(V))
}

lags <- function(x, k) sapply(seq_len(k), function(i) c(rep(NA, i), head(x, -i)))

#' Local projections of log real GDP on one shock series.
lp <- function(dat, shock, label) {
  dat <- dat[order(dat$date), ]
  y   <- dat$lrgdp
  s   <- dat[[shock]]
  dg  <- c(NA, 100 * diff(y))                       # quarterly GDP growth
  Ls  <- lags(s, NLAG); Lg <- lags(dg, NLAG)
  sp  <- dat$X_SpendToGDP; sp[is.na(sp)] <- 0
  out <- do.call(rbind, lapply(H, function(h) {
    # y[t+h] by index, out-of-range giving NA. tail(y, -0) returns an empty
    # vector, so the shift must not be written with tail().
    yh <- 100 * (y[seq_along(y) + h] - c(NA, head(y, -1)))
    df <- data.frame(yh = yh, s = s, sp = sp, Ls, Lg)
    ok <- complete.cases(df) & dat$year >= SAMP[1] & dat$year <= SAMP[2]
    df <- df[ok, ]
    if (nrow(df) < 40) return(NULL)
    f  <- lm(yh ~ ., data = df)
    se <- nw(f, h + 1)["s"]
    b  <- coef(f)["s"]
    data.frame(series = label, h = h, n = nrow(df), b = b, se = se,
               lo = b - 1.96*se, hi = b + 1.96*se, t = b/se)
  }))
  rownames(out) <- NULL
  out
}

res <- do.call(rbind, lapply(
  list(c("unant","Unanticipated, implementation-dated"),
       c("ant_news","Anticipated, announcement-dated"),
       c("ant_imp","Anticipated, implementation-dated")),
  function(z) lp(p, z[1], z[2])))

msg("\nsample %d-%d, horizons 0-%d, %d lags, Newey-West(h+1)\n",
    SAMP[1], SAMP[2], max(H), NLAG)
for (lab in unique(res$series)) {
  z <- res[res$series == lab, ]
  msg("--- %s ---", lab)
  msg("   h      b       se       t     [95%% interval]")
  for (i in seq_len(nrow(z))) if (z$h[i] %in% c(0,2,4,6,8,12,16))
    msg("  %2d  %+6.3f  %6.3f  %+6.2f   [%+.3f, %+.3f]%s",
        z$h[i], z$b[i], z$se[i], z$t[i], z$lo[i], z$hi[i],
        ifelse(abs(z$t[i]) > 1.96, "  *", ""))
  pk <- z[which.max(abs(z$b)), ]
  msg("   peak |b| = %+.3f at h = %d (t = %+.2f), n = %d\n", pk$b, pk$h, pk$t, pk$n)
}

write.csv(res, file.path(OUTPUT, "p2_lp_baseline.csv"), row.names = FALSE)

# --- does the answer survive conditioning on instrument mix? ----------------
# Paper 1 showed anticipation is determined by instrument. The composition
# tables in script 12 put the difference mostly in social security (anticipated)
# and excise and capital gains (surprise). If the contrast below is driven by
# that, splitting the surprise series into its excise and non-excise parts
# should move it.
msg("--- significance count by series (|t| > 1.96 across h = 0..16) ---")
for (lab in unique(res$series)) {
  z <- res[res$series == lab, ]
  msg("  %-38s %2d of %2d horizons", lab, sum(abs(z$t) > 1.96), nrow(z))
}

msg("\nwritten: output/p2_lp_baseline.csv")
