USE B2BLeadAnalytics;
GO
SELECT 
	COLUMN_NAME,
	DATA_TYPE,
	CHARACTER_MAXIMUM_LENGTH,
	IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA ='raw'
AND TABLE_NAME ='lead_scoring'
ORDER BY ORDINAL_POSITION;

--check lead id NA or duplicate--
SELECT
	COUNT(*)AS total_rows,						--all rows
	COUNT(lead_id) AS non_null_lead_ids,		--non-NULL ids
	COUNT(DISTINCT lead_id) AS unique_lead_ids  --exclude duplicate--
FROM raw.lead_scoring;

--check the numbers of convert & non-convert--
SELECT
	converted_within_90_days,
	COUNT(*) AS lead_count
FROM raw.lead_scoring
GROUP BY converted_within_90_days
ORDER BY converted_within_90_days;

-- Count NULL values in every column
DECLARE @sql nvarchar(max);

SELECT @sql = STRING_AGG(
    CAST(
        N'SELECT N''' + REPLACE(COLUMN_NAME, '''', '''''')
        + N''' AS column_name, COUNT(*) - COUNT('
        + QUOTENAME(COLUMN_NAME)
        + N') AS missing_count FROM raw.lead_scoring'
        AS nvarchar(max)
    ),
    N' UNION ALL '
) + N' ORDER BY missing_count DESC, column_name;'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'raw'
  AND TABLE_NAME = 'lead_scoring';

EXEC sp_executesql @sql;

--check negative value:touch, ACV
--(1) check days_since_last_touch <0 or not

SELECT COUNT(*) AS negative_days_since_last_touch
FROM raw.lead_scoring
WHERE days_since_last_touch<0;

--(2) negative ACV

SELECT 'expected_acv' AS column_name, 
	COUNT(*) AS negative_count
FROM raw.lead_scoring
WHERE expected_acv<0

UNION ALL 

SELECT 'opportunity_estimated_acv' AS column_name,
	COUNT(*)AS negative_count
FROM raw.lead_scoring
WHERE opportunity_estimated_acv <0;

--check the primary key
SELECT COLUMN_NAME, CONSTRAINT_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA ='raw'
AND TABLE_NAME= 'lead_scoring'
AND OBJECTPROPERTY( OBJECT_ID(QUOTENAME(CONSTRAINT_SCHEMA)
          + '.' + QUOTENAME(CONSTRAINT_NAME)),
      'IsPrimaryKey'
  ) = 1;
