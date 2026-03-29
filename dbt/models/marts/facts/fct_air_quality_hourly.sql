{{ config(materialized='table') }}

select
  station_key,
  indicator_key,
  date_key,
  hour_key,
  source_type,
  station_id,
  observed_date,
  observed_at,
  observed_clock_hour,
  indicator_code,
  value_numeric,
  source_row_hash,
  extracted_at,
  measurements_in_day,
  distinct_clock_hours_in_day,
  is_complete_day_series,
  has_repeated_clock_hour,
  has_repeated_or_skipped_clock_hour
from {{ ref('int_air_quality_measurement') }}
