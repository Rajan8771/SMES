import { company, site } from "../content";

export function Nav() {
  return (
    <header className="nav">
      <a className="brand" href="#top">
        <span className="mark" aria-hidden="true">
          <span className="cube">
            <i />
            <i />
            <i />
            <i />
            <i />
            <i />
          </span>
        </span>
        <span>
          <span className="brand-name">{site.name}</span>
          <span className="brand-sub">{company.short}</span>
        </span>
      </a>
      <nav aria-label="Page">
        <a href="#departments">Lineup</a>
        <a href="#showroom">Showroom</a>
        <a href="#visit">Visit</a>
      </nav>
      <a className="btn btn-small" href={`tel:${company.phoneTel}`}>
        Call {company.phoneDisplay}
      </a>
    </header>
  );
}
