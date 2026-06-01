#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-devops-assignment}"
DOCKERHUB_USER="${DOCKERHUB_USER:-your-dockerhub-user}"

if ! kind get clusters | grep -qx "$CLUSTER_NAME"; then
  kind create cluster --name "$CLUSTER_NAME" --config kind-config.yaml
fi

kubectl config use-context "kind-$CLUSTER_NAME"

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --values helm/charts/ingress-nginx/values.yaml \
  --wait

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --values helm/charts/kube-prometheus-stack/values.yaml \
  --wait

helm upgrade --install loki grafana/loki \
  --namespace monitoring --create-namespace \
  --values helm/charts/loki/values.yaml \
  --wait

helm upgrade --install promtail grafana/promtail \
  --namespace monitoring --create-namespace \
  --values helm/charts/promtail/values.yaml \
  --wait

kubectl apply -f monitoring/datasources/k8s-datasources-configmap.yaml
kubectl apply -f monitoring/dashboards/k8s-dashboard-configmap.yaml
kubectl apply -f monitoring/alerts/application-rules.yaml

docker build -t "docker.io/${DOCKERHUB_USER}/devops-api:dev" apps/api
docker build -t "docker.io/${DOCKERHUB_USER}/devops-web:dev" apps/web
kind load docker-image "docker.io/${DOCKERHUB_USER}/devops-api:dev" --name "$CLUSTER_NAME"
kind load docker-image "docker.io/${DOCKERHUB_USER}/devops-web:dev" --name "$CLUSTER_NAME"

kubectl apply -k k8s/overlays/dev
kubectl -n devops-app set image deployment/api api="docker.io/${DOCKERHUB_USER}/devops-api:dev"
kubectl -n devops-app set image deployment/web web="docker.io/${DOCKERHUB_USER}/devops-web:dev"
kubectl -n devops-app rollout status deploy/postgres --timeout=180s
kubectl -n devops-app rollout status deploy/api --timeout=180s
kubectl -n devops-app rollout status deploy/web --timeout=180s

kubectl -n devops-app get pods,svc,ingress
