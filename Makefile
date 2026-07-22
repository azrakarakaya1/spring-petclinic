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
apply-manifests:
	./scripts/apply_k8s.sh
clean-manifests:
	./scripts/apply_k8s.sh clean
clean-pvc:
	./scripts/apply_k8s.sh clean-pvc
cluster-stop: clean-manifests
	minikube stop -p petclinic
cluster-status:
	minikube status -p petclinic

.PHONY: up down restart cluster-start apply-manifests clean-manifests cluster-stop clean-pvc cluster-status