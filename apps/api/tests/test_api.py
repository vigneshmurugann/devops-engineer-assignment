from fastapi.testclient import TestClient

from main import app


def test_health():
    client = TestClient(app)
    assert client.get("/health").json() == {"status": "ok"}


def test_message():
    client = TestClient(app)
    response = client.get("/api/message")
    assert response.status_code == 200
    assert "message" in response.json()
