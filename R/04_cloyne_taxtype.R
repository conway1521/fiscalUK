# 04_cloyne_taxtype.R --------------------------------------------------------
# Make Cloyne's tax-type field usable for a pre-2004 instrument breakdown.
#
# THE PROBLEM: Cloyne's README disclaims his Tax Type (col C) and Group (col E):
# "This has not been used for analysis and likely needs further cleaning - use
# at your own risk!". Columns F to I (the exogeneity coding) are endorsed.
#
# WHAT THE DISCLAIMER IS ACTUALLY ABOUT: inspection shows the problem is (a) an
# internally inconsistent Group column, where 11 of 47 tax types map to more
# than one group, and (b) a messy long tail of 30-odd rare labels. It is NOT
# that "Income" fails to mean income tax. The eight high-frequency labels are
# plain tax names, not judgement calls.
#
# THE APPROACH: keep Cloyne's label only where it is unambiguous, mark the rest
# as unclassified, and report the coverage honestly. This respects the
# disclaimer while retaining 97% of revenue, and reduces the manual review from
# 1,221 rows to about 50.
#
# A keyword re-derivation from description text was tried and rejected: it
# reached only 70% coverage at 77% agreement, and tuning it further would mean
# fitting to the very column it was meant to replace.

source("R/00_setup.R")
msg("== 04_cloyne_taxtype ==")

cl_raw <- rx(file.path(DATA, "CloyneNarrativeDataset-2.xlsx"), sheet = "TaxData")
cl     <- readRDS(file.path(DERIVED, "cloyne_measures.rds"))
tt     <- trimws(as.character(cl_raw$`Tax Type`))

# Labels that are plain tax names. Anything requiring interpretation is excluded
# on purpose: "Business", "Various", "Other", "Levy", "?" and similar.
UNAMBIGUOUS <- c("Income", "Duty", "CT", "VAT", "CGT", "NI", "Stamp duty", "Oil",
                 "Inheritance", "Estate duty", "CTT", "SDLT", "Surtax", "SET",
                 "CCL", "Landfill", "Aggregates", "VED", "Poll tax", "Rates",
                 "Insurance Premium Tax", "Insurance premium tax")

cl$tax_label_ok <- tt %in% UNAMBIGUOUS
cl$tax_h <- ifelse(cl$tax_label_ok, harmonise_tax_type(tt), NA_character_)

s <- cl$timing_sample   # Paper 1 scope, not the narrower Paper 2 sample
msg("clean exogenous rows: %d", sum(s))
msg("with an unambiguous tax label: %d (%.1f%% of rows, %.1f%% of revenue)",
    sum(s & cl$tax_label_ok),
    100 * mean(cl$tax_label_ok[s]),
    100 * sum(abs(cl$peak_value[s & cl$tax_label_ok]), na.rm = TRUE) /
          sum(abs(cl$peak_value[s]), na.rm = TRUE))

msg("")
msg("--- the residual carrying no usable label ---")
res <- sort(table(tt[s & !cl$tax_label_ok], useNA = "ifany"), decreasing = TRUE)
print(res)
msg("rows: %d", sum(s & !cl$tax_label_ok))

