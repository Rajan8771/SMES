"""Shop-floor tables for orders, routings, machines, and the event tape."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship

from smes.db import utcnow


class Base(DeclarativeBase):
    pass


class Station(Base):
    __tablename__ = "stations"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(16), unique=True)
    name: Mapped[str] = mapped_column(String(80))
    sequence: Mapped[int] = mapped_column(Integer)


class Machine(Base):
    __tablename__ = "machines"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(16), unique=True)
    name: Mapped[str] = mapped_column(String(80))
    station_id: Mapped[int] = mapped_column(ForeignKey("stations.id"))
    status: Mapped[str] = mapped_column(String(16), default="idle")
    ideal_cycle_seconds: Mapped[float] = mapped_column(Float)

    station: Mapped[Station] = relationship()
    downtimes: Mapped[list[Downtime]] = relationship(back_populates="machine")


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(32), unique=True)
    name: Mapped[str] = mapped_column(String(120))

    steps: Mapped[list[RoutingStep]] = relationship(
        back_populates="product", order_by="RoutingStep.sequence"
    )


class RoutingStep(Base):
    __tablename__ = "routing_steps"

    id: Mapped[int] = mapped_column(primary_key=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"))
    sequence: Mapped[int] = mapped_column(Integer)
    station_id: Mapped[int] = mapped_column(ForeignKey("stations.id"))
    name: Mapped[str] = mapped_column(String(80))
    ideal_cycle_seconds: Mapped[float] = mapped_column(Float)

    product: Mapped[Product] = relationship(back_populates="steps")
    station: Mapped[Station] = relationship()


class ProductionOrder(Base):
    __tablename__ = "production_orders"

    id: Mapped[int] = mapped_column(primary_key=True)
    order_no: Mapped[str] = mapped_column(String(32), unique=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"))
    qty_ordered: Mapped[int] = mapped_column(Integer)
    qty_good: Mapped[int] = mapped_column(Integer, default=0)
    qty_scrap: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[str] = mapped_column(String(16), default="planned")
    priority: Mapped[int] = mapped_column(Integer, default=100)
    hold_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    released_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    product: Mapped[Product] = relationship()
    operations: Mapped[list[Operation]] = relationship(back_populates="order")


class Operation(Base):
    __tablename__ = "operations"

    id: Mapped[int] = mapped_column(primary_key=True)
    order_id: Mapped[int] = mapped_column(ForeignKey("production_orders.id"))
    step_sequence: Mapped[int] = mapped_column(Integer)
    station_id: Mapped[int] = mapped_column(ForeignKey("stations.id"))
    name: Mapped[str] = mapped_column(String(80))
    status: Mapped[str] = mapped_column(String(16), default="queued")
    qty_in: Mapped[int] = mapped_column(Integer)
    qty_good: Mapped[int] = mapped_column(Integer, default=0)
    qty_scrap: Mapped[int] = mapped_column(Integer, default=0)
    machine_id: Mapped[int | None] = mapped_column(ForeignKey("machines.id"), nullable=True)
    ideal_cycle_seconds: Mapped[float] = mapped_column(Float)
    defect_code: Mapped[str | None] = mapped_column(String(32), nullable=True)
    queued_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    started_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    order: Mapped[ProductionOrder] = relationship(back_populates="operations")
    station: Mapped[Station] = relationship()
    machine: Mapped[Machine | None] = relationship()


class Downtime(Base):
    __tablename__ = "downtimes"

    id: Mapped[int] = mapped_column(primary_key=True)
    machine_id: Mapped[int] = mapped_column(ForeignKey("machines.id"))
    reason: Mapped[str] = mapped_column(String(120))
    started_at: Mapped[datetime] = mapped_column(DateTime)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    machine: Mapped[Machine] = relationship(back_populates="downtimes")


class ShopEvent(Base):
    __tablename__ = "shop_events"

    id: Mapped[int] = mapped_column(primary_key=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    kind: Mapped[str] = mapped_column(String(32))
    message: Mapped[str] = mapped_column(Text)
    order_id: Mapped[int | None] = mapped_column(ForeignKey("production_orders.id"), nullable=True)
    machine_id: Mapped[int | None] = mapped_column(ForeignKey("machines.id"), nullable=True)
    operation_id: Mapped[int | None] = mapped_column(ForeignKey("operations.id"), nullable=True)
