USE B2BLeadAnalytics;
GO

-- 9.1 Compare company sizes within each lead source.
-- Intermediate grain: one row per account and source.
WITH account_source_summary AS (
    SELECT
        account_id,
        lead_source,
        employee_band,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM clean.vw_lead_scoring
    GROUP BY
        account_id,
        lead_source,
        employee_band
)
SELECT
    lead_source,
    employee_band,
    COUNT(*) AS account_count,
    SUM(lead_count) AS lead_count,
    SUM(converted_lead_count) AS converted_lead_count,
    CAST(
        100.0 * SUM(converted_lead_count) / SUM(lead_count)
        AS DECIMAL(5, 2)
    ) AS lead_conversion_rate_pct,
    CAST(
        AVG(100.0 * converted_lead_count / lead_count)
        AS DECIMAL(5, 2)
    ) AS avg_account_lead_conversion_rate_pct
FROM account_source_summary
GROUP BY
    lead_source,
    employee_band
ORDER BY
    lead_source,
    CASE employee_band
        WHEN '200-499' THEN 1
        WHEN '500-999' THEN 2
        WHEN '1000-1999' THEN 3
        WHEN '2000+' THEN 4
    END;
-- Equal-account mean conversion decreases with company size within inbound_marketing.
-- Partner referral and SDR outbound do not show the same decreasing pattern;
-- both have their highest equal-account mean in the 2000+ band.
-- The overall company-size ranking does not apply to every source.
-- These are descriptive strata, not evidence of causality or a significant interaction.

-- 9.2 Calculate lead-source shares within each company-size band.
WITH source_counts AS (
    SELECT
        employee_band,
        lead_source,
        COUNT(*) AS lead_count
    FROM clean.vw_lead_scoring
    GROUP BY employee_band, lead_source
)
SELECT
    employee_band,
    lead_source,
    lead_count,
    CAST(
        100.0 * lead_count
        / SUM(lead_count) OVER (PARTITION BY employee_band)
        AS DECIMAL(5, 2)
    ) AS source_share_pct
FROM source_counts
ORDER BY
    CASE employee_band
        WHEN '200-499' THEN 1
        WHEN '500-999' THEN 2
        WHEN '1000-1999' THEN 3
        WHEN '2000+' THEN 4
    END,
    lead_source;
-- Source shares are similar across company-size bands:
-- inbound about 43-46%, partner about 18-20%, outbound about 33-37% (rounded).
-- No large source-mix imbalance is apparent; its contribution to rate gaps is not quantified.

-- 9.3 Inspect source concentration within each account.
WITH account_source_counts AS (
    SELECT
        account_id,
        employee_band,
        lead_source,
        COUNT(*) AS lead_count
    FROM clean.vw_lead_scoring
    GROUP BY
        account_id,
        employee_band,
        lead_source
)
SELECT
    account_id,
    employee_band,
    lead_source,
    lead_count,
    SUM(lead_count) OVER (
        PARTITION BY account_id
    ) AS account_total_leads,
    CAST(
        100.0 * lead_count
        / SUM(lead_count) OVER (PARTITION BY account_id)
        AS DECIMAL(5, 2)
    ) AS within_account_source_share_pct
FROM account_source_counts
ORDER BY
    account_total_leads DESC,
    account_id,
    within_account_source_share_pct DESC,
    lead_source;
-- 9.4 Average within-account source shares by company size, giving each account equal weight.
-- An account with no leads from a source contributes a 0% share for that source.
WITH account_source_shares AS (
    SELECT
        account_id,
        employee_band,
        COUNT(*) AS lead_count,
        100.0 * SUM(
            CASE WHEN lead_source = 'inbound_marketing'
                 THEN 1 ELSE 0 END
        ) / COUNT(*) AS inbound_share_pct,
        100.0 * SUM(
            CASE WHEN lead_source = 'partner_referral'
                 THEN 1 ELSE 0 END
        ) / COUNT(*) AS partner_share_pct,
        100.0 * SUM(
            CASE WHEN lead_source = 'sdr_outbound'
                 THEN 1 ELSE 0 END
        ) / COUNT(*) AS outbound_share_pct
    FROM clean.vw_lead_scoring
    GROUP BY account_id, employee_band
)
SELECT
    employee_band,
    COUNT(*) AS account_count,
    SUM(lead_count) AS lead_count,
    CAST(AVG(inbound_share_pct) AS DECIMAL(5, 2))
        AS avg_account_inbound_share_pct,
    CAST(AVG(partner_share_pct) AS DECIMAL(5, 2))
        AS avg_account_partner_share_pct,
    CAST(AVG(outbound_share_pct) AS DECIMAL(5, 2))
        AS avg_account_outbound_share_pct
FROM account_source_shares
GROUP BY employee_band
ORDER BY
    CASE employee_band
        WHEN '200-499' THEN 1
        WHEN '500-999' THEN 2
        WHEN '1000-1999' THEN 3
        WHEN '2000+' THEN 4
    END;
-- 9.5 Compare company sizes within each industry.
-- Calculate lead counts and conversions for each account first.
WITH account_industry_summary AS (
    SELECT
        account_id,
        industry,
        employee_band,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM clean.vw_lead_scoring
    GROUP BY
        account_id,
        industry,
        employee_band
)
SELECT
    industry,
    employee_band,
    COUNT(*) AS account_count,
    SUM(lead_count) AS lead_count,
    SUM(converted_lead_count) AS converted_lead_count,
    CAST(
        100.0 * SUM(converted_lead_count) / SUM(lead_count)
        AS DECIMAL(5, 2)
    ) AS lead_conversion_rate_pct,
    CAST(
        AVG(100.0 * converted_lead_count / lead_count)
        AS DECIMAL(5, 2)
    ) AS avg_account_lead_conversion_rate_pct
FROM account_industry_summary
GROUP BY
    industry,
    employee_band
ORDER BY
    industry,
    CASE employee_band
        WHEN '200-499' THEN 1
        WHEN '500-999' THEN 2
        WHEN '1000-1999' THEN 3
        WHEN '2000+' THEN 4
    END;
-- Equal-account mean lead conversion rates do not decrease
-- consistently with company size within any of the four industries.
-- Healthcare, logistics and manufacturing peak in the 200-499 band,
-- decline through 1000-1999, then rebound in the 2000+ band.
-- Professional services peaks in the 1000-1999 band.
-- The overall size pattern should not be generalised to every industry.
-- The 2000+ groups contain only 29-41 accounts each.
-- These are descriptive comparisons, not significance or causal tests.