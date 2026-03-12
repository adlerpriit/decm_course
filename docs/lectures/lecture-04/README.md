# Lecture 4: Python ETL + Superset Basics

## Audience and Goal

This lecture is for students who completed Lecture 3 and can already run the repository in a devcontainer.

Goal: implement and explain a complete ETL cycle (extract, transform, load), then visualize curated outputs in Superset.

## Learning Outcomes

After this lecture, students should be able to:

1. Explain ETL stages and map them to this repository.
2. Run the Python ETL for a bounded historical period.
3. Validate ingestion results with warehouse status checks.
4. Connect Superset to the warehouse and create first visuals.
5. Explain why idempotency and data-quality checks matter.

## Practical Flow (Core Path)

Run from repo root inside the devcontainer:

```bash
make up-superset
make devcontainer-join-course-network
make etl-bootstrap
make etl-backfill-2020-2025
make warehouse-status
```

Lecture 4 intentionally keeps Airflow out of scope.
Do not run `make up-all` here; Airflow orchestration is introduced in Lecture 5.

Then in Superset:

1. Open <http://localhost:8088>.
2. Connect to Postgres warehouse DB.
3. Use marts for analysis (`mart.v_air_quality_hourly`, `mart.v_pollen_daily`, `mart.v_airviro_measurements_long`).
4. Build one chart and one dashboard.

## ETL Stages In This Repository

1. Extract:
   - Pull CSV data from Airviro API in bounded date windows.
   - The extractor starts with larger windows (fewer API calls) and splits only when needed.
   - Retries are applied for transient fetch failures.
2. Transform:
   - Parse datetime values, normalize numeric types, and run integrity checks.
   - Convert wide CSV rows into long-form measurement records.
   - Normalize indicator names into stable machine-friendly indicator codes.
3. Load:
   - Upsert to `raw.airviro_measurement` with idempotent keys.
   - Write ingestion audit records for observability and troubleshooting.
4. Serve:
   - Refresh curated marts/dimensions in `mart.*` for Superset.

## Code Walkthrough (File + Function Map)

Use this map to connect ETL theory to implementation:

1. CLI orchestration (`etl/airviro/cli.py`)
   - `build_parser`: defines `bootstrap-db`, `run`, `backfill`, and `warehouse-status`.
   - `run_pipeline`: end-to-end flow for selected source(s) and date range.
   - `build_progress_logger`: verbose extraction progress events.
   - `main`: command dispatch and top-level error handling.

2. Runtime configuration (`etl/airviro/config.py`)
   - `Settings.from_env`: reads `.env` values into one typed config object.
   - `candidate_db_hosts`: supports both devcontainer and compose network host resolution.

3. Extraction + transformation (`etl/airviro/pipeline.py`)
   - `get_source_configs`: expands configured station IDs into source definitions.
   - `date_chunks`: splits date ranges into fixed-size windows.
   - `fetch_source_window`: calls Airviro API with retry/backoff behavior.
   - `extract_window_with_split`: recursively splits failing windows.
   - `parse_airviro_csv`: parses CSV rows and builds normalized measurements.
   - `parse_localized_numeric`: handles localized numeric formats and null-like values.
   - `normalize_indicator_code`: creates stable indicator keys from source headers.
   - `build_source_records`: complete per-source extract+transform stage.

4. Load + warehouse operations (`etl/airviro/db.py`)
   - `connect_warehouse`: opens Postgres connection with fallback host candidates.
   - `apply_schema`: applies `sql/warehouse/airviro_schema.sql`.
   - `upsert_measurements`: idempotent upsert into `raw.airviro_measurement`.
   - `log_ingestion_audit`: records success/failure metadata per source batch.
   - `refresh_dimensions`: refreshes serving-layer dimensions/views after load.
   - `collect_warehouse_status`: used by `warehouse-status` reporting.

## Why This Structure Works Well For Learning

1. Separation of concerns:
   - `pipeline.py` focuses on source parsing and data quality.
   - `db.py` focuses on persistence and SQL-side concerns.
   - `cli.py` focuses on user-facing command flow.
2. Idempotency:
   - rerunning the same window updates existing rows instead of duplicating them.
3. Observability:
   - verbose mode + ingestion audit table provide a clear trace of what happened.
4. Operational safety:
   - bounded windows and split-on-failure reduce risk from unstable source behavior.

See the operational runbook for commands and schema details:
- [operations.md](./operations.md)

## Better Practices: "Ideal" Flow Beyond The Classroom

Our local Compose setup is intentionally simple for teaching. A more ideal real-world flow would add:

1. Clear layered modeling (`staging` -> `intermediate` -> `marts`) and strict naming conventions.
2. Automated data tests and source freshness checks in every build.
3. Incremental processing with explicit keys/watermarks and safe reruns.
4. CI/CD checks that run transformations/tests before deployment.
5. Orchestrated scheduling, retries, and alerting (introduced in Lecture 5).

Verified references (as of March 12, 2026):

- dbt project structure best practices:
  <https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview>
- dbt incremental models:
  <https://docs.getdbt.com/docs/build/incremental-models>
- dbt source freshness:
  <https://docs.getdbt.com/reference/resource-properties/freshness>
- dbt build command (run + test in one command):
  <https://docs.getdbt.com/reference/commands/build>
