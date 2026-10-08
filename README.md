# B2B Lead Conversion & Commercial Insights

A learning-led SQL Server and Power BI portfolio project exploring how lead sources, company characteristics, buyer roles and engagement signals relate to 90-day B2B lead conversion.

## Business question

What signals help a commercial team understand lead quality, conversion performance and prioritisation opportunities?

The intended audience is Sales Operations / Commercial Analytics. This project focuses on descriptive analysis and decision support, not rebuilding predictive models from the underlying dissertation.

## Current status

**Milestone 01: scope definition and initial raw-data inspection.**

Completed:
- Defined the business question, project boundaries and proposed workflow.
- Inspected the supplied CSV: 5,000 lead records and 32 columns.
- Identified keys, missingness, consistency checks and data-quality concerns.
- Proposed a small account-to-lead model; it has not been implemented.

The initial inspection was performed with Python/pandas with AI assistance during project planning. It is not evidence of completed SQL Server validation. SQL checks will be implemented and compared with these baseline results in a later milestone.

Not yet completed or confirmed:
- Local SQL Server connection, project database creation and import.
- SQL validation scripts, analytical queries and views.
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

## Proposed workflow — not yet implemented

Raw CSV → SQL Server → SQL analysis/views → Power BI Import → Power Query → data model → DAX → interactive report.

SQL will own reusable cleaning and analytical definitions. Power Query will handle report-specific preparation without duplicating SQL transformations. DAX measures will calculate metrics in the current filter context.

The proposed model uses a preserved raw table and two analytical views: one row per account and one row per lead. Consistent account attributes justify an Accounts-to-Leads one-to-many relationship. No activity-event table will be invented from aggregate counts.

## Planned report

1. **Lead Conversion Overview:** overall outcomes, source performance and company segments, with volume alongside conversion rate.
2. **Engagement & Buyer Insights:** engagement levels, pricing/demo interactions and buyer characteristics associated with conversion.

No revenue, full-funnel or long-term trend dashboard is planned from the available fields.

## Incremental delivery

Each coherent milestone will update the relevant files and this status section, then be committed at the time it is completed. No backdated or fabricated commits. Later milestones will add SQL, Power BI, screenshots and findings only when the corresponding work exists and has been checked.

Current files: `README.md`, `docs/data-assessment.md`, `.gitignore`.
Future directories, created when needed: `sql/`, `powerbi/`, `images/`.
