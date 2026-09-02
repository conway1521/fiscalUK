# Paper 1: Results Log

**Status as of 2 September 2026.** This log records what was tested, what was found, and
**what was retracted**. Three separate rounds of adversarial review changed the answers, twice
because of my own errors. Read the methodology warning first; it is the most important thing here.

---

## 0. METHODOLOGY WARNING: the answer depends on how you define "timing"

Three operationalisations of the same concept were used across this project. **They give different
answers.** Any draft must report all three and justify the primary choice.

| Outcome | Definition | Problem |
|---|---|---|
| `lag_quarters` | quarters between announcement and implementation | 42% of mass at zero; variance runs 1.04 (1940s) to 11.25 (2010s). Degenerate. |
| `deferred` | implementation falls in a later fiscal year | **Partly artefactual.** 34% of "deferrals" are under 60 days (a March Budget implementing on 6 April). That share drifts from 0.72 in the 1980s to 0.11 in the 2010s, so the measure's *meaning* changes over the sample. |
| `long` | gap of 120+ days | Cleanest. Not sensitive to the Budget-month / tax-year interaction. **Recommended primary.** |

Two further errors compounded this:

1. **Revenue weighting collapsed the sample.** Kish effective n = 251 against a nominal 2,252, an
   89% loss. It was applied to every test in the first pass. It is a descriptive weight for "the
   typical pound", not a sampling weight, and using it for inference destroyed power. **Report
   unweighted for inference, revenue-weighted for descriptive magnitudes.**
2. **Several tests did not match their own stated hypotheses.** Q1 as written in `QUESTIONS.md`
   claims rises "land after the next election"; it was first operationalised as "is the lag longer
   at pre-election Budgets", which is a different statement.

The trend by decade under the recommended outcome (`long`, unweighted):

| 1940s | 1950s | 1960s | 1970s | 1980s | 1990s | 2000s | 2010s |
|---|---|---|---|---|---|---|---|
| 0.16 | 0.04 | 0.13 | 0.18 | 0.15 | 0.36 | 0.39 | **0.65** |

Flat to the 1980s, then a sustained rise from the 1990s. **Note this contradicts the two-step
(1980 and 2010) result obtained on the `deferred` outcome.** The step dates are not robust to the
outcome definition.

---

## 1. Findings that survive

### Q4. Instrument determines timing — GREEN

Budget-event fixed effects, so instruments announced on the same day by the same Chancellor are
compared. Effects relative to excise duties.

| Instrument | on `deferred` | on `long` (recommended) |
|---|---|---|
| Social security | +0.54 (z 11.6) | **+0.385 (z 7.5)** |
| Income | +0.44 (z 9.9) | **+0.128 (z 3.5)** |
| VAT | +0.26 (z 4.4) | +0.096 (z 2.3) |
| Property recurrent | +0.31 (z 2.8) | +0.148 (z 2.0) |
| Corporate | +0.21 (z 4.6) | +0.036 (n.s.) |
| Capital gains | +0.21 (z 3.3) | −0.112 (z −3.3) |

**The magnitudes on `deferred` were inflated by the fiscal-year-boundary artefact.** On the clean
outcome the result is smaller but survives for social security, income tax, VAT and property.
Capital gains reverses sign. Report the `long` column.

### B. The mechanism: instruments run on different clocks — GREEN

Using Cloyne's own sub-type labels rather than a text classifier:

| | Deferred |
|---|---|
| Explicit parameter changes (rates, allowances, thresholds) | 0.668 |
| All other labelled measures | 0.203 |

Within-Budget: **+0.541, z = 10.18**. The opposite of the pre-specified hypothesis, and of an earlier
regex-based test which is superseded.

Interpretation: income tax and NICs are tied to the fiscal year, so a rate or allowance change waits
for 6 April by construction. Excise duties change at the till and take effect on Budget night. This
converts Q4 from a correlation into a mechanism.

