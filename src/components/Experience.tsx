import { roles, type Focus } from "../content";

export function Experience({
  focus,
  onFocus,
}: {
  focus: Focus;
  onFocus: (focus: Focus) => void;
}) {
  const role = roles.find((item) => item.id === focus) ?? roles[0];

  return (
    <section className="showroom" id="experience">
      <div className="showroom-copy">
        <p className="eyebrow light">Experience</p>
        <h2>{role.title}</h2>
        <p>
          {role.org}
          <br />
          {role.place}
        </p>
        <p className="when-tag">{role.when}</p>
        <ul className="role-list">
          {role.points.map((point) => (
            <li key={point}>{point}</li>
          ))}
        </ul>
        <div className="pills" role="group" aria-label="Roles">
          {roles.map((item) => (
            <button
              key={item.id}
              type="button"
              className="pill"
              style={{ ["--swatch" as string]: item.swatch }}
              aria-pressed={role.id === item.id}
              onClick={() => onFocus(item.id)}
            >
              {item.when.startsWith("Jan") ? "OPPO MES" : "RF engineer"}
            </button>
          ))}
        </div>
      </div>
    </section>
  );
}
