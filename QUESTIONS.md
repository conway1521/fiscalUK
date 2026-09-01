# Paper 1: Research Architecture

**Status:** pre-specified, not yet tested. Written 1 September 2026, before running any of it.

The point of writing this before testing is discipline. Five questions, each with subsample splits,
run against 2,252 measures will produce spurious significance if we fish. Every test below is
specified in advance: the sample, the statistic, and **what would kill it**. Results that require
departing from the specification get reported as exploratory, not as findings.

Referee panel used throughout: **Saraceno** (fiscal rules, constraints on discretion, policy mix),
**Hubert** (announcement effects, expectations, information content of policy),
**Ragot** (heterogeneous agents, liquidity, incidence), **Heyer** (applied forecasting, real-time
policy evaluation, multipliers).

---

## Q1. Is the implementation lag chosen around elections?

**The claim to test.** Governments choose the announcement-to-implementation gap so that tax rises
land after the next election and cuts land before it.

**Why it is fresh.** The political budget cycle literature (Nordhaus 1975; Rogoff 1990; Brender and
Drazen 2005) is about the size and timing of *deficits*. Nobody has asked whether the implementation
lag is itself a strategic instrument. It is a new margin on an old and well-cited question, and the
data to test it has not existed before.

**Test.** For each measure, compute months from implementation to the *next* general election. Test
whether revenue-raising measures are disproportionately implemented just *after* an election and
revenue-losing measures just *before*. Sample: all datable measures, 1945-2019, excluding reversals.
Statistic: distribution of implementation dates within the electoral cycle, split by sign, revenue-
weighted.

**What would kill it.** UK election dates were not fixed before 2011, so "the next election" is partly
endogenous to the government's own choice. If the effect appears only in the fixed-term period
(2011-2019) it is too small a sample to carry. Also: Budget dates cluster in March/April, and if
elections also cluster in May the pattern could be calendar mechanics rather than strategy. Must
control for month-of-year.

| | What they would want |
|---|---|
| **Saraceno** | Whether this is the mechanism by which discretion gets pre-committed: if governments deliberately push pain past an election, the pipeline is not administrative residue but a political device. Strengthens his case that constraints on fiscal policy are political rather than technical. |
| **Hubert** | Whether the electorate or forecasters *see through* it. If pain is scheduled after an election, do official forecasts price it at announcement? A strategic delay that everyone anticipates is not the same object as one that surprises. |
| **Ragot** | Who bears a post-election tax rise. If delayed pain falls disproportionately on households who cannot smooth, electoral timing has a distributional signature that is invisible in the headline numbers. |
| **Heyer** | Whether this is forecastable in real time. If implementation timing is electorally predictable, a forecaster should exploit it, and the failure to do so is a measurable forecast error. |

---

## Q2. Do crises collapse the lag?

**The claim to test.** In crises, governments revert to fast implementation. If so, the slow modern
default is a choice, not a capability constraint.

**Why it is fresh.** This is the identification that rescues the whole paper from the obvious
objection that lags lengthened because the tax code and legislative process got more complex.
Complexity does not care about urgency; politics does.

**Test.** Event windows around 1976 (IMF), 1992 (ERM exit), 2008-09 (financial crisis). Compare
revenue-weighted median lag inside the window against the surrounding decade. Pre-specify windows as
eight quarters from the event. Sample: all datable measures.

**What would kill it.** Crisis measures are disproportionately endogenous by construction, and we
already know endogenous measures are faster (1 quarter against 4 in the 2000s). So the finding could
be pure composition. **The test must hold the exogenous/endogenous mix constant**, or compare
exogenous measures only within and outside crisis windows. If the effect vanishes once composition
is controlled, Q2 fails and the "choice not constraint" reading weakens considerably.

| | What they would want |
|---|---|
| **Saraceno** | Direct evidence on whether fiscal frameworks bind in emergencies. If lags collapse in crises, the constraint is soft and self-imposed, which is his long-standing argument about European rules being political choices dressed as technical necessity. |
| **Hubert** | Whether crisis announcements carry different information content. A measure implemented immediately conveys urgency about the state of the world; one implemented in two years conveys a view about the medium term. The lag is itself a signal. |
| **Ragot** | Crisis measures land on constrained households immediately, with no smoothing window. So the welfare cost per pound is highest exactly when lags are shortest, and that interaction is unmeasured. |
| **Heyer** | Real-time evaluation: in a crisis the forecaster's problem is that policy arrives faster than the forecast round. Quantifying how much faster is directly useful to a forecasting shop. |

---

## Q3. Does the pipeline actually get delivered?

**The claim to test.** Announced policy is not the same as delivered policy. Measure the mortality
rate of announced measures, and check whether the pipeline is a real constraint or a soft one.

**Why it is fresh.** It is the honest stress test of our own headline object. A pipeline that is
routinely abandoned is not a constraint on a Chancellor's discretion, and the paper's central claim
would need weakening. Doing this ourselves, prominently, is what makes the rest credible.

**Test.** Using stop dates and REVERSE rows: what share of announced measures are reversed or
truncated before or shortly after implementation? Does mortality vary with the length of the lag
(longer-announced measures should be more likely to die), with government change, and over time?

