USE dm_course;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'gold')
    EXEC(N'CREATE SCHEMA gold;');
GO

IF OBJECT_ID(N'gold.dim_building', N'U') IS NULL
BEGIN
    CREATE TABLE gold.dim_building
    (
        building_id INT NOT NULL,
        site_id INT NULL,
        primary_use VARCHAR(100) NULL,
        square_feet INT NULL,
        year_built INT NULL,
        floor_count INT NULL,
        CONSTRAINT PK_gold_dim_building PRIMARY KEY CLUSTERED (building_id)
    );
END;
GO

/* One row per building + meter + calendar date.
   meter_reading is treated as interval energy usage and summed per day. */
IF OBJECT_ID(N'gold.fact_energy_daily', N'U') IS NULL
BEGIN
    CREATE TABLE gold.fact_energy_daily
    (
        building_id INT NOT NULL,
        meter TINYINT NOT NULL,
        reading_date DATE NOT NULL,
        site_id INT NULL,

        daily_energy_consumption FLOAT NOT NULL,
        average_hourly_reading FLOAT NOT NULL,
        maximum_hourly_reading FLOAT NOT NULL,
        minimum_hourly_reading FLOAT NOT NULL,
        reading_count INT NOT NULL,

        average_air_temperature FLOAT NULL,
        average_cloud_coverage FLOAT NULL,
        average_dew_temperature FLOAT NULL,
        total_precipitation FLOAT NULL,
        average_sea_level_pressure FLOAT NULL,
        average_wind_speed FLOAT NULL,

        CONSTRAINT PK_gold_fact_energy_daily
            PRIMARY KEY CLUSTERED (building_id, meter, reading_date),
        CONSTRAINT CK_gold_fact_daily_energy_nonnegative
            CHECK (daily_energy_consumption >= 0),
        CONSTRAINT CK_gold_fact_reading_count_positive
            CHECK (reading_count > 0)
    );
END;
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'gold.fact_energy_daily')
      AND name = N'IX_gold_fact_energy_daily_date_meter'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_gold_fact_energy_daily_date_meter
        ON gold.fact_energy_daily (reading_date, meter)
        INCLUDE (daily_energy_consumption, building_id, site_id);
END;
GO
