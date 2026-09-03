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

Flat through the 1980s, sustained rise from the 1990s. **Superseded in part:** the claim that
no institutional break survives was made on a data-driven break search over the `deferred`
outcome. A targeted search on `long` puts the break at 1993, and it is large and significant.
See §7 and R7.

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
announced 6-24 months before it: cuts 0.031, rises 0.125. Within-Budget +0.075 (z = 2.37, p = 0.018),
n = 751 across 49 events. *(Updated 3 Sept 2026: the 2019 general election was missing from the date
list, which silently dropped the 56 measures announced after June 2017. Adding it strengthens the
result from +0.064, p 0.038.)*

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

---

# 7. SEAM AND ANTICIPATION TESTS (3 September 2026)

Run by `R/08_robustness.R`. Two questions were outstanding before drafting: whether Fact 1 is an
artefact of the Cloyne-to-modern data join, and whether the timing change matters to the revenue
impulse rather than only to a count of measures.

## 7.1 The seam is clean. Fact 1 survives.

Six tests, all passed.

| Test | Result |
|---|---|
| **Announcement convention** | 91.6% of Cloyne rows and 88.8% of modern rows date announcement to the Budget day itself. Same object. |
| **2004-09 overlap, same 11 Budgets** | Cloyne 0.460 long, modern 0.496 unweighted; 0.627 against 0.615 revenue-weighted. Paired within-event difference −0.021, t = −0.46. |
| **Itemisation** | Cloyne splits those Budgets 2.8x more finely (32.0 measures per event against 11.5) and still returns the same long-gap share. |
| **Weighting** | Trend holds unweighted (0.162 to 0.646), event-level (0.195 to 0.618) and revenue-weighted (0.285 to 0.740). |
| **Composition** | Holding the 1945-79 instrument mix fixed changes the 2010s rate by 0.019. The rise is within-instrument, not a change in which taxes are used. |
| **Granularity-proof** | The 20 largest measures of each decade: 0.25, 0.10, 0.20, 0.30, 0.20, 0.70, 0.80, 0.80. Equal count per decade, same result. |

**Decisive:** the post-1990 step is +0.206 (z 5.18) inside Cloyne's coding alone, and +0.175
(z 4.43) with instrument controls. No seam can produce a break that sits entirely on one side of it.

Retroactivity, the one remaining asymmetry (Cloyne's implementation date includes retroactive
components, ours does not), moves the decade rates by at most 0.021.

## 7.2 The anticipation share of the impulse

Revenue-weighted share of the tax impulse, dated by implementation, announced 120+ days ahead.
Measures implementing after 2019 are dropped as end-of-sample long-lead survivors.

| Sample | 1945-79 | 1980-99 | 2000-19 |
|---|---|---|---|
| All measures | 0.184 | 0.384 | **0.699** |
| Household exogenous (the Paper 2 series) | 0.202 | 0.364 | **0.815** |

Revenue-weighted lead time rises from 102 to 322 days (all measures) and 131 to 383 days
(household exogenous).

**The sharper form.** Splitting the quarterly impulse into foreseen and unforeseen components
(household exogenous, % of nominal GDP):

| Period | mean abs. foreseen | mean abs. unforeseen | foreseen share |
|---|---|---|---|
| 1945-79 | 0.041 | 0.077 | 0.348 |
| 1980s | 0.049 | 0.083 | 0.373 |
| 1990-2003 (Cloyne only) | 0.051 | 0.030 | 0.630 |
| 2004-18 (modern only) | 0.030 | 0.015 | 0.665 |

**What disappeared is the surprise.** The unforeseen impulse falls by a factor of about five on both
samples, and the standard deviation of the unforeseen series falls from 0.24 to 0.03% of GDP.
Crucially the collapse happens between the 1980s and 1990-2003, a window that is entirely Cloyne's
coding, so it cannot be an artefact of the modern data.

**Corrected 3 September 2026 (R8).** An earlier version of this section claimed the foreseen impulse
had been "the same size for seventy years". It has not. It is flat to 2003 (0.041, 0.049, 0.051) and
then falls to 0.030. The foreseen *share* still rises monotonically because the unforeseen component
falls much faster, and that is the claim the evidence supports. The total impulse shrinks too.

