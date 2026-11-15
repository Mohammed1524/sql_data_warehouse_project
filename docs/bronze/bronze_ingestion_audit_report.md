# Bronze Layer Ingestion & Quality Report

**Project:** ASHRAE Energy Prediction
**University:** New Mansoura University - Faculty of Computer Science and Engineering
**Date:** October 24, 2026
**Team:** Mohamed Nour - Haneen Mohamed

## 1. Summary
Built the Bronze Layer on SQL Server to store raw CSV datasets without modification. Successfully ingested over 20.3 million rows and executed data quality checks.

## 2. Database & Schemas Setup
Executed DDL statements to create:
- Database: `dm_course`
- Schema `metadata`: For tracking source files and lineage
- Schema `raw`: For storing raw Bronze staging tables
- Schema `quality`: For storing data quality check scripts and results

## 3. Source Registration
Created table `metadata.source_registry` and registered the three Kaggle datasets:
- `building_metadata.csv`: Static building properties
- `weather_train.csv`: Hourly weather observations
- `train.csv`: Hourly energy meter readings

## 4. Bulk Data Ingestion
Created staging tables in the `raw` schema and loaded data using `BULK INSERT` with `TABLOCK` and `0x0a` row terminator:
- `raw.building_metadata`: 1,449 rows loaded
- `raw.weather_train`: 139,773 rows loaded
- `raw.train`: 20,216,100 rows loaded
- Total records ingested: 20,357,322 rows

## 5. Data Quality Results
Executed `01_data_quality_checks.sql` with the following findings:

### A. Completeness:
- `air_temperature`: 99.96% complete (55 missing values)
- `cloud_coverage`: 50.51% complete (69,173 missing values)
- `year_built`: 46.58% complete (774 missing values)

### B. Validity & Duplicates:
- Negative readings in `meter_reading`: 0 invalid records found
- Duplicate records for `(building_id, meter, timestamp)`: 0 duplicates found

## 6. Next Steps for Silver Layer
- Fill missing `air_temperature` values using daily averages
- Replace missing `year_built` values with a default indicator instead of dropping buildings
- Decode `meter` numbers (0, 1, 2, 3) into descriptive names: Electricity, Chilled Water, Steam, Hot Water
- Split `timestamp` into separate Year, Month, Day, and Hour columns