# Silver Layer Audit Report

## Purpose
The Silver layer provides cleaned, standardized, deduplicated data for downstream analytical processing. It reads from the Bronze `raw` schema and writes to the `silver` schema.

## Output tables
- `silver.building_metadata`
- `silver.weather_train`
- `silver.train`

## Transformations
### Building metadata
- Converts source fields to the expected SQL data types.
- Trims `primary_use` and converts blank strings to `NULL`.
- Keeps missing values as `NULL`; it does not invent placeholder values.
- Excludes building IDs that occur more than once in the raw source because conflicting source records require review.
- Uses `NOT EXISTS` to make inserts rerunnable without duplicating existing keys.

### Weather
- Converts timestamps and numeric measurements.
- Consolidates repeated `(site_id, timestamp)` keys by averaging available measurements.
- Fills missing `air_temperature` using the same site's daily average, then the same site's overall average.
- Leaves the value `NULL` if no valid site-level average is available.
- Derives year, month, day, and hour from the timestamp.

### Meter readings
- Converts keys, timestamps, and readings to the expected data types.
- Excludes null keys/timestamps/readings and negative readings.
- Collapses exact duplicate readings.
- Excludes conflicting readings for the same `(building_id, meter, timestamp)` key for review.
- Excludes readings whose building is absent in cleaned Silver metadata to prevent orphan records; the quality script reports the number excluded.
- Derives year, month, day, and hour from the timestamp.

## Data quality validation
Run `sql/quality/02_silver_data_quality_checks.sql` after loading. Review:
- Duplicate primary keys (expected: no rows).
- Negative meter readings (expected: no rows).
- Orphan meter readings without building metadata (expected: zero).
- Invalid time features (expected: zero).
- Remaining missing air temperatures.
- Conflicting source records excluded during loading.

## Execution status
**Not yet executed/verified in SQL Server.** Do not report row counts or claim that all checks passed until the scripts have been run against the actual `dm_course` database and the results have been reviewed.

## Important source compatibility note
Before execution, compare the source column names and data types in `raw.building_metadata`, `raw.weather_train`, and `raw.train` with the Bronze DDL. The scripts assume the source columns are named as referenced in the SQL files. Adjust them if the actual Bronze schema differs.

## Suggested run order
1. `sql/ddl/02_init_silver_layer.sql`
2. `sql/dml/01_populate_silver_layer.sql`
3. `sql/quality/02_silver_data_quality_checks.sql`

Gold should read from the three `silver` tables above, not directly from the Bronze `raw` tables.

## Compatibility review (2026-11-15)
The column names and SQL data types referenced by the Silver DML match the published Bronze initialization script (`sql/ddl/01_init_database.sql`): `raw.building_metadata`, `raw.weather_train`, and `raw.train`. This is a **static schema review**, not a database execution test.

## Follow-up considerations
- DML uses `NOT EXISTS`, so a repeated run skips previously inserted keys rather than refreshing changed source values.
- The load skips incoming training rows with no matching Silver building. The quality script additionally reports any orphan rows that already exist from prior loads.
- A duplicate `building_id` is excluded whether the duplicate rows are identical or contradictory.
- Site weather duplicate measures are arithmetically averaged; this includes `wind_direction`, where a circular mean might be more physically accurate if required by the instructor.
- The reported Bronze completeness and duplicate counts in the original repository README are Bronze observations, **not verified Silver results**.
