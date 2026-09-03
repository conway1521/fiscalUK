# The Anticipation Content of Fiscal Policy: UK Tax Measures, 1945-2019

**Superseded, 3 September 2026.** `paper/fiscaluk-paper1.tex` is now the authoritative draft. It
carries a round of corrections made after external review that are **not** reflected below: the
120-day rationale is rewritten and a four-outcome robustness table added, the aggregation formulas
behind the anticipation share are stated, Table 4's sample labels are corrected, the bootstrap is
extended to all five significant instrument coefficients, the crisis nulls carry confidence intervals
and minimum detectable effects, the 2010 break is shown not to survive revenue weighting, and the
causal and multiplier language is weakened throughout. See RESULTS.md section 15. This file is kept
as the record of the pre-review draft.

Every number below is produced by `run_all.R` and logged in `RESULTS.md`. Institutional citations are
in `SOURCES.md` and carry a verification warning.

---

## Abstract

Narrative tax shocks are dated by implementation, and the resulting series are pooled across decades.
Using 2,252 UK tax measures announced between 1945 and 2019, we show that the interval between
announcement and implementation has changed enough that such a series mixes two economically
different objects. The share of the tax impulse announced more than 120 days before taking effect
rises from 0.18 in 1945-79 to 0.70 since 2000, and the unanticipated component of the quarterly
impulse falls roughly fivefold. Computing the same quantity from the century-long dataset of Cloyne,
Hürtgen and Dimsdale (2025), on their coding and their threshold, reproduces the series and extends
it back to 0.02 in 1920-44. We then show the interval is not incidental. Within the same Budget,
National Insurance changes are 39 percentage points more likely than excise duties to arrive with
long notice, the fiscal-year calendar produces long notice only when the Budget falls late in the
year, and tax rises are four times more likely than cuts to take effect after an election. The rise dates
to 1993 and 2010, coinciding with two reforms of the Budget process justified by scrutiny and
predictability and never assessed for macroeconomic consequence. Crises do not shorten it.

**JEL:** E62, E65, H20, H30. **Keywords:** narrative tax shocks, fiscal foresight, tax policy
making, announcement effects, fiscal multipliers.

---

## 1. Introduction

Discretionary tax policy is measured, in the narrative tradition running from Romer and Romer (2010)
through Cloyne (2013), by identifying legislated tax changes, coding their motivation, and dating
them by when they take effect. That dating convention embeds an assumption: that the moment a tax
change affects the economy is the moment it becomes law in practice. Where a change is announced well
in advance, the assumption fails, because households and firms can respond to the announcement.

The problem is understood. Leeper, Walker and Yang (2013) show that foresight puts the econometrician
behind the agent's information set, and Mertens and Ravn separate anticipated from unanticipated US
tax changes for exactly this reason. What the literature treats as a nuisance to be handled, this
paper treats as an object to be measured. The question is not whether foresight exists but how much
of it there is, whether it is systematic, and whether it has changed.

For the United Kingdom it has changed enormously. We assemble announcement and implementation dates
for 2,252 tax measures across 122 Budget events from 1945 to 2019, chaining Cloyne's narrative record
to our own coding of the modern period. Defining long notice as a gap of at least 120 days, the share
of measures arriving with long notice runs at roughly 15% from the 1950s through the 1980s and
reaches 65% in the 2010s. Weighted by revenue, the share of the tax impulse announced more than 120
days ahead rises from 0.20 in 1945-79 to 0.82 since 2000, and the revenue-weighted lead time roughly
triples.

**The first contribution is therefore a warning about the data everyone uses.** A narrative tax series
spanning the post-war period is not a series of comparable objects. Decomposing the quarterly impulse
into foreseen and unforeseen components, the unforeseen part falls from 0.077% to 0.015% of GDP in a
typical quarter, a fall of roughly five to one, while the foreseen part is far more stable. Any
estimate that pools 1945 with 2015 is averaging a regime in which tax changes mostly arrived as
surprises with one in which they mostly did not. We provide the split series.

**The second contribution is that the interval is systematic.** Three regularities survive Budget-event
fixed effects, so that measures announced by the same Chancellor on the same afternoon are compared
with one another.

