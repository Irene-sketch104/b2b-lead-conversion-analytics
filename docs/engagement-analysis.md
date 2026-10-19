# Engagement analysis — milestone 10

## Scope and execution

Completed sections 10.1–10.13 of `sql/10_analyze_engagement.sql`. These are read-only exploratory queries against `clean.vw_lead_scoring` in `B2BLeadAnalytics`; no new view, imputation or source-table update is introduced. Run in SSMS after milestone 06 has created and validated the clean view. Earlier account/contact validation established non-missing account IDs and a complete binary outcome.

Results were executed by the project author in local SSMS and reviewed from supplied exports. The reviewer did not connect to or rerun the local SQL Server. SQL is preserved as uploaded, including explanatory comments and section order.

## Metrics and grouping

- Lead conversion rate: converted leads / all leads in the group × 100.
- Equal-account mean lead conversion rate: first compute that rate separately for each account **within the current group**, then average the unrounded account rates with equal weight. This is not the percentage of companies with a conversion, and is not an average of each company's full-snapshot rate.
- Account count: distinct companies represented in a group. One company may occur in several groups, so these counts must not be summed to obtain the dataset's 1,280 companies.
- Lead shares: group leads / all 5,000 leads, except section 10.5, whose denominator is all leads within the corresponding source.
- Sections 10.3 and 10.10 represent every lead once for each direction/page type. Reconcile each type separately; do not treat both types together as 10,000 unique leads.
- Missing values remain separate from zero. Joint-pattern queries classify a lead as missing when either input is NULL; both inputs must be present to classify the complete pattern.
- Section 10.6 includes only `flag_touch_recency_conflict = 0`. Section 10.7 retains all leads, showing missing/invalid and conflicting recency separately. Under 7 days includes zero and excludes 7. Completed day 0 in 10.6 means [0,1), not only exactly zero.
- Rates displayed to two decimals are descriptive associations. Equal-account weighting changes the estimand; it is not a significance test or a correction for all within-account dependence.

## Source definitions

