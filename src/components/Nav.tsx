import { shop } from "../content";

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
          <span className="brand-name">{shop.short}</span>
          <span className="brand-sub">Hardware & Mill Store</span>
        </span>
      </a>
      <nav aria-label="Page">
        <a href="#departments">Departments</a>
        <a href="#showroom">Showroom</a>
        <a href="#visit">Visit</a>
      </nav>
      <a className="btn btn-small" href={`tel:${shop.phoneTel}`}>
        Call {shop.phoneDisplay}
      </a>
    </header>
  );
}