# ---------------------------------------------------------------------------
# Manual assignment of the residual, read off the measure descriptions.
# Keyed on description text, NOT row numbers (row-number keys were one of the
# defects in the original script and break silently when rows shift).
#
# Ordered: first match wins. `conf` records how much weight to put on it:
#   high   - the description names the tax outright
#   medium - a reasoned call where the instrument is arguable
#
# These 51 rows carry ~3% of the revenue in the clean exogenous sample, so the
# medium calls move very little. Their effect is checked below.
# ---------------------------------------------------------------------------
overrides <- rbind(
  # --- named outright in the description -----------------------------------
  data.frame(pat = "lan[d]?fill",                      tax = "Excise and duties", conf = "high"),  # "Lanfill" typo in source
  data.frame(pat = "aggregates levy",                  tax = "Excise and duties", conf = "high"),
  data.frame(pat = "vehicle excise duty",              tax = "Excise and duties", conf = "high"),
  data.frame(pat = "increase in fuel|real increase in fuel", tax = "Excise and duties", conf = "high"),
  data.frame(pat = "tobacco",                          tax = "Excise and duties", conf = "high"),
  data.frame(pat = "poll betting|pool betting",        tax = "Excise and duties", conf = "high"),
  data.frame(pat = "^car tax$",                        tax = "Excise and duties", conf = "high"),
  data.frame(pat = "vehicles leased to disabled",      tax = "Excise and duties", conf = "high"),
  data.frame(pat = "information technology agreement", tax = "Excise and duties", conf = "high"),
  data.frame(pat = "zero rate on converted dwellings", tax = "VAT",               conf = "high"),
  data.frame(pat = "alignment of thresholds|^uel from","tax" = "Social security", conf = "high"),
  data.frame(pat = "excess profits tax|^ept$",         tax = "Corporate",         conf = "high"),
  data.frame(pat = "flat rate of profit tax",          tax = "Corporate",         conf = "high"),
  data.frame(pat = "tonnage tax",                      tax = "Corporate",         conf = "high"),
  data.frame(pat = "r&d tax|research and development", tax = "Corporate",         conf = "high"),
  data.frame(pat = "contaminated sites",               tax = "Corporate",         conf = "high"),
  data.frame(pat = "additional capital allowances",    tax = "Corporate",         conf = "high"),
  data.frame(pat = "end income tax relief|employment termination", tax = "Income", conf = "high"),
  # --- administrative / compliance, no single instrument -------------------
  data.frame(pat = "crown's preferential|mutual assistance|review of powers|attachment of debt",
                                                       tax = "Other",             conf = "high"),
  # --- reasoned calls -------------------------------------------------------
  # ITV/broadcasting levies: a charge on franchise revenue, closest to a profits tax.
  # Cloyne groups these inconsistently (Business twice, Consumption once).
  data.frame(pat = "television act|itv levy",          tax = "Corporate",         conf = "medium"),
  # Development Land Tax and Betterment Levy: taxes on realised development land
  # value. No exact home in the taxonomy; nearest economic equivalent is a gain.
  data.frame(pat = "dlt abolition|betterment levy|disposals by non-residents|annual exempt amount|reduction in rate and increase in exempt",
                                                       tax = "Capital gains",     conf = "medium"),
  # Life-assurance company taxation and insurance anti-avoidance.
  data.frame(pat = "life companies|artificial annuities|life insurance policies",
                                                       tax = "Corporate",         conf = "medium"),
  # Anti-avoidance landing on income tax per Cloyne's own grouping.
  data.frame(pat = "rent factoring|reverse premiums",  tax = "Income",            conf = "medium")
)

res_i <- which(s & !cl$tax_label_ok)
mtxt  <- tolower(gsub("[\r\n]+", " ", cl$measure[res_i]))
cl$tax_conf <- ifelse(cl$tax_label_ok, "source-label", NA_character_)
for (k in seq_along(res_i)) {
  hit <- which(vapply(overrides$pat, function(p) grepl(p, mtxt[k], perl = TRUE), logical(1)))
  if (length(hit)) {
    cl$tax_h[res_i[k]]    <- overrides$tax[hit[1]]
    cl$tax_conf[res_i[k]] <- overrides$conf[hit[1]]
  }
}

still <- res_i[is.na(cl$tax_h[res_i])]
msg("")
msg("--- manual assignment of the residual ---")
msg("assigned high confidence:   %d", sum(cl$tax_conf[res_i] == "high",   na.rm = TRUE))
msg("assigned medium confidence: %d", sum(cl$tax_conf[res_i] == "medium", na.rm = TRUE))
msg("still unassigned:           %d", length(still))
if (length(still)) for (k in still)
  msg("    %s | %s", format(cl$budget_date[k]), substr(cl$measure[k], 1, 70))

msg("")
msg("revenue share of the medium-confidence calls: %.2f%%",
    100 * sum(abs(cl$peak_value[s & cl$tax_conf %in% "medium"]), na.rm = TRUE) /
          sum(abs(cl$peak_value[s]), na.rm = TRUE))
msg("coverage after manual assignment: %.1f%% of rows, %.1f%% of revenue",
    100 * mean(!is.na(cl$tax_h[s])),
    100 * sum(abs(cl$peak_value[s & !is.na(cl$tax_h)]), na.rm = TRUE) /
          sum(abs(cl$peak_value[s]), na.rm = TRUE))

review <- cl[res_i, c("budget_date","measure","group","peak_value","tax_h","tax_conf")]
review$cloyne_label <- tt[res_i]
review <- review[order(-abs(review$peak_value)), ]
write.csv(review, file.path(OUTPUT, "cloyne_taxtype_review.csv"), row.names = FALSE)

msg("")
msg("--- resulting instrument mix, pre-2004 clean exogenous ---")
pre <- s & cl$budget_date < as.Date("2004-01-01") & !is.na(cl$tax_h)
print(sort(table(cl$tax_h[pre]), decreasing = TRUE))

saveRDS(cl, file.path(DERIVED, "cloyne_measures.rds"))
msg("")
msg("written: output/cloyne_taxtype_review.csv (%d rows, largest first)", nrow(review))
msg("        cloyne_measures.rds now carries tax_h and tax_label_ok")
msg("")
msg("NOTE: the headline lag analysis does NOT use this field. It is required only")
msg("      for the optional pre-2004 breakdown by instrument.")
