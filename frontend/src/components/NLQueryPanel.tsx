interface Props {
  query: string;
  onChange: (q: string) => void;
  onGenerate: () => void;
  loading: boolean;
  similar: { nl_query: string; sql_text: string; score: number }[];
}

export default function NLQueryPanel({
  query,
  onChange,
  onGenerate,
  loading,
  similar,
}: Props) {
  return (
    <div style={{ marginTop: 16 }}>
      <div className="panel-header">Natural Language → SQL</div>
      <div className="panel-body">
        <textarea
          rows={3}
          placeholder="例: Show all users / 全ユーザーを表示"
          value={query}
          onChange={(e) => onChange(e.target.value)}
        />
        <div className="actions">
          <button onClick={onGenerate} disabled={loading || !query.trim()}>
            {loading ? "Generating..." : "Generate SQL"}
          </button>
        </div>
        {similar.length > 0 && (
          <>
            <p style={{ fontSize: 13, marginBottom: 4 }}>Similar past queries (TinyVectorizer):</p>
            <ul className="similar-list">
              {similar.map((s, i) => (
                <li key={i}>
                  <strong>{s.nl_query}</strong>
                  <br />
                  <code>{s.sql_text}</code>
                  <span className="badge">score {s.score.toFixed(3)}</span>
                </li>
              ))}
            </ul>
          </>
        )}
      </div>
    </div>
  );
}
