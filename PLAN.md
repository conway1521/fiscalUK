# FiscalUK: Project Plan

**Author:** Ale Con (solo-authored; Paul Hubert and Fergus Cumming contactable but not co-authors)
**Last updated:** 31 August 2026
**Status:** planning complete, pipeline build starting

---

## 1. Overall project

Two standalone papers built from one narrative database of discretionary tax policy, following the
identification approach of Romer and Romer (2010, *American Economic Review*) and its UK
implementation in Cloyne (2013, *American Economic Review*).

The project's distinguishing asset is not the exogeneity coding, which exists elsewhere, but the
**timing information attached to each individual measure**: the date it was announced, the date it
took effect, and for the modern period the full multi-year profile of how its revenue impact phases
in. No existing narrative dataset carries all three.

- **Paper 1 (conceptual/descriptive):** the timing of fiscal policy and what it means for households.
- **Paper 2 (empirical):** fiscal multipliers by instrument and by position in the wealth distribution.

Both are aimed at **policy contribution**, not methods or measurement. The target is timely
completion at Q2/Q3 level under a thesis-by-publication route, not Q1 prestige.

Papers 3 and 4 remain signposted future agent-based modelling work and are out of scope here.

---

## 2. Data assets and hard constraints

### What exists

| Asset | Coverage | Content | State |
|---|---|---|---|
| `UK_classification.xlsx` (`Narrative2021`) | Budget 2004 – Autumn 2018 | 334 household measures, 181 exogenous, all with written `reason`, 323 with Treasury `quote` | **Authoritative, complete** |
| `NarrativeClassif.xlsx` | same | 630 measures incl. firm-targeted | Superset, **stale** (34 household rows still "NA") |
| `taxData.xlsx` | FY 2004-05 to 2023-24 | 630 × 20 multi-year costing profiles | Complete, row-aligned to the above |
| `CloyneNarrativeDataset-2.xlsx` (`TaxData`) | Oct 1945 – Apr 2009 | 2,462 measures, 1,324 exogenous, announcement + implementation dates, **single** revenue figure each | Published, ready to use |
| `USA data (1).xlsx` | JCT + Budget tables | 993 + 2,399 rows, multi-year revenue profiles | Extracted, **unclassified** |
| `GER data.xlsx` | Finanzbericht tables | 498 / 334 / 129 rows | Extracted, **unclassified** |

### Constraints that shape the design

1. **No re-coding of narrative measures.** The UK database stops at Autumn 2018 events and stays
   there. Refreshing nominal GDP outturn is permitted; it is not narrative coding.
2. **Cloyne has no phase-in profile.** One number per measure. Therefore the anticipation-lag
   analysis extends to 1945 but the phase-in analysis does not extend before 2004.
3. **Codebooks already match.** Cloyne's `Major`/`Minor` scheme (X/N; DC, DM, DR, ET, IL, LR, SD, SS)
   is exactly the scheme used in the 2004-2018 coding. Chaining was designed in from the start.
4. **Five-year overlap (2004-2009)** between the two datasets. This is the validation gate, not a
   nuisance.
5. **Nominal GDP outturn stops at 2020-21** in `NomGDPgrowth_OBR.xlsx`. Must be refreshed.
6. **Country scope is UK core, US and Germany comparison.** Italy and Spain signposted. France
   dropped (no data exists).

---

## 3. Paper 1 — The timing of fiscal policy and what it means for households

### The claim

Discretionary tax policy in the UK has become **slow**, and the standard narrative approach has not
noticed. Two distinct delays have opened up between a Chancellor speaking and households feeling
anything:

- **Anticipation.** Median announcement-to-implementation lag for exogenous measures rose from
  essentially zero (1950s–1990s) to roughly one year by 2004-2018.
- **Phase-in.** Even after implementation, the average measure delivers only ~43% of its full effect
  in the first year, and the profile differs sharply by instrument (NICs 67% in year one, VAT 11%).

