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