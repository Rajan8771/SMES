import { company, site } from "../content";

export function Footer() {
  return (
    <footer className="footer">
      <div className="footer-inner">
        <div>
          <p className="brand-name">{site.name}</p>
          <p>
            {company.name}
            <br />
            {company.floor}, {company.street}
            <br />
            {company.region}
          </p>
        </div>
        <div>
          <a href={`tel:${company.phoneTel}`}>{company.phoneDisplay}</a>
          <a href={company.site} target="_blank" rel="noreferrer">
            oppo.com/in
          </a>
        </div>
      </div>
    </footer>
  );
}
