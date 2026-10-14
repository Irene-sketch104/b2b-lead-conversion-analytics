USE B2BLeadAnalytics;
GO

-- 1 of lecontact in a company may appear times in different leads
SELECT
    account_id,
    COUNT(*) AS lead_count,
    COUNT(DISTINCT contact_id) AS contact_count,
    COUNT(DISTINCT buyer_role) AS buyer_role_count,
    COUNT(DISTINCT seniority) AS seniority_count,
    COUNT(DISTINCT role_function) AS role_function_count
FROM clean.vw_lead_scoring
GROUP BY account_id
ORDER BY contact_count DESC, account_id;




-- which kinda roles and seniority and role_function

WITH role_combinations AS (
    SELECT
        account_id,
        STRING_AGG(buyer_role, ', ')
            WITHIN GROUP (ORDER BY buyer_role) AS buyer_role_combination
    FROM (
        SELECT DISTINCT account_id, buyer_role
        FROM clean.vw_lead_scoring
    ) AS distinct_roles
    GROUP BY account_id
),
seniority_combinations AS (
    SELECT
        account_id,
        STRING_AGG(seniority, ', ')
            WITHIN GROUP (ORDER BY seniority) AS seniority_combination
    FROM (
        SELECT DISTINCT account_id, seniority
        FROM clean.vw_lead_scoring
    ) AS distinct_seniority
    GROUP BY account_id
),
function_combinations AS (
    SELECT
        account_id,
        STRING_AGG(role_function, ', ')
            WITHIN GROUP (ORDER BY role_function)
            AS role_function_combination
    FROM (
        SELECT DISTINCT account_id, role_function
        FROM clean.vw_lead_scoring
    ) AS distinct_functions
    GROUP BY account_id
)
SELECT
    r.account_id,
    r.buyer_role_combination,
    s.seniority_combination,
    f.role_function_combination
FROM role_combinations AS r
INNER JOIN seniority_combinations AS s
    ON r.account_id = s.account_id
INNER JOIN function_combinations AS f
    ON r.account_id = f.account_id
ORDER BY r.account_id;

--firmographic

SELECT DISTINCT
    account_id,
    industry,
    region,
    employee_band,
    estimated_revenue_band,
    process_maturity_band
FROM clean.vw_lead_scoring
ORDER BY account_id;

GO

-- ===== 正式建立公司 View：請從這裡開始執行 =====
-- 上方保留原有練習查詢與註解。
-- 每家公司一列，整合公司特徵、數量與三種組合。
-- 這些組合代表資料涵蓋的類別，不表示共同參與同一筆採購。
USE B2BLeadAnalytics;
GO
IF SCHEMA_ID(N'analytics') IS NULL
    EXEC(N'CREATE SCHEMA analytics AUTHORIZATION dbo;');
GO

CREATE OR ALTER VIEW analytics.vw_accounts
AS
WITH account_profiles AS (
    -- 公司屬性已檢查一致；若未來不一致，後面的唯一性驗證會顯示問題。
    SELECT DISTINCT account_id, industry, region, employee_band, estimated_revenue_band, process_maturity_band
    FROM clean.vw_lead_scoring
),
account_counts AS (
    SELECT
        account_id,
        COUNT(*) AS lead_count,
        COUNT(DISTINCT contact_id) AS contact_count,
        COUNT(DISTINCT buyer_role) AS buyer_role_count,
        COUNT(DISTINCT seniority) AS seniority_count,
        COUNT(DISTINCT role_function) AS role_function_count
    FROM clean.vw_lead_scoring
    GROUP BY account_id
),
role_combinations AS (
    SELECT
        account_id,
        STRING_AGG(buyer_role, ', ')
            WITHIN GROUP (ORDER BY buyer_role) AS buyer_role_combination
    FROM (
        SELECT DISTINCT account_id, buyer_role
        FROM clean.vw_lead_scoring
    ) AS distinct_roles
    GROUP BY account_id
),
seniority_combinations AS (
    SELECT
        account_id,
        STRING_AGG(seniority, ', ')
            WITHIN GROUP (ORDER BY seniority) AS seniority_combination
    FROM (
        SELECT DISTINCT account_id, seniority
        FROM clean.vw_lead_scoring
    ) AS distinct_seniority
    GROUP BY account_id
),
function_combinations AS (
    SELECT
        account_id,
        STRING_AGG(role_function, ', ')
            WITHIN GROUP (ORDER BY role_function)
            AS role_function_combination
    FROM (
        SELECT DISTINCT account_id, role_function
        FROM clean.vw_lead_scoring
    ) AS distinct_functions
    GROUP BY account_id
)
SELECT
    p.account_id,
    p.industry,
    p.region,
    p.employee_band,
    p.estimated_revenue_band,
    p.process_maturity_band,
    c.lead_count,
    c.contact_count,
    c.buyer_role_count,
    c.seniority_count,
    c.role_function_count,
    r.buyer_role_combination,
    s.seniority_combination,
    f.role_function_combination
