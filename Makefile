# default settings are for docker compose
up:
	docker compose up -d
restart:
	docker compose down -v
	docker compose up -d
down:
	docker compose down -v

# cluster operations
cluster-start:
	minikube start -p petclinic --driver=docker
apply-manifests: cluster-start
	./scripts/apply-k8s.sh
clean-manifests:
	./scripts/apply-k8s.sh clean
cluster-stop: clean-manifests
	minikube stop -p petclinic

.PHONY: up down restart cluster-start apply-manifests clean-manifests cluster-stop