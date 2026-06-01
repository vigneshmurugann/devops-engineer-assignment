#!/usr/bin/env bash
set -euo pipefail

source scripts/use-local-tools.sh

echo "== Tool versions =="
docker version --format 'Docker {{.Server.Version}}'
docker compose version
kubectl version --client=true
kind version
helm version --short
kustomize version
trivy --version

echo
echo "== Static checks =="
bash -n deploy.sh scripts/bootstrap-kind.sh scripts/install-jenkins.sh scripts/install-docker-wsl.sh
python3 -m py_compile apps/api/main.py apps/api/tests/test_api.py
kustomize build k8s/overlays/dev >/tmp/devops-assignment-rendered.yaml
(
  cd apps/api
  python3 -m pytest
)

echo
echo "Demo prerequisites look good."