*Instrument.* National Insurance changes are 38.5 percentage points more likely to arrive with long
notice than excise duties, income tax 12.8 points, VAT 9.6 points, while capital gains tax is 11.2
points less likely. The joint test on instrument within Budget gives F = 11.7 on 10 degrees of
freedom.

*Calendar.* Among measures pinned to early April by the fiscal year, 32% arrive with long notice
after a spring Budget and 86% after an autumn one. The same rule, applied to the same measure,
delivers three weeks or five months of warning depending only on when the Budget falls.

*Elections.* Among measures announced six to twenty-four months before a general election, 12.5% of
tax rises take effect after the country has voted, against 3.1% of tax cuts.

**The third contribution is to date the change and attach it to decisions.** A search over single break
years locates the transition at 1993, the year Britain merged the spring Budget and the Autumn
Statement into a single November Budget, a reform Lamont announced in March 1992. A second, smaller
step appears at 2010, when the Treasury and HMRC rebuilt tax policy making around consultation and
the publication of draft Finance Bill clauses. The 1997 return to a spring Budget, which would have
reversed a purely mechanical calendar effect, does nothing.

These were choices. What they were not is choices about macroeconomic policy. Across the 1992, 2010,
2016 and 2017 documents the stated justifications are parliamentary and external scrutiny,
predictability, stability, simplicity, and giving taxpayers time to prepare. The Treasury now
publishes a target that most measures be announced at least sixteen months before taking effect. No
document in that sequence considers the consequences for stabilisation, for the anticipation content
of the fiscal impulse, or for households unable to act on advance notice.

**We also report two negatives.** Crises do not shorten the interval, on three separate definitions of
treatment: the coefficient is small, positive and insignificant in every case. Whatever capacity to
act quickly the tax system once had, emergencies do not restore it. And the data cannot observe
quiet abandonment of announced policy: expiry dates in a scorecard record pre-announced sunsets, not
later changes of mind. Claims about the delivery of announced tax policy must be confined to scored,
dated commitments.

### Relation to the literature

The narrative tradition in fiscal policy has always recorded the dates this paper studies, and has
always used them for something else. Romer and Romer (2010) identify legislated US tax changes from
the contemporaneous record, code their motivation, and date them by when they take effect, and
Cloyne (2013) builds the corresponding UK account for 1945 to 2009. That record has since been
extended in both directions, back into the interwar period by Cloyne, Dimsdale and Postel-Vinay
(2023) and forward to 2020 by Hürtgen, Cloyne, Dimsdale and Postel-Vinay (2024), so that a
narrative account of British tax policy now spans roughly a century and has been used at that length
by Cloyne, Hürtgen and Dimsdale (2025). In all of this work the implementation date is a dating
convention, an input to the construction of a shock series rather than a quantity of interest, and
the announcement date enters, when it enters at all, as the means of separating measures that were
foreseen from measures that were not.

The foresight literature takes the same dates and asks a sharper question of them, which is whether
anticipation invalidates the identification. Yang (2005) shows that policy foresight changes the
dynamic response to a tax change, Leeper, Walker and Yang (2013) establish that foresight places the
econometrician behind the agent's information set and that the resulting representation is
non-invertible, so that the shock cannot be recovered from the observed series in the usual way, and
Mertens and Ravn (2011, 2012) construct separate anticipated and unanticipated US tax series in
order to estimate their effects apart. Ramey (2011) makes the parallel argument for government
spending, that the timing of the news rather than the timing of the outlay is what identifies the
shock. Favero and Giavazzi (2012) and Alesina, Favero and Giavazzi (2015) go further towards the
policy process itself, the latter treating fiscal consolidations as multi-year plans with announced
and unexpected components rather than as sequences of independent measures, which is the closest
existing treatment to the one taken here.

What these two bodies of work share is the level at which anticipation is handled. In both, foresight
is a property of an individual measure, to be recorded, corrected for, or modelled, and the
correction is applied measure by measure within a sample that is treated as homogeneous. Neither
assembles the anticipation of individual measures into a property of the policy regime, and neither
asks how much of it there is in a given decade, whether it falls disproportionately on particular
instruments, or whether the quantity has moved over the life of the sample. The assumption that it
has not moved is nowhere defended, because it is nowhere stated.

