USE B2BLeadAnalytics;
GO

-- 12.1 Inspect existing view columns before preparing reporting views.
SELECT
    TABLE_SCHEMA AS schema_name,
    TABLE_NAME AS view_name,
    ORDINAL_POSITION AS column_position,
    COLUMN_NAME AS column_name,
    DATA_TYPE AS data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE
    (TABLE_SCHEMA = 'clean'
        AND TABLE_NAME = 'vw_lead_scoring')
    OR
    (TABLE_SCHEMA = 'analytics'
        AND TABLE_NAME = 'vw_accounts')
ORDER BY
    TABLE_SCHEMA,
    TABLE_NAME,
    ORDINAL_POSITION;

-- 12.2 Create a lead-level reporting view for Power BI.
-- Reuse established cleaning rules and reporting bands.
-- Keep one row per lead; calculate conversion measures in Power BI.
GO

CREATE OR ALTER VIEW analytics.vw_leads_reporting AS
WITH reporting_base AS (
    SELECT
        lead_id,
        account_id,
        contact_id,
        lead_created_at,
        lead_source,
        role_function,
        seniority,
        buyer_role,
        converted_within_90_days,
        touch_count,
        inbound_touch_count,
        outbound_touch_count,
        activity_count,
        session_count,
        pricing_page_views,
        demo_page_views,
        total_session_duration_seconds,
        clean_days_since_last_touch,
        flag_touch_recency_conflict,

        CASE
            WHEN flag_touch_recency_conflict IS NULL
                THEN 'Missing or invalid recency'
            WHEN flag_touch_recency_conflict = 1
                THEN 'Conflicting recency'
            WHEN clean_days_since_last_touch >= 0
                AND clean_days_since_last_touch < 7
                THEN 'Under 7 days'
            WHEN clean_days_since_last_touch >= 7
                AND clean_days_since_last_touch < 14
                THEN '7 to under 14 days'
            WHEN clean_days_since_last_touch >= 14
                AND clean_days_since_last_touch < 21
                THEN '14 to under 21 days'
            WHEN clean_days_since_last_touch >= 21
                THEN '21+ days'
            ELSE 'Missing or invalid recency'
        END AS recency_band,

        CASE
            WHEN inbound_touch_count IS NULL
                OR outbound_touch_count IS NULL
                THEN 'Missing touch data'
            WHEN inbound_touch_count < 0
                OR outbound_touch_count < 0
                THEN 'Invalid touch data'
            WHEN inbound_touch_count > 0
                AND outbound_touch_count > 0
                THEN 'Both directions'
            WHEN inbound_touch_count > 0
                AND outbound_touch_count = 0
                THEN 'Inbound only'
            WHEN inbound_touch_count = 0
                AND outbound_touch_count > 0
                THEN 'Outbound only'
            WHEN inbound_touch_count = 0
                AND outbound_touch_count = 0
                THEN 'No recorded touches'
        END AS touch_pattern,

        CASE
            WHEN pricing_page_views IS NULL
                OR demo_page_views IS NULL
                THEN 'Missing page-view data'
            WHEN pricing_page_views < 0
                OR demo_page_views < 0
                THEN 'Invalid page-view data'
            WHEN pricing_page_views > 0
                AND demo_page_views > 0
                THEN 'Both pages'
            WHEN pricing_page_views > 0
                AND demo_page_views = 0
                THEN 'Pricing only'
            WHEN pricing_page_views = 0
                AND demo_page_views > 0
                THEN 'Demo only'
            WHEN pricing_page_views = 0
                AND demo_page_views = 0
                THEN 'Neither page'
        END AS page_pattern,

        CASE
            WHEN total_session_duration_seconds IS NULL
                THEN 'Missing'
            WHEN total_session_duration_seconds < 0
                THEN 'Invalid negative'
            WHEN total_session_duration_seconds = 0
                THEN 'Zero seconds'
            WHEN total_session_duration_seconds < 300
                THEN '>0 to <5 minutes'
            WHEN total_session_duration_seconds < 600
                THEN '5 to <10 minutes'
            WHEN total_session_duration_seconds < 900
                THEN '10 to <15 minutes'
            WHEN total_session_duration_seconds < 1200
                THEN '15 to <20 minutes'
            WHEN total_session_duration_seconds < 1500
                THEN '20 to <25 minutes'
            WHEN total_session_duration_seconds < 1800
                THEN '25 to <30 minutes'
            ELSE '30+ minutes'
        END AS duration_band
    FROM clean.vw_lead_scoring
)
SELECT
    reporting_base.*,

    CASE recency_band
        WHEN 'Under 7 days' THEN 1
        WHEN '7 to under 14 days' THEN 2
        WHEN '14 to under 21 days' THEN 3
        WHEN '21+ days' THEN 4
        WHEN 'Missing or invalid recency' THEN 5
        WHEN 'Conflicting recency' THEN 6
    END AS recency_band_sort,

    CASE touch_pattern
        WHEN 'Inbound only' THEN 1
        WHEN 'Outbound only' THEN 2
        WHEN 'Both directions' THEN 3
        WHEN 'No recorded touches' THEN 4
        WHEN 'Missing touch data' THEN 5
        WHEN 'Invalid touch data' THEN 6
    END AS touch_pattern_sort,

    CASE page_pattern
        WHEN 'Pricing only' THEN 1
        WHEN 'Demo only' THEN 2
        WHEN 'Both pages' THEN 3
        WHEN 'Neither page' THEN 4
        WHEN 'Missing page-view data' THEN 5
        WHEN 'Invalid page-view data' THEN 6
    END AS page_pattern_sort,

    CASE duration_band
        WHEN 'Zero seconds' THEN 1
        WHEN '>0 to <5 minutes' THEN 2
        WHEN '5 to <10 minutes' THEN 3
        WHEN '10 to <15 minutes' THEN 4
        WHEN '15 to <20 minutes' THEN 5
        WHEN '20 to <25 minutes' THEN 6
        WHEN '25 to <30 minutes' THEN 7
        WHEN '30+ minutes' THEN 8
        WHEN 'Missing' THEN 9
        WHEN 'Invalid negative' THEN 10
    END AS duration_band_sort
