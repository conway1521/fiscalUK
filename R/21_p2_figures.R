# 21_p2_figures.R --------------------------------------------------------------
# Paper 2 figures, on the same visual grammar as Paper 1's.
# Run after R/18, R/19 and R/20.

source("R/00_setup.R")
suppressMessages(library(ggplot2))
msg("== 21_p2_figures ==")

FIG <- file.path(OUTPUT, "figures"); dir.create(FIG, showWarnings = FALSE)
theme_p1 <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 12),
        plot.subtitle = element_text(colour = "grey35", size = 9.5),
        plot.caption = element_text(colour = "grey45", size = 8, hjust = 0))
INK <- "#1f4e79"; ACC <- "#c0504d"
sv <- function(p, name, w = 7, h = 4.4) {
  ggsave(file.path(FIG, paste0(name, ".png")), p, width = w, height = h, dpi = 200)
  msg("  written: figures/%s.png", name)
}

# --- FIG P1: consumption against output, same shock -------------------------
g <- read.csv(file.path(OUTPUT, "p2_lp_lrgdp_unant.csv")); g$series <- "Real GDP"
c <- read.csv(file.path(OUTPUT, "p2_lp_lcons_unant.csv")); c$series <- "Household consumption"
d <- rbind(g, c)
d$series <- factor(d$series, levels = c("Household consumption", "Real GDP"))
p1 <- ggplot(d, aes(h, b, colour = series, fill = series)) +
  geom_hline(yintercept = 0, colour = "grey55", linewidth = .4) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = .13, colour = NA) +
  geom_line(linewidth = .85) +
  scale_colour_manual(values = c("Household consumption" = ACC, "Real GDP" = INK), name = NULL) +
  scale_fill_manual(values = c("Household consumption" = ACC, "Real GDP" = INK), guide = "none") +
  scale_x_continuous(breaks = seq(0, 16, 4)) +
  labs(title = "Consumption moves more than output, and more precisely",
       subtitle = "Response to an unanticipated tax rise worth one per cent of annual GDP",
       x = "Quarters after the tax change takes effect", y = "Per cent",
       caption = paste0("Local projections, 1955-2016. Four lags of the shock and of outcome growth, ",
                        "narrative spending shocks controlled.\n95 per cent bands from Newey-West ",
                        "standard errors at bandwidth h+1.")) +
  theme_p1 + theme(legend.position = "top")
sv(p1, "p2_fig1_cons_vs_gdp")

# --- FIG P2: the state split, the paper's central exhibit -------------------
s <- read.csv(file.path(OUTPUT, "p2_state_split.csv"))
s$state <- factor(ifelse(s$state == "slack", "Economy has slack", "Economy does not"),
                  levels = c("Economy has slack", "Economy does not"))
p2 <- ggplot(s, aes(h, b, colour = state, fill = state)) +
  geom_hline(yintercept = 0, colour = "grey55", linewidth = .4) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = .13, colour = NA) +
  geom_line(linewidth = .85) +
  scale_colour_manual(values = c("Economy has slack" = ACC, "Economy does not" = INK), name = NULL) +
  scale_fill_manual(values = c("Economy has slack" = ACC, "Economy does not" = INK), guide = "none") +
  scale_x_continuous(breaks = seq(0, 16, 4)) +
  labs(title = "The same tax rise costs twice as much in a slack economy",
       subtitle = "Consumption response to an unanticipated tax rise worth one per cent of annual GDP",
       x = "Quarters after the tax change takes effect", y = "Per cent",
       caption = paste0("Slack is unemployment above its own seven-year backward moving average, ",
                        "so it uses only information\navailable at the time. 149 quarters in slack ",
                        "and 99 outside. The difference between the two paths is\ntested separately ",
                        "in Table 3 and is significant at eight of seventeen horizons.")) +
  theme_p1 + theme(legend.position = "top")
sv(p2, "p2_fig2_state")

# --- FIG P3: the incidence gradient, for the work-in-progress section -------
inc <- read.csv(file.path(OUTPUT, "p2_incidence_shares.csv"))
long <- do.call(rbind, lapply(c("income","nic","vat","duty"), function(v)
  data.frame(year = inc$year, share = inc[[v]], tax = v)))
long$tax <- factor(long$tax, levels = c("duty","vat","nic","income"),
                   labels = c("Duties","VAT","National Insurance","Income tax"))
long <- long[!is.na(long$share), ]
p3 <- ggplot(long, aes(year, share, colour = tax)) +
  geom_line(linewidth = .8) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_colour_manual(values = c("Duties" = ACC, "VAT" = "#e08214",
                                 "National Insurance" = "grey45", "Income tax" = INK), name = NULL) +
  labs(title = "Which taxes lean furthest down the income distribution",
       subtitle = "Share of each tax's cash burden paid by the bottom five income deciles",
       x = NULL, y = "Share borne by the bottom half",
       caption = paste0("ONS, Effects of taxes and benefits on household income, 1977-2017. ",
                        "Cash shares, so none reaches 50 per cent:\nricher households pay more of ",
                        "every tax in absolute terms. What the series rank is relative concentration.")) +
  theme_p1 + theme(legend.position = "top")
sv(p3, "p2_fig3_incidence")

msg("\nfigures written to output/figures/")