Set against that is a second literature, entirely separate, which does treat the timing of tax
policy as its subject and treats it as procedure. The reform of the Budget process is documented in
the parliamentary record and in the Treasury's own accounts of how tax policy is made, from the
unification of the Budget and the Autumn Statement announced in 1992 through the consultation
framework of 2010 and 2011 to the single fiscal event of 2016, and that record is explicit about
lead times, to the point of stating a target of sixteen months from announcement to effect. It is
not, however, in any conversation with the macroeconomic literature. The documents justify longer
lead times by reference to parliamentary scrutiny and to the predictability of the tax system, and
they contain no assessment of what a longer lead time does to the transmission of a fiscal impulse,
because that is not the question they were written to answer.

The gap this paper occupies lies between the two. The macroeconomic literature has established that
foresight matters and has built the tools to handle it, one measure at a time and within a sample
assumed to be stationary in this respect. The institutional record has established that the process
generating foresight was deliberately reformed, twice, and says nothing about the consequence. What
has not been done is to measure the foresight itself as a time series, to ask whether it is
systematically distributed, and to connect its movement to the reforms that produced it. That is the
object of this paper, and the finding that motivates the rest of it is that the quantity is neither
small nor stationary: the share of the British tax impulse arriving with more than four months'
notice has risen from roughly a fifth to roughly four fifths, and the unanticipated component has
fallen by about five to one. A sample assumed homogeneous in its anticipation content is not.

The paper proceeds as follows. Section 2 describes the data and the chaining, and reports the tests
that establish the trend is not an artefact of joining two sources. Sections 3 to 6 present the
trend, the instrument gradient, the calendar mechanism and the election result. Section 7 reports the
negatives. Section 8 converts the measure-level results into the anticipation content of the revenue
impulse. Section 9 dates the break and sets out the institutional history. Section 10 concludes.

---

## 2. Data

### 2.1 Construction

Cloyne (2013) codes UK tax measures from 1945 to 2009 from Financial Statement and Budget Reports,
recording announcement date, implementation date, revenue costing and a motivation classification. We
extend the record to Budget 2004 through Autumn 2018 from Treasury scorecards, using the same
concepts. The two are chained at 1 January 2004, Cloyne before and our coding after, giving 2,252
datable measures across 122 Budget events.

Paper 1 uses every datable, non-reversal measure regardless of exogeneity. How long the policy
process takes is a descriptive question with no endogeneity to purge, and imposing the identifying
restriction would discard 41% of Cloyne's datable measures and 69% of ours.

### 2.2 The outcome

The primary outcome is `long`, an indicator for a gap of at least 120 days between announcement and
implementation. **The concept is not ours.** Cloyne (2013), following Mertens and Ravn (2012),
classifies a tax change as anticipated when its implementation lag exceeds 90 days, and the
literature has used that convention since. Our 120-day threshold is a variant of it, widened to
exclude the March-Budget-to-6-April case described below, and section 8.1 shows the two thresholds
give the same answer. What is new in this paper is not the distinction but the treatment of its
incidence as a time series. Two alternatives were considered and rejected as primary. The raw lag in quarters is
degenerate, with 42% of mass at zero. An indicator for implementation falling in a later fiscal year
is partly artefactual: 34% of its positives are under 60 days, being a March Budget implementing on
6 April, and that share drifts from 0.72 in the 1980s to 0.11 in the 2010s, so the measure changes
meaning across the sample. Both are reported as robustness. The choice of outcome was made after
seeing results on the alternatives and the paper must say so.

All inference is unweighted and clustered on the Budget event. Revenue weighting reduces the Kish
effective sample from 2,252 to 251 and is used only for descriptive magnitudes.

### 2.3 The seam

The trend crosses a source join, which is the first thing a referee will attack. Six tests.

*Announcement convention.* Both codings place roughly 90% of announcements on the Budget day itself
(Cloyne 0.916, ours 0.888), so `announce` is the same object.

*The overlap.* 2004-09 is coded twice. On the eleven Budgets both record, Cloyne gives a long-notice
share of 0.460 and our coding 0.496; revenue-weighted, 0.627 and 0.615. The paired within-event
difference is −0.021 with t = −0.46.

