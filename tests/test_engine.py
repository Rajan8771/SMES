from datetime import timedelta

from sqlalchemy import select

from smes.db import utcnow
from smes.lan import lan_ip
from smes.engine import (
    DomainError,
    complete_operation,
    machine_down,
    machine_metrics,
    machine_up,
    release_all,
    release_order,
    resume_order,
    simulate_shift,
)
from smes.models import Machine, Operation, ProductionOrder


def _order(session, order_no: str) -> ProductionOrder:
    order = session.scalar(select(ProductionOrder).where(ProductionOrder.order_no == order_no))
    assert order is not None
    return order


def _machine(session, code: str) -> Machine:
    machine = session.scalar(select(Machine).where(Machine.code == code))
    assert machine is not None
    return machine


def _running(session, machine_code: str) -> Operation | None:
    machine = _machine(session, machine_code)
    return session.scalar(
        select(Operation).where(
            Operation.machine_id == machine.id,
            Operation.status == "running",
        )
    )


def test_release_all_dispatches_highest_priority_first(session):
    assigned = release_all(session)
    assert len(assigned) == 1
    assert assigned[0].order_id == _order(session, "PO-1001").id
    assert _machine(session, "KIT-1").status == "running"
    assert _order(session, "PO-1001").status == "in_progress"
    queued = session.scalars(select(Operation).where(Operation.status == "queued")).all()
    assert len(queued) == 3


def test_completion_advances_the_routing_and_keeps_the_quantity_identity(session):
    release_order(session, _order(session, "PO-1001").id)
    guard = 0
    while _order(session, "PO-1001").status != "completed":
        guard += 1
        assert guard < 8
        running = session.scalars(select(Operation).where(Operation.status == "running")).all()
        assert running
        for operation in running:
            if operation.order_id != _order(session, "PO-1001").id:
                continue
            complete_operation(
                session,
                operation.id,
                operation.qty_in,
                0,
                record_ideal_time=True,
            )
    order = _order(session, "PO-1001")
    assert order.qty_good == order.qty_ordered
    assert order.qty_scrap == 0
    assert order.completed_at is not None


def test_scrap_below_the_hold_ratio_continues_with_the_good_pieces(session):
    order = _order(session, "PO-1001")
    release_order(session, order.id)
    operation = _running(session, "KIT-1")
    assert operation is not None
    complete_operation(session, operation.id, operation.qty_in - 1, 1, record_ideal_time=True)
    order = _order(session, "PO-1001")
    assert order.status == "in_progress"
    assert order.qty_scrap == 1
    nxt = session.scalar(
        select(Operation).where(
            Operation.order_id == order.id,
            Operation.status.in_(("queued", "running")),
        )
    )
    assert nxt is not None
    assert nxt.qty_in == order.qty_ordered - 1
    assert nxt.name == "Assemble panel"


def test_scrap_at_the_hold_ratio_stops_the_order_until_resume(session):
    order = _order(session, "PO-1001")
    release_order(session, order.id)
    operation = _running(session, "KIT-1")
    assert operation is not None
    complete_operation(session, operation.id, 10, 2, record_ideal_time=True)
    order = _order(session, "PO-1001")
    assert order.status == "on_hold"
    assert "10% hold rule" in (order.hold_reason or "")
    waiting = session.scalar(
        select(Operation).where(
            Operation.order_id == order.id,
            Operation.status.in_(("queued", "running")),
        )
    )
    assert waiting is None

    resume_order(session, order.id)
    order = _order(session, "PO-1001")
    assert order.status == "in_progress"
    nxt = session.scalar(
        select(Operation).where(Operation.order_id == order.id, Operation.name == "Assemble panel")
    )
    assert nxt is not None
    assert nxt.qty_in == 10
    assert nxt.status == "running"


def test_machine_down_requeues_work_onto_the_other_cell(session):
    release_order(session, _order(session, "PO-1001").id)
    kit = _running(session, "KIT-1")
    assert kit is not None
    complete_operation(session, kit.id, kit.qty_in, 0, record_ideal_time=True)
    running = _running(session, "ASM-1")
    assert running is not None
    assert _running(session, "ASM-2") is None

    machine_down(session, _machine(session, "ASM-1").id, "Air supply lost")
    assert _machine(session, "ASM-1").status == "down"
    moved = _running(session, "ASM-2")
    assert moved is not None
    assert moved.order_id == _order(session, "PO-1001").id
    assert _running(session, "ASM-1") is None


def test_quantities_must_add_up(session):
    release_order(session, _order(session, "PO-1001").id)
    operation = _running(session, "KIT-1")
    assert operation is not None
    try:
        complete_operation(session, operation.id, 1, 1)
    except DomainError as exc:
        assert exc.status_code == 422
    else:
        raise AssertionError("expected DomainError")


def test_oee_uses_run_time_downtime_and_good_pieces(session):
    start = utcnow() - timedelta(minutes=30)
    release_order(session, _order(session, "PO-1001").id, at=start)
    operation = _running(session, "KIT-1")
    assert operation is not None
    finish = start + timedelta(seconds=operation.ideal_cycle_seconds * operation.qty_in)
    complete_operation(session, operation.id, operation.qty_in - 1, 1, at=finish)
    machine = _machine(session, "KIT-1")
    machine_down(session, machine.id, "Jam", at=finish)
    machine_up(session, machine.id, at=finish + timedelta(seconds=600))

    metrics = machine_metrics(session, _machine(session, "KIT-1"), now=finish + timedelta(seconds=600))
    run_seconds = operation.ideal_cycle_seconds * operation.qty_in
    assert metrics["run_seconds"] == run_seconds
    assert metrics["down_seconds"] == 600
    assert metrics["quality"] == (operation.qty_in - 1) / operation.qty_in
    assert metrics["performance"] == 1
    assert metrics["availability"] == run_seconds / (run_seconds + 600)
    assert metrics["oee"] == metrics["availability"] * metrics["performance"] * metrics["quality"]


def test_lan_address_is_not_loopback():
    address = lan_ip()
    if address is None:
        return
    assert not address.startswith("127.")


def test_sensor_fault_is_cleared_before_the_shift_ends(session):
    summary = simulate_shift(session, max_completions=16, with_disruptions=True, at=utcnow())
    assert summary["downtime_events"] >= 1
    assert summary["completions"] > 7
    down = list(session.scalars(select(Machine).where(Machine.status == "down")))
    assert down == []


def test_clean_simulation_tracks_ideal_pace(session):
    summary = simulate_shift(session, max_completions=8, with_disruptions=False, at=utcnow())
    assert summary["completions"] == 8
    assert summary["orders_on_hold"] == 0
    assert summary["downtime_events"] == 0
    metrics = machine_metrics(session, _machine(session, "KIT-1"))
    assert metrics["performance"] == 1
    assert metrics["quality"] == 1
