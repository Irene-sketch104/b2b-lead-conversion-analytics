# Company size, source mix and industry comparisons

## Completed scope and evidence

The user executed sections 9.1-9.5 in SSMS and supplied the result workbook on 16 October 2026. The uploaded SQL contains the five matching read-only queries. No new tables or views are created. This stage focuses on employee-size patterns identified in milestone 08; it does not claim equivalent stratified tests for revenue or maturity.

Run `sql/09_analyze_segment_mix.sql` in `B2BLeadAnalytics` after the earlier import and clean-view steps. Each CTE and its following SELECT must be executed together. The source is `clean.vw_lead_scoring`; all 5,000 leads remain in scope.

## Metric definitions

- Pooled lead conversion rate: converted leads divided by leads within the displayed group.
- Equal-account mean lead conversion rate: average of each participating account's own lead conversion rate. In 9.1 each account rate uses only leads from that source; accounts without that source are excluded because no source-specific conversion rate exists. This is not the proportion of accounts with at least one conversion.
- Lead-weighted source share (9.2): source leads divided by all leads within an employee-size band.
- Within-account source share (9.3): source leads divided by all leads for that account. The detail output contains observed account/source pairs only.
- Equal-account average source share (9.4): average each company's source shares within its size band, including 0% for absent sources. Unlike conversion rates, absent-source shares are defined as zero.

Source-specific conversion means use different sets of participating accounts and different within-account denominators. They cannot simply be averaged to reconstruct the overall equal-account conversion mean. Source-share comparisons alone do not decompose or explain all conversion differences.

## 9.1 Conversion within source and size

| Source | Employee band | Accounts | Leads | Converted | Pooled rate (%) | Equal-account mean (%) |
| --- | --- | --- | --- | --- | --- | --- |
| inbound_marketing | 200-499 | 362 | 820 | 196 | 23.9 | 23.94 |
| inbound_marketing | 500-999 | 365 | 793 | 166 | 20.93 | 21.07 |
| inbound_marketing | 1000-1999 | 202 | 442 | 92 | 20.81 | 20.54 |
| inbound_marketing | 2000+ | 103 | 219 | 47 | 21.46 | 19.81 |
| partner_referral | 200-499 | 237 | 341 | 64 | 18.77 | 18.26 |
| partner_referral | 500-999 | 237 | 352 | 64 | 18.18 | 20.18 |
| partner_referral | 1000-1999 | 124 | 174 | 25 | 14.37 | 14.65 |
| partner_referral | 2000+ | 70 | 102 | 21 | 20.59 | 21.55 |
| sdr_outbound | 200-499 | 325 | 635 | 135 | 21.26 | 19.93 |
| sdr_outbound | 500-999 | 319 | 573 | 124 | 21.64 | 21.62 |
| sdr_outbound | 1000-1999 | 182 | 364 | 71 | 19.51 | 21.46 |
| sdr_outbound | 2000+ | 96 | 185 | 44 | 23.78 | 22.2 |

Only inbound marketing shows a consistently decreasing equal-account mean across increasing size bands. Partner referral and SDR outbound peak in the largest band. Under equal-account weighting, inbound leads in the smallest band; SDR outbound leads in the other three size bands. This statement is specific to the equal-account metric, not both weighting methods.

Accounts can appear under multiple sources, so source-level account counts must not be added to obtain a global unique-company total. Lead and conversion counts across these rows do reconcile to 5,000 and 1,049.

## 9.2 Lead-weighted source composition

| Employee band | Source | Leads | Source share (%) |
| --- | --- | --- | --- |
| 200-499 | inbound_marketing | 820 | 45.66 |
| 200-499 | partner_referral | 341 | 18.99 |
| 200-499 | sdr_outbound | 635 | 35.36 |
| 500-999 | inbound_marketing | 793 | 46.16 |
| 500-999 | partner_referral | 352 | 20.49 |
| 500-999 | sdr_outbound | 573 | 33.35 |
| 1000-1999 | inbound_marketing | 442 | 45.1 |
| 1000-1999 | partner_referral | 174 | 17.76 |
| 1000-1999 | sdr_outbound | 364 | 37.14 |
| 2000+ | inbound_marketing | 219 | 43.28 |
| 2000+ | partner_referral | 102 | 20.16 |
| 2000+ | sdr_outbound | 185 | 36.56 |

Source mix is broadly similar: inbound spans 43.28-46.16%, partner 17.76-20.49%, and outbound 33.35-37.14%. This is descriptive evidence against a large source-mix imbalance, not proof that source mix contributes nothing to conversion differences. Rounded shares can total 99.99% or 100.01%.

## 9.3 Within-company source concentration

