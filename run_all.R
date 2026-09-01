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
source("R/03_chain.R")         # chain + overlap validation gate
source("R/04_cloyne_taxtype.R") # salvage Cloyne tax labels for the optional pre-2004 split

cat("\nDone. Outputs in data-derived/ and output/.\n")
