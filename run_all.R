# run_all.R ------------------------------------------------------------------
# Rebuild the UK narrative dataset end to end.
# Run from the repository root:  Rscript run_all.R
#
# Expects the data directory as a sibling of the repo:
#   FiscalUK/
#     Data/        <- inputs (not version controlled)
#     fiscalUK/    <- this repository

if (!dir.exists("R")) stop("Run from the repository root.")

source("R/01_build_uk.R")      # modern coding, 2004-2018, with phase-in profiles
source("R/02_build_cloyne.R")  # Cloyne 1945-2009, single revenue figure per measure
source("R/04_cloyne_taxtype.R") # salvage Cloyne's disclaimed tax-type field
source("R/03_chain.R")         # chain + overlap validation gate (needs 04's tax_h)
source("R/05_series.R")        # quarterly shock series, 1945Q1-2018Q4
source("R/06_analysis.R")      # Paper 1 results on the 120-day outcome
source("R/07_figures.R")       # Paper 1 figures
source("R/08_robustness.R")    # seam tests, anticipation share, break dating
source("R/09_shock_split.R")   # anticipated/unanticipated series for Paper 2
source("R/10_external_validation.R")  # replicate Fact 1 on Cloyne-Hurtgen-Dimsdale JPE data
source("R/11_external_data.R")        # Paper 2: macro outcomes + interwar measures
source("R/12_paper2_series.R")        # Paper 2: three shock series + estimation panel
source("R/13_lp.R")                   # Paper 2: first-pass local projections
source("R/14_lp_diagnostics.R")       # Paper 2: is the wrong-signed response real?
source("R/15_multipliers.R")          # Paper 2: multipliers overall and by instrument
source("R/16_reconcile.R")            # Paper 2: BLOCKING - our series vs the published ones
source("R/17_reconcile_build.R")      # Paper 2: prices each convention difference
source("R/18_consumption.R")          # Paper 2: household consumption, the primary outcome
source("R/19_incidence.R")            # Paper 2: distributional incidence from public ONS data
source("R/20_state_dependence.R")     # Paper 2: what survives - state-dependent multipliers
source("R/21_p2_figures.R")          # Paper 2: figures

cat("\nDone. Outputs in data-derived/ and output/.\n")
