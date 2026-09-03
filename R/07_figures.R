# 07_figures.R ---------------------------------------------------------------
# Paper 1 figures. All on the primary outcome `long` (gap of 120+ days).
# Run after R/06_analysis.R.

source("R/00_setup.R")
suppressMessages(library(ggplot2))
msg("== 07_figures ==")

FIG <- file.path(OUTPUT, "figures"); dir.create(FIG, showWarnings = FALSE)
m <- readRDS(file.path(DERIVED, "paper1_analysis.rds"))
m$bmonth <- as.integer(format(m$budget_date, "%m"))
m$autumn <- as.integer(m$bmonth %in% 9:12)

theme_p1 <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        plot.title = element_text(face = "bold", size = 12),
        plot.subtitle = element_text(colour = "grey35", size = 9.5),
        plot.caption = element_text(colour = "grey45", size = 8, hjust = 0))
INK <- "#1f4e79"; ACC <- "#c0504d"

sv <- function(p, name, w = 7, h = 4.4) {
  ggsave(file.path(FIG, paste0(name, ".png")), p, width = w, height = h, dpi = 200)
  msg("  written: figures/%s.png", name)
}

# --- FIG 0: why 120 days ----------------------------------------------------
# Justifies the threshold. The spike just under 30 days is the March Budget to
# 6 April convention: a fiscal-year crossing on three weeks' notice.
d0 <- m[!is.na(m$days) & m$days >= 0 & m$days <= 730, ]
p0 <- ggplot(d0, aes(days)) +
  geom_histogram(binwidth = 15, fill = INK, alpha = .85) +
  geom_vline(xintercept = 120, colour = ACC, linewidth = .7, linetype = "22") +
  annotate("text", x = 140, y = Inf, label = "120-day threshold", hjust = 0, vjust = 1.6,
           colour = ACC, size = 3.1) +
  scale_x_continuous(breaks = seq(0, 730, 90)) +
  labs(title = "Announcement-to-implementation gap, UK tax measures 1945-2019",
       subtitle = "The mass below 30 days is the March Budget to 6 April convention: a fiscal-year\ncrossing on three weeks' notice. The primary outcome excludes it.",
       x = "Days from announcement to implementation", y = "Measures",
       caption = paste0("n = ", nrow(d0), " measures with a gap of 0-730 days.")) + theme_p1
sv(p0, "fig0_gap_distribution")

# --- FIG 1: the trend -------------------------------------------------------
blk <- read.csv(file.path(OUTPUT, "fact1_trend_5yr.csv"))
blk <- blk[blk$n >= 15, ]
p1 <- ggplot(blk, aes(block, long)) +
  geom_line(colour = INK, linewidth = .9) +
  geom_point(aes(size = n), colour = INK) +
  scale_size_continuous(range = c(1.2, 4), guide = "none") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, NA)) +
  scale_x_continuous(breaks = seq(1945, 2015, 10)) +
  labs(title = "UK tax policy takes far longer to take effect than it did",
       subtitle = "Share of measures implemented 120+ days after announcement, five-year blocks",
       x = NULL, y = "Share of measures",
       caption = "Point size is the number of measures in the block. Blocks with fewer than 15 measures omitted.") +
  theme_p1
sv(p1, "fig1_trend")

# --- FIG 2: instruments, within Budget --------------------------------------
ri <- read.csv(file.path(OUTPUT, "fact2_instruments.csv"))
ii  <- m[!is.na(m$tax_h), ]
n2  <- nrow(ii); e2 <- nlevels(droplevels(factor(ii$ev)))
f2j <- anova(lm(long ~ ev, data = ii), lm(long ~ tax_h + ev, data = ii))
ri$instrument <- factor(ri$instrument, levels = ri$instrument[order(ri$est)])
ri$sig <- ifelse(ri$p < 0.05, "p < 0.05", "not significant")
p2 <- ggplot(ri, aes(est, instrument, colour = sig)) +
  geom_vline(xintercept = 0, colour = "grey55", linewidth = .4) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0, linewidth = .7) +
  geom_point(size = 2.3) +
  scale_colour_manual(values = c("p < 0.05" = INK, "not significant" = "grey65"), name = NULL) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(title = "Instrument choice is a timing choice",
       subtitle = "Change in the probability of a 120+ day gap, relative to excise duties.\nBudget-event fixed effects: instruments announced on the same day by the same Chancellor.",
       x = "Percentage-point difference vs excise duties", y = NULL,
       caption = sprintf(paste0("Bars are 95%% confidence intervals, standard errors clustered on Budget event.\n",
                                "Joint F = %.1f on %d df, p = %.2g. n = %s measures, %d Budget events."),
                         f2j$F[2], f2j$Df[2], f2j$`Pr(>F)`[2], format(n2, big.mark = ","), e2)) +
  theme_p1 + theme(legend.position = "top")
