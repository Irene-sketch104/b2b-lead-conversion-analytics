# SQL validation — milestone 03

## Scope and evidence

The project owner executed `sql/03_validate_schema.sql` in local SQL Server through SSMS. Results were reviewed from supplied screenshots and explicit result confirmations against the initial CSV inspection. This report records those observed checks; it does not claim a separate automated database test run.

The submitted SQL preserves the owner's query structure and learning comments. Only comment spelling (`raws` to `rows`, `promary` to `primary`) and the clarification `non-NULL ids` were adjusted. Query logic was unchanged. The packaged text uses UTF-8.

## Observed checks

| Check | Observed result | Interpretation |
| --- | --- | --- |
| Column inventory | 32 columns | Types and NULL settings match the import plan |
| Total rows | 5,000 | Matches CSV baseline |
| Non-NULL lead IDs | 5,000 | No NULL lead IDs |
| Distinct lead IDs | 5,000 | No duplicate lead IDs |
| Primary key | `PK_lead_scoring` on `lead_id` | Primary-key constraint exists |
| Conversion outcome 0 | 3,951 | Matches CSV baseline |
| Conversion outcome 1 | 1,049 | Matches CSV baseline; 20.98% of all leads |
| Negative `days_since_last_touch` | 102 | Existing source anomaly preserved |
| Negative `expected_acv` | 98 | Existing source anomaly preserved |
| Negative `opportunity_estimated_acv` | 70 | Existing source anomaly preserved |

The three negative counts are separate field counts; their sum is not a count of distinct affected leads.

## Schema confirmed

- Thirteen identifier/category columns: `nvarchar(50)`, NOT NULL.
- `lead_created_at`: `date`, NOT NULL.
- Fourteen numeric measures: `float`, nullable (listed below).
- `opportunity_created`, `has_open_opportunity`, `converted_within_90_days`: `bit`, NOT NULL.
- `total_touches_all`: `int`, NOT NULL.
- `lead_id` is the primary-key column. NULL and duplicate key values are prohibited.

The NULL under `CHARACTER_MAXIMUM_LENGTH` for non-text fields means text length is not applicable; it is not a missing data count.

## NULL counts

All 32 column counts matched the initial CSV baseline. Fourteen columns contain NULLs:

| Column | NULL count |
| --- | ---: |
| `opportunity_estimated_acv` | 1,400 |
| `days_since_last_touch` | 472 |
| `days_since_first_touch` | 439 |
| `total_session_duration_seconds` | 416 |
| `touch_count` | 413 |
| `outbound_touch_count` | 412 |
| `expected_acv` | 408 |
| `pricing_page_views` | 408 |
| `touches_last_7_days` | 403 |
| `inbound_touch_count` | 399 |
| `activity_count` | 398 |
| `demo_page_views` | 389 |
| `touches_days_0_7` | 388 |
| `session_count` | 378 |

The remaining eighteen columns have zero NULLs: `split`, `account_id`, `industry`, `region`, `employee_band`, `estimated_revenue_band`, `process_maturity_band`, `contact_id`, `role_function`, `seniority`, `buyer_role`, `lead_id`, `lead_created_at`, `lead_source`, `opportunity_created`, `has_open_opportunity`, `total_touches_all`, and `converted_within_90_days`.

`opportunity_estimated_acv` has the highest missingness: 1,400 / 5,000 = 28%. These are per-column counts, not a count of rows with any missing value. Empty strings, whitespace and zero are not NULL and are not covered by this check.

## Running the saved checks

Open `sql/03_validate_schema.sql` in SSMS and execute it against the imported database. The script starts with `USE B2BLeadAnalytics`. It only reads data and metadata. Execute the complete dynamic SQL block together, from `DECLARE @sql` through `EXEC sp_executesql @sql`; do not insert `GO` inside that block. The dynamic query uses STRING_AGG, available in SQL Server 2017 and later.

Expected result sets, in script order: column inventory; lead ID counts; conversion counts; column NULL counts; negative recency count; two negative ACV counts; primary-key metadata. The ACV UNION ALL result has no guaranteed row order; identify results by `column_name`.

## Limits and next work — not yet completed

- These checks do not establish full row-by-row equivalence with the CSV or complete data quality.
- Account/contact cardinality and attribute consistency, touch-count arithmetic, date ranges and broader numeric validity still need SQL checks. Earlier Python observations remain baseline evidence only.
- Missingness mechanisms and the meaning of negative values have not been resolved. No rows were deleted, NULLs filled, negative values corrected or analytical views created.
- Cleaning rules, type conversions for the analysis layer, model relationships, business analysis and Power BI remain planned.
- Observation windows and possible post-outcome fields require care before early-prioritisation claims.

## Repository contents

This milestone adds a SQL script and aggregate validation notes, and updates README and import notes. No raw CSV, database backups, credentials, private local paths or screenshots containing machine/account details are included. Dataset source and redistribution documentation remain pending.