**What would kill it.** The data may simply not record abandonment. We have 58 stop dates and 58
reversal rows in the modern data, which looks small relative to 630 measures. If abandonment is
recorded inconsistently, or only for measures that were formally reversed rather than quietly
dropped, mortality will be understated and the test is uninformative rather than negative. **Check
coverage before interpreting.**

| | What they would want |
|---|---|
| **Saraceno** | Whether pre-commitment is credible. A rule that is routinely broken is not a rule. This determines whether the pipeline belongs in the fiscal-rules conversation at all. |
| **Hubert** | Credibility is his core concept from the central-bank communication literature. If announced measures die often, announcements should move expectations less, and that is directly testable against the forecast data. |
| **Ragot** | Households facing an uncertain announced tax change behave differently from those facing a certain one. Mortality rates are the empirical counterpart of policy uncertainty in a heterogeneous-agent setting. |
| **Heyer** | Practical: should a forecaster condition on announced-but-unimplemented policy at all, and with what haircut? Mortality gives the haircut. |

---

## Q4. Is there an urgency-instrument trade-off?

**The claim to test.** Instrument choice is partly a timing decision. A government needing revenue
this quarter must use duties or VAT; income tax cannot deliver fast.

**Why it is fresh.** It is the cleanest expression of the paper's thesis, that choosing an instrument
is choosing a time profile. It also connects to the tax-based versus spending-based composition
debate in Alesina, Favero and Giavazzi (2019) from an angle they do not consider.

**Test.** Two parts. (a) Establish the instrument-specific lag distribution, 1945-2019, using the
harmonised tax taxonomy. (b) Test whether the share of fast instruments rises in crisis quarters and
in the run-up to elections.

**What would kill it.** Per-instrument samples are thin pre-2004, and the pre-2004 instrument
classification rests on Cloyne's disclaimed Tax Type column, salvaged to 100% coverage but with 13
reasoned calls. If the result depends on those calls it is not robust. Also: instrument choice is
obviously driven by revenue need and politics as well as speed, so this is at best suggestive of a
trade-off rather than evidence of one.

| | What they would want |
|---|---|
| **Saraceno** | Composition of adjustment is his territory via the austerity debate. If speed constrains instrument choice, then a government under time pressure is pushed toward regressive instruments, which is a strong political-economy claim. |
| **Hubert** | Different instruments have different announcement salience. A VAT change is understood immediately; a change to allowances is not. Instrument choice therefore shapes how much of the effect is anticipation. |
| **Ragot** | The strongest version of this for him: fast instruments (VAT, duties) are regressive, slow ones (income tax, CGT) are progressive. **So urgency mechanically pushes adjustment onto poorer households.** That is a distributional consequence of a timing constraint, and it is the most quotable result in the whole paper if it holds. |
| **Heyer** | Forecasting the composition of an announced consolidation matters as much as forecasting its size, because instruments differ in multiplier and in speed. |

---

## Q5. Did institutions cause the pre-commitment?

**The claim to test.** The rise in lags coincides with identifiable institutional changes: Maastricht
(1992), Bank of England independence (May 1997), the Code for Fiscal Stability (1998), the OBR and
the "new approach to tax policy making" (2010).

**Why it is fresh.** It is the most obvious explanation and needs addressing, but I rank it last
deliberately.

**What would kill it, and probably will.** Four candidate dates, a strong secular trend, and one
country. Identification is weak by construction. We will almost certainly end up saying "consistent
with" rather than "caused by". **Treat this as a discussion section, not a results section**, unless
a break test produces something unusually sharp.

| | What they would want |
|---|---|
| **Saraceno** | This is his question, and he would want it done properly or not at all. The Maastricht and monetary-delegation angles are the ones he would press. |
| **Hubert** | BoE independence in 1997 is the interesting one: if fiscal policy must now coordinate with an independent central bank, pre-announcement becomes more valuable because it lets the MPC respond in advance. That is a policy-mix argument with a sharp date. |
| **Ragot** | Least interested of the four. |
| **Heyer** | Whether the OBR's creation changed the informational environment for forecasters, which is testable against forecast errors either side of 2010. |

---

## What is deliberately excluded

- **Party as a headline.** Labour's main spell (1997-2010) coincides exactly with the decades when
  lags lengthened. With three party-periods and a strong trend, party cannot be separated from era.
  Retained only as the *within-government* asymmetry between rises and cuts, which is far less
  vulnerable to the confound. Coda, not pillar.
- **Any chronological section.** The test of whether a section is boring is whether it answers a
  question or describes a period.
- **COVID.** Sample ends early 2019.

## Likely paper boundaries

These five are not five papers. Realistically:

- **Paper 1** = Q1, Q2, Q4 as pillars, Q3 as stress test, Q5 as discussion. One coherent claim:
  *the timing of fiscal policy is chosen, and the choice has distributional consequences.*
- **Possible Paper 1b** = the Hubert angle. Fiscal announcements and expectation revisions, using
  `Historical_official_forecasts_database_October_2021.xlsx`. Different data, different method,
  genuinely separable.
- **Paper 2** = multipliers and distribution, as already planned.
