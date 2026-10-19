USE B2BLeadAnalytics
GO

--Behaviour and Conversion
-- 10.1 Inspect touch counts before defining engagement bands.
-- 10.1 Inspect touch counts and account coverage before defining bands.
SELECT
    touch_count AS [touch_count per lead],
    COUNT(DISTINCT account_id) AS account_count,
    COUNT(*) AS lead_count,
    SUM(CAST(converted_within_90_days AS INT))
        AS converted_lead_count,
    CAST(
        100.0 * SUM(CAST(converted_within_90_days AS INT))
        / COUNT(*)
        AS DECIMAL(5, 2)
    ) AS conversion_rate_pct
FROM clean.vw_lead_scoring
GROUP BY touch_count
ORDER BY touch_count;
-- Conversion rates are low at 0-2 recorded touches, but do not
-- increase consistently as touch counts rise.
-- The 14-touch group contains 79 leads across 76 accounts.
-- Groups with 16+ touches are small and should be interpreted cautiously.
-- Missing touch counts remain separate from zero recorded touches.
-- These descriptive results do not establish an optimal touch count
-- or a causal effect of additional outreach.

-- 10.2 Group leads by touch count and compare two calculations:
-- 1. Calculate the conversion rate using all leads in each group.
-- 2. Calculate each account's conversion rate within that group,
--    then average those rates, giving every account equal weight.
WITH account_touch_summary AS (
    SELECT
        account_id,
        touch_count,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM clean.vw_lead_scoring
    GROUP BY account_id, touch_count
)
SELECT
    touch_count AS [touch_count per lead],
    COUNT(*) AS account_count,
    SUM(lead_count) AS lead_count,
    SUM(converted_lead_count) AS converted_lead_count,
    CAST(
        100.0 * SUM(converted_lead_count)
        / SUM(lead_count)
        AS DECIMAL(5, 2)
    ) AS lead_conversion_rate_pct,
    CAST(
        AVG(100.0 * converted_lead_count / lead_count)
        AS DECIMAL(5, 2)
    ) AS avg_account_lead_conversion_rate_pct
FROM account_touch_summary
GROUP BY touch_count
ORDER BY touch_count;
-- The two conversion rates differ by less than 2 percentage points
-- in every touch-count group, so the overall pattern is similar.
-- The 14-touch group remains relatively high after equal-account
-- weighting, but this does not establish an optimal touch count.
-- For 16+ touches, each account contributes one lead per group,
-- so both calculations are identical; sample sizes remain small.

-- 10.3 Analyse inbound and outbound touch counts separately.
-- Each lead appears once under inbound and once under outbound.
-- Keep missing counts separate from zero recorded touches.
WITH touch_types AS (
    SELECT
        account_id,
        converted_within_90_days,
        'inbound' AS touch_type,
        inbound_touch_count AS touch_count
    FROM clean.vw_lead_scoring

    UNION ALL

    SELECT
        account_id,
        converted_within_90_days,
        'outbound' AS touch_type,
        outbound_touch_count AS touch_count
    FROM clean.vw_lead_scoring
),
account_touch_summary AS (
    SELECT
        touch_type,
        touch_count,
        account_id,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM touch_types
    GROUP BY touch_type, touch_count, account_id
)
SELECT
    touch_type,
    touch_count AS [touch_count per lead],
    COUNT(*) AS account_count,
    SUM(lead_count) AS lead_count,
    SUM(converted_lead_count) AS converted_lead_count,
    CAST(
        100.0 * SUM(converted_lead_count)
        / SUM(lead_count)
        AS DECIMAL(5, 2)
    ) AS lead_conversion_rate_pct,
    CAST(
        AVG(100.0 * converted_lead_count / lead_count)
        AS DECIMAL(5, 2)
    ) AS avg_account_lead_conversion_rate_pct
FROM account_touch_summary
GROUP BY touch_type, touch_count
ORDER BY touch_type, touch_count;
-- Zero inbound touches do not imply zero outbound touches, and vice versa.
-- Lead-weighted and equal-account rates differ by less than
-- 1.5 percentage points in every group.
-- High-touch groups have small samples.
-- These separate summaries do not establish that one touch
-- direction is more effective than the other.

