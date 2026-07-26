#!/bin/bash

helm package petclinic-chart
helm push petclinic-chart-*.tgz oci://ghcr.io/azrakarakaya1/charts