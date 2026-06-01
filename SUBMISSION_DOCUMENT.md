# DevOps Engineer Assignment - Submission and Implementation Guide

## 1. Objective

This project implements a complete Linux-based DevOps assignment environment using WSL/Ubuntu. It includes a sample web application, backend API, database, containerization, Kubernetes deployment, CI/CD setup, security checks, and monitoring.

The implementation was completed inside WSL using Linux Docker Engine, not Docker Desktop for Windows.

## 2. How to Use This Document

This document is written so that a fresher can reproduce and demo the project from scratch.

Use it in this order:

1. Complete the fresh Linux/WSL setup in section 6.
2. Run the Docker Compose demo in section 8.
3. Run the Kubernetes/Kind demo in section 9.
4. Install and access Jenkins in section 10.
5. Access Grafana, Prometheus, Loki, and Promtail in section 11.
6. Use the demo flow and screenshot checklist near the end for interview submission.

Do not share any personal sudo password in the submitted document or interview notes.

## 3. Technology Stack

| Area | Tooling |
| --- | --- |
| Frontend | Static HTML/CSS/JavaScript served by Nginx |
| Backend | Python FastAPI |
| Database | PostgreSQL 16 |
| Local containers | Docker Engine and Docker Compose |
| Kubernetes | Kind single-node Kubernetes cluster |
| Kubernetes configuration | Kustomize |
| Infrastructure charts | Helm |
| CI/CD | Jenkins on Kubernetes |
| Security scanning | Trivy |
| Monitoring | Prometheus, Grafana |
| Logging | Loki, Promtail |

## 4. What Was Built

The repository contains:

- A FastAPI backend with `/health`, `/ready`, and `/metrics` endpoints.
- A static Nginx frontend.
- PostgreSQL database connectivity from the API.
- Dockerfiles for API and web containers.
- Docker Compose setup for local demo.
- Kubernetes manifests for API, web, Postgres, services, ingress, probes, resources, and network policies.
- Helm values for ingress-nginx, kube-prometheus-stack, Loki, and Promtail.
- Jenkins Helm installation values.
- Jenkins pipeline definition in `Jenkinsfile`.
- Prometheus alert rules.
- Grafana dashboard and datasource provisioning.
- Helper scripts for install, bootstrap, validation, and deployment.

## 5. Repository Structure

```text
apps/
  api/                  FastAPI backend
  web/                  Static frontend served by Nginx
docs/
  architecture.md       Architecture notes
helm/
  charts/               Helm values for platform services
jenkins/
  values.yaml           Jenkins Helm values
k8s/
  base/                 Base Kubernetes manifests
  overlays/dev/         Development overlay
monitoring/
  alerts/               Prometheus alert rules
  dashboards/           Grafana dashboard provisioning
  datasources/          Grafana datasource provisioning
scripts/
  bootstrap-kind.sh     Creates Kind cluster and deploys platform/app
  demo-check.sh         Validates local tools and tests
  install-docker-wsl.sh Installs Docker Engine in WSL
  install-jenkins.sh    Installs Jenkins in Kubernetes
deploy.sh              Docker Compose helper
docker-compose.yml     Local Compose stack
Jenkinsfile            CI/CD pipeline
README.md              Main usage guide
```

## 6. Fresh Setup from Zero on WSL/Linux

This section explains how a new person can set up and run the entire project.

### 6.0 System prerequisites

Use a Windows machine with WSL2 and Ubuntu, or use a native Linux machine.

If WSL is not installed on Windows, open PowerShell as Administrator and run:

```powershell
wsl --install -d Ubuntu
```

Restart the machine if Windows asks for it, then open Ubuntu from the Start menu.

If the repository is not already available locally, clone or copy it first:

```bash
git clone <repository-url>
cd <repository-folder>
```

If the repository was provided as a ZIP file, extract it and `cd` into the extracted folder.

### 6.1 Open WSL Ubuntu

Open Ubuntu/WSL terminal from Windows.

