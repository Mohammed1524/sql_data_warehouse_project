# ASHRAE Energy Prediction — Project Idea, Sources & Analytical Questions

## 1. Sources Links & Datasets
- **Official Competition:** [ASHRAE - Great Energy Predictor III (Kaggle)](https://www.kaggle.com/competitions/ashrae-energy-prediction)
- **Dataset Download Page:** [Kaggle Competition Data](https://www.kaggle.com/competitions/ashrae-energy-prediction/data)
- **Local Raw CSV Files (`data/raw/`):**
  - `building_metadata.csv` (1,449 buildings across 16 sites)
  - `weather_train.csv` (hourly site weather measurements)
  - `train.csv` (hourly building meter readings)

---

## 2. Project Idea
Design and implement a 3-layer SQL Server Data Warehouse (**Bronze**, **Silver**, **Gold**) in database `dm_course` for the ASHRAE Great Energy Predictor III dataset to ingest raw CSV files, clean and standardize building/weather/meter data, and aggregate hourly readings into an analytics-ready daily energy mart.

---

## 3. Analytical Questions & Answers (SQL Queries on Gold Layer)

### Question 1: How does daily energy consumption vary by building `primary_use`, floor area (`square_feet`), and `year_built`?
**Answer:** By joining `gold.fact_energy_daily` with `gold.dim_building` on `building_id`, we can compare building counts, average floor area, average daily consumption, and total energy consumption across each `primary_use` category.

```sql
USE dm_course;
SELECT
    b.primary_use,
    COUNT(DISTINCT b.building_id) AS building_count,
    ROUND(AVG(CAST(b.square_feet AS FLOAT)), 0) AS avg_square_feet,
    ROUND(AVG(f.daily_energy_consumption), 2) AS avg_daily_consumption,
    ROUND(SUM(f.daily_energy_consumption), 2) AS total_energy_consumption
FROM gold.fact_energy_daily AS f
INNER JOIN gold.dim_building AS b
    ON b.building_id = f.building_id
GROUP BY b.primary_use
ORDER BY total_energy_consumption DESC;
```

---

### Question 2: How do daily site weather conditions (`average_air_temperature`, etc.) affect daily energy consumption across sites (`site_id`)?
**Answer:** `gold.fact_energy_daily` stores pre-aggregated daily site weather alongside each building's daily energy consumption, allowing direct comparison of energy demand across temperature bands per site without multiplying rows.

```sql
USE dm_course;
SELECT
    f.site_id,
    CASE
        WHEN f.average_air_temperature < 10 THEN 'Cold (< 10 C)'
        WHEN f.average_air_temperature BETWEEN 10 AND 22 THEN 'Moderate (10-22 C)'
        ELSE 'Warm (> 22 C)'
    END AS temp_band,
    COUNT(*) AS day_meter_records,
    ROUND(AVG(f.daily_energy_consumption), 2) AS avg_daily_consumption
FROM gold.fact_energy_daily AS f
WHERE f.average_air_temperature IS NOT NULL
GROUP BY
    f.site_id,
    CASE
        WHEN f.average_air_temperature < 10 THEN 'Cold (< 10 C)'
        WHEN f.average_air_temperature BETWEEN 10 AND 22 THEN 'Moderate (10-22 C)'
        ELSE 'Warm (> 22 C)'
    END
ORDER BY f.site_id, temp_band;
```

---

### Question 3: What are the monthly and daily consumption patterns across each `meter` type?
**Answer:** `gold.fact_energy_daily` keeps each meter category separate (`0` = Electricity, `1` = Chilled Water, `2` = Steam, `3` = Hot Water) so monthly and seasonal consumption trends can be tracked accurately per meter type without mixing incompatible units.

```sql
USE dm_course;
SELECT
    f.meter,
    CASE f.meter
        WHEN 0 THEN 'Electricity'
        WHEN 1 THEN 'Chilled Water'
        WHEN 2 THEN 'Steam'
        WHEN 3 THEN 'Hot Water'
        ELSE 'Other'
    END AS meter_type,
    YEAR(f.reading_date) AS reading_year,
    MONTH(f.reading_date) AS reading_month,
    ROUND(SUM(f.daily_energy_consumption), 2) AS monthly_total_consumption,
    ROUND(AVG(f.daily_energy_consumption), 2) AS avg_daily_consumption
FROM gold.fact_energy_daily AS f
GROUP BY f.meter, YEAR(f.reading_date), MONTH(f.reading_date)
ORDER BY f.meter, reading_year, reading_month;
```
