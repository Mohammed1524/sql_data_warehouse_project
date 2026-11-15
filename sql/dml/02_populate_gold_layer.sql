USE dm_course;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* Gold is rebuilt from Silver on each run to keep aggregates in sync.
   Run only after the Silver DDL, DML, and quality checks. */
BEGIN TRY
    BEGIN TRANSACTION;

    DELETE FROM gold.fact_energy_daily;
    DELETE FROM gold.dim_building;

    /* Building dimension: Silver already has one unique row per building_id. */
    INSERT INTO gold.dim_building
    (
        building_id, site_id, primary_use,
        square_feet, year_built, floor_count
    )
    SELECT
        building_id, site_id, primary_use,
        square_feet, year_built, floor_count
    FROM silver.building_metadata;

    /* Aggregate weather to one row per site and date before joining.
       This prevents hourly weather rows multiplying daily energy totals. */
    ;WITH weather_daily AS
    (
        SELECT
            site_id,
            CAST([timestamp] AS DATE) AS reading_date,
            AVG(air_temperature) AS average_air_temperature,
            AVG(cloud_coverage) AS average_cloud_coverage,
            AVG(dew_temperature) AS average_dew_temperature,
            SUM(precip_depth_1_hr) AS total_precipitation,
            AVG(sea_level_pressure) AS average_sea_level_pressure,
            AVG(wind_speed) AS average_wind_speed
        FROM silver.weather_train
        GROUP BY site_id, CAST([timestamp] AS DATE)
    ),
    energy_daily AS
    (
        SELECT
            t.building_id,
            t.meter,
            CAST(t.[timestamp] AS DATE) AS reading_date,
            SUM(t.meter_reading) AS daily_energy_consumption,
            AVG(t.meter_reading) AS average_hourly_reading,
            MAX(t.meter_reading) AS maximum_hourly_reading,
            MIN(t.meter_reading) AS minimum_hourly_reading,
            COUNT_BIG(*) AS reading_count
        FROM silver.train AS t
        INNER JOIN gold.dim_building AS b
            ON b.building_id = t.building_id
        GROUP BY
            t.building_id,
            t.meter,
            CAST(t.[timestamp] AS DATE)
    )
    INSERT INTO gold.fact_energy_daily
    (
        building_id, meter, reading_date, site_id,
        daily_energy_consumption, average_hourly_reading,
        maximum_hourly_reading, minimum_hourly_reading, reading_count,
        average_air_temperature, average_cloud_coverage,
        average_dew_temperature, total_precipitation,
        average_sea_level_pressure, average_wind_speed
    )
    SELECT
        e.building_id,
        e.meter,
        e.reading_date,
        b.site_id,
        e.daily_energy_consumption,
        e.average_hourly_reading,
        e.maximum_hourly_reading,
        e.minimum_hourly_reading,
        CONVERT(INT, e.reading_count),
        w.average_air_temperature,
        w.average_cloud_coverage,
        w.average_dew_temperature,
        w.total_precipitation,
        w.average_sea_level_pressure,
        w.average_wind_speed
    FROM energy_daily AS e
    INNER JOIN gold.dim_building AS b
        ON b.building_id = e.building_id
    LEFT JOIN weather_daily AS w
        ON w.site_id = b.site_id
       AND w.reading_date = e.reading_date;

    COMMIT TRANSACTION;
    PRINT 'Gold layer loaded successfully.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
