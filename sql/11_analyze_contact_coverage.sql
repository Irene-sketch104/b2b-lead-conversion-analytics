USE B2BLeadAnalytics;
GO

-- 11.1 Inspect the number of distinct CONTACTS per account.
-- Count each contact once within its account, even if it has multiple leads.
WITH account_contact_counts AS (
    SELECT
        account_id,
        COUNT(DISTINCT contact_id) AS contact_count,
        COUNT(*) AS lead_count
    FROM clean.vw_lead_scoring
    GROUP BY account_id
)
SELECT
    contact_count AS [Contacts per account],
    COUNT(*) AS account_count,
    SUM(lead_count) AS lead_count,
    CAST(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()
        AS DECIMAL(5, 2)
    ) AS account_share_pct
FROM account_contact_counts
GROUP BY contact_count
ORDER BY contact_count;

-- 11.2 Compare conversion rates by distinct contacts per account.
-- Contact counts describe recorded coverage in this dataset.
-- Calculate each account's LEAD CONVERSION RATE before averaging.
-- Interpret groups with few accounts cautiously.
WITH account_summary AS (
    SELECT
        account_id,
        COUNT(DISTINCT contact_id) AS contact_count,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM clean.vw_lead_scoring
    GROUP BY account_id
)
SELECT
    contact_count AS [Contacts per account],
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
FROM account_summary
GROUP BY contact_count
ORDER BY contact_count;
-- Pooled lead conversion rates increase across the 1-6 contact groups.
-- Equal-account rates show a broadly similar pattern, but are not
-- strictly increasing: the 2- and 3-contact groups are nearly identical.
-- The 6-contact group contains only 15 accounts; the 7- and 8-contact groups contain only 3 and 2 accounts, respectively.
-- These results do not establish an optimal number of contacts.
-- Contact coverage also varies with lead volume and may reflect differences in account characteristics or engagement.

-- 11.3 Compare conversion rates by distinct BUYER ROLES per account.
-- Multiple contacts with the same buyer role count as one role.
-- Role counts describe recorded coverage, not the full buying committee.
WITH account_role_summary AS (
    SELECT
        account_id,
        COUNT(DISTINCT buyer_role) AS buyer_role_count,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM clean.vw_lead_scoring
    GROUP BY account_id
)
SELECT
    buyer_role_count AS [Buyer roles per account],
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
FROM account_role_summary
GROUP BY buyer_role_count
ORDER BY buyer_role_count;
-- Both conversion metrics increase across the observed role-count groups.
-- The largest pooled-rate increase is from one to two buyer roles (+1.57 percentage points); rates for two to four roles are close.
-- The four-role group contains only 27 accounts.
-- These associations do not establish a benefit from adding buyer roles.
-- Role diversity may also reflect contact coverage and lead volume.

-- 11.4 Compare conversion rates across buyer-role combinations.
-- Remove duplicate roles within each account before combining names.
-- Summarise lead outcomes separately to avoid duplicating lead counts.
WITH distinct_roles AS (
    SELECT DISTINCT
        account_id,
        buyer_role
    FROM clean.vw_lead_scoring
),
account_roles AS (
    SELECT
        account_id,
        COUNT(buyer_role) AS buyer_role_count,
        STRING_AGG(buyer_role, ', ')
            WITHIN GROUP (ORDER BY buyer_role)
            AS buyer_role_combination
    FROM distinct_roles
    GROUP BY account_id
),
account_outcomes AS (
    SELECT
        account_id,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM clean.vw_lead_scoring
    GROUP BY account_id
)
SELECT
    r.buyer_role_count,
    r.buyer_role_combination,
    COUNT(*) AS account_count,
    SUM(o.lead_count) AS lead_count,
    SUM(o.converted_lead_count) AS converted_lead_count,
    CAST(
        100.0 * SUM(o.converted_lead_count) / SUM(o.lead_count)
        AS DECIMAL(5, 2)
    ) AS lead_conversion_rate_pct,
    CAST(
        AVG(100.0 * o.converted_lead_count / o.lead_count)
        AS DECIMAL(5, 2)
    ) AS avg_account_lead_conversion_rate_pct
