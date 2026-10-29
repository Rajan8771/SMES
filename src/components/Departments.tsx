import { departments, type DepartmentId, type Focus } from "../content";

export function Departments({
  active,
  onPick,
}: {
  active: Focus;
  onPick: (id: DepartmentId) => void;
}) {
  return (
    <section className="sheet" id="departments">
      <div className="sheet-inner">
        <header className="sheet-head">
          <p className="eyebrow">Six ways in</p>
          <h2>Pick a counter.</h2>
          <p>
            The sculpture in the showroom rebuilds around the family you choose.
            Shelf stock changes by the day — these are the counters to ask for.
          </p>
        </header>
        <div className="ring-wrap">
          <div className="ring">
            {departments.map((dept, index) => (
              <button
                key={dept.id}
                type="button"
                style={{ ["--swatch" as string]: dept.swatch, ["--ink" as string]: dept.ink }}
                aria-pressed={active === dept.id}
                onClick={() => onPick(dept.id)}
              >
                <span className="card-face">
                  <span className="card-index">0{index + 1}</span>
                  <span>
                    <span className="card-kicker">{dept.kicker}</span>
                    <span className="card-title">{dept.title}</span>
                    <span className="card-blurb">{dept.blurb}</span>
                  </span>
                  <span className="card-go">Show in 3D</span>
                </span>
              </button>
            ))}
          </div>
        </div>
        <p className="ring-hint">Choose a counter. The showroom sculpture rebuilds around it.</p>
      </div>
    </section>
  );
}
