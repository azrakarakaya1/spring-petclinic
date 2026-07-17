#!/bin/bash

minikube start -p petclinic --driver=docker

status=$(kubectl get nodes | grep petclinic | awk '{print $2}')

if [[ $status != "Ready" ]]
then
    echo "fail to start cluster"
    exit 1
fi
