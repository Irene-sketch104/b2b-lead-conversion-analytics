# B2B Lead Conversion & Commercial Insights

**SQL Server + Power BI | Sales Operations & Commercial Analytics portfolio project**

An end-to-end, learning-led analysis of synthetic B2B sales pipeline data, examining how lead sources, company characteristics, engagement patterns and buyer context relate to **conversion within 90 days**. The goal is to translate validated descriptive analysis into practical, appropriately qualified commercial insights—not to reproduce the predictive modelling in the underlying MSc dissertation.

## Business question

**Which observable signals can help a commercial team understand lead quality, compare conversion performance and inform lead-prioritisation discussions?**

**Scope:** descriptive comparisons and interactive reporting. Observed associations are not causal effects or validated lead-scoring rules.

## At a glance

| Metric | Result |
|---|---:|
| Distinct leads | **5,000** |
| Distinct accounts | **1,280** |
| Distinct contacts | **2,889** |
| Converted within 90 days | **1,049** |
| Overall lead conversion rate | **20.98%** |

**Data:** synthetic [LeadForge Intermediate v1 dataset on Kaggle](https://www.kaggle.com/datasets/derelictpanda/leadforge-lead-scoring-intermediate-v1/data). Leads were created between **1–30 January 2024**. These results do not describe a real company's performance.

## Power BI dashboards

The `.pbix` contains two report pages using an imported two-table SQL reporting model. The images below are static previews; open the Power BI file to explore the interactive visuals.

### Page 1 — Lead Conversion Overview

![Lead Conversion Overview dashboard](powerbi/screenshots/Lead_Conversion_Overview.png)

[Open Page 1 screenshot](powerbi/screenshots/Lead_Conversion_Overview.png)

Shows overall conversion KPIs and comparisons by **lead source, industry and employee band**, including a direct comparison of pooled lead-level conversion and equal-account mean lead conversion.

### Page 2 — Engagement & Buyer Insights

![Engagement and Buyer Insights dashboard](powerbi/screenshots/Engagement_Buyer_Insights.png)

[Open Page 2 screenshot](powerbi/screenshots/Engagement_Buyer_Insights.png)

Explores **touch-frequency bands, pricing/demo page engagement patterns, buyer role and buyer seniority**. Missing touch counts are reported separately (`Unknown`: **413 leads, 8.26%**), rather than treated as zero engagement.

**Power BI project:** [`powerbi/B2B_Lead_Conversion_Analytics.pbix`](powerbi/B2B_Lead_Conversion_Analytics.pbix)

## Key findings

### 1. Changing the weighting changes the company-size ranking

Pooling all leads gives larger accounts more influence when they contribute more leads. In contrast, averaging each account's lead conversion rate gives **one equal weight to each account**, including accounts with zero conversions.

| Employee band | Pooled lead conversion | Equal-account mean lead conversion |
|---|---:|---:|
| 200–499 | 21.99% | 21.69% |
| 500–999 | 20.61% | 20.90% |
| 1,000–1,999 | 19.18% | 20.02% |
| 2,000+ | **22.13%** | **19.89%** |

The **2,000+ employee band ranks highest** under pooled lead-level conversion but **lowest** when accounts are equally weighted. Neither metric is universally preferable: the denominator and business question determine the appropriate comparison. Company-size rankings also differ across some lead-source and industry subgroups; see [segment-mix analysis](docs/segment-mix-analysis.md).

### 2. Engagement patterns vary with observed conversion

Recorded touch frequency and pricing/demo page behaviour provide useful **descriptive segmentation signals**. Among the reported page-pattern groups, leads with views of **both pricing and demo pages** have a **26.93%** conversion rate, compared with **19.16%** for those with neither page recorded. This does **not** show that viewing a page caused conversion, nor establish an optimal activity threshold.

See [engagement analysis](docs/engagement-analysis.md) for definitions, missing/invalid data categories, source-field caveats and additional breakdowns.

### 3. Buyer context adds interpretation, not a stand-alone rule

Buyer-role and seniority groups show differences in observed conversion, but the descriptive comparisons alone do not justify prioritising a lead solely by role or seniority. Contact coverage and organisational context require attention to subgroup sizes, account composition and observation timing. See [contact coverage analysis](docs/contact-coverage-analysis.md).

## Commercial implications

- **Combine conversion rates with lead volumes.** A high-performing segment may contribute relatively few conversions; use the dashboard tooltips to inspect denominators and converted lead counts.
- **Specify the unit of comparison.** Use pooled lead conversion for lead-level performance; use equal-account means when every account should contribute equally.
- **Treat engagement as a signal to investigate, not proof of causality.** Pricing/demo activity and touch frequency may reflect underlying buying intent or later-stage engagement.
- **Use buyer information as context.** Buyer-role and seniority breakdowns support commercial conversations but are not validated standalone scoring rules.
- **Separate missing from zero.** Missing touch counts (`Unknown`) are kept distinct from an observed count of zero.

## Workflow and technical implementation

`Raw CSV → SQL Server (raw) → validated clean and analytics views → Power BI Import / Power Query → Accounts-to-Leads data model → DAX measures → two-page dashboard`

| Layer | Implementation |
|---|---|
| Raw ingestion | Imported `lead_scoring.csv` into `raw.lead_scoring` in SQL Server using SSMS; checked row counts, keys, types and NULL patterns. |
| Cleaning and validation | Created `clean.vw_lead_scoring`; preserved raw fields, converted selected negative values to NULL in derived fields, and flagged unresolved recency conflicts without silently modifying records. |
| Reporting views | Created `analytics.vw_accounts` (one row per account) and `analytics.vw_leads_reporting` (one row per lead), with validated keys, categories and totals. |
| Power BI model | **Import mode** with active **Accounts (1) → Leads (*)** relationship on `account_id`, using single-direction filtering. |
| DAX measures | Distinct total leads, distinct total accounts, converted leads, lead conversion rate and equal-account mean lead conversion rate. For the equal-account mean, zero-conversion accounts are retained rather than excluded as BLANK. |
| Presentation | Two dashboard pages, categorical sorting and explanatory notes; report-specific sort fields are handled without changing raw SQL data. |

A **lead**, not an account, is the outcome unit. Multiple leads may belong to the same account; account-level attributes are stored once in the Accounts view. No event-level activity table, revenue dashboard, full-funnel model or long-term trend is invented from the aggregated source fields.

See the [reporting model and metric definitions](docs/reporting-model.md) for the original SQL-to-Power BI design and calculation scope. Earlier planning language in that historical document reflects the project's stage when it was written.

## SQL milestones and evidence

SQL milestones were completed and documented before Power BI was built. Their analysis notes remain available rather than being overwritten by the final presentation.

| Milestone | Evidence | Focus |
|---|---|---|
| 01–05 | [Data assessment](docs/data-assessment.md), [database import](docs/database-import.md), [SQL validation](docs/sql-validation.md), [relationship validation](docs/relationship-validation.md), [cross-field validation](docs/cross-field-validation.md) | Source assessment, ingestion, schema, keys, NULLs, entity consistency and cross-field issues. |
| 06 | [Cleaning rules](docs/cleaning-rules.md) | `clean.vw_lead_scoring` and validated, non-destructive derivations. |
| 07 | [Account view](docs/account-view.md) | One-row-per-account view and validation against 1,280 accounts. |
| 08 | [Lead conversion analysis](docs/lead-conversion-analysis.md) | Six segment summaries and pooled versus equal-account weighting. |
| 09 | [Segment-mix analysis](docs/segment-mix-analysis.md) | Size comparisons within source/industry and source composition. |
| 10 | [Engagement analysis](docs/engagement-analysis.md) | Touches, recency, activities, sessions and pricing/demo patterns. |
| 11 | [Contact coverage analysis](docs/contact-coverage-analysis.md) | Contact counts, buyer-role and seniority summaries. |
| 12 | [Reporting model](docs/reporting-model.md) | `analytics.vw_leads_reporting`, reconciliation checks and Power BI-ready model definitions. |

The version-controlled SQL scripts are stored in [`sql/`](sql/), from `01_create_database.sql` through `12_prepare_reporting_views.sql`. Validation and analysis details are in [`docs/`](docs/).

The initial CSV inspection used Python/pandas with AI assistance for project planning; the SQL validation queries were subsequently run in SSMS and reconciled against that baseline.

## Limitations and reproducibility

- **Synthetic data:** insights are illustrative; they are not estimates of a real organisation's conversion performance.
- **Short time coverage:** lead-creation dates span only January 2024. Long-term trends cannot be inferred.
- **Definition and timing uncertainty:** source definitions for opportunity flags and recency reference dates remain unconfirmed. Some fields may occur after the point at which a real team would make an early-prioritisation decision.
- **Data quality:** existing NULLs are preserved; selected negative values receive derived NULL treatment. Recency-order conflicts are flagged, not assumed resolved.
- **Multiple leads per account:** pooled lead-level rates and equal-account averages answer different questions. Comparisons are descriptive, not causal.
- **Reproduction:** SQL scripts and reporting artifacts are provided, but the repository is **not yet a fully automated end-to-end pipeline**. The raw dataset is not redistributed pending release/terms verification and can be accessed through the Kaggle source linked above. The local SQL Server connection in the `.pbix` may need to be repointed to a reader's own environment.

## Repository structure

```text
.
├── README.md
├── .gitignore
├── sql/                       # 01–12: SQL setup, validation, analysis, reporting views
├── docs/                      # methods, observed SQL results and limitations
└── powerbi/
    ├── B2B_Lead_Conversion_Analytics.pbix
    └── screenshots/
        ├── Lead_Conversion_Overview.png
        └── Engagement_Buyer_Insights.png
```

**Status:** SQL analysis, Power BI model, two report pages and static dashboard screenshots are complete. Remaining work is limited to portfolio documentation upkeep and any future reproducibility enhancements; no additional analysis page is required for the current scope.
