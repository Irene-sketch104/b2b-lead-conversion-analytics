# Reporting preparation — milestone 12

## Completed scope

Created `analytics.vw_leads_reporting` in `B2BLeadAnalytics`, preserving one row per lead and exposing selected fields plus four reporting groups and their sort keys. Reused the existing `analytics.vw_accounts` without changing it. Reviewed source-view columns, reporting row counts, account-key uniqueness, lead-to-account matching and group totals against milestone 10.

The author executed `sql/12_prepare_reporting_views.sql` in SSMS. The supplied SQL is preserved unchanged. Prerequisites are the database, the `analytics` schema, `clean.vw_lead_scoring` from milestone 06 and `analytics.vw_accounts` from milestone 07. Run the script in SSMS, retaining its `GO` batch boundaries. `CREATE OR ALTER VIEW` updates the named reporting view on subsequent runs; it does not change raw records.

Power BI connection, imported tables, relationships, sort settings, DAX and visual pages are **planned, not implemented** at this milestone.

## Planned model

| Power BI table name | SQL source | Grain | Baseline rows |
| --- | --- | --- | ---: |
| Accounts | `analytics.vw_accounts` | One account | 1,280 |
| Leads | `analytics.vw_leads_reporting` | One lead | 5,000 |

Planned relationship: `Accounts[account_id]` (one) to `Leads[account_id]` (many), active and single-direction from Accounts to Leads. Use company attributes from Accounts and lead attributes from Leads. Import these two views rather than each exploratory aggregate output.

Account filters such as industry restrict the related leads. A lead filter such as lead source does not filter Accounts backwards under this model. Consequently, count companies represented by filtered leads from the Leads account IDs, rather than counting all rows in Accounts.

Account contact counts, role counts and combination strings describe the entire supplied snapshot. They do not recompute when lead source, page pattern or another lead-level filter changes. For example, selecting inbound leads does not turn an account's full-snapshot contact count into its inbound-only contact count. Treat these fields as account profiles. Hide the account view's precomputed `lead_count` from normal report authoring, or label it explicitly as full-snapshot lead count; it is not the dynamic lead-count measure.

## Reporting fields

The lead view defines 27 columns: 19 selected source columns, four labels and four integer sort keys.

| Field family | Included fields |
| --- | --- |
| Identifiers | `lead_id`, `account_id`, `contact_id` |
| Date and origin | `lead_created_at`, `lead_source` |
| Contact attributes | `role_function`, `seniority`, `buyer_role` |
| Outcome | `converted_within_90_days` |
| Touches | `touch_count`, `inbound_touch_count`, `outbound_touch_count` |
| Activity and web behaviour | `activity_count`, `session_count`, `pricing_page_views`, `demo_page_views`, `total_session_duration_seconds` |
| Recency and quality | `clean_days_since_last_touch`, `flag_touch_recency_conflict` |
| Groups and sort keys | `recency_band`, `touch_pattern`, `page_pattern`, `duration_band`, plus each corresponding `_sort` field |

Company attributes and coverage profiles remain in Accounts. The reporting lead view deliberately does not expose split labels, `total_touches_all`, ACV or opportunity fields; these are not needed for the agreed conversion/engagement report. Their original and cleaned values remain available in upstream views. Omitting these fields does not by itself establish that all remaining features precede conversion; the source-version and timing limitations in the engagement notes still apply.

Preserve IDs as text and dates as dates on import. The outcome is SQL `bit`; inspect its imported type before writing DAX and use a matching Boolean or numeric comparison. Source counts/durations are currently SQL `float`; the reporting view does not round or cast them. Keep missing values distinct from zero. Any later change to whole-number types requires confirming that values are integral first. Set identifiers, group labels, sort keys and account-profile counts to appropriate non-summing behaviour in report visuals.

## Group definitions and display order

- Recency: first separate NULL quality flags as missing/invalid and flag 1 as conflicting; valid values use [0,7), [7,14), [14,21), and 21+ days. Zero belongs to Under 7 days. Missing/invalid also includes records whose first-touch field prevents validation, even if last-touch recency is present.
- Touch pattern: missing if either input is NULL, then invalid if either is negative; otherwise classify inbound-only, outbound-only, both positive or both zero. Missing takes precedence if a record is both missing and invalid across inputs.
- Page pattern: the same missing/negative precedence, then pricing-only, demo-only, both positive or both zero. Neither page means neither of these two page types, not no website visits.
- Duration: missing, negative and zero remain distinct. Positive values use (0,300), [300,600), [600,900), [900,1200), [1200,1500), [1500,1800), and 1800+ seconds. Labels use minutes. Duration is cumulative across sessions, not page-specific time.

Use each label's matching `_sort` column in Power BI. Keep the sort columns hidden after configuring them. Missing/invalid groups are quality categories, not numeric trend points. A category with no observed rows is absent from the query output: the missing touch sort key 3 corresponds to zero observed Both directions records, not a broken sequence. All observed label/sort pairs are populated and one-to-one in the supplied result.

