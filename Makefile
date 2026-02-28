SHELL := /bin/bash
ENV_FILE := .env
HOST_WORKSPACE ?= $(PWD)
export HOST_WORKSPACE
COMPOSE := docker compose --env-file $(ENV_FILE)
PROFILES_SUPERSET := --profile superset
PROFILES_AIRFLOW := --profile airflow

.PHONY: help init check-host-workspace up-superset up-airflow up-all down logs ps reset-volumes reset-all

help:
	@echo "Targets:"
	@echo "  make init           Copy .env.example to .env (if missing), set secret key, set AIRFLOW_UID"
	@echo "  make up-superset    Start Superset stack (profile: superset)"
	@echo "  make up-airflow     Start Airflow stack (profile: airflow)"
	@echo "  make up-all         Start Superset + Airflow"
	@echo "  make down           Stop and remove containers"
	@echo "  make ps             Show container status"
	@echo "  make logs SERVICE=<name>  Follow logs for one service"
	@echo "  make reset-volumes  Remove containers and named volumes"
	@echo "  make reset-all      Remove containers, volumes, and local images"

init:
	@if [ ! -f "$(ENV_FILE)" ]; then cp .env.example "$(ENV_FILE)"; echo "Created $(ENV_FILE) from .env.example"; fi
	@if grep -q '^SUPERSET_SECRET_KEY=__CHANGE_ME__' "$(ENV_FILE)"; then \
		key="$$(openssl rand -hex 32)"; \
		sed -i "s/^SUPERSET_SECRET_KEY=.*/SUPERSET_SECRET_KEY=$$key/" "$(ENV_FILE)"; \
		echo "Generated SUPERSET_SECRET_KEY"; \
	fi
	@uid="$$(id -u)"; \
	if grep -q '^AIRFLOW_UID=' "$(ENV_FILE)"; then \
		sed -i "s/^AIRFLOW_UID=.*/AIRFLOW_UID=$$uid/" "$(ENV_FILE)"; \
	else \
		echo "AIRFLOW_UID=$$uid" >> "$(ENV_FILE)"; \
	fi
	@mkdir -p airflow/dags

check-host-workspace:
	@if [ -z "$$HOST_WORKSPACE" ]; then echo "HOST_WORKSPACE is not set."; exit 1; fi
	@if [ ! -d "$$HOST_WORKSPACE" ]; then echo "HOST_WORKSPACE does not exist: $$HOST_WORKSPACE"; exit 1; fi

up-superset: init check-host-workspace
	@$(COMPOSE) $(PROFILES_SUPERSET) up -d

up-airflow: init check-host-workspace
	@$(COMPOSE) $(PROFILES_AIRFLOW) up -d

up-all: init check-host-workspace
	@$(COMPOSE) $(PROFILES_SUPERSET) $(PROFILES_AIRFLOW) up -d

down: check-host-workspace
	@$(COMPOSE) $(PROFILES_SUPERSET) $(PROFILES_AIRFLOW) down --remove-orphans

ps: check-host-workspace
	@$(COMPOSE) $(PROFILES_SUPERSET) $(PROFILES_AIRFLOW) ps

logs: check-host-workspace
	@if [ -z "$(SERVICE)" ]; then echo "Usage: make logs SERVICE=<service-name>"; exit 1; fi
	@$(COMPOSE) $(PROFILES_SUPERSET) $(PROFILES_AIRFLOW) logs -f --tail=200 $(SERVICE)

reset-volumes: check-host-workspace
	@$(COMPOSE) $(PROFILES_SUPERSET) $(PROFILES_AIRFLOW) down -v --remove-orphans

reset-all: check-host-workspace
	@$(COMPOSE) $(PROFILES_SUPERSET) $(PROFILES_AIRFLOW) down -v --rmi local --remove-orphans
