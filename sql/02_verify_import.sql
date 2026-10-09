-- Run after the manual CSV import described in docs/database-import.md.
USE B2BLeadAnalytics;
GO

SELECT COUNT(*) AS total_rows
FROM raw.lead_scoring;
-- Observed result: 5000.
-- Row count alone does not validate field values, types or constraints.