FROM account_profiles AS p
INNER JOIN account_counts AS c ON p.account_id = c.account_id
INNER JOIN role_combinations AS r ON p.account_id = r.account_id
INNER JOIN seniority_combinations AS s ON p.account_id = s.account_id
INNER JOIN function_combinations AS f ON p.account_id = f.account_id;
GO

-- ===== 驗證 1：公司 1280、不同公司 1280、lead 5000、窗口 2889 =====
-- 窗口加總可比對全體 distinct contact，因為已驗證窗口不跨公司。
SELECT
    COUNT(*) AS account_rows,
    COUNT(DISTINCT account_id) AS unique_accounts,
    SUM(lead_count) AS total_leads,
    SUM(contact_count) AS total_contacts
FROM analytics.vw_accounts;

-- ===== 驗證 2：重複公司、缺少公司、多出公司都應為 0 =====
SELECT
    (SELECT COUNT(*) FROM (
        SELECT account_id FROM analytics.vw_accounts
        GROUP BY account_id HAVING COUNT(*) > 1
    ) AS duplicates) AS duplicate_accounts,
    (SELECT COUNT(*) FROM (
        SELECT account_id FROM clean.vw_lead_scoring
        EXCEPT
        SELECT account_id FROM analytics.vw_accounts
    ) AS missing) AS missing_accounts,
    (SELECT COUNT(*) FROM (
        SELECT account_id FROM analytics.vw_accounts
        EXCEPT
        SELECT account_id FROM clean.vw_lead_scoring
    ) AS extra) AS extra_accounts;

-- ===== 驗證 3：每家公司五個數量與來源重新彙總比對，應為 0 =====
SELECT COUNT(*) AS account_count_mismatches
FROM (
    SELECT account_id, lead_count, contact_count, buyer_role_count,
        seniority_count, role_function_count
    FROM analytics.vw_accounts
    EXCEPT
    SELECT account_id, COUNT(*), COUNT(DISTINCT contact_id),
        COUNT(DISTINCT buyer_role), COUNT(DISTINCT seniority),
        COUNT(DISTINCT role_function)
    FROM clean.vw_lead_scoring
    GROUP BY account_id
) AS differences;

-- ===== 驗證 4：原有公司特徵未遺失或改變，應為 0 =====
SELECT COUNT(*) AS profile_mismatches
FROM (
    SELECT account_id, industry, region, employee_band, estimated_revenue_band, process_maturity_band
    FROM clean.vw_lead_scoring
    EXCEPT
    SELECT account_id, industry, region, employee_band, estimated_revenue_band, process_maturity_band
    FROM analytics.vw_accounts
) AS differences;

-- ===== 驗證 5：三種組合不得漏掉／多出來源類別，也不得重複 =====
-- 本資料類別名稱沒有逗號，因此可用 STRING_SPLIT 還原清單比對。
WITH actual_categories AS (
    SELECT a.account_id, 'buyer_role' AS category_type, LTRIM(RTRIM(s.value)) AS category_value
    FROM analytics.vw_accounts AS a
    CROSS APPLY STRING_SPLIT(a.buyer_role_combination, ',') AS s
    UNION ALL
    SELECT a.account_id, 'seniority' AS category_type, LTRIM(RTRIM(s.value)) AS category_value
    FROM analytics.vw_accounts AS a
    CROSS APPLY STRING_SPLIT(a.seniority_combination, ',') AS s
    UNION ALL
    SELECT a.account_id, 'role_function' AS category_type, LTRIM(RTRIM(s.value)) AS category_value
    FROM analytics.vw_accounts AS a
    CROSS APPLY STRING_SPLIT(a.role_function_combination, ',') AS s
),
expected_categories AS (
    SELECT account_id, 'buyer_role' AS category_type, buyer_role AS category_value
    FROM clean.vw_lead_scoring
    WHERE buyer_role IS NOT NULL
    UNION
    SELECT account_id, 'seniority' AS category_type, seniority AS category_value
    FROM clean.vw_lead_scoring
    WHERE seniority IS NOT NULL
    UNION
    SELECT account_id, 'role_function' AS category_type, role_function AS category_value
    FROM clean.vw_lead_scoring
    WHERE role_function IS NOT NULL
),
missing_categories AS (
    SELECT * FROM expected_categories
    EXCEPT SELECT * FROM actual_categories
),
extra_categories AS (
    SELECT * FROM actual_categories
    EXCEPT SELECT * FROM expected_categories
),
duplicate_categories AS (
    SELECT account_id, category_type, category_value
    FROM actual_categories
    GROUP BY account_id, category_type, category_value
    HAVING COUNT(*) > 1
)
SELECT
    (SELECT COUNT(*) FROM missing_categories) AS missing_categories,
    (SELECT COUNT(*) FROM extra_categories) AS extra_categories,
    (SELECT COUNT(*) FROM duplicate_categories) AS duplicate_categories;
-- 上面三個結果應全部為 0。

-- 日後公司特徵與組合可篩選 lead 分析。
-- 公司 View 的數量是全體資料的公司總數量，不會因 Power BI 的 lead 日期篩選自動重算。
-- 轉換率等互動指標之後由 lead 層級計算，避免把公司總數量誤當成當前篩選分母。
