COMPOSE := docker compose -p llama-open-webui

.PHONY: run stop run-strata stop-strata

run:
	$(COMPOSE) -f compose.strata.yaml down --remove-orphans
	$(COMPOSE) -f compose.llama.yaml up -d

stop:
	$(COMPOSE) -f compose.llama.yaml down --remove-orphans

run-strata:
	bash scripts/prepare-strata.sh
	$(COMPOSE) -f compose.strata.yaml config -q
	$(COMPOSE) -f compose.llama.yaml down --remove-orphans
	$(COMPOSE) -f compose.strata.yaml up -d

stop-strata:
	$(COMPOSE) -f compose.strata.yaml down --remove-orphans

include models.mk
