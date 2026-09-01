# FiscalUK: the timing of fiscal policy

A narrative database of UK discretionary tax policy and the timing of its effect on households,
following Romer and Romer (2010, *American Economic Review*) and its UK implementation in Cloyne
(2013, *American Economic Review*).

The distinguishing feature of this database is **timing at the level of the individual measure**:
when it was announced, when it took effect, and for 2004-2018 the full multi-year profile of how its
revenue impact phases in. No existing narrative dataset carries all three.

See [PLAN.md](PLAN.md) for the research plan and the two papers it supports.

## Headline finding so far

UK tax policy has become slow. Announcement-to-implementation lag in **quarters** for clean exogenous
measures, by decade, using no-retroactive dating:

| Estimator | 1940s | 1950s | 1960s | 1970s | 1980s | 1990s | 2000s | 2010s |
|---|---|---|---|---|---|---|---|---|
| **Revenue-weighted** | 2 | 0 | 0 | 1 | 1 | 2 | **4** | **4** |
| Unweighted | 0 | 0 | 0 | 1 | 1 | 1 | 2 | 4 |

Measures that once took effect in the quarter they were announced now take a full year.

**Two reporting choices matter, and both were arrived at by testing rather than assumption.**

*Quarters, not months.* Day-level lags are contaminated by the tax-year convention: a Budget on 17
April implementing "from 6 April" scores as −11 days, which reads as retroactive but is not
economically meaningful. That convention was far more common early than late (42% of 1950s measures
score negative in days, against 3% in the 1990s), so it varies in the same direction as the trend and
would bias the early decades downward. Cloyne ships a "no retroactive component" implementation
quarter for exactly this reason; the pipeline uses it.

*Revenue-weighted, not unweighted.* Cloyne's itemisation varies four-fold across decades (5.6
measures per Budget in the 1970s, 24.2 in the 1980s), so an unweighted median is partly measuring
bookkeeping practice. Weighting by absolute revenue makes a five-way split count the same as the
unsplit equivalent, and is validated on the 2004-2009 overlap where it drives the two independent
codings to the same answer.

Separately, for 2004-2018 where multi-year profiles exist, the average measure delivers **40%** of its
full effect in its first year of operation, and the profile differs sharply by instrument. That figure
is computed on measures with a complete ten-year window; including truncated windows inflates it to
43%, because a censored peak makes the first year look larger than it is.

## Repository layout

```
R/00_setup.R          paths, date and quarter helpers, tax-type taxonomies
R/01_build_uk.R       modern coding 2004-2018, with multi-year phase-in profiles
R/02_build_cloyne.R   Cloyne 1945-2009 (single revenue figure per measure)
R/03_chain.R          chaining plus the overlap validation gate
R/04_cloyne_taxtype.R salvages Cloyne's disclaimed tax-type field
R/05_series.R         quarterly shock series, 1945Q1-2018Q4
run_all.R             rebuild everything
```

The headline output is `output/uk_tax_shocks_quarterly.csv`: two quarterly narrative tax shock
series for 1945Q1-2018Q4 as a share of nominal GDP, one dated by implementation (the convention in
the literature) and one by announcement. Their correlation is only 0.42, which is the point.

Sanity check on the largest shocks: 1979Q3 at +2.04% of GDP is the VAT unification to 15%; 1979Q4 at
-1.14% and 1988Q2 at -1.23% are the basic-rate cuts of those Budgets. The series puts recognisable
events in the right quarters with the right signs.

Inputs are **not** version controlled and live in a sibling directory:

```
FiscalUK/
  Data/        inputs
  fiscalUK/    this repository
```

## Running it

```bash
Rscript run_all.R
```

Requires R with `readxl`. Outputs land in `data-derived/` (measure-level datasets) and `output/`
(tables). Both are gitignored.

## Data notes

- `Budgetary data/UK/UK_classification.xlsx` sheet `Narrative2021` is the **authoritative**
  classification: 334 household measures, 181 exogenous, all with a written justification and most
  with a verbatim Treasury quote. `NarrativeClassif.xlsx` is a 630-row superset but is stale for 34
  rows; the pipeline resolves this automatically.
- Policy **events run Budget 2004 to Autumn 2018**. The 2004-2023 range in the costing tables is the
  costing horizon, not the event window.
- Cloyne records **one** revenue figure per measure, not a profile. The anticipation-lag analysis
  therefore extends to 1945; the phase-in analysis only to 2004.
- The two datasets overlap from March 2004 to April 2009. `R/03_chain.R` uses this to validate that
  the secular trend is not an artefact of differing coding conventions.

## Status

Pipeline complete and validated. Paper 1 in drafting. See [PLAN.md](PLAN.md).
