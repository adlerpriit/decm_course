# Course Local Stack: Superset + Airflow

This repository is designed for teaching with minimum host setup.

Students need on host:
- VS Code
- Docker Desktop or Docker Engine
- Git

Everything else runs from the devcontainer.
The devcontainer sets `HOST_WORKSPACE` to your host repo path so Docker bind mounts resolve correctly through the mounted Docker socket.

## 1) First Run

From the repo root inside the devcontainer:

```bash
make init
make up-superset
```

Open Superset at <http://localhost:8088>.

Default Superset login (from `.env`):
- username: `admin`
- password: `admin`

## 2) Start Airflow

```bash
make up-airflow
```

Open Airflow at <http://localhost:8080>.

Default Airflow login (from `.env`):
- username: `airflow`
- password: `airflow`

## 3) Start Both Stacks

```bash
make up-all
```

## Compose Profiles

This project uses one `docker-compose.yml` with profiles:
- `superset`: Superset app + Superset Redis + shared Postgres + init
- `airflow`: Airflow core services + shared Postgres + init

Equivalent direct commands:

```bash
docker compose --profile superset up -d
docker compose --profile airflow up -d
docker compose --profile superset --profile airflow up -d
```

## Persistent Data

The stack is persistent by default:
- Named volumes keep Superset metadata and shared Postgres data across restarts.
- `airflow/dags` is bind-mounted from your repo for live DAG editing.
- Airflow `logs`, `config`, and `plugins` use Docker named volumes.
- The same Postgres instance also creates a `warehouse` database for ETL/dbt work.

## Reset / Cleanup

Stop containers only:

```bash
make down
```

Remove containers and volumes (keeps pulled images):

```bash
make reset-volumes
```

Remove containers, volumes, and local images:

```bash
make reset-all
```

## Useful Commands

```bash
make ps
make logs SERVICE=superset
make logs SERVICE=airflow-scheduler
make logs SERVICE=postgres
```

## Environment File

- `.env` is local-only and ignored by git.
- `.env.example` is tracked and should be copied for new environments.
- `make init` copies `.env.example` to `.env`, generates `SUPERSET_SECRET_KEY`, and sets `AIRFLOW_UID`.
- `.env.example` includes `SUPERSET_DB_*`, `AIRFLOW_DB_*`, and `WAREHOUSE_DB_*` to keep naming explicit by purpose.

## Running Outside Devcontainer

If you run `make` directly on the host, `HOST_WORKSPACE` defaults to your current directory.
If you run `docker compose` manually, export `HOST_WORKSPACE` first:

```bash
export HOST_WORKSPACE="$(pwd)"
```
