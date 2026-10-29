import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from smes.api import get_session
from smes.main import app
from smes.models import Base
from smes.seed import seed


@pytest.fixture
def client():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    factory = sessionmaker(bind=engine, autoflush=True, expire_on_commit=False)

    def override():
        db = factory()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_session] = override
    with factory() as db:
        seed(db)
        db.commit()
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def test_board_starts_with_planned_orders(client):
    response = client.get("/api/dashboard")
    assert response.status_code == 200
    body = response.json()
    assert body["kpis"]["orders_planned"] == 4
    assert [order["order_no"] for order in body["orders"]] == [
        "PO-1001",
        "PO-1002",
        "PO-1003",
        "PO-1004",
    ]
    health = client.get("/api/health")
    assert health.status_code == 200
    assert health.json()["status"] == "ok"
    assert "lan_urls" in health.json()
    assert client.get("/").status_code == 200
    assert "SMES" in client.get("/").text


def test_release_and_reject_bad_completion(client):
    released = client.post("/api/orders/release-all")
    assert released.status_code == 200
    kit = next(machine for machine in released.json()["machines"] if machine["code"] == "KIT-1")
    assert kit["status"] == "running"
    operation_id = kit["current"]["operation_id"]
    bad = client.post(
        f"/api/operations/{operation_id}/complete",
        json={"qty_good": 1, "qty_scrap": 1, "record_ideal_time": True},
    )
    assert bad.status_code == 422

    done = client.post(
        f"/api/operations/{operation_id}/complete",
        json={"qty_good": 12, "qty_scrap": 0, "record_ideal_time": True},
    )
    assert done.status_code == 200
    order = next(row for row in done.json()["orders"] if row["order_no"] == "PO-1001")
    assert order["steps_done"] == 1
    assert order["current_station"] == "ASM"


def test_simulate_and_reset(client):
    simulated = client.post("/api/simulate", json={"max_completions": 6, "with_disruptions": False})
    assert simulated.status_code == 200
    body = simulated.json()
    assert body["completions"] == 6
    assert body["dashboard"]["kpis"]["orders_planned"] == 0

    reset = client.post("/api/reset")
    assert reset.status_code == 200
    assert reset.json()["kpis"]["orders_planned"] == 4
    assert reset.json()["kpis"]["machines_running"] == 0
