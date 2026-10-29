import { shop, ticker } from "../content";

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
          {shop.category} · Kasna
        </p>
        <h1>
          <span className="sr-only">{shop.name}. </span>
          <span className="display">
            Colour,
            <br />
            metal &amp;
            <br />
            <span className="pop">mill store.</span>
          </span>
        </h1>
        <p className="lede">
          <strong>{shop.name}</strong> sits on {shop.street}, {shop.region}. Come
          for sanitary ware, pipes, bath fittings, door hardware, tools, and the
          mixed mill-store counter.
        </p>
        <div className="cta-row">
          <a className="btn" href={`tel:${shop.phoneTel}`}>
            Call the counter
          </a>
          <a className="btn btn-cyan" href={shop.maps} target="_blank" rel="noreferrer">
            Get directions
          </a>
          <a className="text-link" href="#departments">
            See the counters
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
