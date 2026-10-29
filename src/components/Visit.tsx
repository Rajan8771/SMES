import { shop } from "../content";

export function Visit() {
  return (
    <section className="visit" id="visit">
      <div className="visit-inner">
        <div className="enamel-sign">
          <span>Kasna counter</span>
          <strong>Come by the road.</strong>
        </div>
        <div className="visit-grid">
          <article className="address-card">
            <p className="eyebrow">The shop</p>
            <h2>{shop.name}</h2>
            <dl>
              <div>
                <dt>Listed as</dt>
                <dd>{shop.category}</dd>
              </div>
              <div>
                <dt>Address</dt>
                <dd>
                  {shop.street}
                  <br />
                  {shop.region}
                </dd>
              </div>
              <div>
                <dt>Phone</dt>
                <dd>
                  <a href={`tel:${shop.phoneTel}`}>{shop.phoneDisplay}</a>
                </dd>
              </div>
            </dl>
            <p className="fine">
              Hours are not on the public listing. Call the counter before a special trip, and ask for the material by name.
            </p>
            <div className="cta-row">
              <a className="btn" href={`tel:${shop.phoneTel}`}>
                Call {shop.phoneDisplay}
              </a>
              <a className="btn btn-cyan" href={shop.maps} target="_blank" rel="noreferrer">
                Directions
              </a>
            </div>
          </article>
          <div className="map-frame">
            <iframe
              title="Map of Haryana Sanitary Hardware and Mill Store on Surajpur Kasna Road"
              src={shop.mapEmbed}
              loading="lazy"
              referrerPolicy="no-referrer-when-downgrade"
            />
          </div>
        </div>
      </div>
    </section>
  );
}
