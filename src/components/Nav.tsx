import { cv, profile, site } from "../content";

const links = [
  ["#experience", "Experience"],
  ["#skills", "Skills"],
  ["#projects", "Projects"],
  ["#education", "Education"],
  ["#interview", "Interview"],
  ["#contact", "Contact"],
];

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
          <span className="brand-name">{profile.name}</span>
          <span className="brand-sub">{site.name}</span>
        </span>
      </a>
      <nav aria-label="Profile">
        {links.map(([href, label]) => (
          <a key={href} href={href}>
            {label}
          </a>
        ))}
      </nav>
      <a className="btn btn-small" href={cv.href} download={cv.filename}>
        Download CV
      </a>
    </header>
  );
}
