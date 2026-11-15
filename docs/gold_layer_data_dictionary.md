# ASHRAE Gold Layer — Data Dictionary

## Purpose
The Gold layer provides an analytics-ready daily energy mart built only from the reviewed Silver tables. It does not read from the Bronze `raw` schema.

## `gold.dim_building`
**Grain:** one row per building.

| Column | Type | Description |
|---|---|---|
| building_id | INT (PK) | Building identifier |
| site_id | INT NULL | Weather site associated with the building |
| primary_use | VARCHAR(100) NULL | Building primary use |
| square_feet | INT NULL | Building area |
| year_built | INT NULL | Construction year |
| floor_count | INT NULL | Number of floors |

## `gold.fact_energy_daily`
**Grain:** one row per `building_id`, `meter`, and `reading_date`.

| Column | Type | Description |
|---|---|---|
| building_id | INT | Building key |
| meter | TINYINT | Meter type; kept separate because meter types represent different measurement categories |
| reading_date | DATE | Calendar date |
| site_id | INT NULL | Building's weather site |
| daily_energy_consumption | FLOAT | Sum of hourly meter readings for the day |
| average_hourly_reading | FLOAT | Average hourly reading |
| maximum_hourly_reading | FLOAT | Maximum hourly reading |
| minimum_hourly_reading | FLOAT | Minimum hourly reading |
| reading_count | INT | Number of Silver readings included |
| average_air_temperature | FLOAT NULL | Daily site average air temperature |
| average_cloud_coverage | FLOAT NULL | Daily site average cloud coverage |
| average_dew_temperature | FLOAT NULL | Daily site average dew temperature |
| total_precipitation | FLOAT NULL | Sum of hourly precipitation-depth values for the day |
| average_sea_level_pressure | FLOAT NULL | Daily site average sea-level pressure |
| average_wind_speed | FLOAT NULL | Daily site average wind speed |

## Transformation logic
1. Copy the cleaned Silver building metadata into `gold.dim_building`.
2. Aggregate `silver.train` to daily level by building and meter.
3. Aggregate `silver.weather_train` to site/day **before** joining it to the energy fact. This avoids multiplying energy totals by the number of hourly weather records.
4. Left join weather by `site_id` and date. Missing weather remains NULL.
5. Keep each meter type separate; do not combine different meter types into one energy total.

## Important assumptions and limitations
- `silver.train.meter_reading` is treated as interval usage and summed per day, consistent with the ASHRAE energy-prediction training data use. If the course defines it as a cumulative meter register, the daily calculation must instead use a difference between readings.
- The Gold fact is an aggregate mart; it does not preserve hourly rows.
- `total_precipitation` is the sum of the hourly precipitation-depth field. Missing source values are ignored by SQL `SUM`; an all-NULL day remains NULL.
- Weather is site-level, so all buildings at the same site receive the same daily weather summary.
- The Silver weather `wind_direction` field is not included in this daily mart because the Silver handoff uses a simple arithmetic average for that circular measurement.
- Gold scripts have been statically reviewed against the Silver table definitions supplied in the handoff ZIP. They have not been executed against the user's SQL Server database.

## Execution order
1. Execute Silver DDL, DML, and quality scripts first.
2. Execute `sql/ddl/03_init_gold_layer.sql`.
3. Execute `sql/dml/02_populate_gold_layer.sql`.
4. Execute `sql/quality/03_gold_data_quality_checks.sql`.