Caveat: on the all-measure sample the foreseen share is 0.602 then 0.567 across 2004, so the final
step appears only on the household exogenous sample. The 1980s-to-1990s collapse appears on both.

**Implication for Paper 2 and for the literature.** A multiplier estimated on a pooled 1945-2018 UK
narrative series is averaging over two different objects: a pre-1990 impulse that was mostly a
surprise and a post-2000 one that mostly was not.

## 7.3 The pipeline

Stock of announced-but-not-yet-in-force tax change at each quarter end:

| Period | median % GDP | mean count pending |
|---|---|---|
| 1945-79 | 0.026 | 2.0 |
| 1980s | 0.062 | 4.6 |
| 1990-2003 | 0.816 | 17.7 |
| 2004-18 | 0.991 | 26.4 |

Report the median, not the mean: the mean is dominated by VAT, announced March 1971 and in force
April 1973, which alone put roughly 11% of GDP in the pipeline. That measure is the point in
miniature. Long pre-announcement was once exceptional enough to be a landmark; it is now routine.

## 7.4 R7. Seventh retraction

**"There is no institutional break; the drift has no identifiable start." FALSE.** A grid search
over single break dates on the primary outcome maximises fit at **1993** (R² 0.142), and the annual
series is sharp: 1992 = 0.047, 1993 = 0.372, 1994 = 0.434, 1995 = 0.600. The earlier null came from
searching on `deferred`.

Local tests, eight years either side of each candidate:

| Candidate | Year | Estimate | z | p |
|---|---|---|---|---|
| Unified autumn Budget, first held Nov 1993 | 1993 | **+0.288** | 6.96 | <0.0001 |
| Return to a spring Budget | 1997 | +0.026 | 0.36 | 0.72 |
| Tax policy making framework | 2010 | **+0.257** | 3.20 | 0.001 |
| Draft-clause consultation | 2011 | +0.157 | 1.80 | 0.072 |
| Single fiscal event | 2017 | +0.108 | 1.20 | 0.23 |

Two steps, 1993 and 2010, both at named reforms of the Budget process.

**This is not purely a calendar effect.** Restricting to spring Budgets only, the trend still runs
0.143 (1980s) to 0.275 (1990s) to 0.657 (2010s), and the post-1990 step is +0.275 (z 5.56). The
autumn-minus-spring season gap runs +0.21 (1990s), +0.17 (2000s) and **−0.03 (2010s)**, so the
calendar channel has closed while the level kept rising. *(Corrected 3 Sept 2026: an earlier version
quoted a peak gap of 0.357 in the 1980s. That cell rests on **two** autumn measures from a single
Budget. Autumn Budgets were rare before 1993, so only the 1990s onward are reportable. See
`output/season_gap.csv`, which now carries cell counts.)*

**Consequence for the framing.** "Fiscal forward guidance by accident, with no institutional break"
is not supportable. The defensible claim is that lead times lengthened at two deliberate reforms of
the Budget process, both pursued for scrutiny and legal certainty, and that neither was assessed for
its consequences for stabilisation or for households. Unchosen consequences of chosen reforms, not
drift.

