up:
	docker compose up -d

restart:
	docker compose down -v
	docker compose up -d

down:
	docker compose down -v

.PHONY: up down restart