*Itemisation.* Cloyne splits those same Budgets 2.8 times more finely, 32.0 measures per event against
11.5, and still returns the same share.

*Weighting.* The trend holds unweighted (0.162 to 0.646), at event level (0.195 to 0.618) and
revenue-weighted (0.285 to 0.740).

*Composition.* Holding the 1945-79 instrument mix fixed moves the 2010s rate by 0.019. The rise is
within-instrument.

*Granularity.* The twenty largest measures of each decade, an equal count immune to itemisation, give
0.25, 0.10, 0.20, 0.30, 0.20, 0.70, 0.80, 0.80.

Decisively, the post-1990 step is +0.206 (z 5.18) within Cloyne's coding alone, and +0.175 (z 4.43)
with instrument controls. No join can produce a break lying entirely on one side of it.

---

## 3. Fact 1: the trend

Share of measures arriving with at least 120 days' notice, by decade of announcement:

| 1940s | 1950s | 1960s | 1970s | 1980s | 1990s | 2000s | 2010s |
|---|---|---|---|---|---|---|---|
| 0.162 | 0.039 | 0.129 | 0.182 | 0.145 | 0.363 | 0.393 | **0.646** |

Flat through the 1980s, then a sustained rise. No decade cell is driven by a single Budget: the
largest event accounts for 11 to 25% of a decade's measures.

*Figures:* `fig0_gap_distribution` (justifying the threshold), `fig1_trend`.

---

## 4. Fact 2: instrument determines notice

Budget-event fixed effects, relative to excise duties. Joint F = 11.7 on 10 df, p = 8.6e-20. R²
rises from 0.274 with Budget fixed effects alone to 0.314 with instrument.

| Instrument | Effect | z |
|---|---|---|
| Social security | **+0.385** | 7.5 |
| Property recurrent | +0.148 | 2.0 |
| Income | **+0.128** | 3.5 |
| VAT | +0.096 | 2.3 |
| Capital gains | **−0.112** | −3.3 |

Corporate, oil, property transaction, inheritance and other are insignificant.

The specification has 128 parameters against 118 clusters, so cluster-robust standard errors are
suspect in principle. A 600-replication pairs cluster bootstrap and a within-transformed
specification with 10 parameters both return the same estimates and near-identical standard errors.

*Figure:* `fig2_instruments`.

---

## 5. Fact 3: the mechanism, and its limit

Income tax and National Insurance changes are pinned to early April by the fiscal year. That
produces long notice only when the Budget falls late in the year. Among the 1,050 measures
implementing 1-7 April, the long-notice rate is **0.32 after a spring Budget and 0.86 after an
autumn one** (+0.365, z = 5.14).

This explains cross-sectional variation, not the trend. Adding calendar controls raises R² from
0.155 to 0.214 and absorbs only 9% of the 2010s decade effect. The implementation date has also
migrated from 6 April to 1 April: the 6 April share falls from 0.47 in the 1970s to 0.06 in the
2010s while the 1 April share rises from 0.10 to 0.53.

*Figures:* `fig3_mechanism`, `fig3b_clock_migration`.

---

## 6. Fact 4: tax rises are scheduled past elections

Share of measures whose implementation falls after the next general election, among those announced
six to twenty-four months before it:

| Cuts | Rises |
|---|---|
| 0.031 | **0.125** |

Within Budget: +0.075 (z = 2.37, p = 0.018), n = 751 across 49 events. On the wider 0-24 month
window, +0.060 (z = 2.26, p = 0.024).

This is the paper's most quotable and least robust result and should be presented as such.

*Figure:* `fig4_elections`.

---

## 7. Two negatives

**Crises do not shorten the interval.** Endogenous measures +0.044 (p = 0.58), exogenous +0.071
(p = 0.65). Both positive, neither significant. Earlier tests on calendar windows, the crisis-response
population and emergency years are all null or wrong-signed. The 2008-09 descriptive fact stands:
93.5% of exogenous crisis measures were deferred against 49.5% in the rest of the decade. Crises are
associated with more pre-commitment, not less.

