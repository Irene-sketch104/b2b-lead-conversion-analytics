USE B2BLeadAnalytics;
GO

--touch count = inbound + outbound?

SELECT touch_count , inbound_touch_count, outbound_touch_count

FROM raw.lead_scoring
WHERE touch_count IS NOT NULL
	AND inbound_touch_count IS NOT NULL
	AND outbound_touch_count	is not null
	AND touch_count<> inbound_touch_count + outbound_touch_count

-- Check missing opportunity_estimated_acv by opportunity_created status
SELECT opportunity_created, COUNT(opportunity_estimated_acv) AS acv_present_count, COUNT(*)-COUNT(opportunity_estimated_acv) AS acv_missing_count
FROM raw.lead_scoring
GROUP BY opportunity_created

-- Check whether an open opportunity is also marked as created
--有「進行中的商機」，是否也有標記「已建立商機」？
-- Result: 325 leads are marked as created but not open.
-- These flags alone do not establish follow-up activity or a won/lost outcome.
SELECT has_open_opportunity,opportunity_created,  COUNT(*) AS lead_count

FROM raw.lead_scoring
GROUP BY
 opportunity_created,
 has_open_opportunity

ORDER BY
 opportunity_created,
 has_open_opportunity;



--check the order of days_since_first_touch and days_since_last_touch is reasonable
-- days_since_first_touch >= days_since_last_touch
-- Result: 134 leads have days_since_last_touch > days_since_first_touch.
-- Both values are non-negative and non-NULL.
-- If both fields use the same reference date, the time order is inconsistent.
-- Flag for review; keep the raw values unchanged.
SELECT
lead_id, days_since_last_touch, days_since_first_touch
FROM raw.lead_scoring
WHERE days_since_last_touch >= 0
	AND days_since_first_touch >= 0
	AND days_since_last_touch > days_since_first_touch;