# Cleaning rules and validated lead view

## Completed scope

`sql/06_create_clean_view.sql` creates `clean.vw_lead_scoring` in `B2BLeadAnalytics`. Its definition and five validation queries were executed in SSMS; the results were reviewed from the supplied screenshot on 14 October 2026. This is a cleaning milestone, not a completed business analysis or Power BI model.

The view exposes the 32 original columns plus five derived columns, with one row per lead. It has no row filter, join or aggregation. The raw table is unchanged. The earlier practice queries and original comments remain in the script; only the section marked as the formal view definition creates the database object. `CREATE OR ALTER VIEW` supports rerunning the definition. The script creates the `clean` schema if absent.

## Implemented rules

| Derived field | Rule |
| --- | --- |
| `clean_days_since_last_touch` | Convert negative last-touch days to NULL; otherwise preserve the value. |
| `clean_expected_acv` | Convert negative expected ACV to NULL; otherwise preserve the value. |
| `clean_opportunity_estimated_acv` | Convert negative opportunity ACV to NULL; otherwise preserve the value. |
| `flag_touch_recency_conflict` | NULL if either recency is missing or negative; 1 if both are non-negative and last-touch days exceed first-touch days; otherwise 0. |
| `opportunity_acv_status` | Classify raw opportunity ACV as negative, missing without an opportunity recorded, missing with an opportunity created, or available. |

Existing NULLs are not imputed. Zero is retained as a distinct observed value. No leads are deleted. ACV status describes observed data conditions, not a proven cause of missingness. Available means non-NULL and non-negative under these checks, not verified commercial accuracy or realised revenue.

## Verified results

| Row preservation | Rows | Distinct lead IDs |
| --- | ---: | ---: |
| Raw table | 5,000 | 5,000 |
| Clean view | 5,000 | 5,000 |

| Clean field | Remaining negative values | NULL values |
| --- | ---: | ---: |
| Last-touch days | 0 | 574 |
| Expected ACV | 0 | 506 |
| Opportunity estimated ACV | 0 | 1,470 |

The NULL totals reconcile to original NULLs plus negative values: 472 + 102 = 574; 408 + 98 = 506; 1,400 + 70 = 1,470.

| Recency flag | Meaning | Leads |
| --- | --- | ---: |
| NULL | Cannot assess because at least one recency is missing or negative | 903 |
| 0 | Both values are non-negative and pass the order check | 3,963 |
| 1 | Conflicting order under the shared-reference-date assumption | 134 |
| Total | | 5,000 |

| Opportunity ACV status (exact SQL label) | Leads |
| --- | ---: |
| `Invalid negative value` | 70 |
| `no opportunity recorded` | 745 |
| `Opportunity created but value missing` | 655 |
| `Value available` | 3,530 |
| Total | 5,000 |

The raw-to-view EXCEPT comparison across all 32 original columns returned **0 missing or changed source rows**. Together with the equal row and unique-lead counts, this confirms source-row preservation for this run. These are executed validation results, not just anticipated counts.

## Rules for downstream metrics

- Overall lead counts and conversion rates retain all leads. Do not apply a report-wide recency filter.
- For the planned contact-recency comparisons, use `flag_touch_recency_conflict = 0`. This provisional complete-pair rule uses 3,963 leads and excludes 903 unassessable plus 134 conflicting records. Show the eligible population and acknowledge possible selection bias.
- `clean_days_since_last_touch` only removes negative values. It still contains positive conflicting values and some values with a missing counterpart. The recency metric filter must be applied explicitly; creating the view alone does not enforce it.
- Use the clean ACV fields for numeric analysis. Missing values must not be treated as zero; report the non-missing denominator and coverage alongside averages. Raw ACV and status retain the reason a value is unavailable.
- First- and last-touch recency must share a reference date and compatible event definitions for the order check to be meaningful. These definitions remain unconfirmed, so flagged values are not swapped or invented.

## Planned next work

GitHub publication of this milestone is followed by business analysis/reporting definitions and Power BI connection, modelling and measures. Account contact coverage and buyer-role combinations remain planned. No Power BI connection, dashboard or DAX measures have been completed at this milestone.

Only code and documentation are included. The CSV, exported row-level Excel files, screenshots, database backups and local credentials are excluded. Public source/version/licence verification remains pending before any data redistribution.