Confirm Linux is running:

```bash
uname -a
```

Expected result: output should mention `Linux`.

### 6.2 Go to the project directory

Use the actual project path where the repository exists. Replace `<project-directory>` with the path where the repository is available.

```bash
cd <project-directory>
```

Confirm files are present:

```bash
ls
```

Expected result: files/folders such as `apps`, `k8s`, `helm`, `monitoring`, `docker-compose.yml`, `deploy.sh`, and `Jenkinsfile`.

### 6.3 Install Docker Engine in WSL

Run:

```bash
bash scripts/install-docker-wsl.sh
```

This installs Linux Docker Engine and Docker Compose inside WSL.

Start Docker:

```bash
sudo service docker start
```

Check Docker:

```bash
docker version
docker compose version
```

Expected result: both commands should print version information.

If Docker says permission denied on `/var/run/docker.sock`, either restart WSL or run this temporary command for the current demo session:

```bash
sudo chmod 666 /var/run/docker.sock
```

### 6.4 Install or load local CLI tools

The required CLI tools are installed under `/tmp/aswin-devops-tools/bin`.

Load them in every new WSL terminal:

```bash
source scripts/use-local-tools.sh
```

Check versions:

```bash
kubectl version --client=true
kind version
helm version --short
kustomize version
trivy --version
```

Expected result: all commands should print versions.

### 6.5 Create local environment file

```bash
cp -n environments/local/.env.example environments/local/.env
```

This creates the local environment file used by Docker Compose.

### 6.6 Run pre-demo validation

```bash
bash scripts/demo-check.sh
```

Expected result:

```text
2 passed
Demo prerequisites look good.
```

If this passes, the project is ready for Docker Compose and Kubernetes demo.

## 7. Installed Tools in WSL

The following Linux tools were installed and used:

```text
Docker Engine: 29.5.2
Docker Compose: v5.1.4
kubectl: v1.36.1
Kind: v0.31.0
Helm: v3.21.0
Kustomize: v5.8.1
Trivy: 0.71.0
Python: 3.12
```

The local CLI tools are available through:

```bash
source scripts/use-local-tools.sh
```

## 8. Local Docker Compose Demo

### Start the local stack

```bash
cp -n environments/local/.env.example environments/local/.env
./deploy.sh start
```

### Check service status

```bash
./deploy.sh status
```

Expected result: API, web, Postgres, Prometheus, Grafana, and Loki should be running. API, web, Postgres, Prometheus, Grafana, and Loki should show healthy status.

### Local demo URLs

| Service | URL | Credentials |
| --- | --- | --- |
| Web app | http://localhost:8080 | None |
| API health | http://localhost:8000/health | None |
| API readiness | http://localhost:8000/ready | None |
| API metrics | http://localhost:8000/metrics | None |
| Prometheus | http://localhost:9090 | None |
| Grafana | http://localhost:3000 | `admin/admin` |
| Loki readiness | http://localhost:3100/ready | None |

### Validate local setup

```bash
bash scripts/demo-check.sh
```

Expected result:

```text
2 passed
Demo prerequisites look good.
```

## 9. Kubernetes Demo on Kind

### Bootstrap the cluster

```bash
source scripts/use-local-tools.sh
export DOCKERHUB_USER=<your-dockerhub-username>
./scripts/bootstrap-kind.sh
```

If a different person is reproducing the project, use their Docker Hub username or any local image namespace consistently. If the image namespace is changed permanently, update `k8s/overlays/dev/kustomization.yaml` to match.

The bootstrap script performs these actions:

1. Creates a Kind cluster named `devops-assignment`.
2. Installs ingress-nginx using Helm.
3. Installs kube-prometheus-stack using Helm.
4. Installs Loki using Helm.
5. Installs Promtail using Helm.
6. Applies Grafana datasources, dashboards, and Prometheus rules.
7. Builds API and web Docker images locally.
8. Loads those images into the Kind cluster.
9. Applies Kubernetes manifests using Kustomize.
10. Waits for Postgres, API, and web rollouts.