sv(p2, "fig2_instruments", 7, 4.8)

# --- FIG 3: the mechanism ---------------------------------------------------
p <- m[m$fy_boundary == 1, ]
clx <- function(fit, cluster) {
  X <- model.matrix(fit); b <- solve(crossprod(X)); sc <- X * residuals(fit)
  cf <- droplevels(factor(cluster)); G <- nlevels(cf); N <- nrow(X); K <- ncol(X)
  meat <- matrix(0, K, K)
  for (g in levels(cf)) { sg <- colSums(sc[cf == g, , drop = FALSE]); meat <- meat + tcrossprod(sg) }
  V <- b %*% ((G/(G-1)) * ((N-1)/(N-K)) * meat) %*% b
  se <- sqrt(diag(V)); cbind(est = coef(fit), se = se, z = coef(fit)/se)
}
m3 <- clx(lm(long ~ autumn + factor(dec), data = p), p$ev)["autumn", ]
d3 <- data.frame(
  season = c("Spring Budget", "Autumn Budget"),
  long   = c(mean(p$long[p$autumn == 0]), mean(p$long[p$autumn == 1])),
  n      = c(sum(p$autumn == 0), sum(p$autumn == 1)))
p3 <- ggplot(d3, aes(season, long, fill = season)) +
  geom_col(width = .55) +
  geom_text(aes(label = sprintf("%.0f%%\n(n = %d)", 100*long, n)), vjust = -0.25, size = 3.3) +
  scale_fill_manual(values = c("Spring Budget" = "grey70", "Autumn Budget" = INK), guide = "none") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 1.02)) +
  labs(title = "Why instruments differ: the fiscal-year clock",
       subtitle = "Measures pinned to early April, by Budget season.\nThe same measure is three weeks from a March Budget and five months from a November one.",
       x = NULL, y = "Share with a 120+ day gap",
       caption = sprintf(paste0("April-pinned measures only (implementation 1-7 April), n = %s.\n",
                                "Within-decade estimate +%.3f (z = %.2f), clustered on Budget event."),
                         format(nrow(p), big.mark = ","), m3["est"], m3["z"])) +
  theme_p1
sv(p3, "fig3_mechanism", 7.2, 4.6)

# --- FIG 3b: the clock migration --------------------------------------------
ck <- read.csv(file.path(OUTPUT, "fact3_clock.csv"))
d3b <- rbind(data.frame(decade = ck$decade, share = ck$apr6, what = "6 April (income tax year)"),
             data.frame(decade = ck$decade, share = ck$apr1, what = "1 April (financial year)"),
             data.frame(decade = ck$decade, share = ck$budget_day, what = "Budget day (immediate)"))
p3b <- ggplot(d3b, aes(decade, share, colour = what)) +
  geom_line(linewidth = .85) + geom_point(size = 1.8) +
  scale_colour_manual(values = c(INK, ACC, "grey55"), name = NULL) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_x_continuous(breaks = seq(1940, 2010, 10)) +
  labs(title = "When measures take effect has migrated",
       subtitle = "Share of measures implemented on each date, by decade",
       x = NULL, y = "Share of measures",
       caption = "The shift from 6 April to 1 April is a move from the income tax year to the financial year.") +
  theme_p1 + theme(legend.position = "top")
sv(p3b, "fig3b_clock_migration")

# --- FIG 4: elections -------------------------------------------------------
e  <- read.csv(file.path(OUTPUT, "fact4_elections.csv"))
# Read the estimate rather than retyping it: the caption went stale once before.
ee <- read.csv(file.path(OUTPUT, "fact4_estimate.csv"))
ee <- ee[ee$window == "6-24 months", ]
e$sign <- factor(ifelse(e$sign == "rise", "Tax rises", "Tax cuts"),
                 levels = c("Tax cuts", "Tax rises"))
p4 <- ggplot(e, aes(sign, rate, fill = sign)) +
  geom_col(width = .55) +
  geom_text(aes(label = sprintf("%.1f%%\n(n = %d)", 100*rate, n)), vjust = -0.25, size = 3.3) +
  scale_fill_manual(values = c("Tax cuts" = "grey70", "Tax rises" = ACC), guide = "none") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 0.14)) +
  labs(title = "Tax rises are scheduled past the next election",
       subtitle = "Share of measures whose implementation date falls after the next general election,\nfor measures announced 6-24 months before that election",
       x = NULL, y = "Share landing after the election",
       caption = sprintf(paste0("n = %s measures across %d Budget events. Within-Budget estimate %+.3f ",
                                "(z = %.2f, p = %.3f),\nstandard errors clustered on Budget event."),
                         format(sum(e$n), big.mark = ","), ee$events, ee$est, ee$z, ee$p)) +
  theme_p1
sv(p4, "fig4_elections", 7.2, 4.6)

msg("\nfigures written to output/figures/")
