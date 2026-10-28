const notice = document.querySelector("#notice");
const board = document.querySelector("#board");
const lan = document.querySelector("#lan");
let busy = false;

async function showLanBanner() {
  try {
    const response = await fetch("/api/health");
    if (!response.ok) return;
    const data = await response.json();
    const urls = data.lan_urls || [];
    if (!urls.length) {
      lan.textContent =
        "LAN: no shared address yet. Run start-lan.bat as Administrator on this PC, then reload.";
      return;
    }
    lan.innerHTML =
      "<strong>Share with other users on this network:</strong> " +
      urls.map((url) => escapeHtml(url)).join(" &nbsp;|&nbsp; ");
  } catch (_error) {
    lan.textContent = "";
  }
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function formatTime(iso) {
  if (!iso) return "—";
  return new Intl.DateTimeFormat("en-IN", {
    timeZone: "Asia/Kolkata",
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  }).format(new Date(iso));
}

function pct(value) {
  if (value === null || value === undefined) return "—";
  return `${Math.round(value * 1000) / 10}%`;
}

function chip(status) {
  return `<span class="chip ${escapeHtml(status)}">${escapeHtml(status.replaceAll("_", " "))}</span>`;
}

function errorText(detail) {
  if (typeof detail === "string") return detail;
  if (Array.isArray(detail)) return detail.map((item) => item.msg || "Invalid request").join(" ");
  return "Request failed";
}

function setNotice(text, isError) {
  notice.textContent = text;
  notice.classList.toggle("error", Boolean(isError));
}

async function post(url, body) {
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body ?? {}),
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(errorText(data.detail));
  return data;
}

function render(data) {
  const { kpis, lanes, machines, orders, events } = data;
  const kpi = (label, value) =>
    `<article class="kpi"><span>${label}</span><strong>${value}</strong></article>`;

  const laneHtml = lanes
    .map(
      (lane) => `<div class="lane">
        <div><b>${escapeHtml(lane.code)}</b> ${escapeHtml(lane.name)}</div>
        <em>${lane.running} running · ${lane.queued} queued</em>
      </div>`
    )
    .join("");

  const machineHtml = machines
    .map((machine) => {
      const job = machine.current
        ? `<div class="job">${escapeHtml(machine.current.order_no)} · ${escapeHtml(machine.current.operation)} · ${machine.current.qty_in} pcs</div>`
        : `<div class="job">${machine.down_reason ? escapeHtml(machine.down_reason) : "Waiting for work"}</div>`;
      const oee = `OEE ${pct(machine.oee.oee)} · A ${pct(machine.oee.availability)} · P ${pct(machine.oee.performance)} · Q ${pct(machine.oee.quality)}`;
      let controls = "";
      if (machine.status === "running" && machine.current) {
        const id = machine.current.operation_id;
        controls = `<label>Good <input id="good-${id}" type="number" min="0" value="${machine.current.qty_in}"></label>
          <label>Scrap <input id="scrap-${id}" type="number" min="0" value="0"></label>
          <button type="button" data-action="complete" data-id="${id}" data-qty="${machine.current.qty_in}">Record output</button>
          <button type="button" class="ghost" data-action="down" data-id="${machine.id}">Set down</button>`;
      } else if (machine.status === "down") {
        controls = `<button type="button" data-action="up" data-id="${machine.id}">Return to service</button>`;
      } else {
        controls = `<label>Reason
            <select id="reason-${machine.id}">
              <option>Breakdown</option>
              <option>Material shortage</option>
              <option>Changeover</option>
              <option>Quality stop</option>
            </select>
          </label>
          <button type="button" data-action="down" data-id="${machine.id}">Set down</button>`;
      }
      return `<article class="machine ${escapeHtml(machine.status)}">
        <div>
          <div class="code">${escapeHtml(machine.code)}</div>
          <div class="meta">${escapeHtml(machine.station_code)}</div>
        </div>
        <div>
          <div>${chip(machine.status)} <span class="meta">${escapeHtml(machine.name)}</span></div>
          ${job}
          <div class="oee">${oee}</div>
        </div>
        <div class="controls">${controls}</div>
      </article>`;
    })
    .join("");

  const orderRows = orders
    .map((order) => {
      let action = "";
      if (order.status === "planned") {
        action = `<button type="button" data-action="release" data-id="${order.id}">Release</button>`;
      } else if (order.status === "on_hold") {
        action = `<button type="button" data-action="resume" data-id="${order.id}">Resume</button>`;
      }
      const hold = order.hold_reason ? `<span class="hold">${escapeHtml(order.hold_reason)}</span>` : "";
      return `<tr>
        <td>${escapeHtml(order.order_no)}${hold}</td>
        <td>${escapeHtml(order.product_code)}</td>
        <td class="num">${order.qty_ordered}</td>
        <td class="num">${order.qty_good}</td>
        <td class="num">${order.qty_scrap}</td>
        <td>${order.steps_done}/${order.steps_total}${order.current_station ? " · " + escapeHtml(order.current_station) : ""}</td>
        <td>${chip(order.status)}</td>
        <td>${action}</td>
      </tr>`;
    })
    .join("");

  const eventHtml = events
    .map(
      (event) => `<li>
        <time datetime="${escapeHtml(event.at)}">${formatTime(event.at)}</time>
        <div><div class="kind">${escapeHtml(event.kind)}</div>${escapeHtml(event.message)}</div>
      </li>`
    )
    .join("");

  board.innerHTML = `
    <section class="kpis">
      ${kpi("Line OEE", pct(kpis.line_oee))}
      ${kpi("Open orders", kpis.orders_open)}
      ${kpi("On hold", kpis.orders_on_hold)}
      ${kpi("WIP pieces", kpis.wip_qty)}
      ${kpi("Running / down", `${kpis.machines_running} / ${kpis.machines_down}`)}
    </section>
    <section class="lanes">${laneHtml}</section>
    <section class="layout">
      <div class="panel">
        <h2>Machines</h2>
        <div class="machines">${machineHtml}</div>
      </div>
      <div>
        <div class="panel">
          <h2>Orders</h2>
          <table>
            <thead>
              <tr>
                <th>Order</th><th>Product</th>
                <th class="num">Qty</th><th class="num">Good</th><th class="num">Scrap</th>
                <th>Route</th><th>Status</th><th></th>
              </tr>
            </thead>
            <tbody>${orderRows}</tbody>
          </table>
        </div>
        <div class="panel" style="margin-top:18px">
          <h2>Event tape · Asia/Kolkata</h2>
          <ol class="events">${eventHtml || "<li><time></time><div>No events yet. Release a planned order.</div></li>"}</ol>
        </div>
      </div>
    </section>`;
}

