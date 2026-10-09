# Lead, contact and account relationship validation

## Scope and execution

Milestone 04 checks the relationships and attribute consistency in `B2BLeadAnalytics.raw.lead_scoring`. The four queries are saved in [04_validate_relationships.sql](../sql/04_validate_relationships.sql).

The author executed the queries in SSMS and confirmed the results during the project walkthrough. The contact-role result was also reviewed in a screenshot; the account-attribute result was reported by the author. This document records those observations, not a separate automated database execution.

## Observed results

| Check | Observed result | Interpretation |
|---|---|---|
| Distinct entity counts | 5,000 leads; 2,889 contacts; 1,280 accounts | Leads, contacts and companies are different analytical units. |
| Contacts linked to more than one account | 0 rows | No contact ID is linked to multiple accounts. |
| Contacts with more than one buyer role, function or seniority value | 0 rows | These three attributes are consistent within each contact. |
| Accounts with more than one industry, region, employee band, revenue band or process maturity band | 0 rows | These five attributes are consistent within each account. |

The uploaded script uses the result aliases `unique_leads`, `unique_contact` and `unique_account`. Each exception query groups by the relevant ID and returns only groups with more than one distinct value. An empty exception result therefore means no inconsistency was found by that query.

`COUNT(DISTINCT ...)` ignores NULL. The earlier milestone confirmed no NULL values in the IDs and categorical attributes used here. Together, the checks support the conclusion that each contact belongs to exactly one account in this dataset.

## Why these checks matter

A company can have several contacts, and a contact can appear in several lead records. Counting lead rows as contacts would overstate contact coverage. Checking contact-to-account attribution first supports later counting of distinct contacts within each company.

Consistent contact attributes support role-mix analysis without contradictory labels for the same person. Consistent company attributes support a future account-level view with one row per company.

These are data consistency checks. They do not prove that the attributes are accurate in the real world, that contacts never change jobs or roles, or that the data captures historical changes. No tables, views or constraints were created by this script, and no raw records were modified.

## Planned extension — not implemented

- **Contact coverage:** count distinct contacts per account and explore its association with conversion outcomes.
- **Role mix:** examine buyer-role combinations within accounts, including whether an economic buyer is represented, after confirming category labels.

Keep lead conversion rate separate from the share of accounts with at least one converted lead. Accounts with more lead records have more opportunities to register at least one conversion. Contact coverage and role mix may also reflect observation timing, so comparisons will remain descriptive rather than causal or predictive claims.

Cleaning decisions, remaining cross-field validation, analytical views, Power BI modelling and commercial conclusions remain future work. This milestone includes no raw CSV, individual-level result exports, credentials or private machine paths.
