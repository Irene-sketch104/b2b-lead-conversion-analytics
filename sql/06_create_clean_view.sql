USE B2BLeadAnalytics
GO

--negative days_since_last_touch=> NULL
SELECT 
	lead_id, days_since_last_touch,
	CASE
		WHEN days_since_last_touch < 0 THEN NULL
		ELSE days_since_last_touch
	END AS clean_days_since_last_touch
FROM raw.lead_scoring
WHERE days_since_last_touch < 0
ORDER BY lead_id;

-- nagetive ACV => NULL
SELECT 
	lead_id,
	expected_acv,
	opportunity_estimated_acv,
	CASE
		WHEN expected_acv < 0 THEN NULL
		ELSE expected_acv
	END AS clean_expected_acv,
	CASE
		WHEN opportunity_estimated_acv < 0 THEN NULL
        ELSE opportunity_estimated_acv
    END AS clean_opportunity_estimated_acv
FROM raw.lead_scoring 
WHERE  expected_acv < 0
    OR opportunity_estimated_acv < 0
ORDER BY lead_id;


--flag : days_since_last_touch > days_since_first_touch + NULL
SELECT lead_id, days_since_last_touch, days_since_first_touch,
	CASE
		WHEN days_since_last_touch < 0 THEN NULL
		ELSE days_since_last_touch
	END AS clean_days_since_last_touch,
	CASE
		WHEN days_since_last_touch IS NULL
		OR days_since_first_touch IS NULL
		OR days_since_last_touch < 0
        OR days_since_first_touch < 0
		THEN NULL

		WHEN days_since_last_touch >= 0
	    AND  days_since_first_touch >= 0
		AND  days_since_last_touch > days_since_first_touch
		THEN 1
		ELSE 0
	END AS flag_touch_recency_conflict
FROM raw.lead_scoring
ORDER BY lead_id;

--The reason why missing acv
SELECT lead_id, opportunity_created, opportunity_estimated_acv,
	CASE
		WHEN opportunity_created = 0 AND  opportunity_estimated_acv IS NULL
		THEN 'no opportunity recorded'

		WHEN opportunity_estimated_acv <0
		  THEN 'Invalid negative value'

		WHEN  opportunity_estimated_acv IS NULL  AND opportunity_created = 1
		THEN 'Opportunity created but value missing'

        ELSE 'Value available'
	END AS opportunity_acv_status
FROM raw.lead_scoring
ORDER BY lead_id ;

GO

-- ===== 正式建立清理 View：請從這裡開始執行 =====
-- 前面的 SELECT 是練習與預覽，以上內容保留原樣。
-- View 保存查詢規則，不修改 raw.lead_scoring，也不刪除任何 lead。
USE B2BLeadAnalytics;
GO
IF SCHEMA_ID(N'clean') IS NULL
    EXEC(N'CREATE SCHEMA clean AUTHORIZATION dbo;');
GO

CREATE OR ALTER VIEW clean.vw_lead_scoring
AS
SELECT
    [split],
    [account_id],
    [industry],
    [region],
    [employee_band],
    [estimated_revenue_band],
    [process_maturity_band],
    [contact_id],
    [role_function],
    [seniority],
    [buyer_role],
    [lead_id],
    [lead_created_at],
    [lead_source],
    [touch_count],
    [inbound_touch_count],
    [outbound_touch_count],
    [session_count],
    [pricing_page_views],
    [demo_page_views],
    [total_session_duration_seconds],
    [touches_days_0_7],
    [touches_last_7_days],
    [days_since_first_touch],
    [activity_count],
    [days_since_last_touch],
    [opportunity_created],
    [has_open_opportunity],
    [opportunity_estimated_acv],
    [expected_acv],
    [total_touches_all],
    [converted_within_90_days],
    -- negative days_since_last_touch=> NULL
    CASE
        WHEN days_since_last_touch < 0 THEN NULL
        ELSE days_since_last_touch
    END AS clean_days_since_last_touch,

    -- negative ACV => NULL
    CASE
        WHEN expected_acv < 0 THEN NULL
        ELSE expected_acv
    END AS clean_expected_acv,
    CASE
        WHEN opportunity_estimated_acv < 0 THEN NULL
        ELSE opportunity_estimated_acv
    END AS clean_opportunity_estimated_acv,

    -- flag : days_since_last_touch > days_since_first_touch + NULL
    -- 假設兩個天數使用相同基準日與接觸定義；定義仍待來源確認。
    -- NULL = 無法判斷，1 = 順序矛盾，0 = 通過此項檢查。
    -- 接觸時間分析暫只使用 flag = 0；其他分析保留所有 lead。
    -- clean_days_since_last_touch 僅清理負數，並未自動排除順序矛盾。
    CASE
        WHEN days_since_last_touch IS NULL
            OR days_since_first_touch IS NULL
            OR days_since_last_touch < 0
            OR days_since_first_touch < 0
        THEN NULL
        WHEN days_since_last_touch > days_since_first_touch
        THEN 1
        ELSE 0
    END AS flag_touch_recency_conflict,

    -- The reason why missing acv
    -- 此分類描述觀察到的資料狀態，並非證實缺失的成因。
    CASE
        WHEN opportunity_created = 0 AND opportunity_estimated_acv IS NULL
        THEN 'no opportunity recorded'
        WHEN opportunity_estimated_acv < 0
        THEN 'Invalid negative value'
        WHEN opportunity_estimated_acv IS NULL AND opportunity_created = 1
        THEN 'Opportunity created but value missing'
        ELSE 'Value available'
    END AS opportunity_acv_status
