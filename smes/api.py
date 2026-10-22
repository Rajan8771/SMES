"""HTTP API for the shop floor board."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import delete
from sqlalchemy.orm import Session

from smes.db import get_session, isoformat_utc
from smes.engine import (
    DomainError,
    complete_operation,
    machine_down,
    machine_up,
    release_all,
    release_order,
    resume_order,
    simulate_shift,
)
from smes.models import Base
from smes.queries import snapshot
from smes.seed import seed

router = APIRouter(prefix="/api")


class CompleteIn(BaseModel):
    qty_good: int = Field(ge=0)
    qty_scrap: int = Field(ge=0)
    defect_code: str | None = Field(default=None, max_length=32)
    record_ideal_time: bool = True


class DownIn(BaseModel):
    reason: str = Field(min_length=1, max_length=120)


class SimulateIn(BaseModel):
    max_completions: int = Field(default=16, ge=1, le=200)
    with_disruptions: bool = True


def _run(session: Session, fn):
    try:
        result = fn()
        session.commit()
        return result
    except DomainError as exc:
        session.rollback()
        raise HTTPException(exc.status_code, exc.message) from exc
    except Exception:
        session.rollback()
        raise


@router.get("/health")
def health() -> dict:
    return {"status": "ok", "service": "smes"}


@router.get("/dashboard")
def dashboard(session: Session = Depends(get_session)) -> dict:
    return snapshot(session)


@router.post("/orders/{order_id}/release")
def release(order_id: int, session: Session = Depends(get_session)) -> dict:
    def action():
        release_order(session, order_id)
        return snapshot(session)

    return _run(session, action)


@router.post("/orders/release-all")
def release_everything(session: Session = Depends(get_session)) -> dict:
    def action():
        release_all(session)
        return snapshot(session)

    return _run(session, action)


@router.post("/orders/{order_id}/resume")
def resume(order_id: int, session: Session = Depends(get_session)) -> dict:
    def action():
        resume_order(session, order_id)
        return snapshot(session)

    return _run(session, action)


@router.post("/operations/{operation_id}/complete")
def complete(
    operation_id: int,
    body: CompleteIn,
    session: Session = Depends(get_session),
) -> dict:
    def action():
        complete_operation(
            session,
            operation_id,
            body.qty_good,
            body.qty_scrap,
            record_ideal_time=body.record_ideal_time,
            defect_code=body.defect_code,
        )
        return snapshot(session)

    return _run(session, action)


@router.post("/machines/{machine_id}/down")
def down(machine_id: int, body: DownIn, session: Session = Depends(get_session)) -> dict:
    def action():
        machine_down(session, machine_id, body.reason)
        return snapshot(session)

    return _run(session, action)


@router.post("/machines/{machine_id}/up")
def up(machine_id: int, session: Session = Depends(get_session)) -> dict:
    def action():
        machine_up(session, machine_id)
        return snapshot(session)

    return _run(session, action)


@router.post("/simulate")
def simulate(body: SimulateIn, session: Session = Depends(get_session)) -> dict:
    def action():
        summary = simulate_shift(
            session,
            max_completions=body.max_completions,
            with_disruptions=body.with_disruptions,
        )
        clock = summary.pop("clock")
        summary["clock"] = isoformat_utc(clock)
        summary["dashboard"] = snapshot(session)
        return summary

    return _run(session, action)


@router.post("/reset")
def reset(session: Session = Depends(get_session)) -> dict:
    def action():
        for table in reversed(Base.metadata.sorted_tables):
            session.execute(delete(table))
        session.flush()
        seed(session)
        return snapshot(session)

    return _run(session, action)
