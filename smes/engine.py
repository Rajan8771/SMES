"""Shop-floor automation.

Release explodes the first routing step into a queued operation.
Dispatch assigns the oldest highest-priority queued operation at a station
to an idle machine there. Completion moves the good quantity to the next
step. Scrap at or above the hold ratio stops the order for a person to resume.
A machine going down returns its in-process work to the station queue.
"""

from __future__ import annotations

from datetime import datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from smes.db import utcnow
from smes.models import (
    Downtime,
    Machine,
    Operation,
    ProductionOrder,
    RoutingStep,
    ShopEvent,
)

# A station loses 10% or more of the pieces it started with.
HOLD_SCRAP_RATIO = 0.10
HOLD_MIN_QTY = 4
OPEN_ORDER_STATUSES = ("released", "in_progress")


class DomainError(Exception):
    def __init__(self, message: str, status_code: int = 409):
        super().__init__(message)
        self.message = message
        self.status_code = status_code


def log_event(
    session: Session,
    kind: str,
    message: str,
    *,
    at: datetime | None = None,
    order_id: int | None = None,
    machine_id: int | None = None,
    operation_id: int | None = None,
) -> None:
    session.add(
        ShopEvent(
            created_at=at or utcnow(),
            kind=kind,
            message=message,
            order_id=order_id,
            machine_id=machine_id,
            operation_id=operation_id,
        )
    )


def _steps_for(session: Session, product_id: int) -> list[RoutingStep]:
    return list(
        session.scalars(
            select(RoutingStep)
            .where(RoutingStep.product_id == product_id)
            .order_by(RoutingStep.sequence)
        )
    )


def _enqueue(
    session: Session,
    order: ProductionOrder,
    step: RoutingStep,
    qty: int,
    at: datetime,
) -> Operation:
    if qty <= 0:
        raise DomainError("Cannot queue an operation with no pieces", 422)
    operation = Operation(
        order_id=order.id,
        step_sequence=step.sequence,
        station_id=step.station_id,
        name=step.name,
        status="queued",
        qty_in=qty,
        ideal_cycle_seconds=step.ideal_cycle_seconds,
        queued_at=at,
    )
    session.add(operation)
    session.flush()
    return operation


def release_order(
    session: Session,
    order_id: int,
    *,
    at: datetime | None = None,
    dispatch_now: bool = True,
) -> ProductionOrder:
    order = session.get(ProductionOrder, order_id)
    if order is None:
        raise DomainError("Order not found", 404)
    if order.status != "planned":
        raise DomainError(f"{order.order_no} is {order.status}; only planned orders release")
    steps = _steps_for(session, order.product_id)
    if not steps:
        raise DomainError(f"{order.order_no} has no routing", 422)

    ts = at or utcnow()
    order.status = "released"
    order.released_at = ts
    _enqueue(session, order, steps[0], order.qty_ordered, ts)
    log_event(
        session,
        "order_released",
        f"Released {order.order_no} for {order.qty_ordered} pieces",
        at=ts,
        order_id=order.id,
    )
    if dispatch_now:
        dispatch(session, at=ts)
    return order


def release_all(session: Session, *, at: datetime | None = None) -> list[Operation]:
    """Release every planned order, then dispatch once so priority can apply."""
    ts = at or utcnow()
    orders = list(
        session.scalars(
            select(ProductionOrder)
            .where(ProductionOrder.status == "planned")
            .order_by(ProductionOrder.priority, ProductionOrder.id)
        )
    )
    for order in orders:
        release_order(session, order.id, at=ts, dispatch_now=False)
    return dispatch(session, at=ts)


def dispatch(session: Session, *, at: datetime | None = None) -> list[Operation]:
    """Pull queued work onto idle machines. Does not preempt a running job."""
    ts = at or utcnow()
    machines = list(
        session.scalars(
            select(Machine).where(Machine.status == "idle").order_by(Machine.code)
        )
    )
    assigned: list[Operation] = []
    for machine in machines:
        operation = session.scalars(
            select(Operation)
            .join(ProductionOrder, ProductionOrder.id == Operation.order_id)
            .where(
                Operation.status == "queued",
                Operation.station_id == machine.station_id,
                ProductionOrder.status.in_(OPEN_ORDER_STATUSES),
            )
            .order_by(ProductionOrder.priority, Operation.queued_at, Operation.id)
        ).first()
        if operation is None:
            continue
        order = session.get(ProductionOrder, operation.order_id)
        if order is None:
            continue
        operation.status = "running"
        operation.machine_id = machine.id
        operation.started_at = ts
        machine.status = "running"
        if order.status == "released":
            order.status = "in_progress"
        log_event(
            session,
            "dispatched",
            f"{order.order_no} {operation.name} → {machine.code} ({operation.qty_in} pcs)",
            at=ts,
            order_id=order.id,
            machine_id=machine.id,
            operation_id=operation.id,
        )
        session.flush()
        assigned.append(operation)
    return assigned


