# Airviro ETL Notes (Lecture 4 Starter)

For the student-facing lecture flow and learning outcomes, start with:
- [Lecture 4 Overview](./README.md)

## Overview

This pipeline ingests:
- Air quality measurements from configured Airviro stations (default `8,19`).
- Pollen measurements from configured Airviro stations (default `25`).

It loads normalized long-form measurements into `warehouse.raw.airviro_measurement` and exposes curated Superset-friendly views in `warehouse.mart.*`.

## Why this design

The pipeline follows practical design principles aligned with modern data engineering patterns:
- ingestion in bounded windows with adaptive splitting;
- long-form raw storage + curated serving views;
- idempotent upserts on natural keys;
- quality checks at ingestion boundary;
- explicit audit logging for reruns and backfills.

## Airviro caveat handled

Airviro can fail on wide date windows (observed as HTTP 503). The extractor:
- starts with large windows to minimize request count;
- splits failed windows recursively until successful or minimum window size is reached.

## CLI commands

Run from repo root:

```bash
.venv/bin/python -m etl.airviro.cli bootstrap-db
.venv/bin/python -m etl.airviro.cli run --from 2020-01-01 --to 2025-12-31
.venv/bin/python -m etl.airviro.cli backfill --from 2020-01-01
.venv/bin/python -m etl.airviro.cli warehouse-status
```

Run only selected sources (useful for onboarding a new station without replaying existing sources):

```bash
.venv/bin/python -m etl.airviro.cli run --from 2020-01-01 --to 2025-12-31 --source-key air_quality_station_19
```

Verbose progress (recommended while teaching/debugging):

```bash
.venv/bin/python -m etl.airviro.cli run --from 2020-01-01 --to 2025-12-31 --verbose
```

`--verbose` prints source/window progress, retries, split events, and cumulative counts to stderr while keeping the final JSON summary on stdout.

Warehouse status can also be exported as JSON for automation:

```bash
.venv/bin/python -m etl.airviro.cli warehouse-status --json
```

Dry-run validation without DB writes:

```bash
.venv/bin/python -m etl.airviro.cli run --from 2025-01-01 --to 2025-01-31 --dry-run
```

Source configuration in `.env`:

- `AIRVIRO_AIR_STATION_IDS` (comma-separated, default `8,19`)
- `AIRVIRO_POLLEN_STATION_IDS` (comma-separated, default `25`)

## Superset serving objects

- `mart.v_air_quality_hourly`
- `mart.v_pollen_daily`
- `mart.v_airviro_measurements_long`

Dimensions:
- `mart.dim_datetime_hour`
- `mart.dim_indicator`
- `mart.dim_wind_direction`

## Source links

- Airviro endpoint examples:
  - <https://airviro.klab.ee/station/csv?filter%5Btype%5D=POLLEN&filter%5BcancelSearch%5D=&filter%5BstationId%5D=25&filter%5BdateFrom%5D=01.05.2025&filter%5BdateUntil%5D=31.05.2025&filter%5BsubmitHit%5D=1&filter%5BindicatorIds%5D=>
  - <https://airviro.klab.ee/station/csv?filter%5BstationId%5D=8&filter%5BdateFrom%5D=21.02.2026&filter%5BdateUntil%5D=28.02.2026>
  - <https://airviro.klab.ee/station/csv?filter%5BstationId%5D=19&filter%5BdateFrom%5D=23.02.2026&filter%5BdateUntil%5D=02.03.2026>
- Open-Meteo APIs:
  - Docs: <https://open-meteo.com/en/docs>
  - Historical weather API: <https://open-meteo.com/en/docs/historical-weather-api>
- Estonian Environment Portal open-data API:
  - Overview: <https://www.ilmateenistus.ee/teenused/avaandmete-api/>
  - Swagger: <https://avaandmed.keskkonnaportaal.ee/swagger/index.html>