-- 10.4 Classify each lead by its combination of touch directions(in or out)
-- If either count is missing, the full touch pattern is unknown.
-- Compare the overall lead conversion rate with the average
-- of account-level lead conversion rates within each pattern.
;WITH lead_touch_patterns AS (
    SELECT
        account_id,
        converted_within_90_days,
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
        END AS touch_pattern
    FROM clean.vw_lead_scoring
),
account_pattern_summary AS (
    SELECT
        touch_pattern,
        account_id,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM lead_touch_patterns
    GROUP BY touch_pattern, account_id
)
SELECT
    touch_pattern,
    COUNT(*) AS account_count,
    SUM(lead_count) AS lead_count,
    SUM(converted_lead_count) AS converted_lead_count,
    CAST(
        100.0 * SUM(converted_lead_count)
        / SUM(lead_count)
        AS DECIMAL(5, 2)
    ) AS lead_conversion_rate_pct,
    CAST(
        AVG(100.0 * converted_lead_count / lead_count)
        AS DECIMAL(5, 2)
    ) AS avg_account_lead_conversion_rate_pct
FROM account_pattern_summary
GROUP BY touch_pattern
ORDER BY
    CASE touch_pattern
        WHEN 'Inbound only' THEN 1
        WHEN 'Outbound only' THEN 2
        WHEN 'Both directions' THEN 3
        WHEN 'No recorded touches' THEN 4
        WHEN 'Missing touch data' THEN 5
        WHEN 'Invalid touch data' THEN 6
    END;
-- Inbound-only and outbound-only leads account for 83.10% of all leads.
-- No lead with both touch counts available has positive counts in both directions.
-- Leads with missing touch data cannot be fully classified.
-- The inbound-only conversion rate > outbound-only under both weighting methods (about 1.6 pp)
-- This difference does not establish a causal effect.

-- 10.5 Check the touch-pattern mix within each lead source.
-- Classify each lead before counting the source-pattern combinations.
;WITH lead_touch_patterns AS (
    SELECT
        lead_source,
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
        END AS touch_pattern
    FROM clean.vw_lead_scoring
),
source_pattern_counts AS (
    SELECT
        lead_source,
        touch_pattern,
        COUNT(*) AS lead_count
    FROM lead_touch_patterns
    GROUP BY lead_source, touch_pattern
)
SELECT
    lead_source,
    touch_pattern,
    lead_count,
    CAST(
        100.0 * lead_count
        / SUM(lead_count) OVER (PARTITION BY lead_source)
        AS DECIMAL(5, 2)
    ) AS pattern_share_within_source_pct
FROM source_pattern_counts
ORDER BY lead_source, touch_pattern;

-- Among leads with complete touch counts and at least one touch,
-- inbound_marketing leads are inbound-only, while partner_referral　and sdr_outbound leads are outbound-only.
-- No source contains both inbound-only and outbound-only groups.
-- These data therefore do not support a within-source comparison　of the two touch directions.

-- 10.6 Group recency by COMPLETED DAYS rather than exact decimals.
-- Day 0 means less than one day; day 1 means one to under two days.
-- Include only leads with valid, non-conflicting touch recency.
;WITH lead_recency AS (
    SELECT
        account_id,
        converted_within_90_days,
        CAST(FLOOR(clean_days_since_last_touch) AS INT)
            AS days_since_last_touch_group
    FROM clean.vw_lead_scoring
    WHERE flag_touch_recency_conflict = 0
),
account_recency_summary AS (
    SELECT
        account_id,
        days_since_last_touch_group,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM lead_recency
    GROUP BY account_id, days_since_last_touch_group
)
SELECT
    days_since_last_touch_group AS [Completed days since last touch],
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
FROM account_recency_summary
GROUP BY days_since_last_touch_group
ORDER BY days_since_last_touch_group;
-- Leads with more recent touches generally show higher conversion rates, although the daily pattern is not consistently decreasing.
-- Later-day groups contain fewer leads and have more variable rates.
-- Lead-weighted and equal-account results show similar patterns.
-- These results describe association, not the effect of recontacting a lead.

-- 10.7 Summarise conversion rates by weekly recency bands.
-- Keep all leads, including missing/invalid and conflicting recency.
-- Zero days belongs to the under-7-days band.
-- These bands are reporting intervals, not recommended follow-up deadlines.
;WITH lead_recency_bands AS (
    SELECT
        account_id,
        converted_within_90_days,
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
        END AS recency_band
    FROM clean.vw_lead_scoring
),
account_recency_summary AS (
    SELECT
        recency_band,
        account_id,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM lead_recency_bands
    GROUP BY recency_band, account_id
)
SELECT
    recency_band,
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
FROM account_recency_summary
GROUP BY recency_band
ORDER BY
    CASE recency_band
        WHEN 'Under 7 days' THEN 1
        WHEN '7 to under 14 days' THEN 2
        WHEN '14 to under 21 days' THEN 3
        WHEN '21+ days' THEN 4
        WHEN 'Missing or invalid recency' THEN 5
        WHEN 'Conflicting recency' THEN 6
    END;
