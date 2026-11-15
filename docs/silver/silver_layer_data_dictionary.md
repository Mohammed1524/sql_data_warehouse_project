# Silver Layer Data Dictionary

The Silver layer consumes the three `raw` Bronze tables defined in `sql/ddl/01_init_database.sql`.

## `silver.building_metadata`

| Column | SQL Server data type | Rule |
| --- | --- | --- |
| `building_id` | `INT NOT NULL` | Primary key; invalid/missing IDs excluded; source duplicate IDs excluded |
| `site_id` | `INT NULL` | Site identifier |
| `primary_use` | `VARCHAR(100) NULL` | Trim whitespace; blank -> NULL |
| `square_feet` | `INT NULL` | Building gross area |
| `year_built` | `INT NULL` | Missing year retained NULL |
| `floor_count` | `INT NULL` | Missing floors retained NULL |

## `silver.weather_train`

Primary key: `(site_id, timestamp)`.

| Column | SQL Server data type | Rule |
| --- | --- | --- |
| `site_id` | `INT NOT NULL` | Non-null source key |
| `timestamp` | `DATETIME2(0) NOT NULL` | Non-null source time |
| `air_temperature` | `FLOAT NULL` | Average duplicates; fill from same-site daily or site-wide mean when missing |
| `cloud_coverage` | `FLOAT NULL` | Average duplicates; otherwise preserve missing |
| `dew_temperature` | `FLOAT NULL` | Average duplicates; otherwise preserve missing |
| `precip_depth_1_hr` | `FLOAT NULL` | Average duplicates; otherwise preserve missing |
| `sea_level_pressure` | `FLOAT NULL` | Average duplicates; otherwise preserve missing |
| `wind_direction` | `FLOAT NULL` | Arithmetic mean of duplicate values; not circular averaging |
| `wind_speed` | `FLOAT NULL` | Average duplicates; otherwise preserve missing |
| `year`, `month`, `day`, `hour` | `INT NOT NULL` | Derived from timestamp |

## `silver.train`

Primary key: `(building_id, meter, timestamp)`.

| Column | SQL Server data type | Rule |
| --- | --- | --- |
| `building_id` | `INT NOT NULL` | Non-null key with matching Silver building metadata |
| `meter` | `TINYINT NOT NULL` | Non-null meter identifier |
| `timestamp` | `DATETIME2(0) NOT NULL` | Non-null timestamp |
| `meter_reading` | `FLOAT NOT NULL` | Nonnegative; identical duplicate values collapsed; conflicting key groups excluded |
| `year`, `month`, `day`, `hour` | `INT NOT NULL` | Derived from timestamp |

**Notes:** Silver's training table does not enforce a foreign key to the building metadata table. The loader only inserts readings with matching Silver building metadata; the quality script detects any orphans already present. No business-rule limits on building age or dimensions are imposed by the handoff scripts. Silver is not yet the Gold analytical model.
