# FiscalUK: the timing of fiscal policy

A narrative database of UK discretionary tax policy and the timing of its effect on households,
following Romer and Romer (2010, *American Economic Review*) and its UK implementation in Cloyne
(2013, *American Economic Review*).

The distinguishing feature of this database is **timing at the level of the individual measure**:
when it was announced, when it took effect, and for 2004-2018 the full multi-year profile of how its
revenue impact phases in. No existing narrative dataset carries all three.

See [PLAN.md](PLAN.md) for the research plan and the two papers it supports.

## Headline finding so far

UK tax policy has become slow. Announcement-to-implementation lag in months for clean exogenous
measures, by decade:

| Estimator | 1940s | 1950s | 1960s | 1970s | 1980s | 1990s | 2000s | 2010s |
|---|---|---|---|---|---|---|---|---|
| **Revenue-weighted** | 5.4 | -0.1 | 0.0 | 2.2 | 0.7 | 4.3 | 12.6 | 12.4 |
| Unweighted | 0.8 | 0.0 | 0.0 | 0.4 | 0.6 | 0.9 | 3.9 | 12.3 |
| Event median | 0.8 | 0.0 | 0.0 | 0.4 | 0.4 | 2.9 | 3.7 | 12.4 |

Measures that once took effect on Budget day now take roughly a year. The three estimators disagree
about **when** the shift happened, and that is substantive rather than a nuisance: revenue-weighting
is dominated by large measures, so the weighted series shows lead times lengthening from the 1990s,
a decade before the unweighted series notices. Large tax changes were pre-announced first; small ones
followed.

**Use the revenue-weighted series.** Cloyne's itemisation varies four-fold across decades (5.6
measures per Budget in the 1970s, 24.2 in the 1980s), so the unweighted series is confounded by
itemisation practice.

Separately, for 2004-2018 where multi-year profiles exist, the average measure delivers only ~43% of
its full effect in its first year of operation, and the profile differs sharply by instrument.

## Repository layout

```
R/00_setup.R          paths, date and quarter helpers, tax-type taxonomies
R/01_build_uk.R       modern coding 2004-2018, with multi-year phase-in profiles
R/02_build_cloyne.R   Cloyne 1945-2009 (single revenue figure per measure)
R/03_chain.R          chaining plus the overlap validation gate
run_all.R             rebuild everything
```

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