Public dataset: [Kaggle — LeadForge Intermediate v1](https://www.kaggle.com/datasets/derelictpanda/leadforge-lead-scoring-intermediate-v1/data).
The current [upstream feature dictionary](https://leadforge-dev.github.io/leadforge/docs/dataset/features), checked on 19 October 2026, defines sessions as web/trial sessions, pricing/demo counts as cumulative page views across sessions, and total duration as cumulative seconds across all sessions. Therefore duration is not a page-specific timing measure; separate pricing/demo durations cannot be recovered from these aggregate fields. Demo-page views do not establish that a demo was booked or completed.

The current upstream documentation describes a day-0-to-30 engagement snapshot and a separate 90-day outcome window. The exact local bundle revision has not been matched to that documentation (the inspected local CSV has 32 columns, while the current dictionary describes 31). Preserve this version caveat; do not silently redefine local fields or assume every engagement event precedes conversion. Deployment-time availability remains to be established before predictive or early-prioritisation claims.

## Touch counts and directions (10.1–10.5)

Rates are low at 0–2 total touches and fluctuate thereafter. Fourteen touches has 79 leads from 76 accounts, with rates of 36.71% and 34.87%. This isolated high group does not establish an optimal contact count. Each 16+ group has few leads. The pooled/equal-account gap is below two percentage points in every total-touch group and below 1.5 points in each direction-specific group.

| Group | Accounts | Leads | Converted leads | Lead rate (%) | Equal-account mean (%) |
| --- | --- | --- | --- | --- | --- |
| Inbound only | 953 | 1894 | 416 | 21.96 | 21.76 |
| Outbound only | 1033 | 2261 | 460 | 20.34 | 20.10 |
| No recorded touches | 57 | 58 | 1 | 1.72 | 1.75 |
| Missing touch data | 569 | 787 | 172 | 21.86 | 21.37 |

Inbound-only and outbound-only groups cover 4,155 leads (83.10%). No complete record has positive counts in both directions; the 787 missing-pattern records cannot be fully classified. The pooled inbound/outbound difference is 1.62 percentage points, but source and direction align among complete, positive-touch records:

- Inbound marketing: 1,894 inbound-only; 358 missing; 22 with no recorded touches.
- Partner referral: 796 outbound-only; 157 missing; 16 with no recorded touches.
- SDR outbound: 1,465 outbound-only; 272 missing; 20 with no recorded touches.

There is no within-source inbound-only versus outbound-only comparison. Partner referral identifies the origin of the lead, not who performed an outbound touch. Do not attribute the observed difference to direction alone.

## Recency (10.6–10.7)

| Group | Accounts | Leads | Converted leads | Lead rate (%) | Equal-account mean (%) |
| --- | --- | --- | --- | --- | --- |
| Under 7 days | 1084 | 2634 | 626 | 23.77 | 23.37 |
| 7 to under 14 days | 609 | 875 | 176 | 20.11 | 20.07 |
| 14 to under 21 days | 265 | 294 | 48 | 16.33 | 16.35 |
| 21+ days | 148 | 160 | 9 | 5.63 | 5.74 |
| Missing or invalid recency | 632 | 903 | 173 | 19.16 | 19.28 |
| Conflicting recency | 125 | 134 | 17 | 12.69 | 11.87 |

The four valid weekly bands decline under both weighting methods. The daily results fluctuate rather than decline at every step. The 21+ group has only nine conversions. Missing/invalid and conflicting categories cover 1,037 leads (20.74%); keep them outside a numeric recency trend. These intervals are reporting definitions, not validated follow-up deadlines or estimates of the benefit of recontacting a lead.

## Activities and sessions (10.8–10.9)

Activity conversion rises from 5.62% at zero activities (409 leads) to 25.14% at four (720 leads), then fluctuates. The 13- and 14-activity groups each contain only two leads. There are 398 missing activity counts.

For zero to six sessions, pooled conversion ranges from 19.86% to 23.15%, with no consistent increase. Seven to nine sessions contain only 13 leads in total. There are 378 missing session counts. Zero recorded sessions do not imply no sales activity. Do not add touch, activity and session counts as if they were mutually exclusive events.

## Pricing and demo pages (10.10–10.11)

Separate summaries show higher rates for one or two demo views than zero, and for one to four pricing views than zero. Those summaries include leads viewing both page types. The joint comparison clarifies the overlap:

| Group | Accounts | Leads | Converted leads | Lead rate (%) | Equal-account mean (%) |
| --- | --- | --- | --- | --- | --- |
| Pricing only | 636 | 908 | 214 | 23.57 | 22.95 |
| Demo only | 136 | 145 | 27 | 18.62 | 18.75 |
| Both pages | 496 | 661 | 178 | 26.93 | 26.89 |
| Neither page | 1080 | 2521 | 483 | 19.16 | 19.53 |
| Missing page-view data | 559 | 765 | 147 | 19.22 | 18.87 |

Both-page leads have the highest observed rate under both weighting methods, followed by pricing-only leads. Demo-only and neither-page rates are close, with very different sample sizes. One extra conversion among the 145 demo-only leads would yield 19.31% and reverse the pooled ranking. This is neither evidence of equivalence nor evidence that demo pages harm conversion. Neither-page means no recorded views of these two page types, not no website visits.

## Total session duration (10.12–10.13)

The frequency export has 416 missing, 689 zero and 3,895 positive durations, accounting for all 5,000 leads. The earlier SSMS summary reported no negatives. The 300-to-under-1,200-second range contains 2,593 leads (51.86% of all leads). Durations of 30 minutes or more contain 126 leads (2.52%). Five-minute bands were chosen from the frequency distribution before reviewing band conversion, with the sparse 30+ minute tail combined. Recompute company counts and means within merged groups; do not sum distinct account counts or average pre-aggregated band rates.

| Group | Accounts | Leads | Converted leads | Lead rate (%) | Equal-account mean (%) |
| --- | --- | --- | --- | --- | --- |
| Zero seconds | 535 | 689 | 139 | 20.17 | 20.44 |
| >0 to <5 minutes | 453 | 580 | 119 | 20.52 | 20.45 |
| 5 to <10 minutes | 747 | 1136 | 229 | 20.16 | 19.44 |
| 10 to <15 minutes | 608 | 825 | 185 | 22.42 | 22.02 |
| 15 to <20 minutes | 501 | 632 | 136 | 21.52 | 20.76 |
| 20 to <25 minutes | 329 | 384 | 75 | 19.53 | 17.91 |
| 25 to <30 minutes | 199 | 212 | 55 | 25.94 | 26.38 |
| 30+ minutes | 121 | 126 | 24 | 19.05 | 19.42 |
| Missing | 361 | 416 | 87 | 20.91 | 20.48 |

There is no consistently increasing relationship with duration. The 25-to-under-30-minute band is highest under both metrics, but it does not establish a sweet spot. Zero duration does not establish an absence of sales engagement. Missing duration remains separate from zero.

## Evidence and reconciliation

Review inputs: author-supplied `10_analyze_engagement.sql`, the `10.Behaviour&Conversion` worksheet in `SQL_Results.xlsb.xlsx`, and SSMS results pasted into the project conversation. Working exports are excluded from GitHub; they contain other stages and personal learning notes. Tables above retain aggregate evidence without publishing lead/contact/account records.

| Sections | Reviewed coverage | Reconciliation |
| --- | --- | --- |
| 10.1–10.2 | Worksheet rows 2–24; equal-account results in column H | 5,000 leads; 1,049 conversions |
| 10.3 inbound | Rows 27–47 | 5,000; 1,049 |
| 10.3 outbound | Rows 48–67 omit the last result; prior pasted SSMS output includes outbound count 20: 2 accounts, 2 leads, 1 conversion, both rates 50% | Saved export alone: 4,998; 1,048. Including the previously supplied row: 5,000; 1,049 |
| 10.4 | N27:S30 | 5,000; 1,049 |
| 10.5 | K38:N46 | Source totals: 2,274 / 969 / 1,757; sum 5,000 |
| 10.6 | B71:G103 | 3,963 valid, non-conflicting leads; 859 conversions |
| 10.7 | B107:G112 | 5,000; 1,049; valid bands total 3,963 / 859 |
| 10.8 | B114:G129 | 5,000; 1,049 |
| 10.9 | B132:G142 | 5,000; 1,049 |
| 10.10 | B145:H163 | Each page type: 5,000; 1,049 |
| 10.11 | L145:Q149 | 5,000; 1,049 |
| 10.12 frequencies | K159:N171 | 5,000 leads; shares sum to 100% |
| 10.13 | Full nine-row result pasted in conversation; not yet present in uploaded workbook | 5,000; 1,049; group lead counts agree with duration frequencies |

Pooled rates were independently recalculated from exported counts to displayed precision. Equal-account means were checked against the query definition and supplied results; they cannot be independently reconstructed from group totals alone. No local SQL execution, significance testing or causal analysis was performed during packaging.

## Reporting implications and next work

Completed: descriptive engagement analysis, explicit missing/zero treatment, grouping definitions and weighting comparisons. Show group volume alongside conversion rates; retain quality categories and distinguish page combinations from separate page counts.

Planned: compare contact coverage and role/seniority/function combinations, establish reusable reporting definitions and model readiness, then connect Power BI and implement measures/pages. No Power BI model, DAX or report page is completed in this milestone. Final prioritisation recommendations remain pending.
