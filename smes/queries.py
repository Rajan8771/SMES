"""Read models for the shop-floor board."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from smes.db import isoformat_utc
from smes.engine import line_oee, machine_metrics
from smes.models import (
    Downtime,
    Machine,
    Operation,
    Product,
    ProductionOrder,
    RoutingStep,
    ShopEvent,
    Station,
)


def _order_progress(session: Session, order: ProductionOrder) -> tuple[int, int, str | None]:
    steps = list(
        session.scalars(
            select(RoutingStep)
            .where(RoutingStep.product_id == order.product_id)
            .order_by(RoutingStep.sequence)
        )
    )
    done = list(
        session.scalars(
            select(Operation).where(
                Operation.order_id == order.id,
                Operation.status == "completed",
            )
        )
    )
    current = session.scalars(
        select(Operation)
        .where(Operation.order_id == order.id, Operation.status.in_(("queued", "running")))
        .order_by(Operation.id.desc())
    ).first()
    current_code = None
    if current is not None:
        station = session.get(Station, current.station_id)
        current_code = station.code if station else None
    elif order.status == "completed" and steps:
        station = session.get(Station, steps[-1].station_id)
        current_code = station.code if station else None
    return len(steps), len(done), current_code


def order_row(session: Session, order: ProductionOrder) -> dict:
    product = session.get(Product, order.product_id)
    steps_total, steps_done, current_station = _order_progress(session, order)
    return {
        "id": order.id,
        "order_no": order.order_no,
        "product_code": product.code if product else "",
        "product_name": product.name if product else "",
        "qty_ordered": order.qty_ordered,
        "qty_good": order.qty_good,
        "qty_scrap": order.qty_scrap,
        "status": order.status,
        "priority": order.priority,
        "hold_reason": order.hold_reason,
        "steps_total": steps_total,
        "steps_done": steps_done,
        "current_station": current_station,
        "created_at": isoformat_utc(order.created_at),
        "released_at": isoformat_utc(order.released_at),
        "completed_at": isoformat_utc(order.completed_at),
    }


def snapshot(session: Session) -> dict:
    stations = list(session.scalars(select(Station).order_by(Station.sequence)))
    machines = list(session.scalars(select(Machine).order_by(Machine.code)))
    orders = list(
        session.scalars(select(ProductionOrder).order_by(ProductionOrder.priority, ProductionOrder.id))
    )
    events = list(
        session.scalars(select(ShopEvent).order_by(ShopEvent.id.desc()).limit(24))
    )

    station_by_id = {station.id: station for station in stations}
    metrics_by_machine: list[dict] = []
    machine_rows = []
    for machine in machines:
        metrics = machine_metrics(session, machine)
        metrics_by_machine.append(metrics)
        current = session.scalars(
            select(Operation).where(
                Operation.machine_id == machine.id,
                Operation.status == "running",
            )
        ).first()
        current_payload = None
        if current is not None:
            order = session.get(ProductionOrder, current.order_id)
            product = session.get(Product, order.product_id) if order else None
            current_payload = {
                "operation_id": current.id,
                "order_no": order.order_no if order else "",
                "order_id": order.id if order else None,
                "product_code": product.code if product else "",
                "operation": current.name,
                "qty_in": current.qty_in,
                "priority": order.priority if order else None,
            }
        down_reason = None
        if machine.status == "down":
            interval = session.scalars(
                select(Downtime)
                .where(Downtime.machine_id == machine.id, Downtime.ended_at.is_(None))
                .order_by(Downtime.id.desc())
            ).first()
            down_reason = interval.reason if interval else None
        station = station_by_id[machine.station_id]
        machine_rows.append(
            {
                "id": machine.id,
                "code": machine.code,
                "name": machine.name,
                "station_code": station.code,
                "station_name": station.name,
                "status": machine.status,
                "down_reason": down_reason,
                "current": current_payload,
                "oee": {
                    "availability": metrics["availability"],
                    "performance": metrics["performance"],
                    "quality": metrics["quality"],
                    "oee": metrics["oee"],
                },
            }
        )

    lanes = []
    for station in stations:
        queued = list(
            session.scalars(
                select(Operation).where(
                    Operation.station_id == station.id,
                    Operation.status == "queued",
                )
            )
        )
        running = list(
            session.scalars(
                select(Operation).where(
                    Operation.station_id == station.id,
                    Operation.status == "running",
                )
            )
        )
        lanes.append(
            {
                "code": station.code,
                "name": station.name,
                "sequence": station.sequence,
                "queued": len(queued),
                "running": len(running),
                "queued_qty": sum(op.qty_in for op in queued),
                "running_qty": sum(op.qty_in for op in running),
            }
        )

    open_orders = [order for order in orders if order.status not in ("planned", "completed")]
    wip_qty = sum(lane["queued_qty"] + lane["running_qty"] for lane in lanes)
    return {
        "kpis": {
            "orders_open": len(open_orders),
            "orders_on_hold": sum(1 for order in orders if order.status == "on_hold"),
            "orders_planned": sum(1 for order in orders if order.status == "planned"),
            "wip_qty": wip_qty,
            "machines_running": sum(1 for machine in machines if machine.status == "running"),
            "machines_down": sum(1 for machine in machines if machine.status == "down"),
            "line_oee": line_oee(metrics_by_machine),
        },
        "lanes": lanes,
        "machines": machine_rows,
        "orders": [order_row(session, order) for order in orders],
        "events": [
            {
                "id": event.id,
                "at": isoformat_utc(event.created_at),
                "kind": event.kind,
                "message": event.message,
            }
            for event in events
        ],
    }