The policy point: **choosing a tax instrument is choosing a time profile, not just a number.** Two
consolidations with identical headline sizes deliver completely different paths of impulse, and
nothing in the Budget documents tells a reader this.

### Why this is not a measurement paper

The contribution is a substantive claim about how fiscal policymaking has changed and what that
implies for households and for anyone estimating fiscal effects. The database is the evidence, not
the product.

### Preliminary UK results (computed 31 Aug 2026, to be rebuilt on the clean pipeline)

Median months from announcement to **half** the full effect delivered, 163 clean exogenous household
measures, 2004-2018:

| Fuel duties | Stamp duty | NICs | Income tax | CGT | IHT | VAT |
|---|---|---|---|---|---|---|
| 8 | 14 | 17 | 22 | 25 | 33 | 34 |

Overall median 22 months. Cross-instrument spread of roughly 4×.

Partisan finding: **no** difference in speed across Labour / Coalition / Conservative once profiles
are correctly anchored. Differences are in **size** (Labour mean £873m vs ~£470m) and **instrument
mix** (Coalition 61% income tax; Conservatives leaned on VAT and CGT).

### Stages and aims

| Stage | Work | Aim / success criterion |
|---|---|---|
| **1.1** | Clean UK pipeline (see §5) | Reproducible measure-level dataset, all bugs in §6 fixed |
| **1.2** | Chain to Cloyne 1945-2003 | One continuous UK lag series 1945-2018 |
| **1.3** | **Overlap validation, 2004-2009** | ✅ **PASSED 31 Aug 2026.** See §9. |
| **1.4** | Explain the trend | Link the rise to identifiable institutional changes (OBR 2010, the 2010 "new approach to tax policy making" consultation framework, multi-year fiscal frameworks, Finance Bill process) |
| **1.5** | US and Germany profiles | Extract multi-year profiles from JCT and Finanzbericht tables. Classification taken from Romer and Romer (2010) and Hayo and Uhl (2014, *Empirical Economics*), **not** re-derived |
| **1.6** | AI classifier validation | Held-out split on the 334 UK measures; report Cohen's kappa. *Gate: kappa below acceptable threshold means the cross-country extension is reported as hand-checked only* |
| **1.7** | Figures and draft | Six figures (§7) |

### Risks

- The secular trend may partly reflect Cloyne's dating conventions rather than real change. **Stage
  1.3 is the gate.** This risk is the single biggest threat to the paper.
- Per-instrument sample sizes are thin in the modern period (IHT n=5, fuel n=8, stamp n=10). Mitigate
  by grouping and by cross-country pooling.
- The ten-year profile window currently clamps at the data edge, creating spurious peaks. Fixed in
  stage 1.1.

---

## 4. Paper 2 — Fiscal multipliers by instrument and by wealth

### The question

If the government raises a pound in tax, how much does the economy contract, and does the answer
depend on **which** tax and on **whose** pound? Can we assess policy impacts across wealth groups
using the narrative approach, and does the conclusion survive a change of estimator?

### The argument

The single-number multiplier hides two things.

1. **Timing.** Paper 1 shows measures are anticipated and phase in. Building the same shock four
   different ways from the same measures — implementation-dated one-off (the Cloyne convention),
   implementation-dated shape-weighted, announcement-dated, announcement-dated with anticipated path
   — tests how much of the literature's disagreement is a dating artefact.
2. **Incidence.** A pound taken from a household with no buffer cuts spending far more than a pound
   from a household with savings. This is the Cumming and Hubert (2023, *Review of Economics and
   Statistics* 105(5), 1304-1320) mechanism, transplanted from monetary policy to fiscal.

### Method

- **Local projections** following Jordà (2005, *American Economic Review*).
- **Proxy-SVAR** using the narrative series as external instrument, following Mertens and Ravn (2013,
  *American Economic Review*).
- Same shock into both. The comparison is the method contribution, delivered cheaply.

