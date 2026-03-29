{{ config(materialized='view') }}

select
  source_type,
  source_type || ':' || station_id::text as station_key,
  source_type || ':' || indicator_code as indicator_key,
  station_id,
  observed_at,
  observed_at::date as observed_date,
  cast(to_char(observed_at::date, 'YYYYMMDD') as integer) as date_key,
  extract(hour from observed_at)::integer as observed_clock_hour,
  indicator_code,
  indicator_name,
  value_numeric,
  source_row_hash,
  extracted_at
from {{ source('ohuseire_raw', 'ohuseire_measurement') }}
