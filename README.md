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
- Helm


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
127.0.0.1  petclinic.local
```
Add this line into /etc/hosts to direct requests to localhost

```
minikube tunnel -p petclinic
````


### 3. Helm


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
<summary>apply_k8s.sh</summary>
```
#!/bin/bash

clean=$1

if [[ $clean == "clean" ]]
then
    kubectl delete deployment petclinic-deployment
    kubectl delete statefulset postgres-db
    kubectl delete service petclinic-service
    kubectl delete service postgres-service
    exit 0
fi

if [[ $clean == "clean-pvc" ]]
then
    kubectl delete pvc petclinic-data-postgres-db-0
    exit 0
fi

# database
kubectl apply -f k8s/postgres_statefulset.yaml
kubectl apply -f k8s/postgres_service.yaml

# backend
kubectl apply -f k8s/petclinic_deployment.yaml
kubectl apply -f k8s/petclinic_service.yaml

kubectl wait --for=condition=ready pod --all

# port forward to make the app accessible at http://localhost:8080
#kubectl port-forward service/petclinic-service 8080:8080

# ingress instead of port forwarding
minikube addons enable ingress -p petclinic
kubectl apply -f k8s/nginx_ingress.yaml

#minikube service petclinic-service -p petclinic --url

minikube tunnel -p petclinic
```
</details>

K8s manifests at early stages:

- petclinic_deployment.yaml
- petclinic_service.yaml
- postgres_deployment.yaml
- postgres_service.yaml
- postgres_pvc.yaml

At the beginning I used deployments for both the backend and the database services, and port forwarding for external connections to the cluster.

**Updates:** 

**Ingress Host:** I replaced kubectl port-forward with NGINX Ingress Controller using the petclinic.local alias.
**StatefulSet for Db:** I converted the PostgreSQL database from a Deployment to a StatefulSet to have closer approach to production environments.

The apply_k8s.sh script was updated accordingly.


#### Helm 

To learn helm and practise templating, a helm chart for petclinic sevice was created manually and the Bitnami PostgreSQL chart for database service is integrated.

I used `helm create petclinic-chart` command to create a template for backend. First, I copied my existing service, deployment, and ingress manifests to the templates/ folder inside petclinic-chart. Then, I removed extra files and turned my manifests into templates by moving values of the key-value pairs to values.yaml. I also deleted all unused fields from values.yaml and updated Chart.yaml.

For the database, **helm.sh** script located in the scripts/ folder is used to install the database and install/update the petclinic-chart.

<details>
<summary>See helm.sh</summary>
```
#!/bin/bash

clean=$1

if [[ $clean == "clean" ]]
then
    helm uninstall petclinic-release
    helm uninstall postgresql
    exit 0
fi

if [[ $clean == "clean-pvc" ]]
then
    kubectl delete pvc data-postgresql-0
    exit 0
fi

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

#helm pull bitnami/postgresql --untar

helm install postgresql bitnami/postgresql \
  --set auth.database=petclinic \
  --set auth.username=petclinic \
  --set auth.password=petclinic \
  --set primary.persistence.size=1Gi

helm install petclinic-release petclinic-chart/
#helm upgrade petclinic-release petclinic-chart/

kubectl wait --for=condition=ready pod --all --timeout=180s

#minikube addons enable ingress
#minikube tunnel
```
</details>



### Step 5: CI Pipeline







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
	./scripts/apply_k8s.sh
clean-manifests:
	./scripts/apply_k8s.sh clean
clean-pvc:
	./scripts/apply_k8s.sh clean-pvc
cluster-stop: clean-manifests
	minikube stop -p petclinic
cluster-status:
	minikube status -p petclinic

# helm
helm-install:
	./scripts/helm.sh
helm-upgrade-petclinic:
	helm upgrade petclinic-release petclinic-chart
helm-clean:
	./scripts/helm.sh clean
helm-clean-pvc:
	./scripts/helm.sh clean-pvc

.PHONY: up down restart \
		cluster-start apply-manifests clean-manifests cluster-stop clean-pvc cluster-status \
		helm-install helm-upgrade-petclinic helm-clean helm-clean-pvc
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

Helm commands:



---

## Insights

- Explain 3 different images builded with 3 different base images and why did I choose bellsoft and how multistaging, compiling while building image or inside the container.
- Add how to make docker the main driver
- ClusterIP service type and port forwarding method
- Ingress controller instead of port forward and Ingress host with minikube
- PersistentVolumeClaim (PVC) in K8s
- Evaluate if the provided scripts are shell compatible
- State limitations (like docker compose healthcheck can be added)
- For now, I use local volumes but in a production environment volumes should always be remote so 1 possible improvement is connecting to a neon postgres db
- Changing service type to nodeport for external communication
- Database can be deployed via Statefulset instead of a Deployment
- healthcheck
- rollout status vs wait

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
  - https://last9.io/blog/docker-compose-health-checks/

- Cluster setup:
  - https://kubernetes.io/docs/tutorials/kubernetes-basics/create-cluster/cluster-intro/
  - https://minikube.sigs.k8s.io/docs/drivers/docker/

- Learning K8s objects:
  - https://github.com/kubernetes/kubectl/issues/1120
  - K8s rolling update deployment: https://octopus.com/devops/kubernetes-deployments/kubernetes-rolling-deployment/
  - Port forwarding: https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/
  - Using env variables in K8s manifests: https://www.mirantis.com/blog/cloud-native-5-minutes-at-a-time-using-kubernetes-secrets-with-environment-variables-and-volume-mounts/
  - Persistent storage in K8s: https://www.mirantis.com/blog/persistent-data-and-storage-with-kubernetes/

- Ingress:
  - https://v1-33.docs.kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/
  - https://medium.com/@jadhav.swatissj99/ingress-controller-in-kubernetes-a-detailed-explanation-7dca42999df4
  - https://medium.com/@chandan.chanddu/routing-strategies-in-kubernetes-host-based-and-path-based-routing-with-nginx-ingress-controller-28a35859b508
  - https://medium.com/@saurabh_adhau/unlocking-the-magic-setting-up-ingress-on-minikube-with-nginx-ingress-controller-520ce1c3c3bc

- Helm:
  - https://www.ibm.com/think/insights/kustomize-vs-helm
  - https://medium.com/@mahernaija/deploy-postgresql-on-kubernetes-using-helm-the-easy-way-f7f50f612509
  - https://dev.to/alexmercedcoder/using-helm-with-kubernetes-a-guide-to-helm-charts-and-their-implementation-8dg
  - https://glasskube.dev/blog/what-is-helm-in-kubernetes/

- GitHub Actions:
  - https://github.com/actions/setup-java
  - https://github.com/marketplace/actions/helm-chart-repo-ghcr-io
  - https://dev.to/hkhelil/ensuring-effective-helm-charts-with-linting-testing-and-diff-checks-ni0
  - https://helm.sh/docs/helm/helm_registry_login/
  - https://github.com/orgs/community/discussions/57724 
  - https://docs.github.com/en/packages/learn-github-packages/introduction-to-github-packages
  - https://medium.com/@chandika.s/github-actions-essentials-understanding-github-runners-in-github-actions-0102aefd73b1
  - https://maven.apache.org/surefire/maven-surefire-plugin/examples/single-test.html 

  