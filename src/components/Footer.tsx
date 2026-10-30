import { cv, profile, site } from "../content";

export function Footer() {
  return (
    <footer className="footer">
      <div className="footer-inner">
        <div>
          <p className="brand-name">{profile.name}</p>
          <p>
            {profile.role}
            <br />
            {site.name}
            <br />
            {profile.place}, {profile.region}
          </p>
        </div>
        <div>
          <a href={cv.href} download={cv.filename}>
            Download my CV
          </a>
          <a href={`mailto:${profile.email}`}>{profile.email}</a>
          <a href={`tel:${profile.phones[0].tel}`}>{profile.phones[0].display}</a>
          <a href="#contact">Contact</a>
          <a href="https://rajansuman007.bolt.host/" target="_blank" rel="noreferrer">
            Earlier portfolio
          </a>
        </div>
      </div>
    </footer>
  );
}
