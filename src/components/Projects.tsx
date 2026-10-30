import { projects } from "../content";

export function Projects() {
  return (
    <section className="sheet projects" id="projects">
      <div className="sheet-inner">
        <header className="sheet-head">
          <p className="eyebrow">Projects</p>
          <h2>Work that shipped.</h2>
        </header>
        <div className="project-grid">
          {projects.map((project) => (
            <article key={project.title} className="project-card" style={{ ["--swatch" as string]: project.swatch }}>
              <p className="card-kicker">{project.role}</p>
              <h3>{project.title}</h3>
              <p>{project.detail}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