async function refresh() {
  const response = await fetch("/api/dashboard");
  if (!response.ok) throw new Error("The board could not be loaded");
  render(await response.json());
}

async function act(button) {
  if (busy) return;
  const action = button.dataset.action;
  if (action === "reset" && !window.confirm("Clear this line and load the sample orders again?")) return;
  busy = true;
  document.querySelectorAll("button").forEach((item) => {
    item.disabled = true;
  });
  try {
    if (action === "refresh") {
      await refresh();
      setNotice(`Board refreshed ${formatTime(new Date().toISOString())}`, false);
    } else if (action === "release-all") {
      await post("/api/orders/release-all");
      await refresh();
      setNotice("Planned orders released. Idle machines pulled the highest-priority jobs.", false);
    } else if (action === "release") {
      await post(`/api/orders/${button.dataset.id}/release`);
      await refresh();
      setNotice("Order released onto the first station.", false);
    } else if (action === "resume") {
      await post(`/api/orders/${button.dataset.id}/resume`);
      await refresh();
      setNotice("Hold cleared. Remaining good pieces were queued.", false);
    } else if (action === "simulate") {
      const summary = await post("/api/simulate", { max_completions: 16, with_disruptions: true });
      render(summary.dashboard);
      setNotice(
        `Shift recorded ${summary.completions} completions, ${summary.orders_completed} orders finished, ${summary.orders_on_hold} on hold, ${summary.downtime_events} downtime events.`,
        false
      );
    } else if (action === "reset") {
      const data = await post("/api/reset");
      render(data);
      setNotice("Sample line restored. Orders are planned and every machine is idle.", false);
    } else if (action === "complete") {
      const id = button.dataset.id;
      const qtyGood = Number(document.querySelector(`#good-${id}`).value);
      const qtyScrap = Number(document.querySelector(`#scrap-${id}`).value);
      await post(`/api/operations/${id}/complete`, {
        qty_good: qtyGood,
        qty_scrap: qtyScrap,
        record_ideal_time: true,
        defect_code: qtyScrap > 0 ? "FUNCTIONAL" : null,
      });
      await refresh();
      setNotice("Output recorded. The next station was queued, or the order was held.", false);
    } else if (action === "down") {
      const reasonField = document.querySelector(`#reason-${button.dataset.id}`);
      const reason = reasonField ? reasonField.value : "Breakdown";
      await post(`/api/machines/${button.dataset.id}/down`, { reason });
      await refresh();
      setNotice(`${reason}: in-process work returned to the station queue.`, false);
    } else if (action === "up") {
      await post(`/api/machines/${button.dataset.id}/up`);
      await refresh();
      setNotice("Machine is idle and can take the next queued job.", false);
    }
  } catch (error) {
    setNotice(error.message, true);
  } finally {
    busy = false;
    document.querySelectorAll("button").forEach((item) => {
      item.disabled = false;
    });
  }
}

document.body.addEventListener("click", (event) => {
  const button = event.target.closest("[data-action]");
  if (!button) return;
  act(button);
});

showLanBanner();
refresh().catch((error) => setNotice(error.message, true));