The account/source detail reconciles to 1,280 accounts and 5,000 leads. Counts by number of observed sources are:

| Observed sources per account | Accounts |
| --- | ---: |
| 1 | 341 |
| 2 | 536 |
| 3 | 403 |

Of the 341 single-source accounts, 204 have only one lead; 137 have at least two leads, all from the same source. A 100% share based on one observation cannot establish persistent source preference. Individual-company concentration can coexist with similar aggregate source shares. Company identifiers and account-detail exports are not included in this milestone package.

## 9.4 Equal-account source composition

| Employee band | Accounts | Leads | Mean inbound share (%) | Mean partner share (%) | Mean outbound share (%) |
| --- | --- | --- | --- | --- | --- |
| 200-499 | 448 | 1796 | 45.35 | 20.25 | 34.4 |
| 500-999 | 455 | 1718 | 45.89 | 21 | 33.11 |
| 1000-1999 | 244 | 980 | 45.53 | 18.51 | 35.96 |
| 2000+ | 133 | 506 | 42.82 | 20.38 | 36.81 |

The four rows reconcile to 1,280 accounts and 5,000 leads. The means were independently recalculated from unrounded account/source counts, including zero shares. Average composition remains similar across size bands after equal company weighting. This does not imply every individual company has a balanced mix.

## 9.5 Conversion within industry and size

| Industry | Employee band | Accounts | Leads | Converted | Pooled rate (%) | Equal-account mean (%) |
| --- | --- | --- | --- | --- | --- | --- |
| healthcare_non_clinical | 200-499 | 116 | 499 | 119 | 23.85 | 22.96 |
| healthcare_non_clinical | 500-999 | 112 | 419 | 85 | 20.29 | 21.64 |
| healthcare_non_clinical | 1000-1999 | 56 | 228 | 34 | 14.91 | 14.27 |
| healthcare_non_clinical | 2000+ | 30 | 116 | 26 | 22.41 | 18.85 |
| logistics | 200-499 | 116 | 430 | 86 | 20 | 19.92 |
| logistics | 500-999 | 112 | 441 | 89 | 20.18 | 19.41 |
| logistics | 1000-1999 | 62 | 234 | 37 | 15.81 | 17.28 |
| logistics | 2000+ | 29 | 100 | 24 | 24 | 18.06 |
| manufacturing | 200-499 | 101 | 429 | 107 | 24.94 | 26.26 |
| manufacturing | 500-999 | 110 | 413 | 94 | 22.76 | 23.41 |
| manufacturing | 1000-1999 | 65 | 292 | 64 | 21.92 | 22.42 |
| manufacturing | 2000+ | 41 | 161 | 39 | 24.22 | 23.17 |
| professional_services | 200-499 | 115 | 438 | 83 | 18.95 | 18.17 |
| professional_services | 500-999 | 121 | 445 | 86 | 19.33 | 19.32 |
| professional_services | 1000-1999 | 61 | 226 | 53 | 23.45 | 25.52 |
| professional_services | 2000+ | 33 | 129 | 23 | 17.83 | 18.35 |

None of the four industries shows a fully decreasing equal-account mean across all size bands. Healthcare, logistics and manufacturing peak at 200-499, decline through 1000-1999, then rebound at 2000+. Professional services peaks at 1000-1999. Therefore the aggregate decline observed in milestone 08 is not a universal within-industry pattern.

Each company belongs to one industry and size band. These rows sum to 1,280 accounts, 5,000 leads and 1,049 conversions. The largest-size industry cells contain only 29-41 accounts. Their estimates deserve cautious interpretation; no category merge has been implemented.

## Interpretation limits and next stage

These are descriptive subgroup and weighting comparisons on synthetic data. No causal effects, statistical significance, interaction tests, confidence intervals, source standardisation or formal composition decomposition have been established. Multiple leads within an account may be dependent, and small within-account denominators can produce extreme observed rates. Neither a sweet spot nor a universal size-based prioritisation rule is established.

Next planned stage: engagement analysis, followed by buyer/contact coverage analysis and reusable reporting definitions before Power BI. Revenue and maturity stratification remains untested in this stage. The source-mix investigation is complete at its stated descriptive scope; final commercial recommendations remain pending.

## Packaging and validation

Executable SQL is unchanged from the user-uploaded script. Comments were translated into English and obvious comment typos corrected. Workbook outputs were reconciled against known totals, pooled rates checked against counts, and the four equal-account source-share rows independently recalculated. The assistant did not execute SQL against the user's server.

Only README, SQL and this aggregate analysis note are included. Raw CSV, Excel workbooks, account-level exports, screenshots, dissertation files and supervisor feedback are excluded.
