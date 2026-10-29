import { company, site, ticker } from "../content";

export function Hero() {
  return (
    <section className="hero" id="top">
      <div className="hero-copy">
        <p className="kicker">
          <span className="dots" aria-hidden="true">
            <i />
            <i />
            <i />
            <i />
            <i />
          </span>
          <span className="handle">{site.name}</span> · India
        </p>
        <h1>
          <span className="sr-only">
            {site.name}. {company.spoken}. {company.name}.{" "}
          </span>
          <span className="display">
            Colour,
            <br />
            glass &amp;
            <br />
            <span className="pop">signal.</span>
          </span>
        </h1>
        <p className="lede">
          <strong>{site.name}</strong> for <strong>{company.spoken}</strong> —{" "}
          {company.name}, the company behind OPPO phones in India. Registered
          office: {company.floor}, {company.street}, {company.region}.
        </p>
        <div className="cta-row">
          <a className="btn" href={company.site} target="_blank" rel="noreferrer">
            oppo.com/in
          </a>
          <a className="btn btn-cyan" href={`tel:${company.phoneTel}`}>
            Call the office
          </a>
          <a className="text-link" href="#departments">
            See the lineup
          </a>
        </div>
      </div>
    </section>
  );
}

export function Marquee() {
  const loop = [...ticker, ...ticker];
  return (
    <div className="marquee" aria-hidden="true">
      <div className="marquee-track">
        {loop.map((item, index) => (
          <span key={`${item}-${index}`}>{item}</span>
        ))}
      </div>
    </div>
  );
}
