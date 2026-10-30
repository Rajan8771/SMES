import { cv, profile } from "../content";

export function Contact() {
  return (
    <section className="visit" id="contact">
      <div className="visit-inner">
        <div className="enamel-sign">
          <span>rj_suman_mes</span>
          <strong>Get in touch.</strong>
        </div>
        <div className="visit-grid">
          <article className="address-card">
            <p className="eyebrow">Contact</p>
            <h2>{profile.name}</h2>
            <p>{profile.role}</p>
            <dl>
              <div>
                <dt>Email</dt>
                <dd>
                  <a href={`mailto:${profile.email}`}>{profile.email}</a>
                </dd>
              </div>
              <div>
                <dt>Phone</dt>
                <dd>
                  {profile.phones.map((phone) => (
                    <a key={phone.tel} href={`tel:${phone.tel}`}>
                      {phone.display}
                    </a>
                  ))}
                </dd>
              </div>
              <div>
                <dt>Location</dt>
                <dd>
                  {profile.place}
                  <br />
                  {profile.region}
                </dd>
              </div>
            </dl>
            <div className="cta-row">
              <a className="btn" href={cv.href} download={cv.filename}>
                Download my CV
              </a>
              <a className="btn btn-cyan" href={profile.maps} target="_blank" rel="noreferrer">
                Map
              </a>
            </div>
          </article>
          <div className="map-frame">
            <iframe
              title="Map of Alfa-II, Greater Noida"
              src={profile.mapEmbed}
              loading="lazy"
              referrerPolicy="no-referrer-when-downgrade"
            />
          </div>
        </div>
      </div>
    </section>
  );
}
