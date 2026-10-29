import { company, site } from "../content";

export function Visit() {
  return (
    <section className="visit" id="visit">
      <div className="visit-inner">
        <div className="enamel-sign">
          <span>{site.name}</span>
          <strong>Gurugram office.</strong>
        </div>
        <div className="visit-grid">
          <article className="address-card">
            <p className="eyebrow">Registered office</p>
            <h2>{company.spoken}</h2>
            <dl>
              <div>
                <dt>Legal name</dt>
                <dd>{company.name}</dd>
              </div>
              <div>
                <dt>CIN</dt>
                <dd>{company.cin}</dd>
              </div>
              <div>
                <dt>Address</dt>
                <dd>
                  {company.floor}
                  <br />
                  {company.street}
                  <br />
                  {company.region}
                </dd>
              </div>
              <div>
                <dt>Office</dt>
                <dd>
                  <a href={`tel:${company.phoneTel}`}>{company.phoneDisplay}</a>
                </dd>
              </div>
              <div>
                <dt>Customer care</dt>
                <dd>
                  <a href={`tel:${company.careTel}`}>{company.careDisplay}</a>
                </dd>
              </div>
              <div>
                <dt>Email</dt>
                <dd>
                  <a href={`mailto:${company.email}`}>{company.email}</a>
                </dd>
              </div>
            </dl>
            <p className="fine">
              Page by {site.name}. Phones, prices, and service bookings are on the official OPPO India site.
            </p>
            <div className="cta-row">
              <a className="btn" href={company.site} target="_blank" rel="noreferrer">
                oppo.com/in
              </a>
              <a className="btn btn-cyan" href={company.maps} target="_blank" rel="noreferrer">
                Directions
              </a>
            </div>
          </article>
          <div className="map-frame">
            <iframe
              title="Map of OPPO Mobiles India Private Limited at DLF Cyber City, Gurugram"
              src={company.mapEmbed}
              loading="lazy"
              referrerPolicy="no-referrer-when-downgrade"
            />
          </div>
        </div>
      </div>
    </section>
  );
}