FROM reporting_base;
GO

-- 12.3 Validate reporting-view row counts, identifiers and outcomes.
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT lead_id) AS unique_lead_count,
    COUNT(*) - COUNT(lead_id) AS missing_lead_id_count,
    COUNT(DISTINCT account_id) AS account_count,
    COUNT(*) - COUNT(account_id) AS missing_account_id_count,
    SUM(CAST(converted_within_90_days AS INT))
        AS converted_lead_count,
    COUNT(*) - COUNT(converted_within_90_days)
        AS missing_outcome_count
FROM analytics.vw_leads_reporting;

-- 12.4 Validate account keys and lead-to-account matching.

-- Each account must appear exactly once in the account view.
SELECT
    COUNT(*) AS account_row_count,
    COUNT(DISTINCT account_id) AS unique_account_count,
    COUNT(*) - COUNT(account_id) AS missing_account_id_count
FROM analytics.vw_accounts;

-- Every lead must match exactly one account.
SELECT
    COUNT(*) AS joined_row_count,
    COUNT(DISTINCT l.lead_id) AS unique_lead_count,
    SUM(CASE
        WHEN a.account_id IS NULL THEN 1
        ELSE 0
    END) AS unmatched_lead_count
FROM analytics.vw_leads_reporting AS l
LEFT JOIN analytics.vw_accounts AS a
    ON l.account_id = a.account_id;


-- 12.5 Validate reporting groups against milestone 10 results.
-- Each lead appears once within each grouping dimension.
WITH reporting_groups AS (
    SELECT
        'Recency' AS grouping_dimension,
        recency_band AS group_label,
        recency_band_sort AS sort_order,
        converted_within_90_days
    FROM analytics.vw_leads_reporting

    UNION ALL

    SELECT
        'Touch pattern',
        touch_pattern,
        touch_pattern_sort,
        converted_within_90_days
    FROM analytics.vw_leads_reporting

    UNION ALL

    SELECT
        'Page pattern',
        page_pattern,
        page_pattern_sort,
        converted_within_90_days
    FROM analytics.vw_leads_reporting

    UNION ALL

    SELECT
        'Duration',
        duration_band,
        duration_band_sort,
        converted_within_90_days
    FROM analytics.vw_leads_reporting
)
SELECT
    grouping_dimension,
    group_label,
    sort_order,
    COUNT(*) AS lead_count,
    SUM(CAST(converted_within_90_days AS INT))
        AS converted_lead_count
FROM reporting_groups
GROUP BY
    grouping_dimension,
    group_label,
    sort_order
ORDER BY
    grouping_dimension,
    sort_order;
    -- Power BI model plan:
-- Accounts: analytics.vw_accounts, one row per account.
-- Leads: analytics.vw_leads_reporting, one row per lead.
-- Join on account_id with a one-to-many relationship.
-- Use single-direction filtering from Accounts to Leads.

-- Calculate lead counts and conversion measures from Leads.
-- Count represented accounts using distinct account_id values in Leads.
-- Calculate equal-account conversion rates using only the leads remaining in the current filter context.

-- Account contact counts and role/seniority combinations describe
-- the full supplied snapshot. Lead filters do not recalculate them.
-- Do not use Accounts.lead_count as a dynamic filtered lead count.

-- Sort each reporting label by its corresponding _sort column.
-- Keep missing/invalid categories separate from numeric trends.