**Delivery is unobservable.** In 3,092 rows there is not one case where an expiry date reflects a later
decision rather than a pre-announced sunset. Every reversal row is announced on or before its parent
and implements exactly on the parent's stop date. A scorecard-derived narrative dataset cannot
observe quiet abandonment, and the paper's claims are therefore about scored, dated commitments.
Bounded statements that hold: 10.1% of post-2004 measures carry a pre-announced sunset against
3.6% before (recomputed on the chained timing sample, 3 September 2026).

---

## 8. The anticipation content of the fiscal impulse

Revenue-weighted share of the tax impulse, dated by implementation, announced at least 120 days
ahead. Measures implementing after 2019 are dropped as end-of-sample long-lead survivors.

| Sample | 1945-79 | 1980-99 | 2000-19 |
|---|---|---|---|
| All measures | 0.184 | 0.384 | **0.699** |
| Household exogenous | 0.202 | 0.364 | **0.815** |

Revenue-weighted lead time rises from 102 to 322 days on the full sample.

Splitting the quarterly impulse into foreseen and unforeseen components, as a share of nominal GDP:

| Period | Foreseen | Unforeseen | Foreseen share |
|---|---|---|---|
| 1945-79 | 0.041 | 0.077 | 0.348 |
| 1980s | 0.049 | 0.083 | 0.373 |
| 1990-2003 | 0.051 | 0.030 | 0.630 |
| 2004-18 | 0.030 | 0.015 | 0.665 |

**The unforeseen impulse collapses by roughly five to one**, and the collapse occurs between the 1980s
and 1990-2003, a window lying entirely within Cloyne's coding, so it cannot be an artefact of the
modern data. The foreseen impulse falls too, by less, which is why the foreseen share rises. Do not
claim the foreseen impulse is constant; it is not.

### 8.1 External validation on data we did not build

The result above is computed on a series we assembled, so the obvious question is whether it survives
on someone else's. It does.

Cloyne, Hürtgen and Dimsdale (2025) use a narrative UK tax dataset covering roughly 1918 to 2020, and
their replication package publishes the quarterly exogenous shock series in two variants, a baseline
containing all narrative shocks and an unanticipated variant restricted to measures implemented
within Cloyne's 90-day window. The ratio of the two is an anticipation share, constructed by other
researchers, on their own coding, over a longer sample, using their own threshold. Nothing in it came
from us.

| Era | Their share | Our share |
|---|---|---|
| 1920-44 | 0.022 | not covered |
| 1945-79 | 0.248 | 0.184 |
| 1980-99 | 0.420 | 0.384 |
| 2000-20 | **0.697** | **0.699** |

The two series agree in shape and in level, and most closely where the sample is densest. Their
decade series also contains the break: the anticipation share runs 0.286 in the 1980s and 0.614 in
the 1990s, which is where section 9 dates it independently. And their longer sample strengthens the
result rather than qualifying it, because in 1920-44 the anticipation share was 0.022, so on a
century view the quantity has risen from almost nothing.

This has a second implication. The ingredients for this finding have been publicly available in a
top-five journal's replication archive, and were used there as a robustness check rather than
examined. That is the gap this paper occupies, stated as concretely as it can be.

Reproduced by `R/10_external_validation.R`, which downloads the series from Harvard Dataverse
(doi:10.7910/DVN/JVNAPS).

### 8.2 The pipeline

The stock of announced-but-not-yet-in-force tax change tells the same story. Median pending stock
rises from 0.026% of GDP in 1945-79 to 0.991% in 2004-18, and the mean number of pending measures
from 2.0 to 26.4. Report the median: the mean is dominated by VAT, announced March 1971 and in force
April 1973, which alone placed roughly 11% of GDP in the pipeline.

**Implication.** A multiplier estimated on a pooled UK narrative series averages two different objects.
The split series is provided as `output/uk_tax_shocks_split.csv`, with an announcement-dated news
series and an implementation-dated unanticipated series as separate instruments.

---

## 9. Dating the change

A grid search over single break years maximises fit at **1993** (R² 0.142). The annual series is
sharp: 1992 = 0.047, 1993 = 0.372, 1994 = 0.434, 1995 = 0.600.

Local tests, eight years either side of each candidate:

