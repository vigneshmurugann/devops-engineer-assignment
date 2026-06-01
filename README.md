# DevOps Engineer Take-Home Assignment

This repository implements the required assignment scope: a small cloud-native platform with a frontend, backend API, PostgreSQL, Docker Compose, Kind/Kubernetes, Jenkins CI/CD, Helm-managed infrastructure, Kustomize application configuration, network policies, security scanning, and observability.

For the interviewer-facing submission document and demo runbook, see [`SUBMISSION_DOCUMENT.md`](SUBMISSION_DOCUMENT.md).

## Prerequisites

- Docker Desktop or Docker Engine
- kubectl
- Kind v0.22+
- Helm v3.13+
- Kustomize v5+
- Jenkins
- Trivy
- Git
- Python 3.12 for local API tests

This workspace includes locally installed Linux CLI tools under `/tmp/aswin-devops-tools/bin`.
Load them in each new WSL terminal:

```bash
source scripts/use-local-tools.sh
```

## Local Docker Compose

```bash
cp environments/local/.env.example environments/local/.env
./deploy.sh start
./deploy.sh status
```

Local endpoints:

- Web: http://localhost:8080
- API health: http://localhost:8000/health
- API metrics: http://localhost:8000/metrics
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000, admin/admin
- Loki: http://localhost:3100/ready

Stop or restart:

```bash
./deploy.sh stop
./deploy.sh restart
```

## Kubernetes on Kind

Set your Docker Hub username before bootstrapping:

```bash
export DOCKERHUB_USER=your-dockerhub-user
./scripts/bootstrap-kind.sh
```

The bootstrap script:

1. Creates a single-node Kind cluster from `kind-config.yaml`.
2. Installs ingress-nginx, kube-prometheus-stack, Loki, and Promtail using Helm.
3. Builds API and web images locally.
4. Loads images into Kind.
5. Applies `kubectl apply -k k8s/overlays/dev`.
6. Provisions Grafana dashboards, datasources, and Prometheus alert rules.
7. Validates rollouts.

Add this host entry for browser testing:

```text
127.0.0.1 devops.local
```

Then open http://devops.local.

You can also deploy only the application manifests:

```bash
kubectl apply -k k8s/overlays/dev
```

## Jenkins CI/CD

Install Jenkins into the Kind cluster:

```bash
./scripts/install-jenkins.sh
kubectl -n jenkins port-forward svc/jenkins 8081:8080
```

Open http://localhost:8081. The demo credentials from `jenkins/values.yaml` are `admin/admin`.

Create these Jenkins credentials:

- `dockerhub-username`: Docker Hub username as secret text.
- `dockerhub-token`: Docker Hub access token as secret text.

The `Jenkinsfile` stages are:

1. Checkout source
2. Lint
3. Unit tests
4. Docker build
5. Trivy security scan
6. Push image
7. Deploy to Kubernetes
8. Post-deployment validation

Rollback:

```bash
kubectl -n devops-app rollout undo deployment/api
kubectl -n devops-app rollout undo deployment/web
kubectl -n devops-app rollout status deployment/api
kubectl -n devops-app rollout status deployment/web
```

To demonstrate a failed security scan, temporarily build from a deliberately vulnerable base image in a feature branch and run the pipeline. Revert the base image and rerun to show successful redeployment.

## Observability

The monitoring stack includes Prometheus, Grafana, Loki, and Promtail.

Port-forward Grafana:

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

Open http://localhost:3000 with `admin/admin`.

Provisioned assets:

- `monitoring/dashboards`: Grafana dashboard for CPU, memory, pod restarts, availability, response time, and logs.
- `monitoring/datasources`: Prometheus and Loki datasources.
- `monitoring/alerts/application-rules.yaml`: alerts for high CPU, high memory, pod failures, app unavailable, and excessive error rates.

To demonstrate an alert firing:

```bash
kubectl -n devops-app scale deployment/api --replicas=0
```

Wait for the `ApplicationUnavailable` alert, capture the screenshot, then restore:

```bash
kubectl -n devops-app scale deployment/api --replicas=2
```

## Security Controls

- Containers run as non-root.
- Privilege escalation is disabled.
- Linux capabilities are dropped.
- Resource requests and limits are set.
- Readiness and liveness probes are configured.
- Default deny ingress and egress network policies are enabled.
- Trivy blocks critical image vulnerabilities in CI.

## Submission Checklist

- GitHub repository
- README with reproducible setup
- Architecture diagram: `docs/architecture.md`
- Screenshots:
  - Jenkins pipeline
  - Kubernetes workloads
  - Grafana dashboard
  - Alert firing
- Walkthrough/demo session
