# 00_setup.R -----------------------------------------------------------------
# Paths, libraries and shared helpers. Sourced by every other script.
# Data lives OUTSIDE the repo; nothing here writes to the data directory.

.libPaths(c(path.expand("~/Rlibs"), .libPaths()))
suppressMessages({
  library(readxl)
})

# --- paths ------------------------------------------------------------------
# All scripts are run from the repository root (see run_all.R).
REPO <- getwd()
if (!dir.exists(file.path(REPO, "R")))
  stop("Run from the repository root: setwd() to the folder containing R/")
DATA <- normalizePath(file.path(REPO, "..", "Data"), mustWork = TRUE)
DERIVED <- file.path(REPO, "data-derived")
OUTPUT  <- file.path(REPO, "output")
dir.create(DERIVED, showWarnings = FALSE)
dir.create(OUTPUT,  showWarnings = FALSE)

# --- helpers ----------------------------------------------------------------
rx <- function(...) suppressWarnings(suppressMessages(readxl::read_excel(...)))

#' Excel serial date strings -> Date. Returns NA for anything unparseable.
excel_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXct")) return(as.Date(x))
  n <- suppressWarnings(as.numeric(x))
  out <- as.Date(rep(NA_real_, length(x)), origin = "1970-01-01")
  ok <- !is.na(n) & n > 1000 & n < 60000
  out[ok] <- as.Date(n[ok], origin = "1899-12-30")
  # fall back to parsing anything that looks like an ISO date string
  bad <- is.na(out) & !is.na(x) & is.character(x) &
    grepl("^\\d{4}-\\d{2}-\\d{2}", as.character(x))
  if (any(bad)) {
    out[bad] <- suppressWarnings(as.Date(substr(as.character(x[bad]), 1, 10)))
  }
  out
}

#' UK fiscal year starting April. Returns the START year (2010 => FY 2010-11).
fiscal_year <- function(d) {
  y <- as.integer(format(d, "%Y")); m <- as.integer(format(d, "%m"))
  ifelse(is.na(d), NA_integer_, ifelse(m >= 4L, y, y - 1L))
}

#' Quarter assignment. Mid-month rule: days after the 15th roll into the next
#' quarter. `basis = "calendar"` starts quarters in January, `"fiscal"` in April.
#' Returns a data.frame(year, quarter) where `year` is the quarter's own year
#' (calendar) or the fiscal-year start (fiscal).
assign_quarter <- function(d, basis = c("calendar", "fiscal")) {
  basis <- match.arg(basis)
  y <- as.integer(format(d, "%Y")); m <- as.integer(format(d, "%m")); dd <- as.integer(format(d, "%d"))
  # shift into the "effective month": second half of a month belongs to the next
  em <- m + as.integer(dd > 15L)
  ey <- y + as.integer(em > 12L)
  em <- ifelse(em > 12L, 1L, em)
  if (basis == "calendar") {
    q <- ((em - 1L) %/% 3L) + 1L
    qy <- ey
  } else {
    # fiscal quarters: Apr-Jun = 1, Jul-Sep = 2, Oct-Dec = 3, Jan-Mar = 4
    fm <- ((em - 4L) %% 12L)           # 0 for April
    q  <- (fm %/% 3L) + 1L
    qy <- ifelse(em >= 4L, ey, ey - 1L)
  }
  data.frame(year = ifelse(is.na(d), NA_integer_, qy),
             quarter = ifelse(is.na(d), NA_integer_, q))
}