### Distributional data (public / standard access, no confidential Bank data required)

| Country | Wealth microdata | Tax incidence by decile |
|---|---|---|
| UK | Wealth and Assets Survey (UK Data Service) | ONS *Effects of taxes and benefits on household income* |
| Germany | ECB Household Finance and Consumption Survey | HFCS + national accounts |
| US | Survey of Consumer Finances | CBO distributional analyses |

The HFCS was designed to be comparable to the SCF, so the three-country trio is unusually well
matched. This was luck, but it is worth exploiting.

### Stages and aims

| Stage | Work | Aim / success criterion |
|---|---|---|
| **2.1** | Four shock series, UK 1945-2018 | Quarterly series, each documented and reproducible |
| **2.2** | Baseline LP multipliers | Replicate Cloyne's headline result on the one-off convention as a sanity check |
| **2.3** | Timing sensitivity | Quantify how much the multiplier moves across the four datings |
| **2.4** | Incidence weighting | Map `tax_type` to decile burden; build distributionally weighted shocks |
| **2.5** | State-dependent / weighted LPs | Test whether shocks landing on constrained households have larger multipliers |
| **2.6** | Proxy-SVAR comparison | Report whether distributional conclusions are estimator-robust |
| **2.7** | Extend to US and Germany | Comparison, not core |

### Risks

- **Sample length.** Chaining to Cloyne is what makes this viable. Without it the modern sample is
  ~60 quarters and too thin for long-horizon LPs.
- **COVID.** 2020-21 is an extreme outlier. Default: estimate to 2019Q4, report 2020+ as robustness
  with explicit treatment.
- **Incidence mapping is an assumption**, not a measurement. Must be stated plainly and varied in
  robustness.

---

## 5. Shared infrastructure: the clean UK pipeline

Built once, used by both papers. Deliverables:

1. `R/01_load.R` — read all sources, no side effects, no absolute desktop paths
2. `R/02_reconcile.R` — merge onto `UK_classification.xlsx` as authoritative; resolve the 34 stale rows
3. `R/03_dates.R` — Excel serial → Date; calendar and fiscal quarter assignment
4. `R/04_profiles.R` — anchor costing profiles on the **implementation fiscal year**; handle the
   60 REVERSE measures and 58 stop dates; no window clamping
5. `R/05_cloyne.R` — chain 1945-2003, harmonise codebooks, produce overlap diagnostics
6. `R/06_series.R` — announcement-dated and implementation-dated quarterly shock series
7. `R/07_figures.R` — ggplot2 figures
8. `renv.lock` + a README that lets someone else run it

Data stays outside the repo at `../Data`; the repo holds code and outputs only.

---

## 6. Bugs in `trimestre2j.R` that must not survive the rewrite

1. **Window selection by value, not index.** Floating-point equality on costing values to locate the
   3yr/10yr window. Misplaces windows silently.
2. **Double deflation.** Costings divided by nominal GDP, then divided again by cumulative nominal
   growth. One normalisation must go.
3. **Twelve hard-coded row-number overrides** (rows 280, 308, …, 572) with no record of which
   measures they are.
4. **Profile misalignment.** Aligning on first non-missing costing captures the Budget year, not the
   implementation year (only 39 of 165 coincide). This materially changed results when fixed.
5. `Qspread` silently uses a global instead of its argument.
6. Plot legends with mismatched label/colour/series counts.
7. First ~1,280 lines (Cloyne fuzzy-matching) become dead once chaining replaces them.

---

## 7. Figures for Paper 1

1. **The money shot.** Textbook assumption (spike at 1.0, year one) against the actual average
   profile (0.43, 0.66, 0.73, 0.76). The whole argument in one image.
2. **The secular trend.** Median announcement-to-implementation lag by decade, 1945-2018.
3. **Ranked bars.** Months from announcement to half effect, by instrument.
4. **Small multiples.** One panel per instrument, mean path with individual measures as faint lines.
5. **Heatmap.** Instruments × quarters since announcement, colour = share of effect delivered.
   Extends to three panels for three countries.