-- Conversion rates decrease across the four weekly recency bands.
-- The same ordering holds when every account receives equal weight.
-- The 21+ days group contains 160 leads across 148 accounts,
-- with only 9 conversions.
-- Missing/invalid and conflicting recency account for 20.74% of leads.
-- Display these quality categories separately from the recency trend.
-- Weekly bands are reporting intervals, not validated follow-up deadlines.

-- 10.8 Inspect activity counts and conversion rates.
-- Keep missing activity counts separate from zero.
-- Calculate each account's conversion rate within each activity-count group, then average those rates with equal weight per account.
WITH account_activity_summary AS (
    SELECT
        account_id,
        activity_count,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM clean.vw_lead_scoring
    GROUP BY account_id, activity_count
)
SELECT
    activity_count AS [Activity count per lead],
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
FROM account_activity_summary
GROUP BY activity_count
ORDER BY activity_count;
-- Conversion rates rise from 0 to 4 recorded activities,
-- then fluctuate rather than increase consistently.
-- Lead-weighted and equal-account rates show similar patterns.
-- High-count (13,14) groups each contain two leads.Missing activity remain separate from zero.
-- These results do not establish an optimal activity count.

-- 10.9 Inspect session counts and conversion rates.
-- Keep missing session counts separate from zero.
-- Compare the overall lead conversion rate with the average of account-level lead conversion rates within each session-count group.
WITH account_session_summary AS (
    SELECT
        account_id,
        session_count,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM clean.vw_lead_scoring
    GROUP BY account_id, session_count
)
SELECT
    session_count AS [Session count per lead],
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
FROM account_session_summary
GROUP BY session_count
ORDER BY session_count;
-- Conversion rates range from 19.86% to 23.15% for 0-6 sessions,
-- with no consistently increasing pattern.
-- Equal-account weighting shows a similar overall pattern.
-- Groups with 7-9 sessions contain only 13 leads in total.
-- Zero recorded sessions do not imply no sales touches or other activity.
-- Session count alone shows limited descriptive separation;
-- page-specific behaviour will be examined next.


-- 10.10 Analyse pricing-page and demo-page views separately.
-- Keep missing view counts separate from zero.
-- Each lead appears once under pricing and once under demo.
-- Demo-page views don't mean a demo booking or completion.
WITH page_views AS (
    SELECT
        account_id,
        converted_within_90_days,
        'Pricing' AS page_type,
        pricing_page_views AS view_count
    FROM clean.vw_lead_scoring

    UNION ALL

    SELECT
        account_id,
        converted_within_90_days,
        'Demo' AS page_type,
        demo_page_views AS view_count
    FROM clean.vw_lead_scoring
),
account_page_summary AS (
    SELECT
        page_type,
        view_count,
        account_id,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM page_views
    GROUP BY page_type, view_count, account_id
)
SELECT
    page_type,
    view_count AS [Page views per lead],
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
FROM account_page_summary
GROUP BY page_type, view_count
ORDER BY page_type, view_count;
-- Leads with 1-2 demo-page views have higher observed conversion rates than leads with zero recorded demo-page views.
-- Pricing-page groups with 1-4 views also exceed the zero-view group.
-- These comparisons hold under both weighting methods.
-- Rates do not increase consistently with additional page views.
-- High-view groups are small and do not establish an optimal view count.

-- 10.11 Compare combinations of pricing-page and demo-page views.
-- Each lead belongs to one group.
-- Missing counts remain separate from zero recorded views.
-- Neither page means zero views of these two page types only.
WITH lead_page_patterns AS (
    SELECT
        account_id,
        converted_within_90_days,
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
        END AS page_pattern
    FROM clean.vw_lead_scoring
),
account_page_summary AS (
    SELECT
        page_pattern,
        account_id,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM lead_page_patterns
    GROUP BY page_pattern, account_id
)
SELECT
    page_pattern,
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
FROM account_page_summary
GROUP BY page_pattern
ORDER BY
    CASE page_pattern
        WHEN 'Pricing only' THEN 1
        WHEN 'Demo only' THEN 2
        WHEN 'Both pages' THEN 3
        WHEN 'Neither page' THEN 4
        WHEN 'Missing page-view data' THEN 5
        WHEN 'Invalid page-view data' THEN 6
    END;
