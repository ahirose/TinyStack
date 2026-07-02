import { useCallback, useEffect, useState } from "react";
import {
  executeSQL,
  getSchema,
  getSimilarQueries,
  getComponents,
  nlToSQL,
  saveHistory,
  summarize,
  type SchemaResponse,
  type SQLExecuteResponse,
} from "../api";
import SQLEditor from "../components/SQLEditor";
import NLQueryPanel from "../components/NLQueryPanel";
import ExplainPanel from "../components/ExplainPanel";

type ExplainTab = "ast" | "prompt" | "vector" | "status";

const DEFAULT_SQL = "SELECT * FROM users;";

export default function SQLPlayground() {
  const [sql, setSql] = useState(DEFAULT_SQL);
  const [nlQuery, setNlQuery] = useState("");
  const [result, setResult] = useState<SQLExecuteResponse | null>(null);
  const [schema, setSchema] = useState<SchemaResponse | null>(null);
  const [summary, setSummary] = useState("");
  const [pendingSql, setPendingSql] = useState<string | null>(null);
  const [prompt, setPrompt] = useState("");
  const [vectorResults, setVectorResults] = useState<unknown>(null);
  const [components, setComponents] = useState<Record<string, string> | null>(null);
  const [explainTab, setExplainTab] = useState<ExplainTab>("ast");
  const [loading, setLoading] = useState(false);
  const [nlLoading, setNlLoading] = useState(false);
  const [lastNlQuery, setLastNlQuery] = useState("");
  const [similar, setSimilar] = useState<
    { nl_query: string; sql_text: string; score: number }[]
  >([]);

  useEffect(() => {
    getSchema().then(setSchema).catch(console.error);
    getComponents().then(setComponents).catch(console.error);
  }, []);

  useEffect(() => {
    if (!nlQuery.trim()) {
      setSimilar([]);
      return;
    }
    const t = setTimeout(() => {
      getSimilarQueries(nlQuery)
        .then((data) => {
          setSimilar(data.results ?? []);
          setVectorResults(data);
        })
        .catch(console.error);
    }, 400);
    return () => clearTimeout(t);
  }, [nlQuery]);

  const runSQL = useCallback(async () => {
    setLoading(true);
    setSummary("");
    try {
      const res = await executeSQL(sql);
      setResult(res);
      setExplainTab("ast");
      if (res.result.rows && res.result.rows.length > 0) {
        const sum = await summarize(sql, res.result.rows);
        setSummary(sum.summary);
        setPrompt(sum.prompt);
      }
      if (lastNlQuery) {
        await saveHistory(lastNlQuery, sql);
      }
    } finally {
      setLoading(false);
    }
  }, [sql, lastNlQuery]);

  const generateSQL = async () => {
    setNlLoading(true);
    try {
      const res = await nlToSQL(nlQuery);
      setPendingSql(res.sql);
      setPrompt(res.prompt);
      setSimilar(res.similar_examples ?? []);
      setVectorResults({ query: nlQuery, results: res.similar_examples });
      setExplainTab("prompt");
      setLastNlQuery(nlQuery);
    } finally {
      setNlLoading(false);
    }
  };

  const acceptPendingSql = () => {
    if (pendingSql) {
      setSql(pendingSql);
      setPendingSql(null);
    }
  };

  const rows = result?.result.rows ?? [];

  return (
    <div className="playground">
      <div className="panel">
        <div className="panel-header">SQL Editor (minimalRDBMS)</div>
        <div className="panel-body">
          <SQLEditor value={sql} onChange={setSql} />
          <div className="actions">
            <button onClick={runSQL} disabled={loading}>
              {loading ? "Running..." : "Run SQL"}
            </button>
          </div>
          {pendingSql && (
            <div className="summary-box" style={{ marginTop: 12 }}>
              <strong>Generated SQL (confirm before run):</strong>
              <pre>{pendingSql}</pre>
              <div className="actions">
                <button onClick={acceptPendingSql}>Insert into editor</button>
                <button className="secondary" onClick={() => setPendingSql(null)}>
                  Dismiss
                </button>
              </div>
            </div>
          )}
          <NLQueryPanel
            query={nlQuery}
            onChange={setNlQuery}
            onGenerate={generateSQL}
            loading={nlLoading}
            similar={similar}
          />
          {schema && (
            <div style={{ marginTop: 16 }}>
              <div className="panel-header">Schema</div>
              <ul className="schema-list">
                {schema.tables.map((t) => (
                  <li key={t.name}>
                    <strong>{t.name}</strong>:{" "}
                    {t.columns.map((c) => `${c.name} ${c.type}`).join(", ")}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      </div>

      <div className="panel">
        <div className="panel-header">Results</div>
        <div className="panel-body">
          {result?.error && <div className="error-box">{result.error}</div>}
          {rows.length > 0 ? (
            <table className="result-table">
              <thead>
                <tr>
                  {Object.keys(rows[0]).map((col) => (
                    <th key={col}>{col}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.map((row, i) => (
                  <tr key={i}>
                    {Object.values(row).map((val, j) => (
                      <td key={j}>{String(val ?? "")}</td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            result && !result.error && <p>No rows returned.</p>
          )}
          {summary && (
            <div className="summary-box">
              <strong>TinyLLM Summary:</strong>
              <p>{summary}</p>
            </div>
          )}
        </div>
      </div>

      <div className="panel">
        <ExplainPanel
          tab={explainTab}
          onTabChange={setExplainTab}
          ast={result?.ast ?? null}
          prompt={prompt}
          vectorResults={vectorResults}
          components={components}
        />
      </div>
    </div>
  );
}
