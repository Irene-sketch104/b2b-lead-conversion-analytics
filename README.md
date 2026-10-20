# B2B Lead Conversion & Commercial Insights

A learning-led SQL Server and Power BI portfolio project exploring how lead sources, company characteristics, buyer roles and engagement signals relate to 90-day B2B lead conversion.

## Business question

What signals help a commercial team understand lead quality, conversion performance and prioritisation opportunities?

The intended audience is Sales Operations / Commercial Analytics. This project focuses on descriptive analysis and decision support, not rebuilding predictive models from the underlying dissertation.

## Current status

**Milestone 12: SQL reporting view and model/metric definitions completed; ready to begin Power BI connection.**

Completed:
- Defined the business question, project boundaries and proposed workflow.
- Inspected the supplied CSV: 5,000 lead records and 32 columns.
- Identified keys, missingness, consistency checks and data-quality concerns.
- Proposed a small account-to-lead model; it has not been implemented.
- Connected to the local SQL Server instance using Windows Authentication.
- Created `B2BLeadAnalytics` and the `raw` schema.
- Imported the CSV into `raw.lead_scoring` using the SSMS Import Flat File wizard.
- Executed a SQL row-count check: 5,000 rows, matching the CSV baseline.
- Verified all 32 column types and NULL settings, plus the primary key on `lead_id`.
- Confirmed 5,000 non-NULL, distinct lead IDs and the conversion outcome counts.
- Compared NULL counts across all 32 columns with the CSV baseline: all matched.
- Confirmed negative-value counts in recency and two ACV fields; raw values remain unchanged.
- Verified 5,000 distinct leads, 2,889 contacts and 1,280 accounts in SQL.
- Confirmed each contact maps to one account and has consistent buyer role, function and seniority.
- Confirmed company attributes are consistent across leads within each account.
- Found no touch-count arithmetic mismatches among records with all three required values.
- Split 1,400 missing opportunity ACV values into 745 leads without a created opportunity and 655 with one.
- Reviewed opportunity-status combinations: no leads are marked open without also being marked created.
- Flagged 134 leads where non-negative last-touch recency exceeds first-touch recency; interpretation requires a shared reference date.

- Created `clean.vw_lead_scoring` with all 32 raw columns and five derived fields.
- Validated 5,000 rows and unique leads, negative-to-NULL cleaning, recency flags and ACV status counts.
- Confirmed that no source rows or original column values are missing or changed in the view.

- Created `analytics.vw_accounts`: one row per company, combining company attributes, distinct contact counts and buyer-role, seniority and function counts/combinations.
- Validated 1,280 unique accounts, 5,000 total leads and 2,889 total contacts, with no missing/extra accounts, count mismatches, profile mismatches or category-list discrepancies.

- Completed six lead conversion summaries: source, industry, employee band, revenue band, region and process maturity. Each reconciles to 5,000 leads and 1,049 conversions.
- Compared pooled lead conversion rates with equally weighted company mean lead conversion rates across three company characteristics. Employee-size and revenue rankings change under equal company weighting; maturity ordering remains unchanged.
- Recorded observed results, metric definitions and limitations in [initial conversion analysis](docs/lead-conversion-analysis.md).

- Compared company sizes within lead sources and industries using pooled and equal-account conversion metrics. The overall size ranking does not hold consistently across these subgroups.
- Checked source composition at lead and account level, including within-company concentration and zero-inclusive equal-account source shares. See [segment-mix analysis](docs/segment-mix-analysis.md) for observed results and limitations.

- Completed engagement summaries for touch counts/directions, recency, activities, sessions, pricing/demo page patterns and total session duration. Compared pooled lead conversion with equal-account mean lead conversion rates.
- Documented observed results, reporting bands, source definitions and evidence limits in [engagement analysis](docs/engagement-analysis.md). No optimal engagement threshold or causal effect is claimed.

- Compared conversion by recorded contact counts, buyer-role counts/combinations and seniority counts/combinations using pooled and equal-account metrics. All five conversion summaries reconcile to 1,280 accounts, 5,000 leads and 1,049 conversions.
- Documented observed differences, small-group limitations and evidence in [contact coverage analysis](docs/contact-coverage-analysis.md).

- Created `analytics.vw_leads_reporting` with selected lead fields, four established reporting groups and their sort keys. Validated 5,000 unique leads, 1,049 conversions, account matching and agreement with earlier grouped results.
- Documented the planned two-table model, filter behaviour and metric definitions in [reporting model](docs/reporting-model.md). Power BI implementation has not started.

The initial inspection was performed with Python/pandas with AI assistance during project planning. The SQL checks above were subsequently executed in SSMS, with results reviewed against that baseline. See [SQL validation results](docs/sql-validation.md) for evidence, scope and remaining checks.

See [relationship validation](docs/relationship-validation.md) and [cross-field validation](docs/cross-field-validation.md) for the additional checks, observed results and interpretation limits.

Not yet completed or confirmed:
- Source-definition confirmation for opportunity flags and the reference dates of recency fields.
- Source-based resolution of the recency conflicts; provisional analytical treatment is documented.
- Function-combination conversion comparisons are deferred; contact coverage, buyer-role and seniority comparisons are complete. Further exploratory analysis is not required before Power BI.
- Power BI import/type checks and implementation of the documented relationship, sorting and measure definitions; SQL reporting preparation is complete.
- Power BI connection, data model, DAX measures and report pages.
- Integrated commercial recommendations and final portfolio presentation; initial descriptive observations are documented.

## Data and limitations

