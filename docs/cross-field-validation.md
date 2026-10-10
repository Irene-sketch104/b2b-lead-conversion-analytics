# Cross-field validation

## Scope and evidence

Milestone 05 contains four read-only checks on `B2BLeadAnalytics.raw.lead_scoring`, saved in [05_validate_cross_fields.sql](../sql/05_validate_cross_fields.sql). The author executed the queries in SSMS. The touch-count check returned no rows according to the author; opportunity summaries were reviewed in screenshots. The author reported 134 recency-order exceptions, also supported by the SSMS result count shown in a screenshot.

The uploaded SQL was reviewed for this package, not independently executed against the author's SQL Server. Query logic is preserved; a few comments were clarified and the file is encoded as UTF-8 with BOM to preserve Chinese comments. No raw records were changed.

## 1. Touch-count arithmetic

Check: `touch_count = inbound_touch_count + outbound_touch_count` for records where all three fields are non-NULL.

Observed result: **0 mismatches**. Records with missing components were excluded from this comparison, not deleted or filled. This check alone does not establish a safe imputation rule for every incomplete record.

## 2. Missing opportunity estimated ACV

| opportunity_created | Meaning | ACV present | ACV missing | Total leads (derived) |
|---|---|---:|---:|---:|
| 0 | Not marked as created | 0 | 745 | 745 |
| 1 | Marked as created | 3,600 | 655 | 4,255 |
| Total | All leads | 3,600 | 1,400 | 5,000 |

Totals above are calculated from the observed present and missing counts; the author's query does not separately select total lead count. `COUNT(opportunity_estimated_acv)` counts non-NULL values, including any negative values. Present does not mean valid.

Missing ACV is not restricted to leads without an opportunity. The 745 values may be inapplicable, while the 655 values may be unknown or not yet estimated; the flags alone cannot establish the missingness mechanism. No values were replaced with zero, a mean or a median. Those choices could materially change reported averages.

## 3. Opportunity-status combinations

The author's output places `has_open_opportunity` before `opportunity_created`.

| has_open_opportunity | opportunity_created | Lead count |
|---|---|---:|
| 0 | 0 | 745 |
| 0 | 1 | 325 |
| 1 | 1 | 3,930 |

The open=1 / created=0 combination was absent. All observed open opportunities were also marked as created.

The 325 leads are marked as created but not open. These fields alone do not show that they were never followed up, won or lost. Here, open is provisionally described as an opportunity in progress (進行中的商機), not simply a potential opportunity. Exact scope and observation timing still require source documentation. No funnel stages or closed-opportunity outcomes are inferred from these flags.

## 4. First-touch and last-touch recency order

Check: both recency values are non-negative and `days_since_last_touch > days_since_first_touch`. NULL comparisons do not qualify for the WHERE conditions.

Observed result: **134 leads flagged**. If both fields measure elapsed time from the same reference date, the most recent touch cannot precede the first touch. Under that assumption these pairs are inconsistent. Source definitions and reference dates must be confirmed before treating the issue as a definite recording error.

The previously identified 102 negative last-touch values are excluded by this query and are a separate issue. Missing values are also excluded. No dates were reconstructed, values swapped, rows deleted or values imputed.

## Completed versus next steps

Completed: the four checks, review of their results and documentation of unresolved interpretation issues.

Planned: confirm field definitions where possible; document cleaning and missing-value treatment; implement an analytical layer while preserving the raw table; validate the transformed outputs. Account-level contact coverage, role mix, Power BI and commercial recommendations remain future work.

This is a scoped validation milestone, not certification that every field is error-free. The repository update includes no raw CSV, row-level result export, screenshot, credential or private machine path. All findings concern the synthetic portfolio dataset.
