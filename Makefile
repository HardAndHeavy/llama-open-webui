COMPOSE := docker compose -p llama-open-webui

.PHONY: run stop run-strata stop-strata

run:
	$(COMPOSE) -f compose.strata.yaml down --remove-orphans
	$(COMPOSE) -f compose.llama.yaml up -d

stop:
	$(COMPOSE) -f compose.llama.yaml down --remove-orphans

.env:
	@key=$$(openssl rand -hex 24) && umask 077 && \
		sed "s/^STRATA_API_KEY=.*/STRATA_API_KEY=$$key/" .env.example > .env

run-strata: .env
	$(COMPOSE) -f compose.strata.yaml config -q
	$(COMPOSE) -f compose.llama.yaml down --remove-orphans
	$(COMPOSE) -f compose.strata.yaml up -d

stop-strata:
	$(COMPOSE) -f compose.strata.yaml down --remove-orphans

include models.mk
