export const site = {
  name: "rj_suman_mes",
};

export const cv = {
  href: "/Rajan-Suman-Resume.pdf",
  filename: "Rajan Suman_Resume_P2.pdf",
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

export type InterviewTopicId = "mes" | "sql" | "network" | "factory";

export type InterviewQuestion = {
  q: string;
  a: string;
};

export type InterviewTopic = {
  id: InterviewTopicId;
  title: string;
  swatch: string;
  ink: string;
  questions: InterviewQuestion[];
};

export const interviewTopics: InterviewTopic[] = [
  {
    id: "mes",
    title: "MES",
    swatch: "#1bd176",
    ink: "#042414",
    questions: [
      {
        q: "What is an MES?",
        a: "A Manufacturing Execution System sits between the plan in ERP and the machines on the floor. It tracks orders, materials, routes, and what each unit did, while the line is running.",
      },
      {
        q: "What has to exist before an order can run?",
        a: "The line, the product, the route or flow, and the material setup. If any one of those is missing, the order has nowhere to go.",
      },
      {
        q: "How is MES different from ERP?",
        a: "ERP decides what should be built and when. MES records what the line actually built, which station did it, and which material lot was used.",
      },
      {
        q: "What does L1 and L2 support mean on an MES desk?",
        a: "L1 is the first check: is the station up, is the order released, is the scanner talking. L2 goes into configuration, data, and the integration that L1 cannot fix at the terminal.",
      },
    ],
  },
  {
    id: "sql",
    title: "SQL",
    swatch: "#49d2ff",
    ink: "#042433",
    questions: [
      {
        q: "Where does WHERE stop and HAVING start?",
        a: "WHERE filters rows before they are grouped. HAVING filters the groups after GROUP BY. A salary cutoff on each row is WHERE. An average-salary cutoff per department is HAVING.",
      },
      {
        q: "What does a LEFT JOIN keep that an INNER JOIN drops?",
        a: "LEFT JOIN keeps every row from the left table. Where the right table has no match, those columns are NULL. INNER JOIN keeps only rows that match on both sides.",
      },
      {
        q: "Why would you write a stored procedure?",
        a: "The same multi-step change — validate, update, write a log — can live in the database and be called by name. The grants sit on the procedure instead of on every table.",
      },
      {
        q: "How is COUNT(*) different from COUNT(column)?",
        a: "COUNT(*) counts rows. COUNT(column) skips rows where that column is NULL. A nullable serial number will make the two counts disagree.",
      },
    ],
  },
  {
    id: "network",
    title: "Network",
    swatch: "#ffd23f",
    ink: "#2a2100",
    questions: [
      {
        q: "What is DNS for?",
        a: "DNS turns a name into an address. The MES client asks for a server by name. DNS answers with the IP the packets should use.",
      },
      {
        q: "What does Active Directory hold?",
        a: "Accounts, groups, and the policy that says who may sign in to a line PC. A new engineer gets a group, not a shared password.",
      },
      {
        q: "When do you set a static IP?",
        a: "Printers, scanners, and gateways that other systems call by address stay on a static IP or a reservation. A DHCP lease that moves will break the station that stored the old address.",
      },
    ],
  },
  {
    id: "factory",
    title: "Factory",
    swatch: "#ff4f9a",
    ink: "#2a0016",
    questions: [
      {
        q: "What is SMT in one line?",
        a: "Surface Mount Technology places components onto a board. The MES cares which program, which reel, and which board passed that placement.",
      },
      {
        q: "Why are printers and scanners on the same line as the MES?",
        a: "The scanner reads the unit. The printer writes the label the next station will read. If either one is down, traceability stops even when the machine is still placing parts.",
      },
      {
        q: "What is a practical first step when a station stops scanning?",
        a: "Check the cable or the TCP port, the IP of the scanner, and whether the MES station is the one the order was released to. Most stops are path and setup, not a new defect in the board.",
      },
    ],
  },
];

export const interviewPortals = [
  {
    name: "This site",
    href: "#interview",
    note: "MES, SQL, network, and factory questions on this page.",
    external: false,
  },
  {
    name: "Rajan Suman portfolio",
    href: "https://rajansuman007.bolt.host/",
    note: "MES software engineer profile, projects, and contact.",
    external: true,
  },
  {
    name: "InterviewBit SQL",
    href: "https://www.interviewbit.com/sql-interview-questions/",
    note: "Long SQL question bank with short answers.",
    external: true,
  },
  {
    name: "LeetCode SQL 50",
    href: "https://leetcode.com/studyplan/top-sql-50/",
    note: "Fifty SQL problems, basic through intermediate.",
    external: true,
  },
  {
    name: "GeeksforGeeks SQL",
    href: "https://www.geeksforgeeks.org/data-science/sql-question-for-data-science-interview/",
    note: "Joins, grouping, and query patterns with examples.",
    external: true,
  },
];

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