FROM raw.lead_scoring;
GO

-- ===== 驗證 1：raw 與 View 都應為 5000 列、5000 個不同 lead =====
SELECT 'raw' AS data_layer, COUNT(*) AS row_count,
    COUNT(DISTINCT lead_id) AS unique_leads
FROM raw.lead_scoring
UNION ALL
SELECT 'clean view', COUNT(*), COUNT(DISTINCT lead_id)
FROM clean.vw_lead_scoring;

-- ===== 驗證 2：清理後的三個欄位，負數筆數應全部為 0 =====
SELECT
    SUM(CASE WHEN clean_days_since_last_touch < 0 THEN 1 ELSE 0 END) AS negative_touch_days,
    SUM(CASE WHEN clean_expected_acv < 0 THEN 1 ELSE 0 END) AS negative_expected_acv,
    SUM(CASE WHEN clean_opportunity_estimated_acv < 0 THEN 1 ELSE 0 END) AS negative_opportunity_acv,
    COUNT(*) - COUNT(clean_days_since_last_touch) AS missing_touch_days,
    COUNT(*) - COUNT(clean_expected_acv) AS missing_expected_acv,
    COUNT(*) - COUNT(clean_opportunity_estimated_acv) AS missing_opportunity_acv
FROM clean.vw_lead_scoring;
-- 缺失筆數預期為 574、506、1470（原本缺失加上轉為 NULL 的負數）。

-- ===== 驗證 3：flag = 1 應為 134 筆；三組合計應為 5000 =====
SELECT flag_touch_recency_conflict, COUNT(*) AS lead_count
FROM clean.vw_lead_scoring
GROUP BY flag_touch_recency_conflict
ORDER BY flag_touch_recency_conflict;

-- ===== 驗證 4：金額狀態四類，預期 70、655、3530、745（依下列排序） =====
SELECT opportunity_acv_status, COUNT(*) AS lead_count
FROM clean.vw_lead_scoring
GROUP BY opportunity_acv_status
ORDER BY opportunity_acv_status;

-- ===== 驗證 5：原始資料欄位應完全保留，結果應為 0 =====
SELECT COUNT(*) AS raw_rows_missing_or_changed
FROM (
    SELECT [split], [account_id], [industry], [region], [employee_band], [estimated_revenue_band], [process_maturity_band], [contact_id], [role_function], [seniority], [buyer_role], [lead_id], [lead_created_at], [lead_source], [touch_count], [inbound_touch_count], [outbound_touch_count], [session_count], [pricing_page_views], [demo_page_views], [total_session_duration_seconds], [touches_days_0_7], [touches_last_7_days], [days_since_first_touch], [activity_count], [days_since_last_touch], [opportunity_created], [has_open_opportunity], [opportunity_estimated_acv], [expected_acv], [total_touches_all], [converted_within_90_days]
    FROM raw.lead_scoring
    EXCEPT
    SELECT [split], [account_id], [industry], [region], [employee_band], [estimated_revenue_band], [process_maturity_band], [contact_id], [role_function], [seniority], [buyer_role], [lead_id], [lead_created_at], [lead_source], [touch_count], [inbound_touch_count], [outbound_touch_count], [session_count], [pricing_page_views], [demo_page_views], [total_session_duration_seconds], [touches_days_0_7], [touches_last_7_days], [days_since_first_touch], [activity_count], [days_since_last_touch], [opportunity_created], [has_open_opportunity], [opportunity_estimated_acv], [expected_acv], [total_touches_all], [converted_within_90_days]
    FROM clean.vw_lead_scoring
) AS differences;
