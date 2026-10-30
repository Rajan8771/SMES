import { lazy, Suspense, useState } from "react";
import { Nav } from "./components/Nav";
import { Hero, Marquee } from "./components/Hero";
import { Departments } from "./components/Departments";
import { Showroom } from "./components/Showroom";
import { Visit } from "./components/Visit";
import { Interview } from "./components/Interview";
import { Footer } from "./components/Footer";
import type { DepartmentId, Focus } from "./content";

const StoreScene = lazy(() =>
  import("./scene/StoreScene").then((module) => ({ default: module.StoreScene })),
);

export default function App() {
  const [focus, setFocus] = useState<Focus>("all");

  function pick(id: DepartmentId) {
    setFocus(id);
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    document.getElementById("showroom")?.scrollIntoView({
      behavior: reduce ? "auto" : "smooth",
      block: "start",
    });
  }

  return (
    <>
      <a className="skip" href="#departments">
        Skip to counters
      </a>
      <Suspense fallback={null}>
        <StoreScene focus={focus} />
      </Suspense>
      <div className="page">
        <Nav />
        <main>
          <Hero />
          <Marquee />
          <Departments active={focus} onPick={pick} />
          <Showroom focus={focus} onFocus={setFocus} />
          <Interview />
          <Visit />
        </main>
        <Footer />
      </div>
    </>
  );
}
