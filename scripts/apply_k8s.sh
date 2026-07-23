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