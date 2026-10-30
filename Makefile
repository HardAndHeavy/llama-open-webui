.DEFAULT_GOAL := run

.PHONY: run stop

run:
	docker compose up -d

stop:
	docker compose down

include models.mk