## Metric definitions for later DAX implementation

| Measure | Definition in current filter context | Unfiltered baseline |
| --- | --- | ---: |
| Lead Count | Count rows in Leads, whose lead ID is unique | 5,000 |
| Converted Leads | Count filtered Leads with outcome true / 1 | 1,049 |
| Lead Conversion Rate | Converted Leads divided by Lead Count | 20.98% |
| Represented Accounts | Distinct account IDs among filtered Leads | 1,280 |
| Equal-account Mean Lead Conversion Rate | Compute conversion rate within each represented account using only currently filtered leads, then average those unrounded account rates equally | To validate against SQL during implementation |

For the equal-account mean, include accounts with filtered leads but no conversions at 0%; exclude accounts with no filtered leads rather than treating them as zero-conversion accounts. If no leads are present, show an unavailable/blank rate, not a fabricated 0% rate. Calculate total rates from total numerators and denominators rather than averaging displayed subgroup rates. Store DAX rates as fractions and format as percentages; SQL preview rates are on a 0–100 scale.

The percentage of accounts with at least one conversion is a separate metric and is not implemented here. Do not label the equal-account mean as account conversion rate without explaining its meaning.

## Validation evidence

Inputs reviewed: author-supplied SQL, worksheet `12.PrePowerBI` in `SQL_Results.xlsb(2).xlsx`, and the earlier SSMS screenshot for section 12.4. The workbook includes the 12.4 heading but not its numeric results as cells; the screenshot supplies that evidence. The reviewer did not connect to or rerun the local SQL Server.

| Check | Evidence | Observed result |
| --- | --- | --- |
| Existing columns, 12.1 | Worksheet B2:F52 | Accounts 14 columns; clean leads 37 columns |
| Reporting IDs/outcome, 12.3 | I4:O4 | 5,000 rows and unique leads; 1,280 accounts; 1,049 conversions; zero missing lead IDs, account IDs or outcomes |
| Account keys, 12.4 | Supplied SSMS screenshot | 1,280 rows and unique IDs; zero missing IDs |
| Left join, 12.4 | Supplied SSMS screenshot | 5,000 joined rows and unique leads; zero unmatched leads |
| Groups, 12.5 | I16:M39 | Each of four dimensions totals 5,000 leads and 1,049 conversions; counts match milestone 10 |

### Observed group counts

| Dimension | Label | Sort | Leads | Converted leads |
| --- | --- | ---: | ---: | ---: |
| Duration | Zero seconds | 1 | 689 | 139 |
| Duration | >0 to <5 minutes | 2 | 580 | 119 |
| Duration | 5 to <10 minutes | 3 | 1136 | 229 |
| Duration | 10 to <15 minutes | 4 | 825 | 185 |
| Duration | 15 to <20 minutes | 5 | 632 | 136 |
| Duration | 20 to <25 minutes | 6 | 384 | 75 |
| Duration | 25 to <30 minutes | 7 | 212 | 55 |
| Duration | 30+ minutes | 8 | 126 | 24 |
| Duration | Missing | 9 | 416 | 87 |
| Page pattern | Pricing only | 1 | 908 | 214 |
| Page pattern | Demo only | 2 | 145 | 27 |
| Page pattern | Both pages | 3 | 661 | 178 |
| Page pattern | Neither page | 4 | 2521 | 483 |
| Page pattern | Missing page-view data | 5 | 765 | 147 |
| Recency | Under 7 days | 1 | 2634 | 626 |
| Recency | 7 to under 14 days | 2 | 875 | 176 |
| Recency | 14 to under 21 days | 3 | 294 | 48 |
| Recency | 21+ days | 4 | 160 | 9 |
| Recency | Missing or invalid recency | 5 | 903 | 173 |
| Recency | Conflicting recency | 6 | 134 | 17 |
| Touch pattern | Inbound only | 1 | 1894 | 416 |
| Touch pattern | Outbound only | 2 | 2261 | 460 |
| Touch pattern | No recorded touches | 4 | 58 | 1 |
| Touch pattern | Missing touch data | 5 | 787 | 172 |

The SQL has no reporting-row filter, aggregation or join in the view definition; it selects existing rows and derives labels. The reviewed aggregate checks support preservation of grain and outcomes but are not a full cell-by-cell comparison of every projected field. Branches with no observed records have no runtime evidence in this export. No new blanket exclusions or imputations were introduced.

## Next milestone

After this GitHub update is confirmed: connect Power BI Desktop to SQL Server using Import mode, load the two views, verify row counts/types, configure the relationship and label sorting, then validate measures against SQL baselines. Core DAX and dashboard milestones will be committed as they are actually completed. No credentials, server-specific personal details, raw data, working Excel or Power BI file is included in this package.
