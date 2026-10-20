# Contact coverage, buyer roles and seniority — milestone 11

## Scope

Sections 11.1–11.6 of `sql/11_analyze_contact_coverage.sql` describe recorded contacts, buyer roles and seniority within accounts, then compare lead conversion across account groups. These are read-only queries against `clean.vw_lead_scoring` in `B2BLeadAnalytics`. Run in SSMS after creating and validating the clean view in milestone 06. No new views, source updates or imputations are introduced. The script is preserved exactly as supplied by the author, including comments.

This completes the agreed contact-count, buyer-role and seniority exploration. Function counts/combinations already exist in the account view, but their conversion comparisons were not performed in this milestone and are outside this stage's completed scope.

## Definitions and interpretation

- Contact count uses `COUNT(DISTINCT contact_id)` within each account; repeated leads from the same contact do not create additional contacts.
- Buyer-role and seniority counts measure distinct recorded categories. Seniority count measures diversity, not the highest rank.
- Combinations are deduplicated per account and sorted as text before concatenation. Text order is not a hierarchy.
- Outcomes are aggregated independently to one row per account before joining to the one-row-per-account combination. This avoids multiplying lead counts by the number of roles or levels.
- Lead rate = converted leads / all leads in the group × 100.
- Equal-account mean = average of each represented account's unrounded lead conversion rate. It is not the share of companies with any conversion.
- Every account belongs to one group within each query. Account counts therefore sum to 1,280 for these account-profile partitions, unlike the overlapping account counts in lead-engagement bands.
- Account share in 11.1 uses 1,280 accounts as its denominator.
- SQL distinct counts and `STRING_AGG` ignore NULL categories. These summaries describe observed categories, not proof of complete buying-team coverage; they do not separately measure category completeness.
- Coverage and combinations describe the supplied snapshot, not a contact-acquisition sequence or joint participation in each deal. Adding a contact or seniority level has not been tested as an intervention.

## Contact coverage (11.1–11.2)

There are 1,080 accounts with one to three recorded contacts (84.38%). Six to eight contacts cover only 20 accounts (1.56%). The weighted contact total is 2,889, matching the validated contact baseline.

| Count | Accounts | Leads | Converted leads | Lead rate (%) | Equal-account mean (%) |
| --- | --- | --- | --- | --- | --- |
| 1 | 418 | 743 | 147 | 19.78 | 20.44 |
| 2 | 408 | 1426 | 295 | 20.69 | 20.96 |
| 3 | 254 | 1309 | 277 | 21.16 | 20.94 |
| 4 | 134 | 933 | 198 | 21.22 | 21.27 |
| 5 | 46 | 390 | 87 | 22.31 | 22.01 |
| 6 | 15 | 137 | 35 | 25.55 | 26.66 |
| 7 | 3 | 39 | 6 | 15.38 | 15.38 |
| 8 | 2 | 23 | 4 | 17.39 | 17.05 |

Pooled rates increase from one to six contacts. Equal-account means are broadly similar but nearly flat from two to three. Six contacts is the highest observed group under both metrics, but it has only 15 accounts; seven and eight contacts have three and two accounts. No optimal contact count is established.

Coverage also varies with lead volume: the one-contact group averages 743/418 = 1.78 leads per account, compared with 137/15 = 9.13 for six contacts. Equal-account weighting does not control for lead volume, industry, size or engagement differences.

## Buyer-role counts (11.3)

| Count | Accounts | Leads | Converted leads | Lead rate (%) | Equal-account mean (%) |
| --- | --- | --- | --- | --- | --- |
| 1 | 539 | 1182 | 233 | 19.71 | 20.35 |
| 2 | 499 | 2227 | 474 | 21.28 | 21.18 |
| 3 | 215 | 1361 | 292 | 21.45 | 21.42 |
| 4 | 27 | 230 | 50 | 21.74 | 22.76 |

Both metrics increase across role-count groups. The largest pooled difference is one to two roles (+1.57 percentage points); two to four roles differ by only 0.46 points. The four-role group has 27 accounts. More recorded roles are associated with slightly higher rates here, but the analysis does not establish a benefit from adding roles.

## Buyer-role combinations (11.4)

