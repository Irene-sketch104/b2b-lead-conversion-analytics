# SQL Server setup and CSV import

## Completed in this milestone

- Connected to the local SQL Server Database Engine with Windows Authentication.
- Created the `B2BLeadAnalytics` database and `raw` schema.
- Imported `lead_scoring.csv` into `raw.lead_scoring` using SSMS 22's Import Flat File wizard.
- Confirmed the wizard reported success.
- Ran `SELECT COUNT(*)` against the imported table: **5,000 rows**.

The database name and non-NULL schema ID were checked before import. The row-count query executed successfully and matched the initial CSV inspection. These scripts document work actually performed; the CSV import was performed through the wizard, not a scripted bulk load.

## Setup and import procedure

1. For a fresh setup only, run `sql/01_create_database.sql`. Do not rerun its CREATE statements against the existing project database.
2. In SSMS, right-click `B2BLeadAnalytics`, then select **Tasks > Import Flat File**.
3. Select the locally held CSV. Set the destination schema to `raw` and table name to `lead_scoring`.
4. Leave **Use Rich Data Type Detection** unchecked; inspect the preview and proposed column definitions before importing.
5. Review the column settings described below, then finish the import.
6. Run `sql/02_verify_import.sql` and compare the result with the expected 5,000 rows.

## Column settings reviewed during the guided import

The following settings were recommended during setup. The final database metadata has **not yet been independently queried**, so this list is an import guide, not a verified CREATE TABLE specification.

| Column or group | Recommended import setting |
| --- | --- |
| Identifier and category text | `nvarchar(50)` |
| `lead_created_at` | `date` |
| Three Boolean columns | `bit` |
| Counts represented as decimal strings and other numeric measures | `float` in the raw layer |
| `days_since_first_touch`, `days_since_last_touch` | `float` |
| `opportunity_estimated_acv`, `expected_acv` | `float` |
| `total_touches_all` | `int` |
| `lead_id` | Primary key selected |
| Fields with known missing values | Allow NULLs |

`float` is an approximate numeric type used here for raw import; later analysis will assess suitable types and value ranges. Negative numeric values were not cleaned during import. Missing values must not automatically become zero.

## IntelliSense issue resolved

After import, the editor displayed an “Invalid object name” warning although the query executed successfully and returned 5,000 rows. Refreshing IntelliSense's local cache with **Ctrl + Shift + R** removed the warning. No reimport was required.

## What remains unverified

Matching row counts is a useful first check, but does not establish full import fidelity or data quality. The next milestone will inspect the actual schema and constraints, confirm lead uniqueness, and compare missingness, Boolean outcomes and suspicious numeric values with the original CSV assessment. Analytical views and Power BI work have not started.

## Repository hygiene

No raw CSV, database files, backups, connection credentials, private local paths or machine-identifying screenshots are included. The dataset's exact public source and redistribution terms remain to be documented. The existing `docs/data-assessment.md` remains the initial Python/pandas baseline rather than SQL validation evidence.
