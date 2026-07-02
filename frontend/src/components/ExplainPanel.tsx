type Tab = "ast" | "prompt" | "vector" | "status";

interface Props {
  tab: Tab;
  onTabChange: (t: Tab) => void;
  ast: Record<string, unknown> | null;
  prompt: string;
  vectorResults: unknown;
  components: Record<string, string> | null;
}

export default function ExplainPanel({
  tab,
  onTabChange,
  ast,
  prompt,
  vectorResults,
  components,
}: Props) {
  return (
    <>
      <div className="panel-header">How It Works</div>
      <div className="explain-tabs">
        {(
          [
            ["ast", "Parser AST"],
            ["prompt", "LLM Prompt"],
            ["vector", "Vector Search"],
            ["status", "Components"],
          ] as const
        ).map(([id, label]) => (
          <button
            key={id}
            className={tab === id ? "active" : ""}
            onClick={() => onTabChange(id)}
          >
            {label}
          </button>
        ))}
      </div>
      <div className="panel-body">
        {tab === "ast" && (
          <pre className="trace-json">
            {ast ? JSON.stringify(ast, null, 2) : "Run SQL to see the parsed AST from minirdb/parser.py"}
          </pre>
        )}
        {tab === "prompt" && (
          <pre className="trace-json">
            {prompt || "Generate SQL from natural language to see the TinyLLM prompt"}
          </pre>
        )}
        {tab === "vector" && (
          <pre className="trace-json">
            {vectorResults
              ? JSON.stringify(vectorResults, null, 2)
              : "Similar query results appear here after NL input"}
          </pre>
        )}
        {tab === "status" && (
          <pre className="trace-json">
            {components
              ? JSON.stringify(components, null, 2)
              : "Loading component status..."}
          </pre>
        )}
      </div>
    </>
  );
}
