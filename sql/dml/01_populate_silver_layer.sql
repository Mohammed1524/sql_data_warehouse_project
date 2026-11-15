USE dm_course;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* 1) Building metadata: standardize blank text and exclude ambiguous duplicate keys. */
BEGIN TRY
    BEGIN TRANSACTION;

    ;WITH building_rows AS
    (
        SELECT
            TRY_CONVERT(INT, building_id) AS building_id,
            TRY_CONVERT(INT, site_id) AS site_id,
            NULLIF(LTRIM(RTRIM(CONVERT(VARCHAR(100), primary_use))), '') AS primary_use,
            TRY_CONVERT(INT, square_feet) AS square_feet,
            TRY_CONVERT(INT, year_built) AS year_built,
            TRY_CONVERT(INT, floor_count) AS floor_count
        FROM raw.building_metadata
    ),
    valid_buildings AS
    (
        SELECT *,
               COUNT(*) OVER (PARTITION BY building_id) AS source_record_count
        FROM building_rows
        WHERE building_id IS NOT NULL
    )
    INSERT INTO silver.building_metadata
        (building_id, site_id, primary_use, square_feet, year_built, floor_count)
    SELECT
        b.building_id, b.site_id, b.primary_use, b.square_feet,
        b.year_built, b.floor_count
    FROM valid_buildings AS b
    WHERE b.source_record_count = 1
      AND NOT EXISTS
      (
          SELECT 1 FROM silver.building_metadata AS s
          WHERE s.building_id = b.building_id
      );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/* 2) Weather: consolidate duplicate keys and impute air temperature by site/day,
   then by site overall. If no valid reference exists, preserve NULL. */
BEGIN TRY
    BEGIN TRANSACTION;

    ;WITH weather_source AS
    (
        SELECT
            TRY_CONVERT(INT, site_id) AS site_id,
            TRY_CONVERT(DATETIME2(0), [timestamp]) AS [timestamp],
            TRY_CONVERT(FLOAT, air_temperature) AS air_temperature,
            TRY_CONVERT(FLOAT, cloud_coverage) AS cloud_coverage,
            TRY_CONVERT(FLOAT, dew_temperature) AS dew_temperature,
            TRY_CONVERT(FLOAT, precip_depth_1_hr) AS precip_depth_1_hr,
            TRY_CONVERT(FLOAT, sea_level_pressure) AS sea_level_pressure,
            TRY_CONVERT(FLOAT, wind_direction) AS wind_direction,
            TRY_CONVERT(FLOAT, wind_speed) AS wind_speed
        FROM raw.weather_train
    ),
    weather_deduplicated AS
    (
        SELECT
            site_id, [timestamp],
            AVG(air_temperature) AS air_temperature,
            AVG(cloud_coverage) AS cloud_coverage,
            AVG(dew_temperature) AS dew_temperature,
            AVG(precip_depth_1_hr) AS precip_depth_1_hr,
            AVG(sea_level_pressure) AS sea_level_pressure,
            AVG(wind_direction) AS wind_direction,
            AVG(wind_speed) AS wind_speed
        FROM weather_source
        WHERE site_id IS NOT NULL AND [timestamp] IS NOT NULL
        GROUP BY site_id, [timestamp]
    ),
    daily_average AS
    (
        SELECT site_id, CAST([timestamp] AS DATE) AS weather_date,
               AVG(air_temperature) AS daily_avg_temp
        FROM weather_deduplicated
        GROUP BY site_id, CAST([timestamp] AS DATE)
    ),
    site_average AS
    (
        SELECT site_id, AVG(air_temperature) AS site_avg_temp
        FROM weather_deduplicated
        GROUP BY site_id
    )
    INSERT INTO silver.weather_train
    (
        site_id, [timestamp], air_temperature, cloud_coverage,
        dew_temperature, precip_depth_1_hr, sea_level_pressure,
        wind_direction, wind_speed, [year], [month], [day], [hour]
    )
    SELECT
        w.site_id, w.[timestamp],
        COALESCE(w.air_temperature, d.daily_avg_temp, s.site_avg_temp),
        w.cloud_coverage, w.dew_temperature, w.precip_depth_1_hr,
        w.sea_level_pressure, w.wind_direction, w.wind_speed,
        YEAR(w.[timestamp]), MONTH(w.[timestamp]),
        DAY(w.[timestamp]), DATEPART(HOUR, w.[timestamp])
    FROM weather_deduplicated AS w
    LEFT JOIN daily_average AS d
      ON d.site_id = w.site_id
     AND d.weather_date = CAST(w.[timestamp] AS DATE)
    LEFT JOIN site_average AS s
      ON s.site_id = w.site_id
    WHERE NOT EXISTS
    (
        SELECT 1 FROM silver.weather_train AS t
        WHERE t.site_id = w.site_id AND t.[timestamp] = w.[timestamp]
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/* 3) Meter readings: collapse identical duplicates; exclude conflicting values
   for the same building/meter/time rather than selecting one arbitrarily.
   Also exclude rows without a matching Silver building to prevent orphans. */
BEGIN TRY
    BEGIN TRANSACTION;

    ;WITH train_source AS
    (
        SELECT
            TRY_CONVERT(INT, building_id) AS building_id,
            TRY_CONVERT(TINYINT, meter) AS meter,
            TRY_CONVERT(DATETIME2(0), [timestamp]) AS [timestamp],
            TRY_CONVERT(FLOAT, meter_reading) AS meter_reading
        FROM raw.train
    ),
    train_grouped AS
    (
        SELECT
            building_id, meter, [timestamp],
            MIN(meter_reading) AS meter_reading,
            COUNT(DISTINCT meter_reading) AS distinct_reading_count
        FROM train_source
        WHERE building_id IS NOT NULL
          AND meter IS NOT NULL
          AND [timestamp] IS NOT NULL
          AND meter_reading IS NOT NULL
          AND meter_reading >= 0
        GROUP BY building_id, meter, [timestamp]
    )
    INSERT INTO silver.train
    (
        building_id, meter, [timestamp], meter_reading,
        [year], [month], [day], [hour]
    )
    SELECT
        g.building_id, g.meter, g.[timestamp], g.meter_reading,
        YEAR(g.[timestamp]), MONTH(g.[timestamp]),
        DAY(g.[timestamp]), DATEPART(HOUR, g.[timestamp])
    FROM train_grouped AS g
    WHERE g.distinct_reading_count = 1
      AND EXISTS
      (
          SELECT 1 FROM silver.building_metadata AS b
          WHERE b.building_id = g.building_id
      )
      AND NOT EXISTS
      (
          SELECT 1 FROM silver.train AS t
          WHERE t.building_id = g.building_id
            AND t.meter = g.meter
            AND t.[timestamp] = g.[timestamp]
      );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