| Count | Combination | Accounts | Leads | Converted leads | Lead rate (%) | Equal-account mean (%) |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | champion | 142 | 302 | 59 | 19.54 | 22.59 |
| 1 | economic_buyer | 137 | 293 | 59 | 20.14 | 19.39 |
| 1 | technical_evaluator | 131 | 304 | 64 | 21.05 | 21.22 |
| 1 | end_user | 129 | 283 | 51 | 18.02 | 18.01 |
| 2 | champion, end_user | 102 | 501 | 102 | 20.36 | 19.79 |
| 2 | economic_buyer, end_user | 96 | 417 | 91 | 21.82 | 21.16 |
| 2 | champion, technical_evaluator | 79 | 336 | 74 | 22.02 | 23.82 |
| 2 | end_user, technical_evaluator | 76 | 343 | 87 | 25.36 | 25.11 |
| 2 | economic_buyer, technical_evaluator | 75 | 306 | 54 | 17.65 | 17.12 |
| 2 | champion, economic_buyer | 71 | 324 | 66 | 20.37 | 20.34 |
| 3 | champion, economic_buyer, technical_evaluator | 60 | 364 | 69 | 18.96 | 18.85 |
| 3 | champion, economic_buyer, end_user | 58 | 376 | 83 | 22.07 | 22.19 |
| 3 | economic_buyer, end_user, technical_evaluator | 54 | 326 | 74 | 22.70 | 23.29 |
| 3 | champion, end_user, technical_evaluator | 43 | 295 | 66 | 22.37 | 21.63 |
| 4 | champion, economic_buyer, end_user, technical_evaluator | 27 | 230 | 50 | 21.74 | 22.76 |

Among two-role groups, `end_user, technical_evaluator` has 76 accounts and 343 leads, with 25.36% pooled and 25.11% equal-account rates. `economic_buyer, technical_evaluator` has 75 accounts and 306 leads, with 17.65% and 17.12%. The pooled gap is 7.71 percentage points despite similar group sizes; the two-role aggregate of 21.28% hides this variation.

This does not imply that economic buyers reduce conversion. These are different companies, potentially differing in firmographics and engagement. Single-role rankings also change with weighting: technical evaluator is highest under pooled weighting, while champion is highest under equal-account weighting.

## Seniority counts (11.5)

| Count | Accounts | Leads | Converted leads | Lead rate (%) | Equal-account mean (%) |
| --- | --- | --- | --- | --- | --- |
| 1 | 532 | 1182 | 230 | 19.46 | 20.08 |
| 2 | 505 | 2173 | 465 | 21.40 | 21.54 |
| 3 | 196 | 1247 | 279 | 22.37 | 22.13 |
| 4 | 42 | 342 | 63 | 18.42 | 17.72 |
| 5 | 5 | 56 | 12 | 21.43 | 22.65 |

Both rates rise from one to three levels, fall at four, and rise at five. Five levels contains only five accounts. This pattern does not establish a three-level sweet spot or an advantage from covering every level.

## Seniority combinations (11.6)

| Count | Combination | Accounts | Leads | Converted leads | Lead rate (%) | Equal-account mean (%) |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | manager | 173 | 416 | 85 | 20.43 | 22.59 |
| 1 | director | 148 | 329 | 62 | 18.84 | 18.98 |
| 1 | individual_contributor | 125 | 276 | 55 | 19.93 | 20.77 |
| 1 | vp | 70 | 134 | 22 | 16.42 | 14.10 |
| 1 | c_suite | 16 | 27 | 6 | 22.22 | 23.96 |
| 2 | director, manager | 119 | 521 | 122 | 23.42 | 24.14 |
| 2 | individual_contributor, manager | 96 | 433 | 107 | 24.71 | 24.80 |
| 2 | director, individual_contributor | 81 | 352 | 67 | 19.03 | 19.24 |
| 2 | manager, vp | 56 | 234 | 46 | 19.66 | 20.20 |
| 2 | individual_contributor, vp | 49 | 199 | 30 | 15.08 | 15.46 |
| 2 | director, vp | 38 | 169 | 31 | 18.34 | 17.93 |
| 2 | c_suite, individual_contributor | 22 | 86 | 19 | 22.09 | 19.65 |
| 2 | c_suite, manager | 18 | 71 | 18 | 25.35 | 24.03 |
| 2 | c_suite, director | 17 | 69 | 16 | 23.19 | 22.21 |
| 2 | c_suite, vp | 9 | 39 | 9 | 23.08 | 28.15 |
| 3 | director, individual_contributor, manager | 54 | 355 | 92 | 25.92 | 26.53 |
| 3 | director, manager, vp | 38 | 232 | 47 | 20.26 | 18.47 |
| 3 | individual_contributor, manager, vp | 34 | 210 | 49 | 23.33 | 24.12 |
| 3 | director, individual_contributor, vp | 21 | 133 | 25 | 18.80 | 17.83 |
| 3 | c_suite, individual_contributor, manager | 15 | 101 | 17 | 16.83 | 18.03 |
| 3 | c_suite, director, manager | 11 | 71 | 20 | 28.17 | 27.35 |
| 3 | c_suite, director, individual_contributor | 10 | 66 | 15 | 22.73 | 20.01 |
| 3 | c_suite, manager, vp | 6 | 35 | 5 | 14.29 | 14.35 |
| 3 | c_suite, director, vp | 5 | 30 | 6 | 20 | 21.94 |
| 3 | c_suite, individual_contributor, vp | 2 | 14 | 3 | 21.43 | 21.11 |
| 4 | director, individual_contributor, manager, vp | 22 | 188 | 31 | 16.49 | 15.60 |
| 4 | c_suite, individual_contributor, manager, vp | 7 | 53 | 10 | 18.87 | 20.35 |
| 4 | c_suite, director, individual_contributor, vp | 6 | 41 | 12 | 29.27 | 26.75 |
| 4 | c_suite, director, individual_contributor, manager | 5 | 40 | 7 | 17.50 | 14.14 |
| 4 | c_suite, director, manager, vp | 2 | 20 | 3 | 15 | 13.64 |
| 5 | c_suite, director, individual_contributor, manager, vp | 5 | 56 | 12 | 21.43 | 22.65 |