Supporting fact: the implementation date has migrated from **6 April to 1 April**. Share on 6 April
falls 0.47 (1970s) to 0.06 (2010s); share on 1 April rises 0.10 to 0.53. Adding clock controls lifts
R² from 0.154 to 0.563 but absorbs only 13% of the 2010s decade effect, so **the clock explains
cross-sectional variation, not the trend**.

### Q1. Tax rises are scheduled past elections — GREEN

Share of measures whose implementation falls on the far side of the next general election:

| | Cuts | Rises |
|---|---|---|
| Announced within 24 months of an election | 0.083 | 0.178 |
| Announced 6-24 months out | 0.024 | 0.101 |

Budget-event fixed effects: +0.052 (z 2.00, p 0.046) and +0.064 (z 2.07, p 0.038).

Separately, on the far margin (2+ fiscal years), rises beat cuts by +0.067 (z 3.64), though that is
not election-specific.

### Q5. Institutional regime — AMBER

On `deferred`, a two-step model (1980, 2010) beats a linear trend on AIC (2935 against 2949), with
both steps at z > 5. **But the step dates do not survive the change of outcome**: on `long` the
transition is in the 1990s. Treat as discussion, not results, until the outcome question is settled.

---

## 2. Genuine negatives, tested to the same standard

### Q2. Crises do not speed policy up — RED, robust

Three treatment definitions, all null or wrong-signed:

- calendar windows, exogenous only: −0.017 (p 0.84)
- crisis response population (endogenous): +0.104 (p 0.19), i.e. *slower*
- emergency years (3+ fiscal events): +0.019 (p 0.71); and within emergency years the additional
  events are not faster

The 2008-09 fact stands descriptively: 93.5% of exogenous crisis measures were deferred against
49.5% in the rest of the decade. Crises are associated with *more* pre-commitment, not less.

### Q3. Delivery is unobservable — RED, data limitation

`stop` and `is_reversal` record pre-announced sunsets, not abandonment: in 3,092 rows there is not
one case where a stop date reflects a later decision. Every REVERSE row is announced on or before its
parent and implements exactly on the parent's stop date.

Alternatives checked and rejected: only 48 measures implement after the sample ends (none announced
before 2015); defer-and-cancel language appears in 1.0% of rows and only from the 2000s; the six fuel
duty escalator cancellations reverse parent measures that are not in the dataset because the
escalator sat in the OBR baseline rather than on a scorecard.

**A scorecard-derived narrative dataset cannot observe quiet abandonment.** The pipeline claim must
be stated as a claim about *scored, dated commitments*.

Bounded statements that are supported: 9.2% of modern measures carry a pre-announced sunset (3.5%
pre-2004); observed abandonment is under 7% of gross modern measure value, as an upper bound whose
denominator is unobserved.

---

## 3. RETRACTIONS

**R1. "The state's capacity to act fast has not diminished." FALSE.** Excise duties, the instrument
cited as evidence, went from 0.046 deferred (1945-79) to 0.231 (1980-2009) to **0.667 (2010+)**, with
both steps significant. Every instrument slowed: corporate 0.00 to 0.67, VAT 0.25 to 0.81,
inheritance 0.00 to 1.00. The slowdown is system-wide, not compositional.

**R2. "Two clean step changes." OVERSTATED.** Decade means concealed severe year-to-year volatility
(1969 = 0.00, 1971 = 0.65, 1978 = 0.04, 1980 = 0.60). And the step dates change with the outcome
variable.

**R3. "The rise is concentrated in 1989-96." ARTEFACT.** That came from the revenue-weighted lag
measure. It does not appear on either corrected outcome.

**R4. "Rises are slower than cuts." INCOMPLETE.** Rises are *bimodal*: more mass at zero **and**
twice the mass at 2+ years (0.198 against 0.098). Cuts cluster at one year. Within a Budget, rises
are 7.9 points *less* likely to cross a fiscal-year boundary at all.

