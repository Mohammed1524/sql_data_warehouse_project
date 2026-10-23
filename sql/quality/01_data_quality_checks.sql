USE dm_course;
GO

-- 1. (Completeness percentege ):

SELECT 
    'Weather: Air Temperature' AS Metric_Name,
    COUNT(*) AS Total_Records,
    SUM(CASE WHEN air_temperature IS NULL THEN 1 ELSE 0 END) AS Missing_Count,
    CAST(100.0 * COUNT(air_temperature) / COUNT(*) AS DECIMAL(5,2)) AS Completeness_Pct
FROM raw.weather_train

UNION ALL

SELECT 
    'Weather: Cloud Coverage' AS Metric_Name,
    COUNT(*) AS Total_Records,
    SUM(CASE WHEN cloud_coverage IS NULL THEN 1 ELSE 0 END) AS Missing_Count,
    CAST(100.0 * COUNT(cloud_coverage) / COUNT(*) AS DECIMAL(5,2)) AS Completeness_Pct
FROM raw.weather_train

UNION ALL

SELECT 
    'Buildings: Year Built' AS Metric_Name,
    COUNT(*) AS Total_Records,
    SUM(CASE WHEN year_built IS NULL THEN 1 ELSE 0 END) AS Missing_Count,
    CAST(100.0 * COUNT(year_built) / COUNT(*) AS DECIMAL(5,2)) AS Completeness_Pct
FROM raw.building_metadata;
GO

-- 2. قياس صحة البيانات (Validity):

SELECT 
    COUNT(*) AS Invalid_Negative_Readings
FROM raw.train
WHERE meter_reading < 0;
GO

-- 3. (Duplicate Check):

SELECT TOP 5
    building_id,
    meter,
    timestamp,
    COUNT(*) AS Duplicate_Count
FROM raw.train
GROUP BY building_id, meter, timestamp
HAVING COUNT(*) > 1;
GO