**Sourced 3 September 2026. See `SOURCES.md`.** Both reforms are confirmed from Hansard and from
HM Treasury and HMRC documents. The unified Budget was announced by Lamont on 10 March 1992 ("next
year's Budget will be the last spring Budget"), brought forward to November on 16 March 1993, and
first delivered by Clarke on 30 November 1993. The 2010 reform is Budget 2010 para 1.64 and the
accompanying *Tax policy making: a new approach* (HM Treasury and HMRC, June 2010), with the
consultation response of 9 December 2010 and the Tax Consultation Framework of 31 March 2011.

Two findings from the sourcing that strengthen the framing:

1. **The Treasury states the lead time as a target.** *The new Budget timetable and the tax policy
   making process* (HM Treasury and HMRC, 6 December 2017): "most policies will be announced at
   least 16 months before they come into effect at the start of the next tax year." The paper does
   not have to infer that lead times lengthened by design; the target is published, and 16 months is
   far beyond the 120-day threshold.
2. **No stated rationale is macroeconomic.** Across 1992, 2010, 2016 and 2017 the justifications are
   parliamentary and external scrutiny, predictability, stability, simplicity, and giving taxpayers
   time to prepare. Not one document argues about stabilisation, the anticipation content of the
   fiscal impulse, or households unable to act on notice.

Also note that the 1997 reversion to a spring Budget is the one candidate the tests **reject**
(+0.026, p 0.72). The Budget moved back but the long-gap share did not, which is further evidence
that the 1993 step was not purely a calendar effect.

---

# 8. THE SPLIT SHOCK SERIES, AND A BLOCKING DEFECT IN THE PAPER 2 SAMPLE

Built by `R/09_shock_split.R`. Three series, because an anticipated measure is two events:
`ant_news` dated at announcement, `ant_imp` dated at implementation, and `unant` dated at
implementation, which is also its announcement. A local projection or proxy-SVAR takes `ant_news`
and `unant` as separate instruments; `ant_imp` is the same money as `ant_news` moved forward in time
and must never enter the same regression. Written under two thresholds, the 120-day Paper 1 outcome
and a 2-quarter rule for quarterly estimation, which agree on 96.6% of measures.

## 8.1 The pooling test fails, and one row is responsible

Section 7.1 cleared the Cloyne-to-modern seam for measure counts. A shock series sums money, so the
test had to be redone on revenue, using the 2004-09 window where both codings independently record
the same Budgets.

| Spec | Cloyne | Modern | Correlation |
|---|---|---|---|
| As coded | +0.092% GDP | **−0.398% GDP** | **−0.02** |
| 2007 package made consistent | +0.092% GDP | +0.396% GDP | **0.63** |

Gross revenue agrees to 0.3% and the anticipation share to 0.066 either way. Only the *signed*
series disagrees, and the cause is a single measure.

**The March 2007 income tax package.** The basic rate was cut from 22p to 20p and the 10p starting
rate abolished, both announced in the same Budget and both effective 6 April 2008. Cloyne codes both
exogenous. The modern coding codes the rate cut exogenous (−12,878m) and the starting-rate abolition
**endogenous** (+11,529m), which drops the offsetting leg from the Paper 2 sample and leaves a
spurious −0.82% of GDP shock in 2008Q2 where Cloyne has +0.04.

That one row is **13% of all gross revenue in the modern half of the Paper 2 sample**.

**Paper 1 is unaffected.** It runs on `timing_sample`, which ignores exogeneity entirely. Nothing in
sections 1 to 7 changes.

## 8.2 The audit, adjudicated 3 September 2026

**The 27-group audit was wrong and is withdrawn.** It flagged any Budget event / tax type /
implementation date group containing both exogenous and endogenous rows. But Cloyne's `Major` (X/N)
is a **deterministic function** of his `Minor` motive code, in both codings, with zero exceptions:

| Exogenous | Endogenous |
|---|---|
| LR (long run), IL (ideological), DC (deficit consolidation), ET | DM (demand management), DR, SD (spending driven), SS |

So a Budget containing a long-run reform and a spending-driven measure on the same day is the
taxonomy working, not failing. 26 of the 27 were false positives from a coarse grouping key.

**The right test** uses the 2004-09 window, where the same measures are coded twice. Matching on
measure text within Budget event gives 46 confident matches:

| | Modern N | Modern X |
|---|---|---|
| **Cloyne N** | 16 | 8 |
| **Cloyne X** | 2 | 20 |

**Agreement 78.3% (36 of 46).** Revenue-weighted disagreement is 28.7% of matched gross revenue, but
**74% of that is the single 2007 row**, which is now overridden. Residual after the override: **7.5%**.

**The 2007 override is now properly justified.** It is not a judgement call. Cloyne codes that exact
measure exogenous (IL); we coded it endogenous (SD, "spending driven") on the stated reason that it
"funds parts of the next stage". Under Romer and Romer (2010), which Cloyne (2013) follows,
spending-driven means offsetting a change in *government spending*. This measure funds a *tax cut*,
so the category does not apply, and the published peer-reviewed coding takes precedence. Of 49
modern SD rows with a stated funding rationale, this is the only one that funds a tax measure rather
than spending.

**The residual disagreement is systematic: anti-avoidance.** Five of the ten disagreements are
anti-avoidance measures, every one Cloyne endogenous (SD) against ours exogenous (IL). Cloyne codes
17% of his anti-avoidance rows exogenous; we code 31%. That is a convention difference, not an error,
and neither convention is wrong.

**Recommendation: do not recode.** The stakes are small, 0.5% of Cloyne's exogenous revenue and 3.3%
of ours, and overriding a published classification wholesale is worse than documenting the
divergence. Paper 2 should report results with and without anti-avoidance measures as robustness.
Anti-avoidance is also a modern phenomenon (0.0% of measures before 1960, 10.8% in the 2000s), so it
loads on exactly the period where the two codings meet.

Written to `output/exogeneity_audit.csv`.

## 8.3 A second warning for Paper 2

Standard deviation of the quarterly series, % of nominal GDP:

| Era | News (announcement-dated) | Unanticipated |
|---|---|---|
| 1945-79 | 0.318 | 0.240 |
| 1980-99 | 0.146 | 0.177 |
| 2000-18 | 0.082 | **0.044** |

The news and unanticipated series correlate at −0.011 over the full sample, which is what separate
instruments need. But the unanticipated series loses four-fifths of its variance by the 2000s. **A
proxy-SVAR identified off unanticipated tax changes has very little post-2000 variation left to work
with.** That is the same fact as section 7.2 seen from the estimation side, and it is a constraint on
Paper 2's design rather than a defect.

## 8.4 Next

1. Adjudicate the remaining 26 groups in `output/package_consistency_audit.csv` against Treasury
   documents. The 2007 case is done.
2. Source the 1993 unified Budget and 2010-11 tax policy making reforms to HM Treasury or HMRC
   documents (§7.4), since the framing now rests on them.
3. Then Paper 1's introduction and abstract.

---

# 9. BUG REVIEW, 3 SEPTEMBER 2026

Full adversarial pass over Facts 1-4 and sections 7-8. Three defects found and fixed, two concerns
tested and cleared, one claim retracted.

## Fixed

**F1. The season-gap figure rested on two observations.** §7.4 quoted an autumn-minus-spring gap
"peaking at 0.357 in the 1980s". That decade has **2** autumn measures, from one Budget. Autumn
Budgets were rare before 1993 (n = 20, 3, 11, 17, 2 for the 1940s to 1980s, against 221, 133, 133
after). `R/08_robustness.R` now prints cell counts and a `reportable` flag at n >= 30, and writes
`output/season_gap.csv`. The substantive point is unchanged: among reportable decades the gap runs
+0.21, +0.17, −0.03, so the calendar channel closes while the level keeps rising.

**F2. The 2019 general election was missing from Fact 4.** The election date list ended at
2017-06-08, so the 56 measures announced after it got `next_el = NA` and dropped out silently.
Adding 2019-12-12 **strengthens** the result: +0.075 (z 2.37, p 0.018) on n = 751 across 49 events,
against +0.064 (p 0.038) on n = 719 before.

**F3. Two sections were computed on different data.** The 2007 package override was applied inside
`R/09_shock_split.R` only, so §7.2 (built by `08_robustness.R` from the unfixed chained file)
disagreed with §8 (built by `09` from the fixed one). The override now lives in **`R/03_chain.R`**,
which recomputes `usable` and writes `endo_exo_raw` and `endo_exo_over` so the pre-override coding
stays recoverable. Everything downstream now sees one classification. Effects: the Paper 2
anticipation share for 2000-19 moves 0.795 to 0.815, and `sd_news` for 2000-18 moves 0.144 to 0.082.

## Tested and cleared

**C1. Cluster-robust inference with more parameters than clusters.** Fact 2 has K = 128 parameters
(10 instruments + 118 Budget fixed effects) against G = 118 clusters, so the cluster-robust variance
matrix is rank deficient and CR1 standard errors are suspect in principle. Two checks:

| | CR1 est | CR1 se | Pairs-bootstrap sd (600 reps) | Within-transformed se |
|---|---|---|---|---|
| Social security | +0.385 | 0.051 | 0.051 | 0.050 |
| Income | +0.128 | 0.037 | 0.037 | 0.036 |
| Capital gains | −0.112 | 0.034 | 0.035 | 0.033 |
| VAT | +0.096 | 0.042 | 0.043 | 0.041 |

Demeaning by Budget event reduces K to 10 against G = 118 and returns identical point estimates and
near-identical standard errors. Fact 2 is not an artefact of the estimator.

**C2. Decade cells driven by single Budget events.** The largest single event accounts for 11-25% of
a decade's measures (25% only in the 1940s, n = 80). No decade result rests on one Budget.

## R8. Eighth retraction

**"The pre-announced impulse has been the same size for seventy years." FALSE.** On the household
exogenous sample it is flat to 2003 (0.041, 0.049, 0.051% of GDP) and then falls to 0.030. The claim
that survives is the one about the surprise: the unforeseen impulse falls by a factor of about five,
much faster than the foreseen one, which is why the foreseen *share* rises monotonically. The total
impulse shrinks as well, and the paper must say so.

---

# 10. THE DISTRIBUTIONAL QUESTION, TESTED (3 September 2026)

Run by `R/08_robustness.R` Part D. The framing rests on the idea that timing has consequences for
people. That is checkable, and it does not say what we hoped.

Incidence groups: **regressive** = excise duties and VAT; **progressive** = income tax, CGT,
inheritance tax. NICs excluded from both, being contributory and regressive at the top.

| Era | Count gap (within Budget) | z | p | Revenue-weighted gap |
|---|---|---|---|---|
| 1945-79 | −0.040 | −0.76 | 0.45 | −0.031 |
| 1980-99 | **+0.139** | 2.66 | 0.008 | +0.140 |
| 2000-19 | +0.024 | 0.46 | **0.64** | **+0.262** |

**On the inference-valid count basis, there is no significant gap today.** The gradient was real in
1980-99 and has closed. This confirms R5 on the primary outcome; my expectation that it had widened
was wrong.

On the descriptive revenue basis the gap widens throughout, to 0.262. Both statements are true and
they are not the same statement. **The paper must not quote the revenue gap as though it were
tested.**

The honest version, share arriving with under 30 days' notice:

| Era | Regressive | Progressive | Gap |
|---|---|---|---|
| 1945-79 | 0.829 | 0.833 | −0.004 |
| 1980-99 | 0.736 | 0.694 | +0.042 |
| 2000-19 | 0.432 | 0.328 | **+0.104** |

Today 43% of regressive tax changes arrive with under a month's notice against 33% of progressive
ones. Real, modest, quotable.

## What this means for the framing

**"Poorer households get less warning" is not supportable as a headline finding.** The instrument
gradient does not carry it.

The distributional argument that *is* available runs the other way, and Paper 1 can only establish
its premise, not test it: notice is worth something only to a household that can act on it, which
requires savings, income flexibility or advice. The quadrupling of lead time is therefore a large
change in something whose value is unevenly distributed. **Testing that is Paper 2's job**, and
Paper 1 should state it as the motivation for Paper 2 rather than as a result.

What Paper 1 does establish, and can say boldly: notice is not randomly assigned. It depends on the
instrument (Fact 2), on where the Budget falls in the calendar (Fact 3), and on the electoral cycle
(Fact 4). The only systematic, deliberate-looking use of timing in the whole sample is the political
one.

---

# 11. PAPER 1 CLOSED, 3 September 2026

Draft in `PAPER1.md`: abstract, introduction and all ten sections populated with verified numbers.
The abstract leads with the pooled-multiplier point, which is the only claim in the paper that
obliges another researcher to change what they do.

**Analysis is closed.** No further estimation is planned for Paper 1. Everything reproduces from
`run_all.R`, which now runs 01 through 09 clean.

**What closing means, and what it does not.** The results are settled. Three things remain before
submission and are writing or verification tasks, not analysis:

1. ~~Check every institutional quotation against the original document.~~ **DONE 3 September 2026.**
   All quotations verified against raw source text (Hansard fetched and string-matched, Budget 2010
   parsed from the PDF, GOV.UK pages fetched). Volume and column references now recorded. Three
   outcomes worth noting:
   - **A misattribution was caught.** "The first unified Budget this century" was said by Rhodri
     Morgan, an opposition backbencher, in the debate following the 30 November 1993 Budget. Clarke's
     own statement never uses the word "unified". Do not attribute it to the Government.
   - **The 9 December 2010 statement is verified** (David Gauke: measures confirmed "at least three
     months ahead of publication of the Bill"), via the Internet Archive, because Parliament's
     publications site returns 403. Confirm against Hansard in a library before submission.
   - **The White Paper command number could not be verified.** No Cm number appears in the Hansard
     record. Cm 1867 is dropped from the paper; the White Paper is cited on Lamont's own words
     ("I am publishing today a White Paper on the mechanics of this change").
2. Position against the fiscal foresight literature in the first two pages. Leeper, Walker and Yang
   (2013), Mertens and Ravn, Romer and Romer (2010), Cloyne (2013). Without this a referee says the
   result is already known. Full citations must be added; the draft names them only.
3. Convert `PAPER1.md` to the target journal's format. Fiscal Studies is the intended home.

**Standing caveats to carry into the draft**, all already in the text: the outcome definition was
chosen after seeing results on alternatives; the election result is the weakest finding; the
distributional claim is motivation for Paper 2 and not a result here; delivery of announced policy is
unobservable in this source.

**Paper 2 inherits** the split shock series (`output/uk_tax_shocks_split.csv`), the constraints in
§8.3 and the memory `fiscaluk-paper2-constraints`, and the anti-avoidance coding divergence in §8.2,
which is to be handled as robustness rather than by recoding.

---

# 12. A COMPETING DATASET (found 3 September 2026, during literature verification)

While verifying references for the literature section, Crossref returned work that changes the
competitive position and must be addressed before submission.

**Cloyne's team has extended the UK narrative record to a century.**

- Cloyne, Dimsdale and Postel-Vinay (2023), *Review of Economic Studies*, extend the narrative
  account back into interwar Britain.
- Hürtgen, Cloyne, Dimsdale and Postel-Vinay (2024), SSRN 4909051, publish **"Tax Changes in the
  United Kingdom 2009-2020: A New Narrative Account and Dataset"**.
- Cloyne, Hürtgen and Dimsdale (2025), *Journal of Political Economy* 133(2), 568-603, use a
  roughly 1918-2020 UK narrative dataset.

**Why this matters.**

1. **Overlap.** Their 2009-2020 extension overlaps our own 2004-2018 coding. A referee will ask why we
   coded our own rather than using theirs. Our coding predates the extension, which is a real answer,
   but it has to be stated rather than left implicit.
2. **Opportunity, and possibly a large one.** If their extension records announcement dates as
   Cloyne's original does, then the modern half of Paper 1 could be rebuilt or cross-validated on an
   independent, peer-reviewed coding. That would dispose of the seam question for the recent period
   entirely, and could extend the sample to 2020. The interwar data could extend it backwards.
3. **Urgency.** A team holding a century-long UK narrative dataset, publishing in the JPE, could run
   the anticipation-content exercise in this paper without difficulty. The measurement contribution
   here is not protected. This argues for moving quickly rather than polishing.

**Action before submission.** Obtain the 2024 dataset and check whether it carries announcement dates.
If it does, cross-validate our 2004-2018 coding against it exactly as §7.1 cross-validated against
Cloyne's original, and report the agreement. If it does not, say so, because that absence is itself
the justification for our own coding and turns a weakness into the paper's reason for existing.

This does not change any result in §1 to §10.

---

# 13. EXTERNAL VALIDATION, AND A CORRECTION TO THE NOVELTY CLAIM (3 September 2026)

Run by `R/10_external_validation.R`. Following up §12 turned the competing dataset into the paper's
strongest robustness check, and also corrected an overclaim of mine.

## 13.1 The finding replicates on data we did not build

The replication package for Cloyne, Hürtgen and Dimsdale (2025, *JPE* 133(2), 568-603), at Harvard
Dataverse doi:10.7910/DVN/JVNAPS, publishes their quarterly exogenous shock series in two variants:
a baseline of all narrative shocks, and an **unanticipated** variant restricted to measures
implemented inside Cloyne's 90-day window. The ratio is an anticipation share, built by other
researchers, on their coding, over a century, using their threshold.

| Era | Theirs (90-day) | Ours (120-day) |
|---|---|---|
| 1920-44 | 0.022 | not covered |
| 1945-79 | 0.248 | 0.184 |
| 1980-99 | 0.420 | 0.384 |
| 2000-20 | **0.697** | **0.699** |

Agreement in shape and level, closest where the sample is densest. Their decade series carries the
break too: **0.286 in the 1980s against 0.614 in the 1990s**, which is where §7.4 dates it
independently from measure-level data. Their longer sample strengthens the result: in 1920-44 the
anticipation share was 0.022, so on a century view it has risen from almost nothing to roughly
four fifths.

**What this settles.** Fact 1 and §7.2 are not artefacts of our coding, our threshold, our splice or
our sample period. The single most likely referee objection is now answered pre-emptively, with the
objector's own data.

## 13.2 R9. Ninth retraction, on priority rather than on a result

**"This paper introduces the distinction between anticipated and unanticipated tax measures." FALSE,
and it was never true.** Cloyne (2013), following Mertens and Ravn (2012), classifies a tax change as
anticipated when the implementation lag exceeds 90 days. Our 120-day threshold is a variant of an
established convention, widened to exclude the March-Budget-to-6-April case, not an invention.

The paper's introduction and §2.2 now say so explicitly. The contribution is narrower and still real:
**treating the incidence of anticipation as a time series**, showing it is systematically distributed
across instruments and the calendar, and dating its movement to identifiable reforms. The ingredients
sat in a top-five journal's replication archive and were used there as a robustness check rather than
examined, which is the gap stated as concretely as it can be.

## 13.3 Their package does not supersede our measure-level work

The Dataverse package ships **aggregated quarterly series**, not measure-level announcement dates.
It therefore cannot produce Facts 2, 3 or 4, all of which need the measure. That is the honest answer
to "why did you not use their data": for the aggregate quantity we now do, and for the measure-level
results it does not exist in public form. Obtaining the measure-level 2024 dataset (SSRN 4909051)
remains worth doing, since it would allow direct cross-validation of the modern half.

## 13.4 Hansard verification closed

The 9 December 2010 ministerial statement was checked against **three independent Internet Archive
captures (2013, 2020, 2025)**, all containing Gauke's name and the three-month wording. The library
visit is no longer necessary and the caveat is downgraded in `SOURCES.md` and `PAPER1.md`.

## 13.5 Journal fit

Fiscal Studies: 7,500 words preferred, abstract capped at 200, JEL required, .docx or LaTeX via
Research Exchange, single anonymised review, full replication materials required. The draft is
roughly 5,000 words with a 202-word abstract, so there is room to expand and the replication
requirement is already met by `run_all.R`.

---

# 14. PAPER 1 CLOSED FOR REAL, 3 September 2026

`paper/fiscaluk-paper1.tex` compiles to a 13-page PDF via `latexmk`. Article class, natbib
author-date with the `agsm` style, booktabs tables, the six figures from `output/figures`, and
`paper/references.bib` holding twelve references all verified against Crossref before citing.

**Fiscal Studies fit.** They want at most 7,500 words, a 200-word abstract and a JEL classification.
The draft runs to roughly 3,800 words of body text with a 202-word abstract, so the constraint is
room to expand rather than pressure to cut. Porting is a matter of dropping in their class file.

**Style.** Written to match the prose of the regional development paper: British English in the
paper, no em dashes anywhere, citations carried inline, no bulleted prose. Checked mechanically for
em dashes and for the usual tells; median sentence 26 words.

**Provenance stated where it should be.** The anticipated and unanticipated distinction is credited
to Cloyne (2013) following Mertens and Ravn (2012), the 120-day threshold is presented as a variant
of their 90-day rule with the reason for widening it given, and the fact that the outcome definition
was chosen after seeing results on all three candidates is disclosed in the text rather than left to
be inferred.

**Published to the website.** `assets/papers/fiscal-anticipation.pdf` in `conway1521.github.io`, with
a new Working papers section on `research.html` between the dissertation and publications, and the
page lede widened to name fiscal policy. Committed on `main`, the branch GitHub Pages builds from,
matching that repo's own convention. **Not pushed**: pushing publishes it.

## Everything still outstanding

1. Push the website commit, if the draft is to be public now.
2. Obtain the measure-level dataset behind Hürtgen et al. (2024) and cross-validate the 2004-2018
   coding against it (§13.3). The published replication package carries aggregated series only.
3. Adjudicate the remaining anti-avoidance coding divergence for Paper 2, as robustness rather than
   by recoding (§8.2).
4. Expand the draft towards the word limit if a fuller literature review is wanted.

Nothing outstanding is analysis. Paper 1 is closed.