| Candidate | Year | Estimate | z | p |
|---|---|---|---|---|
| Unified autumn Budget | 1993 | **+0.288** | 6.96 | <0.0001 |
| Return to spring Budget | 1997 | +0.026 | 0.36 | 0.72 |
| Tax policy making framework | 2010 | **+0.257** | 3.20 | 0.001 |
| Draft-clause consultation | 2011 | +0.157 | 1.80 | 0.072 |
| Single fiscal event | 2017 | +0.108 | 1.20 | 0.23 |

**Not a calendar artefact.** Restricting to spring Budgets alone, the trend still runs 0.143 in the
1980s, 0.275 in the 1990s and 0.657 in the 2010s, with a post-1990 step of +0.275 (z 5.56). The
autumn-minus-spring gap runs +0.21, +0.17 and −0.03 across the last three decades, so the calendar
channel closes while the level keeps rising. Earlier decades have too few autumn measures to report.

**The institutional record.** All quotations below were verified against the source documents on
3 September 2026; see `SOURCES.md` for method and status.

Lamont announced the reform in the Budget Statement of 10 March 1992 (HC Deb vol 205, c745): "I
therefore intend that next year's Budget will be the last spring Budget. From then on the annual
Budget will be in December, and it will cover not just taxation but also public expenditure." He
added that "the 1994 Finance Bill will be presented to the House in January rather than April",
which moved the legislative timetable as well as the announcement. The date was brought forward to
November in the Budget Statement of 16 March 1993 (vol 221, cc169-96), and the first unified Budget
was delivered by Clarke on 30 November 1993 (vol 233, cc921-41). Brown returned the Budget to spring
in the statement of 2 July 1997 (vol 297, cc303-16).

Budget 2010 (HC 61, paragraph 1.64) set out predictability, stability and simplicity as objectives
and announced proposals "to improve the way tax policy is made to support these objectives",
accompanied by *Tax policy making: a new approach* (HM Treasury and HMRC, June 2010). The
consultation response followed on 9 December 2010, when the Exchequer Secretary told the House that
"confirming the majority of intended tax changes at least three months ahead of publication of the
Bill supports predictability in the tax system and provides an opportunity for draft legislation to
be properly scrutinised". The Tax Consultation Framework followed on 31 March 2011.

The 2016 move to a single fiscal event was made "to promote certainty and simplicity within the tax
system" and justified on the ground that it "will improve both external and Parliamentary scrutiny of
proposed tax measures". The Treasury's stated target, from *The new Budget timetable and the tax
policy making process* (6 December 2017), is that "most policies will be announced at least 16 months
before they come into effect at the start of the next tax year".

Read together, the stated objectives across 1992, 2010, 2016 and 2017 are parliamentary and external
scrutiny, predictability, stability, certainty, simplicity, and time for stakeholders to comment. None
is macroeconomic.

---

## 10. Conclusion

The interval between announcing a UK tax change and its taking effect has roughly quadrupled since
the middle of the last century, and the unanticipated component of the tax impulse has fallen by
about five to one. The interval is not incidental. It depends on which instrument is chosen, on where
the Budget falls in the calendar, and on whether an election is approaching. It does not respond to
crises.

Two consequences follow. For applied work, a narrative tax series pooled across the post-war period
is not a series of comparable shocks, and the split series provided here is the minimum correction.

For policy, the timing of a tax change is a decision with economic content, and it is currently a
residual of instrument choice and Budget scheduling. Advance notice is only valuable to those able to
act on it, which requires savings, flexible income or professional advice. Whether the large increase
in advance notice documented here has distributional consequences is not testable in this dataset:
the obvious version, that regressive instruments arrive with least warning, was significant in
1980-99 and is not significant today, though 43% of regressive measures still arrive with under a
month's notice against 33% of progressive ones. Establishing whether notice is distributed unevenly
in a way that matters for household behaviour is the subject of the companion paper.

What can be said here is narrower and firm. Britain rebuilt the timing of its tax policy twice, for
reasons of parliamentary scrutiny and legal certainty, and in doing so transformed the anticipation
content of fiscal policy. That consequence appears in no document justifying the reforms.

---

## References

Verified against Crossref, 3 September 2026. Working-paper versions exist for several of these and
are not listed; cite the published version.

