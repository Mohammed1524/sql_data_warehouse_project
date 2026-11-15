USE dm_course;
GO
SET NOCOUNT ON;

PRINT '1. Silver table row counts';
SELECT 'silver.building_metadata' AS table_name, COUNT_BIG(*) AS row_count FROM silver.building_metadata
UNION ALL
SELECT 'silver.weather_train', COUNT_BIG(*) FROM silver.weather_train
UNION ALL
SELECT 'silver.train', COUNT_BIG(*) FROM silver.train;

PRINT '2. Duplicate building keys (expected: 0 rows)';
SELECT building_id, COUNT(*) AS duplicate_count
FROM silver.building_metadata
GROUP BY building_id
HAVING COUNT(*) > 1;

PRINT '3. Duplicate weather keys (expected: 0 rows)';
SELECT site_id, [timestamp], COUNT(*) AS duplicate_count
FROM silver.weather_train
GROUP BY site_id, [timestamp]
HAVING COUNT(*) > 1;

PRINT '4. Duplicate train keys (expected: 0 rows)';
SELECT building_id, meter, [timestamp], COUNT(*) AS duplicate_count
FROM silver.train
GROUP BY building_id, meter, [timestamp]
HAVING COUNT(*) > 1;

PRINT '5. Negative meter readings (expected: 0 rows)';
SELECT *
FROM silver.train
WHERE meter_reading < 0;

PRINT '6. Missing air temperature after imputation (review if any rows remain)';
SELECT COUNT_BIG(*) AS missing_air_temperature_count
FROM silver.weather_train
WHERE air_temperature IS NULL;

PRINT '7. Train rows without a matching building metadata record (expected: 0 rows)';
SELECT COUNT_BIG(*) AS orphan_train_count
FROM silver.train AS t
LEFT JOIN silver.building_metadata AS b
  ON b.building_id = t.building_id
WHERE b.building_id IS NULL;

PRINT '8. Invalid or missing time features (expected: 0 rows)';
SELECT 'weather_train' AS table_name, COUNT_BIG(*) AS invalid_time_rows
FROM silver.weather_train
WHERE [year] IS NULL
   OR [month] IS NULL OR [month] NOT BETWEEN 1 AND 12
   OR [day] IS NULL OR [day] NOT BETWEEN 1 AND 31
   OR [hour] IS NULL OR [hour] NOT BETWEEN 0 AND 23
UNION ALL
SELECT 'train', COUNT_BIG(*)
FROM silver.train
WHERE [year] IS NULL
   OR [month] IS NULL OR [month] NOT BETWEEN 1 AND 12
   OR [day] IS NULL OR [day] NOT BETWEEN 1 AND 31
   OR [hour] IS NULL OR [hour] NOT BETWEEN 0 AND 23;

PRINT '9. Conflicting building records in raw data (review; excluded from Silver)';
SELECT building_id, COUNT(*) AS source_rows
FROM raw.building_metadata
GROUP BY building_id
HAVING COUNT(*) > 1;

PRINT '10. Conflicting meter readings in raw data (review; excluded from Silver)';
SELECT building_id, meter, [timestamp],
       COUNT(DISTINCT meter_reading) AS different_readings
FROM raw.train
WHERE building_id IS NOT NULL
  AND meter IS NOT NULL
  AND [timestamp] IS NOT NULL
  AND meter_reading IS NOT NULL
  AND meter_reading >= 0
GROUP BY building_id, meter, [timestamp]
HAVING COUNT(DISTINCT meter_reading) > 1;

PRINT '11. Valid raw training rows whose building is absent from Silver (excluded)';
SELECT COUNT_BIG(*) AS excluded_missing_building_rows
FROM raw.train AS r
WHERE r.building_id IS NOT NULL
  AND r.meter IS NOT NULL
  AND r.[timestamp] IS NOT NULL
  AND r.meter_reading IS NOT NULL
  AND r.meter_reading >= 0
  AND NOT EXISTS
  (
      SELECT 1 FROM silver.building_metadata AS b
      WHERE b.building_id = r.building_id
  );

PRINT '12. Site IDs in Silver weather without a matching Silver building site (informational)';
SELECT DISTINCT w.site_id
FROM silver.weather_train AS w
WHERE NOT EXISTS
(
    SELECT 1 FROM silver.building_metadata AS b
    WHERE b.site_id = w.site_id
);

GO