### Access the Kubernetes cluster

Use this in every new terminal before running Kubernetes commands:

```bash
cd <project-directory>
source scripts/use-local-tools.sh
kubectl config use-context kind-devops-assignment
```

Check current context:

```bash
kubectl config current-context
```

Expected result:

```text
kind-devops-assignment
```

### Verify cluster

```bash
kubectl get nodes
kubectl get namespaces
kubectl -n devops-app get deploy,pods,svc,ingress -o wide
kubectl -n monitoring get pods
```

Expected result:

```text
Node: Ready
api deployment: 2/2
web deployment: 2/2
postgres deployment: 1/1
monitoring pods: Running
```

Useful namespace commands:

```bash
kubectl -n devops-app get pods
kubectl -n devops-app describe pod <pod-name>
kubectl -n devops-app logs deploy/api
kubectl -n devops-app logs deploy/web
kubectl -n devops-app logs deploy/postgres
```

### Kubernetes app URL

The ingress is configured to work directly from:

```text
http://localhost/
```

It also supports:

```text
http://devops.local/
```

For `devops.local`, add this host entry if needed:

```text
127.0.0.1 devops.local
```

### API readiness inside Kubernetes

```bash
kubectl -n devops-app exec deploy/api -- python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:8000/ready').read().decode())"
```

Expected result:

```json
{"status":"ready","database":"ok"}
```

## 10. Jenkins CI/CD

### Install Jenkins

```bash
source scripts/use-local-tools.sh
./scripts/install-jenkins.sh
```

### Verify Jenkins

```bash
kubectl -n jenkins get pods,svc -o wide
```

Expected result:

```text
jenkins-0   2/2   Running
```

### Access Jenkins

Port-forward Jenkins:

```bash
kubectl -n jenkins port-forward --address 0.0.0.0 svc/jenkins 8081:8080
```

Open:

```text
http://localhost:8081
```

Credentials:

```text
Username: admin
Password: admin
```

### Jenkins pipeline stages

The `Jenkinsfile` includes these stages:

1. Checkout
2. Lint
3. Unit tests
4. Docker build
5. Trivy security scan
6. Docker push
7. Kubernetes deploy
8. Post-deployment validation

For a real Docker Hub push, configure these Jenkins credentials:

```text
dockerhub-username
dockerhub-token
```

## 11. Monitoring and Logging

### Kubernetes Grafana

Port-forward:

```bash
kubectl -n monitoring port-forward --address 0.0.0.0 svc/kube-prometheus-stack-grafana 3001:80
```

Open:

```text
http://localhost:3001
```

Credentials:

```text
Username: admin
Password: admin
```

### Kubernetes Prometheus

Port-forward:

```bash
kubectl -n monitoring port-forward --address 0.0.0.0 svc/kube-prometheus-stack-prometheus 9091:9090
```

Open:

```text
http://localhost:9091
```

### Loki and Promtail

Loki and Promtail are installed in the `monitoring` namespace.

```bash
kubectl -n monitoring get pods
```

Expected result: `loki`, `loki-canary`, and `promtail` pods should be running.

## 12. End-to-End Demo Startup Commands

If the machine is already prepared and you only need to start the demo, run these commands in order.

### Terminal 1: start Docker and Compose

```bash
cd <project-directory>
sudo service docker start
source scripts/use-local-tools.sh
./deploy.sh restart
./deploy.sh status
```

### Terminal 2: verify or start Kubernetes

```bash
cd <project-directory>
source scripts/use-local-tools.sh
kubectl config use-context kind-devops-assignment
kubectl get nodes
kubectl -n devops-app get deploy,pods,svc,ingress -o wide
```

If the Kind cluster does not exist, create it:

```bash
source scripts/use-local-tools.sh
export DOCKERHUB_USER=<your-dockerhub-username>
./scripts/bootstrap-kind.sh
```