Alesina, A., Favero, C. and Giavazzi, F. (2015). The output effect of fiscal consolidation plans.
*Journal of International Economics*.

Cloyne, J. (2013). Discretionary tax changes and the macroeconomy: new narrative evidence from the
United Kingdom. *American Economic Review*, 103(4), 1507-1528.

Cloyne, J., Dimsdale, N. and Postel-Vinay, N. (2023). Taxes and growth: new narrative evidence from
interwar Britain. *Review of Economic Studies*.

Cloyne, J., Hürtgen, P. and Dimsdale, N. (2025). Are tax cuts contractionary at the zero lower
bound? Evidence from a century of data. *Journal of Political Economy*, 133(2), 568-603.

Favero, C. and Giavazzi, F. (2012). Measuring tax multipliers: the narrative method in fiscal VARs.
*American Economic Journal: Economic Policy*.

Hürtgen, P., Cloyne, J., Dimsdale, N. and Postel-Vinay, N. (2024). Tax changes in the United
Kingdom 2009-2020: a new narrative account and dataset. SSRN working paper 4909051.

Leeper, E. M., Walker, T. B. and Yang, S.-C. S. (2013). Fiscal foresight and information flows.
*Econometrica*, 81(3). doi:10.3982/ecta8337.

Mertens, K. and Ravn, M. O. (2011). Understanding the aggregate effects of anticipated and
unanticipated tax policy shocks. *Review of Economic Dynamics*.

Mertens, K. and Ravn, M. O. (2012). Empirical evidence on the aggregate effects of anticipated and
unanticipated US tax policy shocks. *American Economic Journal: Economic Policy*.

Ramey, V. A. (2011). Identifying government spending shocks: it's all in the timing. *Quarterly
Journal of Economics*.

Romer, C. D. and Romer, D. H. (2010). The macroeconomic effects of tax changes: estimates based on a
new measure of fiscal shocks. *American Economic Review*.

Yang, S.-C. S. (2005). Quantifying tax effects under policy foresight. *Journal of Monetary
Economics*.

Primary documents are listed in `SOURCES.md` with verification status.

---

## Appendix: journal fit, reproduction and caveats

**Fiscal Studies requirements.** Papers should preferably not exceed 7,500 words; the abstract is
capped at 200 words and a JEL classification is required. Submission is .docx or LaTeX through
Research Exchange, under single anonymised review, and empirical papers must supply full replication
materials. This draft runs to roughly 4,600 words including tables, so there is room for the
literature review and the figure discussion to expand. The abstract is within the cap. The
replication requirement is already met by `run_all.R`.



`run_all.R` rebuilds everything. `RESULTS.md` logs eight retractions, the seam tests, the bug review
of 3 September 2026 and the distributional test. `SOURCES.md` carries the institutional citations and
flags two unverified items.

**Known limitations to state in the paper.** The outcome definition was chosen after seeing results on
alternatives. The exogeneity classification agrees across the two codings on 78.3% of matched
measures in the overlap, with a systematic divergence on anti-avoidance that affects Paper 2 rather
than Paper 1. The election result is fragile.

**A competing dataset exists, and it corroborates rather than threatens.** Hürtgen, Cloyne, Dimsdale
and Postel-Vinay (2024) extend the UK narrative account to 2009-2020, and Cloyne, Hürtgen and
Dimsdale (2025) use a century-long version in the *Journal of Political Economy*. Section 8.1 uses
their published series to reproduce this paper's central quantity. Their replication package
publishes aggregated quarterly series rather than measure-level announcement dates, so it cannot
substitute for the measure-level work here, and the paper should say so plainly when explaining why
we coded 2004-2018 ourselves. Obtaining the measure-level 2024 dataset would still be worth doing,
since it would allow the modern half to be cross-validated directly.

**Institutional quotations are verified** against source documents (`SOURCES.md`, 3 September 2026).
Two carry caveats. The command number of the 1992 budgetary reform White Paper could not be
confirmed and is omitted; cite the White Paper on Lamont's own words instead. The 9 December 2010
ministerial statement was verified through three independent Internet Archive captures spanning 2013
to 2025, all agreeing, because Parliament's publications site refuses direct requests.
