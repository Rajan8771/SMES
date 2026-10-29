export const site = {
  name: "rj_suman_mes",
};

export const company = {
  name: "OPPO Mobiles India Private Limited",
  spoken: "OPPO Mobile India Pvt Ltd",
  short: "OPPO Mobile India",
  cin: "U74140HR2013PTC069892",
  floor: "5th Floor, Tower B, Building No. 8",
  street: "DLF Cyber City",
  region: "Gurugram, Haryana 122002",
  phoneDisplay: "0124 472 7700",
  phoneTel: "+911244727700",
  careDisplay: "1800 103 2777",
  careTel: "18001032777",
  email: "infoindia@oppo.com",
  site: "https://www.oppo.com/in",
  maps: "https://www.google.com/maps/search/?api=1&query=OPPO+Mobiles+India+Private+Limited+DLF+Cyber+City+Gurugram",
  mapEmbed:
    "https://maps.google.com/maps?q=28.495019,77.089281&z=16&output=embed",
};

export type DepartmentId = "find" | "reno" | "a" | "enco" | "camera" | "care";

export type ModelId = "phones" | "audio" | "camera" | "care";

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
    id: "find",
    model: "phones",
    title: "Find",
    kicker: "Flagship phones",
    blurb: "The Find line, OPPO’s top slab of glass and metal.",
    detail:
      "Find is the flagship family. Live specs and prices sit on oppo.com/in — this page only shows the shape.",
    swatch: "#1bd176",
    ink: "#042414",
  },
  {
    id: "reno",
    model: "phones",
    title: "Reno",
    kicker: "Portrait line",
    blurb: "Reno phones, the portrait series OPPO sells in India.",
    detail:
      "Reno is the portrait line. Open the official store for the model that is on sale this month.",
    swatch: "#ff4f9a",
    ink: "#2a0016",
  },
  {
    id: "a",
    model: "phones",
    title: "A series",
    kicker: "Everyday phones",
    blurb: "A-series phones for a daily pocket.",
    detail:
      "The A series is the everyday range. Colours and storage change by model — check oppo.com/in before you buy.",
    swatch: "#49d2ff",
    ink: "#042433",
  },
  {
    id: "enco",
    model: "audio",
    title: "Enco",
    kicker: "Audio",
    blurb: "Enco buds and neckbands that pair with an OPPO phone.",
    detail:
      "Enco is OPPO’s audio family. The sculpture is a case and a pair of buds, not a stock list.",
    swatch: "#ffd23f",
    ink: "#2a2100",
  },
  {
    id: "camera",
    model: "camera",
    title: "Camera",
    kicker: "The lens stack",
    blurb: "The camera island OPPO puts on the back of the phone.",
    detail:
      "Imaging is the raised camera island. Sensor names and zoom figures belong on the official product page.",
    swatch: "#ff5a1f",
    ink: "#2a0c00",
  },
  {
    id: "care",
    model: "care",
    title: "Care",
    kicker: "Service",
    blurb: "Support for a phone you already own.",
    detail:
      "Customer care is 1800 103 2777. The registered office phone is 0124 472 7700, and mail goes to infoindia@oppo.com.",
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
  "rj_suman_mes",
  "OPPO Mobile India",
  "Find",
  "Reno",
  "A series",
  "Enco",
  "Gurugram",
  "DLF Cyber City",
];
