USE dm_course;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'silver')
    EXEC(N'CREATE SCHEMA silver;');
GO

IF OBJECT_ID(N'silver.building_metadata', N'U') IS NULL
BEGIN
    CREATE TABLE silver.building_metadata
    (
        building_id INT NOT NULL,
        site_id INT NULL,
        primary_use VARCHAR(100) NULL,
        square_feet INT NULL,
        year_built INT NULL,
        floor_count INT NULL,
        CONSTRAINT PK_silver_building_metadata PRIMARY KEY (building_id)
    );
END;
GO

IF OBJECT_ID(N'silver.weather_train', N'U') IS NULL
BEGIN
    CREATE TABLE silver.weather_train
    (
        site_id INT NOT NULL,
        [timestamp] DATETIME2(0) NOT NULL,
        air_temperature FLOAT NULL,
        cloud_coverage FLOAT NULL,
        dew_temperature FLOAT NULL,
        precip_depth_1_hr FLOAT NULL,
        sea_level_pressure FLOAT NULL,
        wind_direction FLOAT NULL,
        wind_speed FLOAT NULL,
        [year] INT NOT NULL,
        [month] INT NOT NULL,
        [day] INT NOT NULL,
        [hour] INT NOT NULL,
        CONSTRAINT PK_silver_weather_train PRIMARY KEY CLUSTERED (site_id, [timestamp])
    );
END;
GO

IF OBJECT_ID(N'silver.train', N'U') IS NULL
BEGIN
    CREATE TABLE silver.train
    (
        building_id INT NOT NULL,
        meter TINYINT NOT NULL,
        [timestamp] DATETIME2(0) NOT NULL,
        meter_reading FLOAT NOT NULL,
        [year] INT NOT NULL,
        [month] INT NOT NULL,
        [day] INT NOT NULL,
        [hour] INT NOT NULL,
        CONSTRAINT PK_silver_train PRIMARY KEY CLUSTERED (building_id, meter, [timestamp]),
        CONSTRAINT CK_silver_train_meter_reading CHECK (meter_reading >= 0)
    );
END;
GO