def complete_operation(
    session: Session,
    operation_id: int,
    qty_good: int,
    qty_scrap: int,
    *,
    at: datetime | None = None,
    record_ideal_time: bool = False,
    defect_code: str | None = None,
) -> Operation:
    operation = session.get(Operation, operation_id)
    if operation is None:
        raise DomainError("Operation not found", 404)
    if operation.status != "running":
        raise DomainError("Only a running operation can be completed")
    if qty_good < 0 or qty_scrap < 0:
        raise DomainError("Quantities cannot be negative", 422)
    if qty_good + qty_scrap != operation.qty_in:
        raise DomainError(
            f"Good ({qty_good}) + scrap ({qty_scrap}) must equal {operation.qty_in}",
            422,
        )

    ts = at or utcnow()
    if record_ideal_time:
        duration = timedelta(seconds=operation.ideal_cycle_seconds * operation.qty_in)
        operation.started_at = ts - duration
    operation.completed_at = ts
    operation.qty_good = qty_good
    operation.qty_scrap = qty_scrap
    operation.status = "completed"
    if defect_code:
        operation.defect_code = defect_code
    elif qty_scrap:
        operation.defect_code = "UNSPECIFIED"

    machine = session.get(Machine, operation.machine_id) if operation.machine_id else None
    if machine is not None and machine.status == "running":
        machine.status = "idle"

    order = session.get(ProductionOrder, operation.order_id)
    if order is None:
        raise DomainError("Order missing for operation", 422)
    order.qty_scrap += qty_scrap

    scrap_ratio = qty_scrap / operation.qty_in if operation.qty_in else 0
    held = operation.qty_in >= HOLD_MIN_QTY and scrap_ratio >= HOLD_SCRAP_RATIO
    if held:
        order.status = "on_hold"
        order.hold_reason = (
            f"Scrap {qty_scrap}/{operation.qty_in} at {operation.name} "
            f"hit the {int(HOLD_SCRAP_RATIO * 100)}% hold rule"
        )
        log_event(
            session,
            "quality_hold",
            order.hold_reason + f" on {order.order_no}",
            at=ts,
            order_id=order.id,
            machine_id=operation.machine_id,
            operation_id=operation.id,
        )
    else:
        _advance_or_finish(session, order, operation, ts)

    if qty_scrap:
        log_event(
            session,
            "scrap",
            f"{order.order_no} scrapped {qty_scrap} at {operation.name}",
            at=ts,
            order_id=order.id,
            machine_id=operation.machine_id,
            operation_id=operation.id,
        )
    log_event(
        session,
        "operation_completed",
        f"{order.order_no} finished {operation.name}: {qty_good} good, {qty_scrap} scrap",
        at=ts,
        order_id=order.id,
        machine_id=operation.machine_id,
        operation_id=operation.id,
    )
    dispatch(session, at=ts)
    return operation


def _advance_or_finish(
    session: Session,
    order: ProductionOrder,
    operation: Operation,
    at: datetime,
) -> None:
    steps = _steps_for(session, order.product_id)
    nxt = next((step for step in steps if step.sequence > operation.step_sequence), None)
    if operation.qty_good > 0 and nxt is not None:
        _enqueue(session, order, nxt, operation.qty_good, at)
        if order.status == "released":
            order.status = "in_progress"
        return
    order.qty_good = operation.qty_good
    order.status = "completed"
    order.completed_at = at
    order.hold_reason = None
    log_event(
        session,
        "order_completed",
        f"{order.order_no} completed with {operation.qty_good} good",
        at=at,
        order_id=order.id,
        operation_id=operation.id,
    )