**R5. The regressivity gradient is real but not stable.** Within-Budget, progressive instruments are
+0.242 more likely to be deferred (z 6.67). But the excise-minus-income gap by decade runs 0.21,
0.13, 0.12, 0.33, **0.81**, 0.55, 0.25, **0.18** — it peaked in the 1980s and has narrowed to 1940s
levels. The "poorer households get less warning" story is at its weakest today.

---

## 4. What to settle before drafting

1. **Choose the primary outcome.** Recommendation: `long` (120+ days), with `deferred` and
   `lag_quarters` as robustness. This is the single most consequential open decision.
2. **Re-run Q1 and Q5 on the primary outcome.** Both were established on `deferred`.
3. **Decide how to present the specification history.** Outcome, weighting and three test designs all
   changed after seeing results. Two changes have defences independent of the results; the Q5 step
   dating does not.

---

## 5. RESULTS ON THE ADOPTED PRIMARY OUTCOME (`long`, 120+ days)

Decision taken 2 September 2026: `long` is primary. `deferred` and `lag_quarters` are robustness.
All inference unweighted, clustered on Budget event. Reproduced by `R/06_analysis.R`.

**FACT 1 — the trend.** Share of measures with a 120+ day gap:

| 1940s | 1950s | 1960s | 1970s | 1980s | 1990s | 2000s | 2010s |
|---|---|---|---|---|---|---|---|
| 0.162 | 0.039 | 0.129 | 0.182 | 0.145 | 0.363 | 0.393 | **0.646** |

Flat through the 1980s, sustained rise from the 1990s. No institutional break survives (see §1, Q5).

**FACT 2 — instrument, within Budget.** Budget-event fixed effects, relative to excise duties.
Joint F = 11.7 on 10 df, p = 8.6e-20. R² 0.274 (Budget FE) to 0.314 (+ instrument).

| Social security | Property recurrent | Income | VAT | Capital gains |
|---|---|---|---|---|
| **+0.385** (z 7.5) | +0.148 (z 2.0) | **+0.128** (z 3.5) | +0.096 (z 2.3) | **−0.112** (z −3.3) |

Corporate, oil, property transaction, inheritance and other are not significant.

**FACT 3 — the mechanism, and its limit.** Among measures pinned to early April, the long-gap rate
is **0.32 after a spring Budget and 0.86 after an autumn one** (+0.365, z = 5.14, n = 1,050). The
fiscal-year clock produces a long gap only when the Budget falls late in the year.

But it explains cross-section, not trend: adding calendar controls lifts R² from 0.155 to 0.214 and
absorbs only **9%** of the 2010s decade effect.

**FACT 4 — elections.** Share whose implementation lands after the next election, for measures
announced 6-24 months before it: cuts 0.024, rises 0.101. Within-Budget +0.064 (z = 2.07, p = 0.038),
n = 719 across 47 events.

**NEGATIVE — crises.** Endogenous +0.044 (p = 0.58), exogenous +0.071 (p = 0.65). Both positive,
neither significant. Crises do not speed policy up.

### R6. Sixth retraction

**"Parameter changes are inherently slower, and this is the mechanism." FALSE on the primary
outcome.** It holds on `deferred` (+0.541, z = 10.18) but not on `long` (+0.042, p = 0.46). Parameter
changes are pinned to 6 April, which crosses the fiscal-year boundary but is often a three-week wait
from a March Budget. The mechanism survives only in the conditional form recorded as Fact 3.

## 6. Figures

`R/07_figures.R` writes six figures to `output/figures/`:

| File | Content |
|---|---|
| `fig0_gap_distribution` | Gap histogram, justifying the 120-day threshold |
| `fig1_trend` | Fact 1, five-year blocks |
| `fig2_instruments` | Fact 2, coefficient plot with clustered 95% CIs |
| `fig3_mechanism` | Fact 3, April-pinned measures by Budget season |
| `fig3b_clock_migration` | 6 April to 1 April migration, by decade |
| `fig4_elections` | Fact 4, rises vs cuts landing after the election |
