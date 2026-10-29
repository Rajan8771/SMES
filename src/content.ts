export const shop = {
  name: "Haryana Sanitary Hardware and Mill Store",
  short: "Haryana Sanitary",
  category: "Hardware store",
  street: "Surajpur Kasna Road, Sadar",
  region: "Kasna, Greater Noida, Gautam Buddha Nagar, Uttar Pradesh",
  phoneDisplay: "086600 82752",
  phoneTel: "+918660082752",
  maps: "https://www.google.com/maps/search/?api=1&query=Haryana+Sanitary+Hardware+and+Mill+store+Surajpur+Kasna+Road+Sadar",
  mapEmbed:
    "https://maps.google.com/maps?q=Haryana%20Sanitary%20Hardware%20and%20Mill%20Store%20Surajpur%20Kasna%20Road%20Sadar&z=16&output=embed",
};

export type DepartmentId =
  | "sanitary"
  | "pipes"
  | "fittings"
  | "hardware"
  | "tools"
  | "mill";

export type ModelId = "sanitary" | "pipes" | "hardware" | "mill";

export type Focus = "all" | DepartmentId;

export type Department = {
  id: DepartmentId;
  model: ModelId;
  title: string;
  kicker: string;
  blurb: string;
  detail: string;
  swatch: string;
  ink: string;
};

export const departments: Department[] = [
  {
    id: "sanitary",
    model: "sanitary",
    title: "Sanitary ware",
    kicker: "Basins & pans",
    blurb: "Chinaware for a new bathroom or a straight replacement.",
    detail:
      "Basins, pans, and seat covers — the ceramic side of the counter. Ask which sizes are on the floor today.",
    swatch: "#49d2ff",
    ink: "#042433",
  },
  {
    id: "pipes",
    model: "pipes",
    title: "Pipes & lines",
    kicker: "Runs & joints",
    blurb: "Lines, elbows, and the pieces that join them.",
    detail:
      "Bring the old fitting if you can. Matching a thread at the counter is faster than describing it over the phone.",
    swatch: "#ff5a1f",
    ink: "#2a0c00",
  },
  {
    id: "fittings",
    model: "sanitary",
    title: "Bath fittings",
    kicker: "Taps & mixers",
    blurb: "The metal you actually touch: taps, showers, and connectors.",
    detail:
      "Faucets and bath fittings sit with the sanitary ware. Finishes change with what the counter has in.",
    swatch: "#ff4f9a",
    ink: "#2a0016",
  },
  {
    id: "hardware",
    model: "hardware",
    title: "Door hardware",
    kicker: "Locks & hinges",
    blurb: "Locks, hinges, tower bolts, and handles.",
    detail:
      "Door and window hardware for a house still being finished, or a hinge that has given up.",
    swatch: "#ffd23f",
    ink: "#2a2100",
  },
  {
    id: "tools",
    model: "hardware",
    title: "Tools & fasteners",
    kicker: "The small parts",
    blurb: "Hand tools, screws, anchors, and the bits that vanish mid-job.",
    detail:
      "Fasteners and hand tools. If the job is stuck on one odd size, call before you cross Kasna.",
    swatch: "#8dff63",
    ink: "#062406",
  },
  {
    id: "mill",
    model: "mill",
    title: "Mill-store mix",
    kicker: "The long counter",
    blurb: "Repair stock and the everyday odds and ends a mill store keeps in reach.",
    detail:
      "The board says mill store as well as hardware. That counter is the mixed one. Call and ask for the material by name.",
    swatch: "#c9a6ff",
    ink: "#1a0a33",
  },
];

export function modelFor(focus: Focus): ModelId | "all" {
  if (focus === "all") return "all";
  return departments.find((item) => item.id === focus)?.model ?? "all";
}

export function departmentById(focus: Focus): Department | undefined {
  if (focus === "all") return undefined;
  return departments.find((item) => item.id === focus);
}

export const ticker = [
  "Haryana Sanitary",
  "Hardware",
  "Mill store",
  "Pipes",
  "Fittings",
  "Taps",
  "Tools",
  "Kasna",
  "Surajpur Kasna Road",
  "Sadar",
];