def resume_order(session: Session, order_id: int, *, at: datetime | None = None) -> ProductionOrder:
    order = session.get(ProductionOrder, order_id)
    if order is None:
        raise DomainError("Order not found", 404)
    if order.status != "on_hold":
        raise DomainError(f"{order.order_no} is not on hold")

    ts = at or utcnow()
    last = session.scalars(
        select(Operation)
        .where(Operation.order_id == order.id, Operation.status == "completed")
        .order_by(Operation.completed_at.desc(), Operation.id.desc())
    ).first()
    if last is None:
        raise DomainError(f"{order.order_no} has no completed operation to resume from", 422)

    order.hold_reason = None
    steps = _steps_for(session, order.product_id)
    nxt = next((step for step in steps if step.sequence > last.step_sequence), None)
    if last.qty_good > 0 and nxt is not None:
        order.status = "in_progress"
        _enqueue(session, order, nxt, last.qty_good, ts)
        log_event(
            session,
            "order_resumed",
            f"Resumed {order.order_no} with {last.qty_good} pieces",
            at=ts,
            order_id=order.id,
        )
    else:
        order.qty_good = last.qty_good
        order.status = "completed"
        order.completed_at = ts
        log_event(
            session,
            "order_completed",
            f"{order.order_no} closed from hold with {last.qty_good} good",
            at=ts,
            order_id=order.id,
        )
    dispatch(session, at=ts)
    return order


def machine_down(
    session: Session,
    machine_id: int,
    reason: str,
    *,
    at: datetime | None = None,
) -> Machine:
    machine = session.get(Machine, machine_id)
    if machine is None:
        raise DomainError("Machine not found", 404)
    if machine.status == "down":
        raise DomainError(f"{machine.code} is already down")
    reason = reason.strip()
    if not reason:
        raise DomainError("A downtime reason is required", 422)

    ts = at or utcnow()
    running = list(
        session.scalars(
            select(Operation).where(
                Operation.machine_id == machine.id,
                Operation.status == "running",
            )
        )
    )
    for operation in running:
        order = session.get(ProductionOrder, operation.order_id)
        operation.status = "queued"
        operation.machine_id = None
        operation.started_at = None
        log_event(
            session,
            "requeued",
            f"{order.order_no if order else 'Job'} {operation.name} returned to queue "
            f"because {machine.code} went down",
            at=ts,
            order_id=operation.order_id,
            machine_id=machine.id,
            operation_id=operation.id,
        )
    machine.status = "down"
    session.add(Downtime(machine_id=machine.id, reason=reason, started_at=ts))
    log_event(
        session,
        "machine_down",
        f"{machine.code} down: {reason}",
        at=ts,
        machine_id=machine.id,
    )
    session.flush()
    dispatch(session, at=ts)
    return machine


def machine_up(session: Session, machine_id: int, *, at: datetime | None = None) -> Machine:
    machine = session.get(Machine, machine_id)
    if machine is None:
        raise DomainError("Machine not found", 404)
    if machine.status != "down":
        raise DomainError(f"{machine.code} is not down")

    ts = at or utcnow()
    open_interval = session.scalars(
        select(Downtime)
        .where(Downtime.machine_id == machine.id, Downtime.ended_at.is_(None))
        .order_by(Downtime.started_at.desc())
    ).first()
    if open_interval is not None:
        open_interval.ended_at = ts
    machine.status = "idle"
    log_event(
        session,
        "machine_up",
        f"{machine.code} is back in service",
        at=ts,
        machine_id=machine.id,
    )
    dispatch(session, at=ts)
    return machine


def _seconds(start: datetime | None, end: datetime | None) -> float:
    if start is None or end is None:
        return 0.0
    return max(0.0, (end - start).total_seconds())


def machine_metrics(session: Session, machine: Machine, *, now: datetime | None = None) -> dict:
    """Availability × performance × quality for one machine.

    Availability uses recorded run time and downtime. Performance compares
    ideal cycle time with the clock time actually recorded on completed jobs.
    Quality is good pieces over pieces processed.
    """
    ts = now or utcnow()
    operations = list(
        session.scalars(
            select(Operation).where(
                Operation.machine_id == machine.id,
                Operation.status == "completed",
            )
        )
    )
    intervals = list(
        session.scalars(select(Downtime).where(Downtime.machine_id == machine.id))
    )
    run_seconds = sum(_seconds(op.started_at, op.completed_at) for op in operations)
    down_seconds = sum(_seconds(interval.started_at, interval.ended_at or ts) for interval in intervals)
    ideal_seconds = sum(op.ideal_cycle_seconds * (op.qty_good + op.qty_scrap) for op in operations)
    good = sum(op.qty_good for op in operations)
    total = sum(op.qty_good + op.qty_scrap for op in operations)

    availability = None
    if run_seconds + down_seconds > 0:
        availability = run_seconds / (run_seconds + down_seconds)
    performance = ideal_seconds / run_seconds if run_seconds > 0 else None
    quality = good / total if total > 0 else None
    oee = None
    if availability is not None and performance is not None and quality is not None:
        oee = availability * performance * quality
    return {
        "availability": availability,
        "performance": performance,
        "quality": quality,
        "oee": oee,
        "run_seconds": run_seconds,
        "down_seconds": down_seconds,
        "good": good,
        "total": total,
    }


