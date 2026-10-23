# ASHRAE Energy Prediction - Data Warehouse Project

## 1. Project Overview
A Data Warehouse project built using SQL Server to store, process, and analyze building energy consumption from the ASHRAE dataset (1,449 buildings across 16 sites).

## 2. Tools & Software
* **Database Engine:** Microsoft SQL Server
* **IDE:** SQL Server Management Studio (SSMS) & VS Code
* **Version Control:** Git & GitHub

## 3. Project Structure
* `data/raw/`: Contains raw CSV files locally (excluded from Git via `.gitignore`).
* `sql/ddl/`: SQL scripts for creating databases, schemas, and tables.
* `sql/quality/`: SQL scripts for data quality checks (Completeness, Validity, Duplicates).
* `docs/`: Project documentation and data dictionaries.

## 4. How to Run
1. Open SSMS and connect to `localhost`.
2. Run `sql/ddl/01_create_bronze_tables.sql` to create database `dm_course` and load data.
3. Run `sql/quality/01_data_quality_checks.sql` to execute the data quality report.

## 5. Quality Report Summary (Unit 1)
* **Air Temperature:** 99.96% complete (only 55 missing values).
* **Cloud Coverage:** 50.51% complete.
* **Year Built:** 46.58% complete.
* **Validity:** Zero negative energy readings.
* **Duplicates:** Zero duplicate records found in 20.2 million rows.