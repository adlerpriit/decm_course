# Lecture 5: Airflow + dbt Orchestration

## Audience and Goal

This lecture builds on Lecture 4 ETL by moving from manual runs to scheduled, automated pipeline execution.

Goal: understand how Airflow orchestrates ETL + dbt with incremental runs, backfill, and idempotent behavior.

## Learning Outcomes

After this lecture, students should be able to:

1. Explain how DAG scheduling, catch-up behavior, and backfill differ.
2. Run and monitor the `airviro_incremental` and `airviro_backfill` DAGs.
3. Explain watermark-based incremental processing in this course pipeline.
4. Run dbt transformations/tests as part of orchestration.
5. Describe how this training setup differs from production architecture.

## Practical Flow (Core Path)

Run from repo root inside the devcontainer:

```bash
make up-all
make airflow-unpause-dags
make airflow-trigger-incremental
make airflow-list-runs DAG_ID=airviro_incremental
make dbt-build
```

Backfill example:

```bash
make airflow-trigger-backfill BACKFILL_START=2020-01-01 BACKFILL_END=2020-12-31 BACKFILL_CHUNK_DAYS=31
```

Open Airflow UI:
- <http://localhost:8080>
- user: `airflow`
- pass: `airflow`

## Pipeline Pattern In This Repository

1. Airflow schedules or triggers ETL windows.
2. Python ETL loads raw data idempotently.
3. dbt builds marts and executes tests.
4. Watermarks advance only after successful ETL + dbt completion.

See detailed operational behavior and DAG notes:
- [operations.md](./operations.md)

## Better Practices: "Ideal" Flow Beyond The Classroom

The current setup is intentionally lightweight for local learning. For production-style delivery, prefer:

1. Airflow production deployment pattern (for example Helm on Kubernetes), not the quick-start Compose topology.
2. Idempotent task design with deterministic partitions and upserts.
3. Minimal heavy logic at DAG parse time (keep top-level DAG code lightweight).
4. Explicit dependency/image management (custom Airflow image with pinned requirements).
5. dbt-first transformation contracts (`dbt build`, tests, source freshness) in CI/CD and scheduled runs.

Verified references (as of March 12, 2026):

- Airflow Docker Compose quick-start caveat (learning/dev):
  <https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html>
- Airflow best practices (idempotency, task design):
  <https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html>
- Airflow DAG run and catchup behavior:
  <https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dag-run.html>
- dbt build command:
  <https://docs.getdbt.com/reference/commands/build>
- dbt source freshness:
  <https://docs.getdbt.com/reference/resource-properties/freshness>
