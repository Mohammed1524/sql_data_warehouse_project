# قاموس البيانات (Data Dictionary)

## 1. جدول المباني `raw.building_metadata` (Static Data)
- `site_id` (INT | Nominal): رقم الموقع الجغرافي من 0 إلى 15.
- `building_id` (INT | Nominal): رقم المبنى الفريد من 0 إلى 1448.
- `primary_use` (VARCHAR | Nominal): نشاط المبنى (مثل Education, Office).
- `square_feet` (INT | Ratio): مساحة المبنى بالقدم المربع (> 0).
- `year_built` (INT | Interval): سنة بناء المبنى (يقبل NULL).
- `floor_count` (INT | Ratio): عدد طوابق المبنى (يقبل NULL).

## 2. جدول الطقس `raw.weather_train` (Time-Series Data)
- `site_id` (INT | Nominal): رقم الموقع المرتبط بالطقس.
- `timestamp` (DATETIME2 | Interval): تاريخ وساعة الرصد.
- `air_temperature` (FLOAT | Interval): حرارة الجو بالدرجة المئوية.
- `cloud_coverage` (FLOAT | Ordinal): تغطية الغيوم من 0 إلى 8.
- `dew_temperature` (FLOAT | Interval): درجة الندى لقياس الرطوبة.
- `precip_depth_1_hr` (FLOAT | Ratio): كمية المطر بالملليمتر (-1 تعني رذاذ خفيف).

- `sea_level_pressure` (FLOAT | Ratio): الضغط الجوي بالملي بار.
- `wind_direction` (FLOAT | Interval): اتجاه الرياح من 0 إلى 360 درجة.
- `wind_speed` (FLOAT | Ratio): سرعة الرياح بالمتر/ثانية (>= 0).

## 3. جدول العدادات `raw.train` (Time-Series Data)
- `building_id` (INT | Nominal): رقم المبنى.
- `meter` (TINYINT | Nominal): نوع العداد (0: كهرباء، 1: مياه مبردة، 2: بخار، 3: مياه ساخنة).
- `timestamp` (DATETIME2 | Interval): وقت قراءة العداد بالساعة.
- `meter_reading` (FLOAT | Ratio): استهلاك الطاقة الفعلي بالكيلوواط (>= 0).