# 34×30 House — 3D Floor Plan

Interactive Three.js viewer for the residential layout:

- **Plot:** 34′ × 30′ (1020 sqft)
- **Basement:** parking, store, utility, multipurpose
- **First floor:** hall, 2 bedrooms, modular kitchen (SE Agni Kon), pooja, common NW bath block (Western + Indian WC + bathroom)
- **Gates:** North main, East secondary

## Run locally

```bash
cd house-3d
python3 -m http.server 8765 --bind 127.0.0.1
```

Open `http://127.0.0.1:8765`

## Controls

- Drag: orbit · Scroll: zoom · Right-drag: pan
- Floor view: Both / First Floor / Basement
- Exploded vs stacked levels
- Click a room (3D or legend) to focus
