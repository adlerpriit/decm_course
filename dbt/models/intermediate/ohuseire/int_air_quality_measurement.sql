{{ config(materialized='view') }}

with source as (
  select
    station_key,
    indicator_key,
    source_type,
    station_id,
    observed_at,
    observed_date,
    date_key,
    observed_clock_hour,
    indicator_code,
    indicator_name,
    value_numeric,
    source_row_hash,
    extracted_at
  from {{ ref('stg_ohuseire_measurement') }}
  where source_type = 'air_quality'
),
daily_stats as (
  select
    station_key,
    indicator_key,
    observed_date,
    count(*) as measurements_in_day,
    count(distinct observed_clock_hour) as distinct_clock_hours_in_day
  from source
  group by station_key, indicator_key, observed_date
),
profiled as (
  select
    source.station_key,
    source.indicator_key,
    source.source_type,
    source.station_id,
    source.observed_at,
    source.observed_date,
    source.date_key,
    source.observed_clock_hour,
    source.indicator_code,
    source.indicator_name,
    source.value_numeric,
    source.source_row_hash,
    source.extracted_at,
    row_number() over (
      partition by source.station_key, source.indicator_key, source.observed_date
      order by source.observed_at, source.source_row_hash
    ) - 1 as hour_key
  from source
)
select
  profiled.station_key,
  profiled.indicator_key,
  profiled.source_type,
  profiled.station_id,
  profiled.observed_at,
  profiled.observed_date,
  profiled.date_key,
  profiled.hour_key,
  profiled.observed_clock_hour,
  profiled.indicator_code,
  profiled.indicator_name,
  profiled.value_numeric,
  profiled.source_row_hash,
  profiled.extracted_at,
  daily_stats.measurements_in_day,
  daily_stats.distinct_clock_hours_in_day,
  daily_stats.measurements_in_day = 24 as is_complete_day_series,
  daily_stats.distinct_clock_hours_in_day < daily_stats.measurements_in_day as has_repeated_clock_hour,
  daily_stats.measurements_in_day = 24
    and daily_stats.distinct_clock_hours_in_day <> 24 as has_repeated_or_skipped_clock_hour
from profiled
inner join daily_stats
  on profiled.station_key = daily_stats.station_key
 and profiled.indicator_key = daily_stats.indicator_key
 and profiled.observed_date = daily_stats.observed_date
