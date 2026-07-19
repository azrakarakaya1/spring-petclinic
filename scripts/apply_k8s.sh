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
