# DevOps Workflow Implementation for the Spring PetClinic App

This repository is based on the official Spring PetClinic sample application.

Original repository: https://github.com/spring-projects/spring-petclinic


- Definition & why did I choose this app among other options



- How to run the app?

1. Docker Compose
2. Kubernetes

Methodology: Run the app with docker compose first without any k8s requirements and write k8s manifests that does the same in a minikube cluster.



- Explain what is done for each step

Dockerize the app:
* Dockerfile
* docker-compose.yml
* Makefile
* build.sh (local)

Setup a minikube cluster:
* cluster_setup.sh


- Evaluate its usability for production environments
- Evaluate if the provided scripts are shell compatible
- State limitations


# References

Dockerfile multi-staging reference: https://medium.com/@cat.edelveis/a-guide-to-docker-multi-stage-builds-for-spring-boot-08e3a64c9812

Cluster setup instructions: https://kubernetes.io/docs/tutorials/kubernetes-basics/create-cluster/cluster-intro/ 

Using Docker Desktop as driver: https://minikube.sigs.k8s.io/docs/drivers/docker/

Learning K8s objects:

