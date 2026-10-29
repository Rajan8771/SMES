import { departmentById, departments, type Focus } from "../content";

export function Showroom({
  focus,
  onFocus,
}: {
  focus: Focus;
  onFocus: (focus: Focus) => void;
}) {
  const dept = departmentById(focus);
  const heading = dept ? dept.title : "The whole lineup, spinning.";
  const copy = dept
    ? dept.detail
    : "Find, Reno, the A series, Enco, and the camera island share one sculpture. Move the cursor and it turns with you.";

  return (
    <section className="showroom" id="showroom">
      <div className="showroom-copy">
        <p className="eyebrow light">Live showroom</p>
        <h2>{heading}</h2>
        <p>{copy}</p>
        <p className="sr-only" aria-live="polite">
          Showing {heading}
        </p>
        <div className="pills" role="group" aria-label="Show a department in 3D">
          <button
            type="button"
            className="pill"
            aria-pressed={focus === "all"}
            onClick={() => onFocus("all")}
          >
            Everything
          </button>
          {departments.map((item) => (
            <button
              key={item.id}
              type="button"
              className="pill"
              style={{ ["--swatch" as string]: item.swatch, ["--ink" as string]: item.ink }}
              aria-pressed={focus === item.id}
              onClick={() => onFocus(item.id)}
            >
              {item.title}
            </button>
          ))}
        </div>
      </div>
    </section>
  );
}
