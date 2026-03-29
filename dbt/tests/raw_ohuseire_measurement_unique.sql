-- Fail when raw natural keys are duplicated.

select
  source_type,
  station_id,
  observed_at,
  indicator_code
from {{ source('ohuseire_raw', 'ohuseire_measurement') }}
group by 1, 2, 3, 4
having count(*) > 1
