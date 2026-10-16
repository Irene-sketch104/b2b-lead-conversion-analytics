USE B2BLeadAnalytics
GO

--8.1 sources*conversion
--Results: the highest conversion-inbound
SELECT
    lead_source,
    COUNT(*) AS lead_count,
    SUM(CAST(converted_within_90_days AS INT)) AS converted_lead_count,
    CAST(
        100.0 * SUM(CAST(converted_within_90_days AS INT))
        / COUNT(*)
        AS DECIMAL(5, 2)
    ) AS conversion_rate_pct
FROM clean.vw_lead_scoring
GROUP BY lead_source
ORDER BY conversion_rate_pct DESC, lead_count DESC;

--8.2 industry*conversion
--Results: Roughly evenly distributed, manufacture is the highest!
SELECT
    industry,
    COUNT(*)AS lead_count,
    SUM(CAST(converted_within_90_days AS INT)) AS converted_lead_count,
    CAST( 
     100.0*SUM(CAST(converted_within_90_days AS INT)) /COUNT(*)
     AS DECIMAL(5,2)
    ) AS conversion_rate_pct

FROM clean.vw_lead_scoring
GROUP BY industry
ORDER BY conversion_rate_pct DESC, lead_count DESC;

--8.3 employee band*conversion
--Observation: Not monotonically increasing; larger companies do not consistently have higher lead conversion rates

SELECT employee_band, COUNT(*)AS lead_count, SUM(CAST(converted_within_90_days AS INT)) AS converted_lead_count,

CAST(100.0*SUM(CAST(converted_within_90_days AS INT))/COUNT(*) AS DECIMAL(5,2)) AS conversion_rate_pct

FROM clean.vw_lead_scoring
GROUP BY employee_band
ORDER BY conversion_rate_pct DESC, lead_count DESC;

--8.4 estimated_revenue_band*conversion
--Results: the highest conversion ($200M+) = 22.78%, based on 474 leads
SELECT estimated_revenue_band, COUNT(*)AS lead_count, SUM(CAST(converted_within_90_days AS INT)) AS converted_lead_count,

CAST(100.0*SUM(CAST(converted_within_90_days AS INT))/COUNT(*) AS DECIMAL(5,2)) AS conversion_rate_pct

FROM clean.vw_lead_scoring
GROUP BY estimated_revenue_band
ORDER BY conversion_rate_pct DESC, lead_count DESC;

-- 8.5  region * conversion
--Results: Almost the same
SELECT
    region,
    COUNT(*) AS lead_count,
    SUM(CAST(converted_within_90_days AS INT)) AS converted_lead_count,
    CAST(
        100.0 * SUM(CAST(converted_within_90_days AS INT))
        / COUNT(*)
        AS DECIMAL(5, 2)
    ) AS conversion_rate_pct
FROM clean.vw_lead_scoring
GROUP BY region
ORDER BY conversion_rate_pct DESC, lead_count DESC;

-- 8.6 process_maturity_band * conversion
-- Results: high>low>medium
SELECT
    process_maturity_band,
    COUNT(*) AS lead_count,
    SUM(CAST(converted_within_90_days AS INT)) AS converted_lead_count,
    CAST(
        100.0 * SUM(CAST(converted_within_90_days AS INT))
        / COUNT(*)
        AS DECIMAL(5, 2)
    ) AS conversion_rate_pct
FROM clean.vw_lead_scoring
GROUP BY process_maturity_band
ORDER BY conversion_rate_pct DESC, lead_count DESC;

--check if part of companies contribute to large amount of leads
SELECT
    account_id,
    employee_band,
    estimated_revenue_band,
    process_maturity_band,
    COUNT(*) AS lead_count,
    SUM(CAST(converted_within_90_days AS INT)) AS converted_lead_count,
    CAST(
        100.0 * SUM(CAST(converted_within_90_days AS INT))
        / COUNT(*)
        AS DECIMAL(5, 2)
    ) AS conversion_rate_pct
FROM clean.vw_lead_scoring
GROUP BY
    account_id,
    employee_band,
    estimated_revenue_band,
    process_maturity_band
ORDER BY lead_count DESC, converted_lead_count DESC, account_id;

--8.7
-- 先整理成一家公司一列，計算各公司的 lead 數與轉換數。
;WITH account_summary AS (
    SELECT
        account_id,
        employee_band,
        estimated_revenue_band,
        process_maturity_band,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM clean.vw_lead_scoring
    GROUP BY
        account_id,
        employee_band,
        estimated_revenue_band,
        process_maturity_band
),
-- 將三個比較面向放在同一份結果中。
account_dimensions AS (
    SELECT
        'employee_band' AS dimension,
        employee_band AS category,
        lead_count,
        converted_lead_count
    FROM account_summary

    UNION ALL

    SELECT
        'estimated_revenue_band',
        estimated_revenue_band,
        lead_count,
        converted_lead_count
    FROM account_summary

    UNION ALL

    SELECT
        'process_maturity_band',
        process_maturity_band,
        lead_count,
        converted_lead_count
    FROM account_summary
)
SELECT
    dimension,
    category,
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
FROM account_dimensions
GROUP BY dimension, category
ORDER BY
    dimension,
    CASE category
        WHEN '200-499' THEN 1
        WHEN '500-999' THEN 2
        WHEN '1000-1999' THEN 3
        WHEN '2000+' THEN 4
        WHEN '$1M-$10M' THEN 1
        WHEN '$10M-$50M' THEN 2
        WHEN '$50M-$200M' THEN 3
        WHEN '$200M+' THEN 4
        WHEN 'low' THEN 1
        WHEN 'medium' THEN 2
        WHEN 'high' THEN 3
    END;

 --Results: 
-- 1. 員工數：公司等權重後，平均 lead 轉換率隨規模增加而下降；
--    2000+ 組由原本最高變為最低。
-- 2. 營收：$200M+ 組由原本最高變為最低。
-- 3. 成熟度：兩種算法的排序皆為 high > low > medium。
-- 兩種算法回答不同問題，並列作為權重敏感性檢查；
-- 尚未控制其他特徵或檢驗統計顯著性。