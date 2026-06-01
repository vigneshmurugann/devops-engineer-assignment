#!/usr/bin/env bash
set -euo pipefail

helm repo add jenkins https://charts.jenkins.io
helm repo update

helm upgrade --install jenkins jenkins/jenkins \
  --namespace jenkins --create-namespace \
  --values jenkins/values.yaml \
  --wait

kubectl -n jenkins get pods,svc
