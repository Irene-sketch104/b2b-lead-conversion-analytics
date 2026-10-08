# Initial raw-data assessment

Status: completed preliminary inspection of the supplied CSV; SQL Server validation pending.
Method: direct inspection with Python/pandas, with AI assistance during planning. CSV types below are inferred semantic types, not an implemented SQL schema.

## Baseline checks

| Check | Observed result |
|---|---|
| Rows / columns | 5,000 / 32 |
| Exact duplicate rows | 0 |
| lead_id | 5,000 distinct; no missing or duplicate values |
| account_id | 1,280 distinct; no missing values; up to 13 leads per account |
| contact_id | 2,889 distinct; no missing values; up to 7 leads per contact |
| Outcome | 1,049 True; 3,951 False; no missing values |
| Overall conversion rate | 1,049 / 5,000 = 20.98% |
| lead_created_at | 2024-01-01 to 2024-01-30; all values parse as dates |
| Rows with at least one missing value | 3,727 |
| Account attribute consistency | All five company attributes constant within account_id |
| Contact attribute consistency | account_id, role_function, seniority and buyer_role constant within contact_id |
| Touch reconciliation | All 3,857 complete triples satisfy touch_count = inbound_touch_count + outbound_touch_count |

Repeated account/contact IDs represent repeated membership, not automatically duplicate records. Conversion is a lead-level outcome, not an account-level rate.

## Column inventory

| Column | Semantic type | Missing | Initial role |
|---|---|---:|---|
| split | Category | 0 | Original model partition; exclude from business report |
| account_id | Text ID | 0 | Account key |
| industry | Category | 0 | Company segment |
| region | Category | 0 | Company segment |
| employee_band | Ordered category | 0 | Company segment |
| estimated_revenue_band | Ordered category | 0 | Company segment; not actual revenue |
| process_maturity_band | Ordered category | 0 | Company segment |
| contact_id | Text ID | 0 | Contact identifier |
| role_function | Category | 0 | Buyer characteristic |
| seniority | Category | 0 | Buyer characteristic |
| buyer_role | Category | 0 | Buyer characteristic |
| lead_id | Text ID | 0 | Candidate primary key |
| lead_created_at | Date | 0 | Lead creation date |
| lead_source | Category | 0 | Source comparison |
| touch_count | Integer count | 413 | Engagement |
| inbound_touch_count | Integer count | 399 | Engagement detail |
| outbound_touch_count | Integer count | 412 | Engagement detail |
| session_count | Integer count | 378 | Engagement |
| pricing_page_views | Integer count | 408 | Pricing interest |
| demo_page_views | Integer count | 389 | Demo interest |
| total_session_duration_seconds | Numeric duration | 416 | Engagement |
| touches_days_0_7 | Integer count | 388 | Window definition to confirm |
| touches_last_7_days | Integer count | 403 | Window definition to confirm |
| days_since_first_touch | Decimal days | 439 | Recency/tenure definition to confirm |
| activity_count | Integer count | 398 | Engagement |
| days_since_last_touch | Decimal days | 472 | Quality issues; defer use |
| opportunity_created | Boolean | 0 | Potential later-stage information; defer prioritisation use |
| has_open_opportunity | Boolean | 0 | Potential later-stage information; defer prioritisation use |
| opportunity_estimated_acv | Decimal amount | 1,400 | Negative/missing values; defer use |
| expected_acv | Decimal amount | 408 | Negative/missing values; defer use |
| total_touches_all | Integer count | 0 | Observation window unclear; defer prioritisation use |
| converted_within_90_days | Boolean | 0 | Target outcome |

## Categorical coverage

| Field | Values |
|---|---|
| split | train, valid, test |
| industry | logistics, healthcare_non_clinical, manufacturing, professional_services |
| region | UK, US |
| employee_band | 200-499, 500-999, 1000-1999, 2000+ |
| estimated_revenue_band | $1M-$10M, $10M-$50M, $50M-$200M, $200M+ |
| process_maturity_band | low, medium, high |
| role_function | procurement_manager, it_director, ap_manager, vp_finance |
| seniority | individual_contributor, manager, director, vp, c_suite |
| buyer_role | end_user, technical_evaluator, champion, economic_buyer |
| lead_source | inbound_marketing, partner_referral, sdr_outbound |

No leading/trailing whitespace was found in text columns. Category combinations should not be interpreted as proof of real-world organisational roles because the data is synthetic.

## Quality issues and proposed treatment

- `days_since_last_touch`: 102 negative values. Flag for review; do not silently take absolute values.
- `expected_acv`: 98 negative values. `opportunity_estimated_acv`: 70 negative values. Do not use for revenue/value KPIs without definitions and a defensible treatment.
- Missing opportunity ACV includes 745 records without an opportunity and 655 with an opportunity. Distinguish structural absence from missing information.
- Unknown engagement is not zero engagement. Preserve NULLs and use explicit missing categories when grouping.
- Preserve source rows rather than deleting all 3,727 records with any missing value.
- No transformations have been applied to the supplied CSV in this milestone. These are proposed handling rules.

## Timing and analytical limits

The CSV alone does not establish when every feature was observed relative to conversion. Opportunity fields, ACV fields and `total_touches_all` need particular scrutiny; other engagement fields also require observation-window confirmation. Suspected leakage is not confirmed leakage.

There is no conversion date, event-level activity history, full stage history, realised revenue or supplied extraction/as-of date. Outcome follow-up completeness cannot be independently verified. Lead creation dates alone do not justify long-term trends or cohort maturity assumptions.

No `acct_n_depts_pricing` or ready-made ICP score exists in this raw file. Dissertation-derived features must not be assumed to exist here.

Future segment analysis must show denominator sizes and missingness, account for repeated account membership in interpretation, and explain any minimum-volume rule. No segment ranking or commercial recommendation has been completed yet.

## Next validation milestone

After database import, reproduce row counts, key checks, missing counts, category coverage and anomaly counts in SQL. Resolve mismatches before building analytical views. No SQL scripts or executed SQL results are included at this stage.