#' Harmonised policy group, matching Cloyne's `Group` field.
map_group <- function(tax_type) {
  t <- tolower(trimws(tax_type))
  business <- c("apprenticeship levy","bank levy","bank surcharge","business rates","ccl",
                "climate change levy","digital services tax","diverted profits tax","eu ets",
                "landfill tax","north sea taxes","on-shore ct","onshore ct","pcgos",
                "probate fees","soft drinks levy","ct","corporation tax")
  capital  <- c("cgt","council tax","iht","stamp duty","capital gains","inheritance")
  consump  <- c("alcohol duty","apd","betting","fuel duty","fuel duties","gambling",
                "immigration health surcharge","ipt","pay to stay","tobacco duty","vat","ved",
                "insurance premium tax","air passenger duty","vehicle excise duty")
  out <- rep(NA_character_, length(t))
  out[t %in% business] <- "Business"
  out[t %in% capital]  <- "Capital"
  out[t %in% consump]  <- "Consumption"
  out[t %in% c("income tax","income")]  <- "Income"
  out[t %in% c("nics","ni","national insurance")] <- "Social Security"
  out[t %in% c("other tax","other")] <- "Other"
  out
}

#' Repair UTF-8 read as latin1 ("¬£85,000" -> "£85,000"). 50 modern measure
#' descriptions are affected; cosmetic, but they would surface in any published
#' appendix or dataset release.
fix_encoding <- function(x) {
  x <- gsub("¬£", "£", x)   # ¬£ -> £
  x <- gsub("Â£", "£", x)   # Â£ -> £
  x <- gsub("â", "'", x)  # curly apostrophe
  x <- gsub("â|â", "\"", x)
  x
}

#' Tidy tax-type labels (fixes the capitalisation/plural drift in the source).
tidy_tax_type <- function(x) {
  x <- trimws(x)
  x[x == "income tax"]     <- "Income tax"
  x[x == "Alcohol Duty"]   <- "Alcohol duty"
  x[x == "Business Rates"] <- "Business rates"
  x[x == "Fuel duty"]      <- "Fuel duties"
  x
}

#' Common tax-type taxonomy spanning both codings.
#' Cloyne and the modern coding itemise at different granularity: Cloyne uses a
#' single "Duty" catch-all where the modern data splits fuel / alcohol / tobacco
#' / APD / VED, and labels differ ("NI" vs "NICs", "SDLT" vs "Stamp duty").
#' Any chained analysis by instrument must run on this harmonised field.
harmonise_tax_type <- function(x) {
  t <- tolower(trimws(x))
  out <- rep("Other", length(t))
  out[t %in% c("income", "income tax")] <- "Income"
  out[t %in% c("ni", "nics", "national insurance", "social security")] <- "Social security"
  out[t %in% c("vat")] <- "VAT"
  out[t %in% c("duty", "duties", "fuel duty", "fuel duties", "alcohol duty",
               "tobacco duty", "apd", "air passenger duty", "ved",
               "vehicle excise duty", "betting", "gambling", "ipt",
               "insurance premium tax", "soft drinks levy")] <- "Excise and duties"
  out[t %in% c("cgt", "capital gains")] <- "Capital gains"
  out[t %in% c("iht", "inheritance", "estate duty", "estate")] <- "Inheritance"
  out[t %in% c("stamp duty", "sdlt", "stamp")] <- "Property transaction"
  out[t %in% c("ct", "on-shore ct", "onshore ct", "corporation tax",
               "business rates", "bank levy", "bank surcharge",
               "diverted profits tax", "digital services tax",
               "apprenticeship levy")] <- "Corporate"
  out[t %in% c("oil", "north sea taxes", "prt")] <- "Oil and North Sea"
  out[t %in% c("council tax")] <- "Property recurrent"
  out[is.na(t)] <- NA_character_
  out
}

#' Revenue-weighted median. This is the workhorse for any statistic compared
#' across the Cloyne and modern codings: the two itemise Budgets at different
#' granularity (Cloyne ~11 measures per event, modern ~4) but cover the same
#' money, so weighting by |revenue| makes them commensurable. Validated on the
#' 2004-2009 overlap, where it drives the two codings to the same answer.
weighted_median <- function(x, w) {
  ok <- !is.na(x) & !is.na(w) & w > 0
  if (!any(ok)) return(NA_real_)
  x <- x[ok]; w <- w[ok]
  o <- order(x); x <- x[o]; w <- w[o]
  x[which(cumsum(w) / sum(w) >= 0.5)[1]]
}

msg <- function(...) cat(sprintf(...), "\n", sep = "")
