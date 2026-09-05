from starlette.testclient import TestClient

from app.main import app

client = TestClient(app, headers={"Authorization": "Bearer test-token"})


def test_health_returns_ok():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_job_routes_require_bearer_auth():
    response = TestClient(app).get("/jobs/missing")
    assert response.status_code == 401
