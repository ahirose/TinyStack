export interface SQLExecuteResponse {
  request_id: string;
  ast: Record<string, unknown>;
  result: { status?: string; rows?: Record<string, unknown>[] };
  error?: string;
}

export interface SchemaResponse {
  tables: { name: string; columns: { name: string; type: string }[] }[];
  docs: { table_name: string; column_name: string; description: string }[];
}

export interface NLToSQLResponse {
  request_id: string;
  sql: string;
  prompt: string;
  similar_examples: { id: number; nl_query: string; sql_text: string; score: number }[];
  source: string;
}

export interface SummarizeResponse {
  request_id: string;
  summary: string;
  prompt: string;
}

export interface TraceData {
  request_id: string;
  trace: Record<string, unknown>;
}

export interface HealthResponse {
  status: string;
  components: Record<string, string>;
}

const API = "";

export async function executeSQL(sql: string): Promise<SQLExecuteResponse> {
  const res = await fetch(`${API}/api/sql/execute`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ sql }),
  });
  return res.json();
}

export async function getSchema(): Promise<SchemaResponse> {
  const res = await fetch(`${API}/api/sql/schema`);
  return res.json();
}

export async function nlToSQL(query: string): Promise<NLToSQLResponse> {
  const res = await fetch(`${API}/api/ai/nl-to-sql`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ query }),
  });
  return res.json();
}

export async function summarize(
  sql: string,
  rows: Record<string, unknown>[]
): Promise<SummarizeResponse> {
  const res = await fetch(`${API}/api/ai/summarize`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ sql, rows }),
  });
  return res.json();
}

export async function getSimilarQueries(q: string) {
  const res = await fetch(`${API}/api/meta/similar-queries?q=${encodeURIComponent(q)}`);
  return res.json();
}

export async function getTrace(requestId: string): Promise<TraceData> {
  const res = await fetch(`${API}/api/meta/trace/${requestId}`);
  return res.json();
}

export async function getHealth(): Promise<HealthResponse> {
  const res = await fetch(`${API}/health`);
  return res.json();
}

export async function saveHistory(nlQuery: string, sqlText: string) {
  await fetch(`${API}/api/meta/history`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ nl_query: nlQuery, sql_text: sqlText }),
  });
}

export async function getComponents() {
  const res = await fetch(`${API}/api/meta/components`);
  return res.json();
}