The supplied `lead_scoring.csv` contains synthetic B2B lead data used in an MSc dissertation. Results do not represent a real company's customers or financial performance.

- Grain: one row per lead; 5,000 distinct lead IDs, 1,280 accounts and 2,889 contacts.
- Outcome: `converted_within_90_days`; 1,049 positive outcomes (20.98%).
- Lead creation dates cover 1–30 January 2024 only.
- Existing NULLs are preserved; three selected negative-valued fields are converted to NULL in derived columns. Recency conflicts are flagged, not corrected or deleted.
- Observation cutoffs and potential post-outcome fields require clarification before making early-prioritisation claims.
- Multiple leads can belong to one account. Segment comparisons are associations, not causal effects.

Raw data is not included in this milestone. The public dataset is [LeadForge Intermediate v1 on Kaggle](https://www.kaggle.com/datasets/derelictpanda/leadforge-lead-scoring-intermediate-v1/data). Current upstream field definitions are linked in the engagement notes; matching the local downloaded bundle to an exact release and confirming redistribution terms remain outstanding before adding any dataset. The repository does not yet provide a fully automated end-to-end reproduction.

See [the initial data assessment](docs/data-assessment.md) for the full column inventory and baseline checks.

## Workflow and implementation status

Raw CSV → SQL Server → SQL analysis/views → Power BI Import → Power Query → data model → DAX → interactive report.

The CSV-to-SQL Server import, first-pass SQL validation, account/contact consistency checks and four selected cross-field checks are complete. The clean lead view and account view are also complete; initial segment conversion queries and company-weight comparisons are complete. Company-size comparisons within sources and industries, and source-mix checks, are also complete. Engagement analysis is complete. Contact-count, buyer-role and seniority analysis is complete. SQL reporting preparation is complete. Power BI connection, model implementation and report stages remain planned. See [account view and validation](docs/account-view.md) for definitions and verified results. See [cleaning rules and validation](docs/cleaning-rules.md) for implemented treatment and verified results. See [database setup and import notes](docs/database-import.md) for the completed steps and verification limits.

SQL will own reusable cleaning and analytical definitions. Power Query will handle report-specific preparation without duplicating SQL transformations. DAX measures will calculate metrics in the current filter context.

The planned Power BI model will import `analytics.vw_accounts` (one row per account) and `analytics.vw_leads_reporting` (one row per lead). The raw table and clean lead view remain upstream SQL sources. Consistent account attributes justify an Accounts-to-Leads one-to-many relationship. No activity-event table will be invented from aggregate counts.

## Planned report

1. **Lead Conversion Overview:** overall outcomes, source performance and company segments, with volume alongside conversion rate.
2. **Engagement & Buyer Insights:** engagement levels, pricing/demo interactions and buyer characteristics associated with conversion.

The account view provides distinct contact counts and buyer-role, seniority and function counts/combinations. SQL comparisons of contact counts, buyer roles and seniority with lead conversion are complete; function comparisons are deferred. Lead conversion rate, equal-account mean lead conversion rate and the share of accounts with at least one converted lead are distinct measures. The last of these and the Power BI measures have not been implemented.

No revenue, full-funnel or long-term trend dashboard is planned from the available fields.

## Incremental delivery

Each coherent milestone will update the relevant files and this status section, then be committed at the time it is completed. No backdated or fabricated commits. Later milestones will add SQL, Power BI, screenshots and findings only when the corresponding work exists and has been checked.

Current files:
- `README.md` and `.gitignore`
- `docs/data-assessment.md` — initial CSV inspection
- `docs/database-import.md` — database setup, manual import and row-count evidence
- `sql/01_create_database.sql` — database and schema setup
- `sql/02_verify_import.sql` — imported row-count check
- `sql/03_validate_schema.sql` — schema, keys, outcomes, NULLs and selected negative values
- `docs/sql-validation.md` — observed SQL results and validation limits
- `sql/04_validate_relationships.sql` — entity counts and contact/account consistency checks
- `docs/relationship-validation.md` — relationship results and planned analytical extension
- `sql/05_validate_cross_fields.sql` — touch arithmetic, opportunity fields and recency-order checks
- `docs/cross-field-validation.md` — observed cross-field results and unresolved issues

- `sql/06_create_clean_view.sql` — retained previews, clean view definition and five validation queries
- `docs/cleaning-rules.md` — implemented cleaning rules, metric scope and verified results

- `sql/07_create_account_view.sql` — retained previews, account view definition and five validation queries
- `docs/account-view.md` — account grain, field definitions, verified results and interpretation limits

- `sql/08_analyze_lead_conversion.sql` — six segment summaries, account detail and three-dimension weighting comparison
- `docs/lead-conversion-analysis.md` — observed results, metric definitions and interpretation limits

- `sql/09_analyze_segment_mix.sql` — source/size and industry/size conversion comparisons and source composition queries
- `docs/segment-mix-analysis.md` — observed subgroup results, concentration checks and metric limits

- `sql/10_analyze_engagement.sql` — engagement distributions, joint patterns and conversion comparisons
- `docs/engagement-analysis.md` — observed results, metric definitions, evidence coverage and reporting implications

- `sql/11_analyze_contact_coverage.sql` — recorded contact coverage, buyer-role and seniority comparisons
- `docs/contact-coverage-analysis.md` — aggregate results, interpretation limits and reconciliation evidence

- `sql/12_prepare_reporting_views.sql` — reporting lead view and schema, key, join and group checks
- `docs/reporting-model.md` — completed SQL preparation, observed checks and planned Power BI model/metrics

Future directories, created when needed: `powerbi/`, `images/`.
