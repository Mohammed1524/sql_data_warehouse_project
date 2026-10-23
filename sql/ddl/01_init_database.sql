-- Unit 1: SQL Server project initialization
CREATE DATABASE dm_course; 
GO 

USE dm_course; 
GO 

-- 1. Creating Schemas

CREATE SCHEMA raw; 
GO 

CREATE SCHEMA metadata; 
GO 

CREATE SCHEMA quality; 
GO 

-- 2. (Source Registry)
CREATE TABLE metadata.source_registry ( 
    source_name        VARCHAR(100) PRIMARY KEY, 
    source_type        VARCHAR(30)  NOT NULL, 
    owner_name         VARCHAR(100) NULL, 
    expected_frequency VARCHAR(30)  NULL, 
    file_pattern       VARCHAR(200) NULL 
); 
GO

INSERT INTO metadata.source_registry (source_name, source_type, owner_name, expected_frequency, file_pattern)
VALUES 
    ('train.csv', 'CSV', 'ASHRAE Kaggle', 'Hourly', 'train.csv'),
    ('building_metadata.csv', 'CSV', 'ASHRAE Kaggle', 'Static', 'building_metadata.csv'),
    ('weather_train.csv', 'CSV', 'ASHRAE Kaggle', 'Hourly', 'weather_train.csv');
GO


-- for testing SELECT * FROM metadata.source_registry;



-- Bronze Layer
-- Raw Staging Tables Definition

CREATE TABLE raw.building_metadata (
    site_id      INT NULL,
    building_id  INT NULL,
    primary_use  VARCHAR(50) NULL,
    square_feet  INT NULL,
    year_built   INT NULL,
    floor_count  INT NULL
);
GO


CREATE TABLE raw.weather_train (
    site_id             INT NULL,
    timestamp           DATETIME2 NULL,
    air_temperature     FLOAT NULL,
    cloud_coverage      FLOAT NULL,
    dew_temperature     FLOAT NULL,
    precip_depth_1_hr   FLOAT NULL,
    sea_level_pressure  FLOAT NULL,
    wind_direction      FLOAT NULL,
    wind_speed          FLOAT NULL
);
GO


CREATE TABLE raw.train (
    building_id    INT NULL,
    meter          TINYINT NULL,
    timestamp      DATETIME2 NULL,
    meter_reading  FLOAT NULL
);
GO

BULK INSERT raw.building_metadata
FROM 'D:\nmu level 3\data minning\sql_data_warehouse_project\data\raw\building_metadata.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


-- for testing   SELECT TOP 10 * FROM raw.building_metadata;


BULK INSERT raw.weather_train
FROM 'D:\nmu level 3\data minning\sql_data_warehouse_project\data\raw\weather_train.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


-- for testing  SELECT TOP 10 * FROM raw.weather_train;


BULK INSERT raw.train
FROM 'D:\nmu level 3\data minning\sql_data_warehouse_project\data\raw\train.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO

-- for testing  SELECT COUNT(*) AS total_meter_readings FROM raw.train;