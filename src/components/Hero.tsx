import { cv, profile, site, ticker } from "../content";

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
          <span className="handle">{site.name}</span> · Greater Noida
        </p>
        <h1>
          <span className="sr-only">
            {profile.name}. {profile.role}.
          </span>
          <span className="display">
            Rajan
            <br />
            Suman
            <br />
            <span className="pop">MES.</span>
          </span>
        </h1>
        <p className="lede">
          {profile.role} at OPPO Mobiles India Pvt. Ltd. Manufacturing execution
          systems, database work, and smart-factory support on the SMT line.
          Based in {profile.place}.
        </p>
        <div className="cta-row">
          <a className="btn" href={cv.href} download={cv.filename}>
            Download my CV
          </a>
          <a className="btn btn-cyan" href={`mailto:${profile.email}`}>
            Email
          </a>
          <a className="text-link" href={`tel:${profile.phones[0].tel}`}>
            {profile.phones[0].display}
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
