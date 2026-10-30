import { education } from "../content";

export function Education() {
  return (
    <section className="sheet" id="education">
      <div className="sheet-inner">
        <header className="sheet-head">
          <p className="eyebrow">Education</p>
          <h2>College and training.</h2>
        </header>
        <ol className="edu-list">
          {education.map((item) => (
            <li key={item.title}>
              <div>
                <strong>{item.title}</strong>
                <span>{item.place}</span>
              </div>
              <div className="edu-meta">
                <span>{item.note}</span>
                <span>{item.when}</span>
              </div>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}
