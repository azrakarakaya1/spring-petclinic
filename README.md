# DevOps Workflow Implementation for the Spring PetClinic App

This repository is based on the official Spring PetClinic sample application.

Original repository: https://github.com/spring-projects/spring-petclinic

For this case study, I selected Spring PetClinic app to practise DevOps concepts in a technology stack outside of my previous experience.

### Requirements

Following tools must be installed before running the project:

- Docker Desktop
- Docker Compose
- Minikube
- kubectl
- Make


### How to run the app?

1. Docker Compose

```
make up
make down
make restart
```

2. Kubernetes

```
make cluster-start
make cluster-stop
make cluster-status
make apply-manifests
make clean-manifests
```

How did I develop this structure?
Methodology: Run the app with docker compose first without any k8s requirements and write k8s manifests that does the same in a minikube cluster.


*Makefile*

bash ````
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


### Project Steps

#### Dockerize the App

*Dockerfile*

<details>
<summary>See Dockerfile</summary>
```Dockerfile
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


*build.sh*

```
./build.sh
```

<details>
<summary>See build.sh</summary>
````build.sh
version=$1

docker build -t azrakarakaya/spring-petclinic-app:$version .
docker push azrakarakaya/spring-petclinic-app:$version
```
</details>

- Explain 3 different images builded with 3 different base images and why did I choose bellsoft and multistaging


*docker-compose.yml*

<details>
<summary>See docker-compose.yml</summary>
````docker-compose.yml
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



#### Setup Minikube Cluster

```
make cluster-start
make cluster-status
```

- How to make docker the main driver?


#### K8s Manifests

* k8s/*
* scripts/apply-k8s.sh



#### Makefile

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

### Checks

- Evaluate its usability for production environments
- Evaluate if the provided scripts are shell compatible
- State limitations


### References

Dockerfile multi-staging reference: https://medium.com/@cat.edelveis/a-guide-to-docker-multi-stage-builds-for-spring-boot-08e3a64c9812

Cluster setup instructions: https://kubernetes.io/docs/tutorials/kubernetes-basics/create-cluster/cluster-intro/ 

Using Docker Desktop as driver: https://minikube.sigs.k8s.io/docs/drivers/docker/

Learning K8s objects:

K8s rolling update deployment: https://octopus.com/devops/kubernetes-deployments/kubernetes-rolling-deployment/

Port forwarding: https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/ 
