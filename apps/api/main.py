import os
import time

import psycopg2
from fastapi import FastAPI, Request, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

app = FastAPI(title="DevOps Assignment API")

REQUESTS = Counter("api_requests_total", "Total API requests", ["path", "status"])
LATENCY = Histogram("api_request_duration_seconds", "API request duration", ["path"])


def database_url() -> str:
    return os.getenv(
        "DATABASE_URL",
        "postgresql://app:app_password@postgres:5432/appdb",
    )


def db_ping() -> bool:
    try:
        with psycopg2.connect(database_url(), connect_timeout=3) as conn:
            with conn.cursor() as cur:
                cur.execute("select 1")
                return cur.fetchone()[0] == 1
    except Exception:
        return False


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
def ready(response: Response):
    if not db_ping():
        response.status_code = 503
        return {"status": "not_ready", "database": "unreachable"}
    return {"status": "ready", "database": "ok"}


@app.get("/api/message")
def message():
    path = "/api/message"
    start = time.time()
    try:
        return {"message": "Cloud-native platform is running", "database": db_ping()}
    finally:
        LATENCY.labels(path).observe(time.time() - start)


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.middleware("http")
async def record_request_metrics(request: Request, call_next):
    response = await call_next(request)
    REQUESTS.labels(request.url.path, str(response.status_code)).inc()
    return response
