# ASHRAE Energy Prediction — Gold Layer

This package adds a daily analytics-ready Gold mart on top of the supplied reviewed Silver layer.

## Files
- `sql/ddl/03_init_gold_layer.sql` — creates `gold.dim_building` and `gold.fact_energy_daily`.
- `sql/dml/02_populate_gold_layer.sql` — rebuilds Gold from Silver in a transaction.
- `sql/quality/03_gold_data_quality_checks.sql` — validates keys, aggregates, and source reconciliation.
- `docs/gold_layer_data_dictionary.md` — grain, columns, transformations, and assumptions.

## Run in SQL Server Management Studio
**Prerequisite:** the Silver layer must already be created and populated in database `dm_course`.

1. Run `sql/ddl/03_init_gold_layer.sql`.
2. Run `sql/dml/02_populate_gold_layer.sql`.
3. Run `sql/quality/03_gold_data_quality_checks.sql`.
4. Review all returned results. In particular, checks 2–6 should show no duplicates, orphan rows, invalid aggregates, or daily-total mismatches.

## Model overview
- `gold.dim_building`: one row per building.
- `gold.fact_energy_daily`: one row per building, meter type, and date.
- Energy readings are summed daily, with average/minimum/maximum hourly readings retained.
- Weather is first aggregated to site/day, then joined to the daily energy fact. This avoids multiplying energy totals during the join.
- Meter types remain separate and are never summed together.

## Reruns
The Gold load is a full rebuild: it deletes existing Gold fact and dimension rows and reloads them from Silver inside one transaction. It is safe to rerun after the Silver layer has been updated, provided no other tables reference these Gold tables.

## Verification status
The scripts were statically checked against the Silver DDL and DML in `ASHRAE_Silver_Layer_Reviewed.zip`. They were **not** executed in SQL Server/SSMS because the actual database and loaded source data are not available in this handoff. Do not report live execution as successful until the scripts have been run and the quality-check outputs reviewed.
