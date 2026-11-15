# Gold Layer Audit Report

## Purpose
The Gold layer provides an analytics-ready daily energy mart built from the cleaned Silver layer (`silver.building_metadata`, `silver.weather_train`, and `silver.train`) inside database `dm_course`.

## Output tables
- `gold.dim_building` — building dimension (1 row per building).
- `gold.fact_energy_daily` — daily energy fact table (1 row per `building_id`, `meter`, and `reading_date`), joined with daily site-level weather aggregates.

## Transformations & Design Decisions
- Aggregated `silver.weather_train` to `(site_id, reading_date)` before joining with `gold.fact_energy_daily` to prevent row multiplication.
- Aggregated `silver.train` hourly readings to daily totals (`daily_energy_consumption`), average, min, max, and `reading_count` while keeping each `meter` type separate.
- Full-rebuild transactional load (`02_populate_gold_layer.sql`) ensuring repeatable, consistent results.

## Execution status
**Executed and verified in SQL Server (`dm_course`, 2026-11-15).**
All three scripts (`03_init_gold_layer.sql`, `02_populate_gold_layer.sql`, `03_gold_data_quality_checks.sql`) completed without errors:
- `gold.dim_building`: 1,449 rows (matches `silver.building_metadata`: 1,449)
- `gold.fact_energy_daily`: 845,701 rows
- Duplicate dimension/fact keys, orphan fact rows, invalid aggregate rows, daily-total mismatches vs. Silver, and fact rows without weather: **0**.