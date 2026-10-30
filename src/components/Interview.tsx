import { useState } from "react";
import { interviewPortals, interviewTopics, type InterviewTopicId } from "../content";

export function Interview() {
  const [topicId, setTopicId] = useState<InterviewTopicId>("mes");
  const [open, setOpen] = useState(0);
  const topic = interviewTopics.find((item) => item.id === topicId) ?? interviewTopics[0];

  return (
    <section className="interview" id="interview">
      <div className="interview-inner">
        <header className="sheet-head">
          <p className="eyebrow">Interview Q&amp;A</p>
          <h2>Practice the desk.</h2>
          <p>
            Questions for an MES software seat: the line, the database, and the
            network around it. The cards below link this page, the portfolio, and
            the public SQL banks.
          </p>
        </header>

        <div className="pills interview-pills" role="group" aria-label="Interview topics">
          {interviewTopics.map((item) => (
            <button
              key={item.id}
              type="button"
              className="pill topic-pill"
              style={{ ["--swatch" as string]: item.swatch, ["--ink" as string]: item.ink }}
              aria-pressed={topic.id === item.id}
              onClick={() => {
                setTopicId(item.id);
                setOpen(0);
              }}
            >
              {item.title}
            </button>
          ))}
        </div>

        <div className="qa-list">
          {topic.questions.map((item, index) => {
            const expanded = open === index;
            return (
              <article key={item.q} className="qa" style={{ ["--swatch" as string]: topic.swatch }}>
                <h3>
                  <button
                    type="button"
                    aria-expanded={expanded}
                    onClick={() => setOpen(expanded ? -1 : index)}
                  >
                    <span>{item.q}</span>
                    <span aria-hidden="true">{expanded ? "–" : "+"}</span>
                  </button>
                </h3>
                {expanded ? <p>{item.a}</p> : null}
              </article>
            );
          })}
        </div>

        <h3 className="portal-title">Portal links</h3>
        <ul className="portal-grid">
          {interviewPortals.map((portal) => (
            <li key={portal.name}>
              <a
                href={portal.href}
                {...(portal.external
                  ? { target: "_blank", rel: "noreferrer" }
                  : {})}
              >
                <span className="portal-name">{portal.name}</span>
                <span>{portal.note}</span>
              </a>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
