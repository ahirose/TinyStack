const STEPS = [
  {
    title: "minimalRDBMS",
    body: "SQL is parsed into an AST, executed by Executor, and persisted via append-only Storage.",
  },
  {
    title: "TinyLLM",
    body: "Natural language queries become SQL prompts. Results can be summarized by the tiny transformer.",
  },
  {
    title: "TinyVectorizer",
    body: "Past queries are embedded with sentence-transformers for semantic similarity search.",
  },
  {
    title: "TinyContainer",
    body: "Deploy API, LLM, and frontend in isolated Linux namespaces (see deploy/tinycontainer/).",
  },
];

interface Props {
  step: number;
  onNext: () => void;
  onClose: () => void;
}

export default function ArchitectureTour({ step, onNext, onClose }: Props) {
  const current = STEPS[step];
  const isLast = step >= STEPS.length - 1;

  return (
    <div className="tour-overlay">
      <div className="tour-card">
        <h2>
          Architecture Tour ({step + 1}/{STEPS.length})
        </h2>
        <h3>{current.title}</h3>
        <p>{current.body}</p>
        <div className="actions">
          {!isLast ? (
            <button onClick={onNext}>Next</button>
          ) : (
            <button onClick={onClose}>Start Playground</button>
          )}
          <button className="secondary" onClick={onClose}>
            Skip
          </button>
        </div>
      </div>
    </div>
  );
}
