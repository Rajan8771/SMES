import { lazy, Suspense, useEffect, useRef, useState } from "react";
import { Nav } from "./components/Nav";
import { Hero, Marquee } from "./components/Hero";
import { Experience } from "./components/Experience";
import { Skills } from "./components/Skills";
import { Projects } from "./components/Projects";
import { Education } from "./components/Education";
import { Interview } from "./components/Interview";
import { Contact } from "./components/Contact";
import { Footer } from "./components/Footer";
import type { Focus } from "./content";

const StoreScene = lazy(() =>
  import("./scene/StoreScene").then((module) => ({ default: module.StoreScene })),
);

const sectionFocus: Record<string, Focus> = {
  top: "all",
  experience: "mes",
  skills: "database",
  projects: "hardware",
  education: "study",
  interview: "database",
  contact: "all",
};

export default function App() {
  const [focus, setFocus] = useState<Focus>("all");
  const section = useRef("");

  useEffect(() => {
    const nodes = Object.keys(sectionFocus)
      .map((id) => document.getElementById(id))
      .filter((node): node is HTMLElement => Boolean(node));
    const observer = new IntersectionObserver(
      (entries) => {
        const hit = entries
          .filter((entry) => entry.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
        if (!hit || hit.target.id === section.current) return;
        section.current = hit.target.id;
        const next = sectionFocus[hit.target.id];
        if (next) setFocus(next);
      },
      { threshold: [0.4, 0.6] },
    );
    nodes.forEach((node) => observer.observe(node));
    return () => observer.disconnect();
  }, []);

  return (
    <>
      <a className="skip" href="#experience">
        Skip to experience
      </a>
      <Suspense fallback={null}>
        <StoreScene focus={focus} />
      </Suspense>
      <div className="page">
        <Nav />
        <main>
          <Hero />
          <Marquee />
          <Experience focus={focus} onFocus={setFocus} />
          <Skills focus={focus} onFocus={setFocus} />
          <Projects />
          <Education />
          <Interview />
          <Contact />
        </main>
        <Footer />
      </div>
    </>
  );
}
