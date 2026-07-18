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
make apply-manifests
```
Creates the cluster if not exists and deploys Kubernetes resources

---


## Project Steps

### Step 1: Select an Application

I selected the Spring PetClinic app (Java): https://github.com/spring-projects/spring-petclinic

### Step 2: Dockerize the App

For this step, I wrote 3 files:
* Dockerfile
* build.sh
* docker-compose.yml

The **Dockerfile** creates a Docker image for the Spring PetClinic application using a multi-stage build. It starts both services and creates a Docker volume.

<details>
<summary>See Dockerfile</summary>
    
```
FROM bellsoft/liberica-runtime-container:jdk-21-stream-musl AS builder

COPY . /home/app/spring-petclinic
WORKDIR /home/app/spring-petclinic
RUN ./mvnw clean package -DskipTests

FROM bellsoft/liberica-runtime-container:jre-21-musl

WORKDIR /home/app
EXPOSE 8080

COPY --from=builder /home/app/spring-petclinic/target/*.jar app.jar

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

The **docker-compose.yml** file defines the Spring PetClinic app and the PostgreSQL database for Docker Compose. It creates se, sets the required environment variables, connects them through the same network, and uses a Docker volume to keep the database data.

<details>
<summary>See docker-compose.yml</summary>
    
```
services:
  db:
    image: postgres:18.4-alpine
    environment:
      POSTGRES_DB: petclinic
      POSTGRES_USER: petclinic
      POSTGRES_PASSWORD: petclinic
    ports:
      - "5432:5432"
    volumes:
      - petclinic-data:/var/lib/postgresql

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
apply-manifests: cluster-start
	./scripts/apply-k8s.sh
clean-manifests:
	./scripts/apply-k8s.sh clean
cluster-stop: clean-manifests
	minikube stop -p petclinic
cluster-status:
	minikube status -p petclinic

.PHONY: up down restart cluster-start apply-manifests clean-manifests cluster-stop
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
```

### Checks

- Evaluate its usability for production environments
- Evaluate if the provided scripts are shell compatible
- State limitations
- Explain 3 different images builded with 3 different base images and why did I choose bellsoft and multistaging
- Add how to make docker the main driver?


### References

Dockerfile multi-staging reference: https://medium.com/@cat.edelveis/a-guide-to-docker-multi-stage-builds-for-spring-boot-08e3a64c9812

Cluster setup instructions: https://kubernetes.io/docs/tutorials/kubernetes-basics/create-cluster/cluster-intro/ 

Using Docker Desktop as driver: https://minikube.sigs.k8s.io/docs/drivers/docker/

Learning K8s objects:

K8s rolling update deployment: https://octopus.com/devops/kubernetes-deployments/kubernetes-rolling-deployment/

Port forwarding: https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/ 
