#!/bin/bash

version=$1

docker build -t azrakarakaya/spring-petclinic-app:$version .
docker push azrakarakaya/spring-petclinic-app:$version