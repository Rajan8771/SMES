import { shop } from "../content";

export function Footer() {
  return (
    <footer className="footer">
      <div className="footer-inner">
        <div>
          <p className="brand-name">{shop.name}</p>
          <p>
            {shop.street}
            <br />
            {shop.region}
          </p>
        </div>
        <div>
          <a href={`tel:${shop.phoneTel}`}>{shop.phoneDisplay}</a>
          <a href={shop.maps} target="_blank" rel="noreferrer">
            Open in Google Maps
          </a>
        </div>
      </div>
    </footer>
  );
}
