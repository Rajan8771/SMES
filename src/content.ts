export const site = {
  name: "rj_suman_mes",
};

export const cv = {
  href: "/Rajan-Suman-Resume.pdf",
  filename: "Rajan Suman_Resume_P2.pdf",
};

export const profile = {
  name: "Rajan Suman",
  role: "MES Software Engineer",
  email: "sumank208@gmail.com",
  place: "Alfa-II, Greater Noida",
  region: "Uttar Pradesh 201308",
  maps: "https://www.google.com/maps/search/?api=1&query=Alfa-II+Greater+Noida+Uttar+Pradesh+201308",
  mapEmbed:
    "https://maps.google.com/maps?q=Alfa-II,+Greater+Noida,+Uttar+Pradesh+201308&z=13&output=embed",
  phones: [
    { display: "+91 9038695782", tel: "+919038695782" },
    { display: "+91 9905943006", tel: "+919905943006" },
  ],
};

export type ModelId = "line" | "signal" | "data" | "study";

export type Focus =
  | "all"
  | "mes"
  | "rf"
  | "database"
  | "network"
  | "hardware"
  | "study";

export function modelFor(focus: Focus): ModelId | "all" {
  if (focus === "mes" || focus === "hardware") return "line";
  if (focus === "rf" || focus === "network") return "signal";
  if (focus === "database") return "data";
  if (focus === "study") return "study";
  return "all";
}

export type Role = {
  id: "mes" | "rf";
  title: string;
  org: string;
  place: string;
  when: string;
  swatch: string;
  points: string[];
};

export const roles: Role[] = [
  {
    id: "mes",
    title: "MES Software Engineer",
    org: "OPPO Mobiles India Pvt. Ltd.",
    place: "Surface Mount Technology (SMT)",
    when: "Jan 2021 – Present",
    swatch: "#1bd176",
    points: [
      "MES configuration for line, order, product, flow, and material setup.",
      "Database work in MySQL and PL/SQL: queries and stored procedures.",
      "Real-time monitoring and integration with manufacturing equipment.",
      "Root-cause analysis and troubleshooting of production issues.",
      "L1 and L2 support for MES application incidents.",
      "Network support: Active Directory, DNS, and IP configuration.",
      "Hardware setup for Zebra printers, scanners, and Honeywell devices.",
      "Smart Factory MOM implementation and monitoring.",
    ],
  },
  {
    id: "rf",
    title: "RF Engineer",
    org: "Telecom sector",
    place: "2G, 3G, and 4G LTE",
    when: "Sept 2015 – Dec 2020",
    swatch: "#ffd23f",
    points: [
      "Planning and optimization of TDD, FDD, Massive MIMO, and small cells.",
      "KPI analysis for Airtel 2G, 3G, and 4G LTE networks.",
      "Drive tests: SCFT and SSCVT of 4G VoLTE networks.",
      "RF survey and EMF survey execution.",
      "Network performance analysis, reporting, and complaint resolution.",
    ],
  },
];

export type Skill = {
  id: "mes" | "database" | "network" | "hardware";
  title: string;
  swatch: string;
  ink: string;
  items: string[];
};

export const skills: Skill[] = [
  {
    id: "mes",
    title: "MES and smart factory",
    swatch: "#1bd176",
    ink: "#042414",
    items: [
      "Smart Factory MOM (S-MES)",
      "EAP, VSKY, Kit Manager",
      "Nexim, Visiset",
      "Portable data terminals",
      "MES setup",
    ],
  },
  {
    id: "database",
    title: "Database",
    swatch: "#49d2ff",
    ink: "#042433",
    items: ["MySQL, Oracle, DBeaver", "PL/SQL", "IntelliJ IDEA", "Scripts, stored procedures, reporting"],
  },
  {
    id: "network",
    title: "IT and networking",
    swatch: "#ffd23f",
    ink: "#2a2100",
    items: ["Active Directory, DNS", "IP networks and gateways", "24/48-port switches", "IIS, ASM/ESET, Radmin"],
  },
  {
    id: "hardware",
    title: "Hardware",
    swatch: "#ff4f9a",
    ink: "#2a0016",
    items: ["Zebra printers", "Data Logic scanners", "USR TCP232", "Honeywell", "Windows XP through 11"],
  },
];

export const projects = [
  {
    title: "SMES PHX",
    role: "L2 MES Engineer",
    detail: "Support for collaboration between SMES, AMES, WMS, IPLAN, and ERP.",
    swatch: "#49d2ff",
  },
  {
    title: "Digital electronics design",
    role: "Final-year project",
    detail: "Digital electronics built with digital and analog instruments and ICs.",
    swatch: "#ffd23f",
  },
];

export const education = [
  {
    title: "B.Tech, ECE",
    place: "HETC, Hooghly, MAKAUT University",
    note: "70.6%",
    when: "2015",
  },
  {
    title: "12th",
    place: "R. Lal College, Alinagar, Nalanda, B.S.E.B",
    note: "60%",
    when: "2010",
  },
  {
    title: "10th",
    place: "High School, Barbigha, B.S.E.B",
    note: "68.2%",
    when: "2008",
  },
  {
    title: "SCADA technology training",
    place: "ITC Limited, Munger",
    note: "30 days",
    when: "June–July 2014",
  },
];

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
    name: "Earlier portfolio",
    href: "https://rajansuman007.bolt.host/",
    note: "The Bolt page. This site is the 3D profile.",
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
  "Rajan Suman",
  "MES Software Engineer",
  "OPPO Mobiles India",
  "SMT",
  "MySQL",
  "PL/SQL",
  "Smart Factory",
  "Greater Noida",
];
