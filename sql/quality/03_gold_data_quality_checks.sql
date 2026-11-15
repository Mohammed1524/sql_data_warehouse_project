USE dm_course;
GO
SET NOCOUNT ON;

PRINT '1. Gold table row counts';
SELECT 'gold.dim_building' AS table_name, COUNT_BIG(*) AS row_count
FROM gold.dim_building
UNION ALL
SELECT 'gold.fact_energy_daily', COUNT_BIG(*)
FROM gold.fact_energy_daily;

PRINT '2. Duplicate building dimension keys (expected: 0 rows)';
SELECT building_id, COUNT(*) AS duplicate_count
FROM gold.dim_building
GROUP BY building_id
HAVING COUNT(*) > 1;

PRINT '3. Duplicate daily fact grain (expected: 0 rows)';
SELECT building_id, meter, reading_date, COUNT(*) AS duplicate_count
FROM gold.fact_energy_daily
GROUP BY building_id, meter, reading_date
HAVING COUNT(*) > 1;

PRINT '4. Fact rows without a Gold building (expected: 0 rows)';
SELECT COUNT_BIG(*) AS orphan_fact_rows
FROM gold.fact_energy_daily AS f
LEFT JOIN gold.dim_building AS b
    ON b.building_id = f.building_id
WHERE b.building_id IS NULL;

PRINT '5. Invalid aggregate values (expected: 0 rows)';
SELECT COUNT_BIG(*) AS invalid_fact_rows
FROM gold.fact_energy_daily
WHERE daily_energy_consumption < 0
   OR average_hourly_reading < 0
   OR minimum_hourly_reading < 0
   OR maximum_hourly_reading < minimum_hourly_reading
   OR reading_count <= 0;

PRINT '6. Fact totals versus Silver source totals (expected: zero difference)';
;WITH silver_totals AS
(
    SELECT
        building_id,
        meter,
        CAST([timestamp] AS DATE) AS reading_date,
        SUM(meter_reading) AS source_total
    FROM silver.train
    GROUP BY building_id, meter, CAST([timestamp] AS DATE)
),
gold_totals AS
(
    SELECT building_id, meter, reading_date,
           daily_energy_consumption AS gold_total
    FROM gold.fact_energy_daily
)
SELECT COUNT_BIG(*) AS mismatched_daily_groups
FROM silver_totals AS s
FULL OUTER JOIN gold_totals AS g
    ON g.building_id = s.building_id
   AND g.meter = s.meter
   AND g.reading_date = s.reading_date
WHERE s.building_id IS NULL
   OR g.building_id IS NULL
   OR ABS(s.source_total - g.gold_total) > 0.000001;

PRINT '7. Missing weather matches (informational; can occur when Silver weather is absent)';
SELECT COUNT_BIG(*) AS fact_rows_without_weather
FROM gold.fact_energy_daily
WHERE average_air_temperature IS NULL
  AND average_cloud_coverage IS NULL
  AND average_dew_temperature IS NULL
  AND total_precipitation IS NULL
  AND average_sea_level_pressure IS NULL
  AND average_wind_speed IS NULL;

PRINT '8. Gold building dimension versus Silver metadata (expected: zero difference)';
SELECT
    (SELECT COUNT_BIG(*) FROM silver.building_metadata) AS silver_building_count,
    (SELECT COUNT_BIG(*) FROM gold.dim_building) AS gold_building_count;
GO
