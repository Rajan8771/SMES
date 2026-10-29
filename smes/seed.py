"""Sample control-panel line used by the demo and the tests."""

from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from smes.models import Machine, Product, ProductionOrder, RoutingStep, Station


STATIONS = (
    ("KIT", "Kitting", 10),
    ("ASM", "Assembly", 20),
    ("TST", "Test", 30),
    ("PCK", "Pack", 40),
)

MACHINES = (
    ("KIT-1", "Kitting bench", "KIT", 25.0),
    ("ASM-1", "Assembly cell 1", "ASM", 80.0),
    ("ASM-2", "Assembly cell 2", "ASM", 80.0),
    ("TST-1", "Functional tester", "TST", 40.0),
    ("PCK-1", "Pack station", "PCK", 20.0),
)

# sequence, station code, operation name, ideal seconds per piece
PRODUCTS = {
    "CP-100": (
        "Control panel CP-100",
        (
            (10, "KIT", "Kit components", 20.0),
            (20, "ASM", "Assemble panel", 75.0),
            (30, "TST", "Functional test", 35.0),
            (40, "PCK", "Pack and label", 15.0),
        ),
    ),
    "CP-200": (
        "Washdown panel CP-200",
        (
            (10, "KIT", "Kit components", 25.0),
            (20, "ASM", "Assemble panel", 95.0),
            (30, "TST", "Hipot and function test", 55.0),
            (40, "PCK", "Pack and label", 20.0),
        ),
    ),
}

# order_no, product code, quantity, priority (lower runs first once queued)
ORDERS = (
    ("PO-1001", "CP-100", 12, 10),
    ("PO-1002", "CP-200", 8, 20),
    ("PO-1003", "CP-100", 20, 30),
    ("PO-1004", "CP-200", 6, 40),
)


def seed(session: Session) -> None:
    stations = [
        Station(code=code, name=name, sequence=sequence) for code, name, sequence in STATIONS
    ]
    session.add_all(stations)
    session.flush()
    station_by_code = {station.code: station for station in stations}

    session.add_all(
        Machine(
            code=code,
            name=name,
            station_id=station_by_code[station_code].id,
            status="idle",
            ideal_cycle_seconds=ideal,
        )
        for code, name, station_code, ideal in MACHINES
    )

    product_by_code: dict[str, Product] = {}
    for code, (name, _steps) in PRODUCTS.items():
        product = Product(code=code, name=name)
        session.add(product)
        product_by_code[code] = product
    session.flush()

    for code, (_name, steps) in PRODUCTS.items():
        product = product_by_code[code]
        for sequence, station_code, step_name, ideal in steps:
            session.add(
                RoutingStep(
                    product_id=product.id,
                    sequence=sequence,
                    station_id=station_by_code[station_code].id,
                    name=step_name,
                    ideal_cycle_seconds=ideal,
                )
            )

    for order_no, product_code, qty, priority in ORDERS:
        session.add(
            ProductionOrder(
                order_no=order_no,
                product_id=product_by_code[product_code].id,
                qty_ordered=qty,
                status="planned",
                priority=priority,
            )
        )
    session.flush()


def seed_if_empty(session: Session) -> bool:
    count = session.scalar(select(func.count()).select_from(Station)) or 0
    if count:
        return False
    seed(session)
    session.commit()
    return True