def line_oee(metrics: list[dict]) -> float | None:
    weighted = 0.0
    weight = 0.0
    for item in metrics:
        if item["oee"] is None:
            continue
        piece_weight = item["total"] or 0
        if piece_weight <= 0:
            continue
        weighted += item["oee"] * piece_weight
        weight += piece_weight
    if weight <= 0:
        return None
    return weighted / weight


def simulate_shift(
    session: Session,
    *,
    max_completions: int = 16,
    with_disruptions: bool = True,
    at: datetime | None = None,
) -> dict:
    """Discrete-event shift. Disruptions are on a fixed cadence so demos repeat."""
    if at is None:
        clock = utcnow() - timedelta(hours=3)
        latest = session.scalar(select(func.max(Operation.started_at)))
        if latest is not None and latest > clock:
            clock = latest
    else:
        clock = at
    planned = session.scalar(
        select(ProductionOrder.id).where(ProductionOrder.status == "planned").limit(1)
    )
    if planned is not None:
        release_all(session, at=clock)

    completions = 0
    downtime_events = 0
    interrupts_done: set[int] = set()
    pending_ups: list[tuple[datetime, int]] = []
    safety = 0
    while completions < max_completions:
        safety += 1
        if safety > max_completions * 8:
            break
        dispatch(session, at=clock)
        running = list(
            session.scalars(select(Operation).where(Operation.status == "running"))
        )
        next_op = None
        next_finish = None
        for operation in running:
            start = operation.started_at or clock
            finish = start + timedelta(seconds=operation.ideal_cycle_seconds * operation.qty_in)
            if next_finish is None or finish < next_finish:
                next_finish = finish
                next_op = operation
        next_up = min(pending_ups) if pending_ups else None

        if next_op is None and next_up is None:
            break
        if next_op is None or (next_up is not None and next_finish is not None and next_up[0] <= next_finish):
            assert next_up is not None
            pending_ups.remove(next_up)
            clock = next_up[0]
            faulted = session.get(Machine, next_up[1])
            if faulted is not None and faulted.status == "down":
                machine_up(session, faulted.id, at=clock)
            continue

        assert next_op is not None and next_finish is not None
        clock = next_finish
        if (
            with_disruptions
            and completions in (5, 14)
            and completions not in interrupts_done
            and next_op.machine_id is not None
        ):
            # machine_down clears the operation's machine, so keep the id first.
            faulted_id = next_op.machine_id
            interrupts_done.add(completions)
            machine_down(session, faulted_id, "Sensor fault", at=clock)
            pending_ups.append((clock + timedelta(minutes=18), faulted_id))
            downtime_events += 1
            continue

        scrap = 0
        if with_disruptions and completions > 0 and completions % 6 == 0 and next_op.qty_in >= HOLD_MIN_QTY:
            scrap = max(1, next_op.qty_in // 8)
        good = next_op.qty_in - scrap
        complete_operation(
            session,
            next_op.id,
            good,
            scrap,
            at=clock,
            defect_code="FUNCTIONAL" if scrap else None,
        )
        completions += 1

    for when, machine_id in sorted(pending_ups):
        clock = when
        faulted = session.get(Machine, machine_id)
        if faulted is not None and faulted.status == "down":
            machine_up(session, faulted.id, at=clock)

    completed_count = session.scalar(
        select(func.count()).select_from(ProductionOrder).where(ProductionOrder.status == "completed")
    ) or 0
    hold_count = session.scalar(
        select(func.count()).select_from(ProductionOrder).where(ProductionOrder.status == "on_hold")
    ) or 0
    queued = session.scalar(
        select(func.count()).select_from(Operation).where(Operation.status == "queued")
    ) or 0
    return {
        "completions": completions,
        "orders_completed": completed_count,
        "orders_on_hold": hold_count,
        "downtime_events": downtime_events,
        "remaining_queued": queued,
        "clock": clock,
    }