6. **One Budget, decomposed.** Headline number announced vs the path the money actually took.

---

## 8. Overlap validation gate — result (31 August 2026)

**Passed.** The rise in anticipation is a real feature of UK policymaking, not a coding artefact.

On the shared years 2004-2009, household-relevant clean exogenous measures:

| Coding | n | Median lag | p90 | Share >12m | Median size |
|---|---|---|---|---|---|
| Cloyne | 123 | 9.7 | 24.8 | 0.50 | £30m |
| Modern | 45 | 12.5 | 28.4 | 0.51 | £343m |

Three reasons to accept the chain:

1. **The distributions agree.** Share above twelve months is 0.50 against 0.51; p90 is 24.8 against
   28.4. The aggregate 2.8-month gap in medians is composition, not convention: Cloyne's overlap
   sample is 41% excise duties (fast) against the modern 24%, and the modern sample is 44% income
   (slow) against Cloyne's 27%.
2. **Like-for-like by instrument agrees closely.** Social security 28.4 months in *both* codings.
   Property transaction 0.0 in both. Income 12.6 against 14.4.
3. **The trend is visible inside Cloyne's own coding.** His 1990s median is 0.9 months; his
   2004-2009 median is 9.7. The rise does not depend on switching datasets at the splice.

### Handling the granularity difference — resolved

Cloyne itemises ~11 measures per Budget; the modern coding ~4. Diagnosis confirms this is
**granularity, not coverage or a definitional mismatch**: the two cover the same 11 vs 10 Budget
events and the same money per event (£3,897m vs £4,301m in absolute revenue, within 10%). Cloyne
simply splits a Budget into more line items.

**The fix is revenue-weighting, and it is empirically validated rather than assumed:**

| Overlap 2004-2009 | Cloyne | Modern |
|---|---|---|
| Measures per Budget event | 11.2 | 4.5 |
| Unweighted median lag | 8.4 | 12.5 |
| **Revenue-weighted median lag** | **12.6** | **12.6** |

Weighting each measure by absolute revenue drives the two codings to an identical answer. An
unweighted statistic gives a finely-split Budget more votes; weighting makes a five-way split
contribute the same total weight as the unsplit equivalent.

Consequences:

- **Paper 1:** report all three estimators (unweighted, revenue-weighted, event-median). The
  revenue-weighted series is the headline. They disagree about *when* the break occurred, which is a
  finding: large measures acquired long lead times in the 1990s, small ones by the 2010s.
- **Paper 2:** granularity is irrelevant to a summed quarterly shock series. But use **Cloyne's
  published aggregate shock series** from the AER (2013) replication package for 1945-2003 rather
  than re-aggregating his measure file, which removes aggregation-convention risk on his side.

### Cloyne column reliability — a constraint on scope

Cloyne's own README states that columns C and E (**Tax Type** and **Group**) "[have] not been used
for analysis and likely need[] further cleaning - use at your own risk!". Columns F to I
(Major/Minor, the exogeneity coding) are explicitly endorsed.

This matters because the household filter derives from `Group` and the by-instrument split from
`Tax Type`. Therefore:

- **Headline analysis runs on all clean exogenous measures**, resting only on endorsed columns
  (Major/Minor, dates, TaxData, Excluded). The household cut is robustness; results are near-identical.
- **Instrument-level claims are restricted to 2004-2018**, where the coding is ours and sound. Any
  pre-2004 instrument breakdown requires hand-verifying Cloyne's tax types first, which is a scoped
  task rather than an assumption.

## 9. Sequencing

Paper 1 first. It is close to done, needs no macro time series work, no micro data access, and no
econometrics beyond description. Paper 2 depends on Paper 1's shock series and is the larger lift.

Immediate next step: build the pipeline in §5, stages 1.1 through 1.3, and run the overlap
validation gate before committing to the Paper 1 framing.
