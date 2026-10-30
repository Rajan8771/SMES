import { skills, type Focus } from "../content";

export function Skills({
  focus,
  onFocus,
}: {
  focus: Focus;
  onFocus: (focus: Focus) => void;
}) {
  const skill = skills.find((item) => item.id === focus) ?? skills[0];

  return (
    <section className="showroom" id="skills">
      <div className="showroom-copy">
        <p className="eyebrow light">Skills</p>
        <h2>{skill.title}</h2>
        <ul className="role-list">
          {skill.items.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
        <div className="pills" role="group" aria-label="Skill groups">
          {skills.map((item) => (
            <button
              key={item.id}
              type="button"
              className="pill"
              style={{ ["--swatch" as string]: item.swatch, ["--ink" as string]: item.ink }}
              aria-pressed={skill.id === item.id}
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
