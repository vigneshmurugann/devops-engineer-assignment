#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="environments/local/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  ENV_FILE="environments/local/.env.example"
fi

COMPOSE=(docker compose --env-file "$ENV_FILE" --profile core --profile app --profile monitoring)

case "${1:-}" in
  start)
    "${COMPOSE[@]}" up -d --build
    ;;
  stop)
    "${COMPOSE[@]}" down
    ;;
  restart)
    "${COMPOSE[@]}" down
    "${COMPOSE[@]}" up -d --build
    ;;
  status)
    "${COMPOSE[@]}" ps
    ;;
  *)
    echo "Usage: ./deploy.sh {start|stop|restart|status}"
    exit 1
    ;;
esac