FROM account_roles AS r
INNER JOIN account_outcomes AS o
    ON r.account_id = o.account_id
GROUP BY
    r.buyer_role_count,
    r.buyer_role_combination
ORDER BY
    r.buyer_role_count,
    account_count DESC,
    r.buyer_role_combination;
-- Specific role combinations reveal differences hidden by role counts.
-- Among two-role accounts, end_user + technical_evaluator has the
-- highest observed rate, while economic_buyer + technical_evaluator
-- has the lowest under both weighting methods.
-- These groups contain 76 and 75 accounts, respectively.
-- Their pooled conversion rates differ by 7.71 percentage points.
-- Combinations describe roles recorded across an account's leads;
-- they do not establish joint participation in each individual deal.
-- Account characteristics and engagement may explain part of the differences.
-- These results do not establish a causal effect of any buyer role.

-- 11.5 Compare conversion rates by distinct SENIORITY levels per account.
-- Multiple contacts with the same seniority count as one level.
-- This measures recorded seniority diversity, not the highest rank.
WITH account_seniority_summary AS (
    SELECT
        account_id,
        COUNT(DISTINCT seniority) AS seniority_count,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM clean.vw_lead_scoring
    GROUP BY account_id
)
SELECT
    seniority_count AS [Seniority levels per account],
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
FROM account_seniority_summary
GROUP BY seniority_count
ORDER BY seniority_count;

-- Both conversion metrics rise from 1 to 3 seniority levels,decline at 4 levels, and rise again at 5.
-- The 4-level group contains 42 accounts; the 5-level group contains only 5 accounts and requires particular caution.
-- These results do not establish an optimal number of seniority levels.
-- Counts alone do not show which specific levels are represented.

-- 11.6 Compare conversion rates across seniority combinations.
-- Remove duplicate seniority levels within each account.
-- Summarise lead outcomes separately to avoid duplicating lead counts.
WITH distinct_seniority AS (
    SELECT DISTINCT
        account_id,
        seniority
    FROM clean.vw_lead_scoring
),
account_seniority AS (
    SELECT
        account_id,
        COUNT(seniority) AS seniority_count,
        STRING_AGG(seniority, ', ')
            WITHIN GROUP (ORDER BY seniority)
            AS seniority_combination
    FROM distinct_seniority
    GROUP BY account_id
),
account_outcomes AS (
    SELECT
        account_id,
        COUNT(*) AS lead_count,
        SUM(CAST(converted_within_90_days AS INT))
            AS converted_lead_count
    FROM clean.vw_lead_scoring
    GROUP BY account_id
)
SELECT
    s.seniority_count,
    s.seniority_combination,
    COUNT(*) AS account_count,
    SUM(o.lead_count) AS lead_count,
    SUM(o.converted_lead_count) AS converted_lead_count,
    CAST(
        100.0 * SUM(o.converted_lead_count) / SUM(o.lead_count)
        AS DECIMAL(5, 2)
    ) AS lead_conversion_rate_pct,
    CAST(
        AVG(100.0 * o.converted_lead_count / o.lead_count)
        AS DECIMAL(5, 2)
    ) AS avg_account_lead_conversion_rate_pct
FROM account_seniority AS s
INNER JOIN account_outcomes AS o
    ON s.account_id = o.account_id
GROUP BY
    s.seniority_count,
    s.seniority_combination
ORDER BY
    s.seniority_count,
    account_count DESC,
    s.seniority_combination;
-- Specific seniority combinations differ within the same level count.
-- Among two-level groups, individual_contributor + manager and
-- director + manager have relatively high rates under both metrics.
-- The director + individual_contributor + manager group contains
-- 54 accounts and has rates of 25.92% and 26.53%.
-- Within the four-level category, the combination without c_suite
-- accounts for 22 of 42 accounts and 188 of 342 leads.
-- Its low rates contribute substantially to the category's lower average.
-- These are comparisons between different accounts, not before-and-after
-- evidence of adding a seniority level. Small groups require caution.