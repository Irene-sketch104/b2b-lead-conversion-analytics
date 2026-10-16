# Initial lead conversion analysis and company-weight sensitivity

## Completed scope and evidence

The user executed the six segment queries in SSMS and supplied their results on 15 October 2026. Account detail was exported the same day. The combined company-weight comparison was executed in SSMS and its 11 result rows supplied on 16 October 2026. These are actual observed outputs. The assistant independently recalculated weighting comparisons from the supplied account detail; no direct SQL Server execution by the assistant is claimed.

Source: `clean.vw_lead_scoring` in `B2BLeadAnalytics`. All 5,000 leads are included, with 1,049 conversions (20.98%). There is no recency-based exclusion in this analysis. The conversion outcome is complete and binary, as verified in prior milestones.

`sql/08_analyze_lead_conversion.sql` contains six segment summaries, a 1,280-row account-detail query, and an 11-row combined weighting comparison. These are read-only queries; no new view or table is created. Execute after the earlier setup/import and clean-view steps, selecting the complete CTE block when running the final query alone.

## Metric definitions

- **Pooled lead conversion rate:** total converted leads / total leads within a segment. Each lead has equal weight; accounts with more leads contribute more.
- **Equal-account mean lead conversion rate:** calculate converted leads / leads separately for each account, then average those account rates within a segment. Each company has equal weight, regardless of its lead count. The SQL averages unrounded rates before rounding the final output.
- **Not yet calculated here:** the share of accounts with at least one converted lead. This is a different measure and must not be confused with the equal-account mean.

## Six segment summaries

Each table independently reconciles to 5,000 leads and 1,049 converted leads. Counts must not be summed across different dimensions.

### Lead source

| Category | Leads | Converted leads | Lead conversion rate |
| --- | ---: | ---: | ---: |
| inbound_marketing | 2,274 | 501 | 22.03% |
| sdr_outbound | 1,757 | 374 | 21.29% |
| partner_referral | 969 | 174 | 17.96% |

### Industry

| Category | Leads | Converted leads | Lead conversion rate |
| --- | ---: | ---: | ---: |
| manufacturing | 1,295 | 304 | 23.47% |
| healthcare_non_clinical | 1,262 | 264 | 20.92% |
| professional_services | 1,238 | 245 | 19.79% |
| logistics | 1,205 | 236 | 19.59% |

### Employee band

| Category | Leads | Converted leads | Lead conversion rate |
| --- | ---: | ---: | ---: |
| 200-499 | 1,796 | 395 | 21.99% |
| 500-999 | 1,718 | 354 | 20.61% |
| 1000-1999 | 980 | 188 | 19.18% |
| 2000+ | 506 | 112 | 22.13% |

### Estimated revenue band

| Category | Leads | Converted leads | Lead conversion rate |
| --- | ---: | ---: | ---: |
| $1M-$10M | 1,324 | 267 | 20.17% |
| $10M-$50M | 1,931 | 408 | 21.13% |
| $50M-$200M | 1,271 | 266 | 20.93% |
| $200M+ | 474 | 108 | 22.78% |

### Region

| Category | Leads | Converted leads | Lead conversion rate |
| --- | ---: | ---: | ---: |
| US | 2,420 | 508 | 20.99% |
| UK | 2,580 | 541 | 20.97% |

### Process maturity

| Category | Leads | Converted leads | Lead conversion rate |
| --- | ---: | ---: | ---: |
| low | 1,373 | 290 | 21.12% |
| medium | 2,353 | 475 | 20.19% |
| high | 1,274 | 284 | 22.29% |

## Why investigate company weighting?

Initial comparisons showed lower adjacent categories sometimes outperforming higher ones. The user asked whether multiple leads from the same account could be influencing these averages before proceeding to source or industry comparisons.

The account-detail export contains 1,280 distinct accounts, 5,000 leads and 1,049 conversions. Accounts have between 1 and 13 leads; the ten accounts with the most leads contribute 124 leads (2.48% of all leads). This does not indicate overwhelming concentration in a few companies at the full-dataset level, but does not rule out within-segment weighting effects.

## Observed weighting comparison

| Dimension | Category | Accounts | Leads | Converted | Pooled lead rate | Equal-account mean lead rate |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Employee band | 200-499 | 448 | 1796 | 395 | 21.99% | 21.69% |
| Employee band | 500-999 | 455 | 1718 | 354 | 20.61% | 20.90% |
| Employee band | 1000-1999 | 244 | 980 | 188 | 19.18% | 20.02% |
| Employee band | 2000+ | 133 | 506 | 112 | 22.13% | 19.89% |
| Revenue band | $1M-$10M | 338 | 1324 | 267 | 20.17% | 20.46% |
| Revenue band | $10M-$50M | 510 | 1931 | 408 | 21.13% | 21.28% |
| Revenue band | $50M-$200M | 309 | 1271 | 266 | 20.93% | 21.17% |
| Revenue band | $200M+ | 123 | 474 | 108 | 22.78% | 19.90% |
| Process maturity | low | 363 | 1373 | 290 | 21.12% | 21.18% |
| Process maturity | medium | 598 | 2353 | 475 | 20.19% | 20.27% |
| Process maturity | high | 319 | 1274 | 284 | 22.29% | 21.77% |

Each dimension separately represents all 1,280 accounts. The UNION ALL stacks three analytical dimensions, not three independent populations.

## Interpretation

- Inbound marketing has the largest lead volume and highest observed source conversion rate. Manufacturing has the highest observed industry rate. US and UK rates are nearly identical.
- **Employee size:** under pooled lead weighting, the largest category ranks first. Under equal company weighting, rates decrease across increasing size categories (21.69%, 20.90%, 20.02%, 19.89%); the largest category ranks last. The disappearance of the largest-category rebound is more informative than merely noting that one adjacent smaller category still outperforms the next.
- **Estimated revenue:** the highest revenue category also moves from first to last. The middle categories have higher equal-account mean rates than either end, but this is not evidence of an optimal revenue level or a verified sweet spot.
- **Process maturity:** high > low > medium under both weighting schemes. Stable ordering across these two definitions is not a significance test or proof of causality.
- Within the largest employee and revenue categories, pooled rates exceed equal-account means: accounts with more leads have higher conversion rates on average in the weighted relationship. This is a descriptive weighting effect, not proof that creating more leads improves conversion.

## Limits and next questions

Both metrics are valid summaries of different questions. Equal company weighting is a sensitivity check, not a correction to an incorrect pooled rate. A company with only one lead has a 0% or 100% observed rate yet receives the same weight as a company with thirteen leads under equal weighting.

No statistical significance testing, confidence intervals or adjustment for other characteristics has been completed in this stage. Leads within an account are not necessarily independent; formal inference would need to account for that structure. Synthetic data cannot establish real-world commercial effects. Source costs, margins and revenue outcomes have not been analysed, so these rates do not establish ROI or justify budget allocation. Process-maturity definitions still require confirmation.

Planned next: examine source/industry composition, engagement, buyer characteristics and contact/role coverage; complete the SQL analysis layer before Power BI. These are pending, not completed findings. Any subsequent model or sensitivity work must be documented when actually performed.

## Packaging notes

The user-authored SQL and comments were retained, with minor comment corrections: employee-size rates are not monotonically increasing, the highest revenue category rate is 22.78% (not 22.28%), and obvious typing errors were removed. Executable SQL is unchanged.

Only README, SQL and this aggregate analysis note are included. Raw data, account-level exports, screenshots, dissertation drafts and supervisor feedback are excluded. This milestone does not publish a LinkedIn post or create a GitHub commit automatically.