-- Leads viewing both page types have the highest observed conversion rate under both weighting methods, followed by pricing-only leads.
-- Demo-only and neither-page leads have similar observed conversion rates (18.62% vs 19.16%), but very different sample sizes (145 vs 2,521).
-- One additional conversion in the demo-only group would reverse the ranking.
-- This small observed difference does not establish an advantage or equivalence between the two groups.

-- 10.12 Inspect total session duration before defining reporting bands.
-- Keep missing, negative, zero and positive values separate.
SELECT
    COUNT(*) AS lead_count,
    SUM(CASE
        WHEN total_session_duration_seconds IS NULL THEN 1
        ELSE 0
    END) AS missing_count,
    SUM(CASE
        WHEN total_session_duration_seconds < 0 THEN 1
        ELSE 0
    END) AS negative_count,
    SUM(CASE
        WHEN total_session_duration_seconds = 0 THEN 1
        ELSE 0
    END) AS zero_count,
    SUM(CASE
        WHEN total_session_duration_seconds > 0 THEN 1
        ELSE 0
    END) AS positive_count
FROM clean.vw_lead_scoring;

-- Summarise the distribution of positive durations only.
SELECT DISTINCT
    MIN(total_session_duration_seconds) OVER ()
        AS min_positive_seconds,
    PERCENTILE_CONT(0.25) WITHIN GROUP (
        ORDER BY total_session_duration_seconds
    ) OVER () AS p25_seconds,
    PERCENTILE_CONT(0.50) WITHIN GROUP (
        ORDER BY total_session_duration_seconds
    ) OVER () AS median_seconds,
    PERCENTILE_CONT(0.75) WITHIN GROUP (
        ORDER BY total_session_duration_seconds
    ) OVER () AS p75_seconds,
    MAX(total_session_duration_seconds) OVER ()
        AS max_seconds
FROM clean.vw_lead_scoring
WHERE total_session_duration_seconds > 0;

-- Inspect duration frequencies in 300-second intervals.
-- Keep missing, negative and zero durations in separate groups.
-- Shares use all leads as the denominator.
;WITH duration_groups AS (
    SELECT
        account_id,
        CASE
            WHEN total_session_duration_seconds IS NULL THEN -3
            WHEN total_session_duration_seconds < 0 THEN -2
            WHEN total_session_duration_seconds = 0 THEN -1
            ELSE CAST(
                FLOOR(total_session_duration_seconds / 300.0)
                AS INT
            )
        END AS duration_group
    FROM clean.vw_lead_scoring
),
duration_counts AS (
    SELECT
        duration_group,
        COUNT(DISTINCT account_id) AS account_count,
        COUNT(*) AS lead_count
    FROM duration_groups
    GROUP BY duration_group
)
SELECT
    CASE
        WHEN duration_group = -3 THEN 'Missing'
        WHEN duration_group = -2 THEN 'Invalid negative'
        WHEN duration_group = -1 THEN 'Zero seconds'
        WHEN duration_group = 0 THEN '>0 to <300 seconds'
        ELSE CONCAT(
            duration_group * 300,
            ' to <',
            (duration_group + 1) * 300,
            ' seconds'
        )
    END AS duration_band,
    account_count,
    lead_count,
    CAST(
        100.0 * lead_count / SUM(lead_count) OVER ()
        AS DECIMAL(5, 2)
    ) AS lead_share_pct
FROM duration_counts
ORDER BY
    CASE WHEN duration_group < 0 THEN 1 ELSE 0 END,
    duration_group;

-- 10.13 Compare conversion rates across total session duration bands.
-- Use five-minute intervals and combine durations of 30+ minutes.
-- Bands were chosen from the duration distribution, not conversion rates.
-- Total duration may include multiple sessions per lead.
WITH lead_duration_bands AS (
    SELECT
        account_id,
        converted_within_90_days,
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
),
account_duration_summary AS (
    SELECT
        duration_band,
        account_id,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM lead_duration_bands
    GROUP BY duration_band, account_id
)
SELECT
    duration_band,
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
FROM account_duration_summary
GROUP BY duration_band
ORDER BY
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
    END;
-- Total session duration is cumulative across all sessions.
-- It is not a separate measure of time spent on pricing or demo pages.
-- Source: https://leadforge-dev.github.io/leadforge/docs/dataset/features
