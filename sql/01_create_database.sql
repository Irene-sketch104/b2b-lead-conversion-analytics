-- Milestone 02: commands used to create the project database and schema.
-- Run once on a new setup. These objects already exist in the completed setup.
-- Rerunning CREATE statements there will produce object-already-exists errors.
CREATE DATABASE B2BLeadAnalytics;
GO

USE B2BLeadAnalytics;
GO

CREATE SCHEMA raw;
GO

SELECT DB_NAME() AS current_database,
       SCHEMA_ID('raw') AS raw_schema_id;
-- Expected: B2BLeadAnalytics and a non-NULL schema ID.
-- The numeric schema ID is assigned by SQL Server and can vary.