### Terminal 3: start demo port-forwards

Run these commands and keep the terminal open:

```bash
source scripts/use-local-tools.sh
kubectl -n jenkins port-forward --address 0.0.0.0 svc/jenkins 8081:8080
```

In another terminal for Grafana:

```bash
source scripts/use-local-tools.sh
kubectl -n monitoring port-forward --address 0.0.0.0 svc/kube-prometheus-stack-grafana 3001:80
```

In another terminal for Prometheus:

```bash
source scripts/use-local-tools.sh
kubectl -n monitoring port-forward --address 0.0.0.0 svc/kube-prometheus-stack-prometheus 9091:9090
```

### Browser URLs for demo

| Purpose | URL | Credentials |
| --- | --- | --- |
| Docker Compose app | http://localhost:8080 | None |
| Docker Compose API readiness | http://localhost:8000/ready | None |
| Docker Compose Grafana | http://localhost:3000 | `admin/admin` |
| Docker Compose Prometheus | http://localhost:9090 | None |
| Kubernetes app | http://localhost/ | None |
| Kubernetes Jenkins | http://localhost:8081 | `admin/admin` |
| Kubernetes Grafana | http://localhost:3001 | `admin/admin` |
| Kubernetes Prometheus | http://localhost:9091 | None |

## 13. Security Controls Implemented

The project includes these security and reliability controls:

- API and web containers run as non-root numeric user `10001`.
- Kubernetes readiness and liveness probes are configured.
- Resource requests and limits are configured.
- Default deny network policy is enabled.
- Explicit network policies allow only required traffic.
- Trivy image scanning is included in CI/CD.
- Secrets are separated into Kubernetes Secret manifests.
- Application metrics are exposed for Prometheus.

Note: PostgreSQL uses the official image entrypoint, so its Kubernetes security context was adjusted to allow proper database volume initialization in Kind.

## 14. Rollback Procedure

Rollback API:

```bash
kubectl -n devops-app rollout undo deployment/api
kubectl -n devops-app rollout status deployment/api
```

Rollback web:

```bash
kubectl -n devops-app rollout undo deployment/web
kubectl -n devops-app rollout status deployment/web
```

## 15. Alert Demonstration

To demonstrate an application availability alert:

```bash
kubectl -n devops-app scale deployment/api --replicas=0
```

Then check Prometheus/Grafana for the `ApplicationUnavailable` alert.

Restore the API:

```bash
kubectl -n devops-app scale deployment/api --replicas=2
kubectl -n devops-app rollout status deployment/api
```

## 16. Troubleshooting Guide

### Docker is not running

Symptom:

```text
Cannot connect to the Docker daemon
```

Fix:

```bash
sudo service docker start
docker ps
```

### Docker permission denied

Symptom:

```text
permission denied while trying to connect to the Docker daemon socket
```

Fix for current session:

```bash
sudo chmod 666 /var/run/docker.sock
```

Permanent fix is to ensure the user is in the `docker` group and restart WSL.

### kubectl command not found

Fix:

```bash
cd <project-directory>
source scripts/use-local-tools.sh
kubectl version --client=true
```

### Wrong Kubernetes context

Fix:

```bash
kubectl config get-contexts
kubectl config use-context kind-devops-assignment
kubectl get nodes
```

### App URL `http://localhost/` does not open

Check ingress controller:

```bash
kubectl -n ingress-nginx get pods,svc -o wide
```

Check app pods:

```bash
kubectl -n devops-app get pods
```

Reapply the app manifests:

```bash
kubectl apply -k k8s/overlays/dev
kubectl -n devops-app rollout status deploy/api
kubectl -n devops-app rollout status deploy/web
```

### Jenkins/Grafana/Prometheus URL does not open

Port-forward again:

