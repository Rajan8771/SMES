# SMES

SMES is a small manufacturing execution system for one discrete assembly line. It sits where a plant-level MES sits: between a list of production orders and the machines that run them. Releasing an order, choosing a machine, holding a bad lot, and putting a cell back to work are rules in this service, not steps a supervisor has to remember.

The sample line builds two control panels, `CP-100` and `CP-200`, across kitting, assembly, test, and pack.

## What runs automatically

| Shop-floor decision | Rule |
| --- | --- |
| Release | The first routing step is queued for the full order quantity. |
| Dispatch | Each idle machine pulls the highest-priority queued job at its station. A running job is not preempted. |
| Completion | Good pieces move to the next step. Scrap stays at the step that found it. |
| Quality hold | If a step scraps 10% or more of a lot of at least 4 pieces, the order waits until someone resumes it. |
| Downtime | The machine stops taking work. Anything it was running goes back on the station queue and another idle machine at that station can take it. |
| OEE | Availability is run time ÷ (run time + downtime). Performance is ideal cycle time ÷ recorded run time. Quality is good ÷ processed. Line OEE weights machines by pieces processed. |

`Run shift` replays that loop as a short discrete-event shift, including a repeated sensor fault and a scrap spike, so the board is not empty before a PLC is connected.

## Run it

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn smes.main:app --host 127.0.0.1 --port 8000
```

Open [http://127.0.0.1:8000](http://127.0.0.1:8000). Interactive API docs are at [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs).

```bash
pytest
python -m smes.simulate
```

The SQLite file is `data/smes.db`. `Reset line` on the board drops it back to the four sample orders.

## Layout

```
smes/engine.py    release, dispatch, complete, hold, downtime, OEE, shift replay
smes/api.py       HTTP API used by the board
smes/seed.py      Line A sample plant
static/           shop-floor board
tests/            rule tests and API tests
```

Times on the board are shown in Asia/Kolkata. The database stores UTC.

This is a single-line demo with no logins. A production MES would add ERP order import, barcode genealogy, and a machine adapter (MQTT or OPC UA) that calls the same complete / down / up actions with real timestamps instead of ideal cycle time.
