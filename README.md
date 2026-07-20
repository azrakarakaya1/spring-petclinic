# DevOps Workflow Implementation for the Spring PetClinic App

This repository is based on the official Spring PetClinic sample application.

Original repository: https://github.com/spring-projects/spring-petclinic

For this case study, I selected Spring PetClinic app to practise DevOps concepts in a technology stack outside of my previous experience. 


---


## Requirements

Following tools must be installed before running the project:

- Docker Desktop
- Docker Compose
- Minikube
- kubectl
- Make


---


## How to run the app?

The application can be deployed using either Docker Compose or Kubernetes manifests. I deployed the application with Docker Compose first. Then, I created Kubernetes manifests to create the same setup in a Minikube cluster.

### 1. Docker Compose

```
make up 
```
Starts the application and the PostgreSQL database


### 2. Kubernetes Manifests

```
make cluster-start
```
Creates the Minikube cluster

```
make apply-manifests
```
Deploys Kubernetes resources

```
kubectl port-forward service/petclinic-service 8080:8080
```
Applies port forwarding to make the app accessible at http://localhost:8080

---


## Project Steps

### Step 1: Select an Application

I selected the Spring PetClinic app (Java): https://github.com/spring-projects/spring-petclinic

### Step 2: Dockerize the App

For this step, I wrote 3 files:
* Dockerfile
* build.sh
* docker-compose.yml

The **Dockerfile** creates a Docker image for the Spring PetClinic application using a multi-stage build.

<details>
<summary>See Dockerfile</summary>
    
```
FROM bellsoft/liberica-runtime-container:jdk-21-stream-musl

COPY . /home/app/spring-petclinic
WORKDIR /home/app/spring-petclinic
RUN ./mvnw clean package -DskipTests

FROM bellsoft/liberica-runtime-container:jre-21-musl

WORKDIR /home/app
EXPOSE 8080

COPY --from=0 /home/app/spring-petclinic/target/*.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]
```

</details>

The **build.sh** script builds the Docker image and pushes it to Docker Hub by running:

```
./build.sh <tag>
```

<details>
<summary>See build.sh</summary>
    
```
version=$1

docker build -t azrakarakaya/spring-petclinic-app:$version .
docker push azrakarakaya/spring-petclinic-app:$version
```
</details>

The **docker-compose.yml** file defines the Spring PetClinic app and the PostgreSQL database. It starts both services and creates a Docker volume for persistent data storage.

<details>
<summary>See docker-compose.yml</summary>
    
```
services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: petclinic
      POSTGRES_USER: petclinic
      POSTGRES_PASSWORD: petclinic
    ports:
      - "5432:5432"
    volumes:
      - petclinic-data:/var/lib/postgresql/data

  web:
    image: azrakarakaya/spring-petclinic-app:3
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=postgres
      - SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/petclinic
    depends_on:
      - db

volumes:
  petclinic-data:
```
</details>


### Step 3: Setup a Minikube Cluster

In this step, I created a local Kubernetes cluster using Minikube. Using the following commands, you can start the cluster and check its status:

```
make cluster-start
make cluster-status
```

### Step 4: K8s Manifests

For this step, I wrote 5 Kubernetes manifests and a script that applies them all starting with the database.

The **apply_k8s.sh** 

<details>
<summary>See docker-compose.yml</summary>
    
```
#!/bin/bash

clean=$1

if [[ $clean == "clean" ]]
then
    kubectl delete deployment petclinic-deployment
    kubectl delete deployment postgres-deployment
    kubectl delete service petclinic-service
    kubectl delete service postgres-service
    exit 0
fi

if [[ $clean == "clean-pvc" ]]
then
    kubectl delete pvc petclinic-data-claim
    exit 0
fi

# database
kubectl apply -f k8s/postgres_pvc.yaml
kubectl apply -f k8s/postgres_deployment.yaml
kubectl apply -f k8s/postgres_service.yaml
kubectl rollout status deployment/postgres-deployment

# backend
kubectl apply -f k8s/petclinic_deployment.yaml
kubectl apply -f k8s/petclinic_service.yaml
kubectl rollout status deployment/petclinic-deployment

# port forward to make the app accessible at http://localhost:8080
#kubectl port-forward service/petclinic-service 8080:8080
```
</details>

* k8s/*
* scripts/apply-k8s.sh

(current work)


### Makefile

I find it easier to run common Docker Compose and Kubernetes commands using a Makefile. This way, I can manage both environments using a single file with simplified commands.

<details>
<summary>See Makefile</summary>

```
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
	chmod +x scripts/apply_k8s.sh
	./scripts/apply_k8s.sh
clean-manifests:
	chmod +x scripts/apply_k8s.sh
	./scripts/apply_k8s.sh clean
clean-pvc:
	chmod +x scripts/apply_k8s.sh
	./scripts/apply_k8s.sh clean-pvc
cluster-stop: clean-manifests
	minikube stop -p petclinic
cluster-status:
	minikube status -p petclinic

.PHONY: up down restart cluster-start apply-manifests clean-manifests cluster-stop clean-pvc cluster-status
```
</details>

Docker Compose commands:

```
make up             # Starts the application and the PostgreSQL database 
make down           # Stops and removes containers and volumes
make restart        # Restarts the setup
```

Cluster-related commands:

```
make cluster-start          # Starts the Minikube cluster
make cluster-status         # Shows the current status of the cluster
make apply-manifests        # Deploys Kubernetes resources
make clean-manifests        # Removes deployments and services
make cluster-stop           # Removes resources and stops the cluster
make clean-pvc              # Removes persistent volume claim and the data
```

---

## Insights

- Explain 3 different images builded with 3 different base images and why did I choose bellsoft and how multistaging, compiling while building image or inside the container.
- Add how to make docker the main driver
- ClusterIP service type and port forwarding method
- PersistentVolumeClaim (PVC) in K8s
- Evaluate its usability for production environments (ingress controller instead of port forward)
- Evaluate if the provided scripts are shell compatible
- State limitations (like docker compose healthcheck can be added)
- For now, I use local volumes but in a production environment volumes should always be remote so 1 possible improvement is connecting to a neon postgres db
- Changing service type to nodeport for external communication
- Database can be deployed via Statefulset instead of a Deployment

Notes: Add image of the app and a flowchart that shows how each make command runs which files/commands

---

## References

- Dockerfile multi-staging reference:
  - https://docs.docker.com/build/building/multi-stage/  
  - https://medium.com/@cat.edelveis/a-guide-to-docker-multi-stage-builds-for-spring-boot-08e3a64c9812

- Docker Compose & PostgreSQL:
  - https://docs.docker.com/compose/how-tos/startup-order/
  - https://jdbc.postgresql.org/documentation/use/ 
  - https://dev.to/alexmercedcoder/a-deep-dive-into-docker-compose-27h5
  - https://stackoverflow.com/questions/66808350/what-is-the-jdbc-connection-string-when-using-a-docker-container

- Cluster setup:
  - https://kubernetes.io/docs/tutorials/kubernetes-basics/create-cluster/cluster-intro/
  - https://minikube.sigs.k8s.io/docs/drivers/docker/

- Learning K8s objects:

- K8s rolling update deployment: https://octopus.com/devops/kubernetes-deployments/kubernetes-rolling-deployment/
- Port forwarding: https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/
- Using env variables in K8s manifests: https://www.mirantis.com/blog/cloud-native-5-minutes-at-a-time-using-kubernetes-secrets-with-environment-variables-and-volume-mounts/
- Persistent storage in K8s: https://www.mirantis.com/blog/persistent-data-and-storage-with-kubernetes/
