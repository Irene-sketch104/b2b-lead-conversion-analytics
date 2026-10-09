--check lead, contact, account

USE B2BLeadAnalytics;
GO
-- Count distinct leads, contacts and accounts

SELECT 
	COUNT(DISTINCT(lead_id)) AS unique_leads,
	COUNT(DISTINCT(contact_id)) AS unique_contact,
	COUNT(DISTINCT(account_id)) AS unique_account
FROM raw.lead_scoring;

--1 contact linked to 1 account(company)?
--for calculating the number of contacts and role combo later
-- Result: 0 rows. Each contact belongs to one account in this dataset.
SELECT contact_id, COUNT(DISTINCT (account_id)) AS account_count
FROM raw.lead_scoring
GROUP BY contact_id
HAVING COUNT(DISTINCT account_id) > 1;

-- Check whether the same contact has inconsistent role details
SELECT
    contact_id,
    COUNT(DISTINCT buyer_role) AS buyer_role_count,
    COUNT(DISTINCT role_function) AS role_function_count,
    COUNT(DISTINCT seniority) AS seniority_count
FROM raw.lead_scoring
GROUP BY contact_id
HAVING COUNT(DISTINCT buyer_role) > 1
    OR COUNT(DISTINCT role_function) > 1
    OR COUNT(DISTINCT seniority) > 1;

-- Check whether company details are consistent across leads within the same account
SELECT
    account_id,
    COUNT(DISTINCT industry) AS industry_count,
    COUNT(DISTINCT region) AS region_count,
    COUNT(DISTINCT employee_band) AS employee_band_count,
    COUNT(DISTINCT estimated_revenue_band) AS revenue_band_count,
    COUNT(DISTINCT process_maturity_band) AS maturity_band_count
FROM raw.lead_scoring
GROUP BY account_id
HAVING COUNT(DISTINCT industry) > 1
    OR COUNT(DISTINCT region) > 1
    OR COUNT(DISTINCT employee_band) > 1
    OR COUNT(DISTINCT estimated_revenue_band) > 1
    OR COUNT(DISTINCT process_maturity_band) > 1;