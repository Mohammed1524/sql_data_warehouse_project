# ASHRAE Energy Prediction — Silver Layer (Unit 2)

This folder is a **drop-in set of files** for the existing `sql_data_warehouse_project` repository. The scripts were compared against the existing Bronze schema in `sql/ddl/01_init_database.sql` (GitHub `main`, reviewed 2026-11-15).

## Files to copy into the existing GitHub project

| File in this ZIP | GitHub destination | Purpose |
| --- | --- | --- |
| `sql/ddl/02_init_silver_layer.sql` | `sql/ddl/` | Create Silver schema and 3 typed tables |
| `sql/dml/01_populate_silver_layer.sql` | `sql/dml/` (create this folder) | Transform/load Bronze to Silver |
| `sql/quality/02_silver_data_quality_checks.sql` | `sql/quality/` | Validate loads and surface conflicts |
| `docs/silver_layer_audit_report.md` | `docs/` | Transformation decisions, limitations and execution status |
| `docs/silver_layer_data_dictionary.md` | `docs/` | Column definitions and keys |
| `README_SILVER_LAYER.md` | repository root or `docs/` | This guide |
| `README_HANDOFF.txt` | optional | Original handoff notes |

## How to run in SSMS

**Prerequisite:** Bronze tables `raw.building_metadata`, `raw.weather_train` and `raw.train` must already exist and have been populated in database `dm_course`.

1. Execute `sql/ddl/02_init_silver_layer.sql`.
2. Execute `sql/dml/01_populate_silver_layer.sql`. Loading ~20 million train rows may take a while; make sure SQL Server has sufficient log space.
3. Execute `sql/quality/02_silver_data_quality_checks.sql`.
4. Review results. The duplicate, negative, invalid-time checks should return no rows/zero. Other checks may require investigation (notably excluded source conflicts). Existing Silver orphan rows from an earlier load will still require cleanup.
5. Save your observed SQL Server query output for the course submission; results are **not** pre-filled.

The DML is *insert-only and rerunnable*: existing Silver records are not updated if Bronze source values change. To refresh previously loaded values, plan an explicit reload procedure first; do **not** assume rerunning the DML updates data.

## Transformations

- Building metadata: standardize types and trim use text; exclude duplicate building IDs from source.
- Weather: average numeric data for duplicate site/timestamp keys; fill missing air temperature from daily site averages, then overall site averages; add year/month/day/hour.
- Train: remove invalid keys and negative/null readings; collapse exact duplicates, exclude conflicting readings and missing-building orphans; add time features.

Missing `year_built`, `floor_count`, `cloud_coverage`, and other weather measures are retained as NULL rather than invented.

## Important limitation

This package is **code-only**. It was checked against the published Bronze DDL but **has not been run against your SQL Server instance or datasets**. No success claims, output row counts, commits, or database modifications have been made.

## For the main repository README

Add these steps *after* existing Bronze setup:

```markdown
### Silver Layer (Unit 2)
1. Run `sql/ddl/02_init_silver_layer.sql`.
2. Run `sql/dml/01_populate_silver_layer.sql`.
3. Run `sql/quality/02_silver_data_quality_checks.sql`.
4. Review `docs/silver_layer_audit_report.md` and `docs/silver_layer_data_dictionary.md`.
```