```bash
kubectl -n jenkins port-forward --address 0.0.0.0 svc/jenkins 8081:8080
kubectl -n monitoring port-forward --address 0.0.0.0 svc/kube-prometheus-stack-grafana 3001:80
kubectl -n monitoring port-forward --address 0.0.0.0 svc/kube-prometheus-stack-prometheus 9091:9090
```

### Pods are not ready

Check events and logs:

```bash
kubectl -n devops-app get events --sort-by=.lastTimestamp
kubectl -n devops-app logs deploy/api
kubectl -n devops-app logs deploy/web
kubectl -n devops-app logs deploy/postgres
```

## 17. Commands Used for Final Verification

```bash
./deploy.sh status
bash scripts/demo-check.sh
kubectl get nodes
kubectl -n devops-app get deploy,pods,svc,ingress -o wide
kubectl -n monitoring get pods
kubectl -n jenkins get pods,svc -o wide
curl -fsS http://127.0.0.1:8000/ready
curl -fsS http://127.0.0.1:8080/
curl -fsS http://127.0.0.1/
curl -fsS http://127.0.0.1:3001/api/health
curl -fsS http://127.0.0.1:9091/-/healthy
curl -fsS -I http://127.0.0.1:8081/login
```

Final verification results:

```text
Docker Compose stack: Running
API readiness: {"status":"ready","database":"ok"}
Kubernetes node: Ready
Kubernetes API deployment: 2/2
Kubernetes web deployment: 2/2
Kubernetes Postgres deployment: 1/1
Monitoring stack: Running
Jenkins: Running
Unit tests: 2 passed
```

## 18. Demo Flow for Interview

Use this order during the demo:

1. Show the repository structure.
2. Open `README.md` and this submission document.
3. Run `./deploy.sh status` to show the local Docker Compose stack.
4. Open `http://localhost:8080` for the local web app.
5. Open `http://localhost:8000/ready` for API/database readiness.
6. Run `kubectl get nodes` to show the Kind cluster.
7. Run `kubectl -n devops-app get deploy,pods,svc,ingress -o wide`.
8. Open `http://localhost/` to show the Kubernetes ingress app.
9. Open Jenkins at `http://localhost:8081`.
10. Open Grafana at `http://localhost:3001`.
11. Open Prometheus at `http://localhost:9091`.
12. Explain the `Jenkinsfile`, Kubernetes manifests, network policies, monitoring, and rollback command.

## 19. Screenshot Checklist

Capture these screenshots before submission or during the demo:

1. Repository structure showing `apps`, `k8s`, `helm`, `monitoring`, `Jenkinsfile`, and `docker-compose.yml`.
2. Docker Compose status from `./deploy.sh status`.
3. Local web app at `http://localhost:8080`.
4. API readiness response at `http://localhost:8000/ready`.
5. Kubernetes deployments from `kubectl -n devops-app get deploy,pods,svc,ingress -o wide`.
6. Kubernetes app at `http://localhost/`.
7. Jenkins running at `http://localhost:8081`.
8. Grafana dashboard at `http://localhost:3001`.
9. Prometheus targets or alerts at `http://localhost:9091`.
10. Output from `bash scripts/demo-check.sh`.

## 20. Stop and Restart Commands

Stop Docker Compose:

```bash
./deploy.sh stop
```

Restart Docker Compose:

```bash
./deploy.sh restart
```

Stop demo port-forwards if they were started in the background:

```bash
kill $(cat /tmp/aswin-jenkins-portforward.pid /tmp/aswin-grafana-portforward.pid /tmp/aswin-prometheus-portforward.pid)
```

Delete the Kind cluster only when the demo is completely finished:

```bash
kind delete cluster --name devops-assignment
```

## 21. Notes for Reviewer

- The entire implementation was done with Linux tooling inside WSL.
- Docker Desktop for Windows is not required.
- Kind runs Kubernetes using the Linux Docker Engine in WSL.
- Local images are built and loaded into Kind for the demo.
- Jenkins is installed in the Kind cluster and is ready for pipeline configuration.
- The project is suitable for live demonstration using local URLs.
