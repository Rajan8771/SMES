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
          <a href="#interview">Interview Q&amp;A</a>
          <a href="https://rajansuman007.bolt.host/" target="_blank" rel="noreferrer">
            Portfolio
          </a>
        </div>
      </div>
    </footer>
  );
}
