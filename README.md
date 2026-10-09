# B2B Lead Conversion & Commercial Insights

A learning-led SQL Server and Power BI portfolio project exploring how lead sources, company characteristics, buyer roles and engagement signals relate to 90-day B2B lead conversion.

## Business question

What signals help a commercial team understand lead quality, conversion performance and prioritisation opportunities?

The intended audience is Sales Operations / Commercial Analytics. This project focuses on descriptive analysis and decision support, not rebuilding predictive models from the underlying dissertation.

## Current status

**Milestone 04: lead, contact and account relationship validation.**

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
- Confirmed negative-value counts in recency and two ACV fields; no cleaning has been applied.
- Verified 5,000 distinct leads, 2,889 contacts and 1,280 accounts in SQL.
- Confirmed each contact maps to one account and has consistent buyer role, function and seniority.
- Confirmed company attributes are consistent across leads within each account.

The initial inspection was performed with Python/pandas with AI assistance during project planning. The SQL checks above were subsequently executed in SSMS, with results reviewed against that baseline. See [SQL validation results](docs/sql-validation.md) for evidence, scope and remaining checks.

See [relationship validation](docs/relationship-validation.md) for the latest SQL checks and their limits.

Not yet completed or confirmed:
- Remaining cross-field checks in SQL, including touch-count arithmetic and opportunity-field relationships.
- Account-level contact coverage and role-mix analysis.
- Cleaning decisions, analytical queries and views.
- Power BI connection, data model, DAX measures and report pages.
- Commercial findings, recommendations and final portfolio presentation.

## Data and limitations

The supplied `lead_scoring.csv` contains synthetic B2B lead data used in an MSc dissertation. Results do not represent a real company's customers or financial performance.

- Grain: one row per lead; 5,000 distinct lead IDs, 1,280 accounts and 2,889 contacts.
- Outcome: `converted_within_90_days`; 1,049 positive outcomes (20.98%).
- Lead creation dates cover 1–30 January 2024 only.
- Missing values, negative recency values and negative ACV values require explicit treatment.
- Observation cutoffs and potential post-outcome fields require clarification before making early-prioritisation claims.
- Multiple leads can belong to one account. Segment comparisons are associations, not causal effects.

Raw data is not included in this milestone. The exact public source URL, version and redistribution terms must be verified and documented before any dataset is added. This repository is not yet a reproducible implementation.

See [the initial data assessment](docs/data-assessment.md) for the full column inventory and baseline checks.

## Workflow and implementation status

Raw CSV → SQL Server → SQL analysis/views → Power BI Import → Power Query → data model → DAX → interactive report.

The CSV-to-SQL Server import, first-pass SQL validation and account/contact consistency checks are complete. Cleaning, analytical views and Power BI stages remain planned. See [database setup and import notes](docs/database-import.md) for the completed steps and verification limits.

SQL will own reusable cleaning and analytical definitions. Power Query will handle report-specific preparation without duplicating SQL transformations. DAX measures will calculate metrics in the current filter context.

The proposed model uses a preserved raw table and two analytical views: one row per account and one row per lead. Consistent account attributes justify an Accounts-to-Leads one-to-many relationship. No activity-event table will be invented from aggregate counts.

## Planned report

1. **Lead Conversion Overview:** overall outcomes, source performance and company segments, with volume alongside conversion rate.
2. **Engagement & Buyer Insights:** engagement levels, pricing/demo interactions and buyer characteristics associated with conversion.

Planned extension: compare distinct contact counts and buyer-role combinations at account level. Lead conversion rate and the share of accounts with at least one converted lead will be treated as separate measures. These analyses and measures have not yet been implemented.

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

Future directories, created when needed: `powerbi/`, `images/`.