Among two-level groups, `individual_contributor, manager` (96 accounts) and `director, manager` (119 accounts) have relatively high rates under both metrics. `individual_contributor, vp` is lower, at 15.08% pooled and 15.46% equal-account. There is no simple higher-rank-is-better pattern.

For three levels, `director, individual_contributor, manager` is the largest group (54 accounts, 355 leads), with rates of 25.92% and 26.53%. The higher pooled rate for `c_suite, director, manager` (28.17%) comes from only 11 accounts.

The four-level combination without c_suite represents 22 of 42 accounts and 188 of 342 leads. Its 16.49% pooled and 15.60% equal-account rates contribute substantially to the category's lower mean. Comparing it with a three-level combination is not before-and-after evidence of adding a VP. Small groups elsewhere in the table make apparent rankings particularly unstable.

## Evidence and validation

Evidence: author-supplied SQL and worksheet `11.Contacts` in `SQL_Results.xlsb(1).xlsx`, reviewed on 20 October 2026. The author executed the queries in local SSMS; the reviewer inspected the code and exported results without connecting to or rerunning SQL Server.

| Section | Worksheet range | Verified totals |
| --- | --- | --- |
| 11.1 contact distribution | A3:D10 | 1,280 accounts; 5,000 leads; 2,889 contacts derived from count × accounts |
| 11.2 contact conversion | A13:F20 | 1,280 accounts; 5,000 leads; 1,049 conversions |
| 11.3 role counts | A24:F27 | 1,280; 5,000; 1,049 |
| 11.4 role combinations | B30:H44 | 1,280; 5,000; 1,049 |
| 11.5 seniority counts | B47:G51 | 1,280; 5,000; 1,049 |
| 11.6 seniority combinations | B53:H83 | 1,280; 5,000; 1,049 |

Contact distributions agree between 11.1 and 11.2. Combination account, lead and conversion counts roll up exactly to their corresponding category-count summaries. Pooled rates and account shares recalculate correctly to displayed precision. Account-count-weighted combination means agree with category-count means within rounding tolerance. Equal-account means cannot be independently reconstructed from group totals alone; their query definitions and cross-summary consistency were checked.

## Reporting use and remaining work

Show account and lead counts next to rates. Keep pooled and equal-account metrics explicitly labelled and show coverage as recorded snapshot coverage. Do not present the highest observed combination as a recommended team design or optimal coverage threshold. These synthetic-data comparisons are descriptive, unadjusted and involve many groups; no significance tests, causal effects or validated targeting rules are claimed.

Next: milestone 12 will consolidate existing reporting fields, band definitions, metric definitions and model-readiness checks. Power BI connection, relationships, DAX measures and pages remain unimplemented. Static account-profile counts and combinations must have explicit filter behaviour in the eventual model; filtering leads does not automatically rebuild the account's recorded profile. Further function-combination exploration is deferred rather than required before Power BI.

Only this aggregate note, the SQL and README are included in the update. Raw records and the personal working workbook are excluded.
