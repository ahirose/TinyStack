import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

ROOT = Path(__file__).resolve().parents[1]
API_DIR = ROOT / "services" / "api"


@pytest.fixture
def client(tmp_path, monkeypatch):
    data_dir = tmp_path / "data"
    monkeypatch.setenv("TINYSTACK_DATA_DIR", str(data_dir))
    sys.path.insert(0, str(API_DIR))

    for name in list(sys.modules):
        if name in ("main", "config") or name.startswith("services") or name.startswith("routes"):
            del sys.modules[name]

    import config

    config.DATA_DIR = data_dir

    import services.db_service as db_mod

    db_mod.db_service = db_mod.DBService(data_dir)
    db_mod.db_service.ensure_bootstrap()

    import services.trace_service as trace_mod

    trace_mod.trace_service = trace_mod.TraceService()

    from main import app

    with TestClient(app) as c:
        yield c


def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json()["status"] == "ok"


def test_sql_execute_select(client):
    res = client.post("/api/sql/execute", json={"sql": "SELECT * FROM users;"})
    assert res.status_code == 200
    body = res.json()
    assert body["error"] is None
    assert body["ast"]["type"] == "select"
    assert len(body["result"]["rows"]) >= 1


def test_schema(client):
    res = client.get("/api/sql/schema")
    assert res.status_code == 200
    tables = {t["name"] for t in res.json()["tables"]}
    assert "users" in tables


def test_nl_to_sql(client):
    res = client.post("/api/ai/nl-to-sql", json={"query": "Show all users"})
    assert res.status_code == 200
    body = res.json()
    assert "SELECT" in body["sql"].upper()
    assert body["prompt"]


def test_similar_queries(client):
    res = client.get("/api/meta/similar-queries?q=users")
    assert res.status_code == 200
    assert "results" in res.json()
