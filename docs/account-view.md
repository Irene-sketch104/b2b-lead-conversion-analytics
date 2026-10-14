# Account view and validation

## Completed scope

`sql/07_create_account_view.sql` retains the exploratory queries, creates the `analytics` schema if needed, and creates or alters `analytics.vw_accounts` in `B2BLeadAnalytics`. It reads `clean.vw_lead_scoring` without changing raw data or the clean view. Each account has one row.

The user executed the five validation queries in SSMS on 14 October 2026 and supplied a screenshot of all five result sets. The values below are observed results, not assumed expectations.

## Fields and definitions

| Fields | Meaning |
| --- | --- |
| `account_id` | Company identifier; unique at this view's grain |
| `industry`, `region`, `employee_band`, `estimated_revenue_band`, `process_maturity_band` | Consistent company attributes retained from the source |
| `lead_count` | Number of lead records for the company; not a transaction count |
| `contact_count` | Distinct contacts observed for the company |
| `buyer_role_count` | Distinct buyer roles observed for the company |
| `seniority_count` | Distinct seniority categories observed for the company |
| `role_function_count` | Distinct functions observed for the company |
| `buyer_role_combination`, `seniority_combination`, `role_function_combination` | Separate comma-separated lists of distinct categories, ordered by SQL text collation |

The view has 14 columns. Separate CTEs aggregate counts and category lists before joining them by account ID. Category lists use distinct account/category pairs before `STRING_AGG`, so repeated lead records do not repeat a category. Ordering is textual, not a business hierarchy. Profile attributes use `DISTINCT`; inconsistent profiles are not silently resolved with `MAX`.

## Observed validation results

| Check | Observed result |
| --- | ---: |
| Account rows | 1,280 |
| Distinct accounts | 1,280 |
| Sum of company lead counts | 5,000 |
| Sum of company distinct contact counts | 2,889 |
| Duplicate / missing / extra accounts | 0 / 0 / 0 |
| Accounts with count mismatches | 0 |
| Profile mismatches | 0 |
| Missing / extra / duplicate list categories | 0 / 0 / 0 |

The contact sum can be compared with the global distinct contact total because prior checks established that each contact belongs to one account. Count checks compare all five account counts with a fresh source aggregation. Category checks split the lists and compare them with source categories; this assumes category labels contain no commas, as in the current dataset.

## Interpretation and reporting limits

- Contact count measures observed coverage in this dataset, not every contact at the company.
- Role, seniority and function combinations describe categories observed across company leads. They do not establish a single buying committee or show which role corresponds to which seniority/function.
- Company attributes include process maturity; do not assume every attribute belongs to the dissertation's firmographic block without checking its original definitions.
- View counts cover the full source data available at query time. They do not automatically recalculate when a lead-date or lead-source filter is applied in Power BI. Interactive lead counts, contact counts and conversion metrics must be defined at the appropriate grain and filter context.
- This view does not yet contain conversion comparisons, commercial recommendations or Power BI measures. More contacts or roles must not be presented as causing conversion.
- Future data refreshes require rerunning validation, particularly profile consistency, unique accounts and category-list checks.

## Run order and next stage

Run the earlier setup/import steps and `06_create_clean_view.sql` before this script. The original previews can be run for learning; the marked formal section creates the account view and runs validation.

After this milestone is committed and confirmed, continue with SQL commercial analysis: lead sources, company segments, engagement, buyer characteristics, and contact coverage/role combinations. Power BI connection, relationships, DAX and dashboards remain future work.

This milestone package contains only the README, this documentation and the SQL script. Raw CSV data, query-result workbooks, screenshots and credentials are not included.
