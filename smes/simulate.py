"""Run a sample shift against the local database.

Usage: python -m smes.simulate
"""

from __future__ import annotations

import json

from smes.db import SessionLocal, isoformat_utc
from smes.engine import simulate_shift
from smes.main import init_db
from smes.queries import snapshot
from smes.seed import seed_if_empty


def main() -> None:
    init_db()
    with SessionLocal() as session:
        seed_if_empty(session)
        summary = simulate_shift(session, max_completions=18, with_disruptions=True)
        session.commit()
        clock = summary.pop("clock")
        board = snapshot(session)
        report = {
            "completions": summary["completions"],
            "orders_completed": summary["orders_completed"],
            "orders_on_hold": summary["orders_on_hold"],
            "downtime_events": summary["downtime_events"],
            "remaining_queued": summary["remaining_queued"],
            "clock": isoformat_utc(clock),
            "line_oee": board["kpis"]["line_oee"],
            "orders": [
                {
                    "order_no": row["order_no"],
                    "status": row["status"],
                    "steps_done": row["steps_done"],
                    "steps_total": row["steps_total"],
                    "qty_good": row["qty_good"],
                    "qty_scrap": row["qty_scrap"],
                    "hold_reason": row["hold_reason"],
                }
                for row in board["orders"]
            ],
        }
        print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
