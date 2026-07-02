# TinyStack Architecture

TinyStack integrates four educational projects into a single full-stack platform.

## Component Map

| Layer | Project | Role |
|-------|---------|------|
| Data | minimalRDBMS | SQL parsing, execution, file-based storage |
| AI | TinyLLM | NL→SQL generation, result summarization |
| Search | TinyVectorizer | Semantic similarity over query history |
| Runtime | TinyContainer | Linux namespace-based multi-container deployment |

## Request Flow: SQL Execute

```
Browser → POST /api/sql/execute
       → minirdb.parser.parse_sql(sql) → AST
       → minirdb.executor.Executor.execute(ast)
       → minirdb.storage.Storage (JSON files in data/)
       ← { ast, result, request_id }
```

## Request Flow: NL → SQL

```
Browser → POST /api/ai/nl-to-sql
       → TinyVectorizer: find similar rows in query_history
       → Build prompt with schema + examples
       → TinyLLM generate (or rule-based fallback)
       ← { sql, prompt, similar_examples }  (user confirms before execute)
```

## Directory Layout

```
TinyStack/
├── packages/          # git submodules
├── services/api/      # FastAPI gateway
├── frontend/          # React SQL Playground
├── bootstrap/         # Initial SQL seed data
├── deploy/            # Docker Compose + TinyContainer scripts
└── data/              # minirdb runtime data (gitignored)
```

## Deployment Options

1. **Local dev**: `uvicorn` + `vite dev` (Windows/macOS/Linux)
2. **Docker Compose**: `deploy/dev/docker-compose.yml`
3. **TinyContainer** (auto-start): `deploy/tinycontainer/setup_platform.sh` then `run_all.sh`

### TinyContainer runtime (3 services)

```
Host (WSL2/Linux)
├── tinystack-llm   PID+UTS namespace, host Python, port 8001, cgroup memory limit
├── tinystack-api   Alpine chroot + PID/Mount/UTS, port 8000, calls LLM via HTTP
└── tinystack-web   Alpine chroot + nginx, port 8080, proxies /api → 8000
```

API sets `TINYSTACK_LLM_URL=http://127.0.0.1:8001` and delegates inference to the LLM worker.

## Design Constraints (Educational)

- minirdb: no transactions, single-user, CREATE/INSERT/SELECT only
- TinyLLM: small character-level model; rule-based fallback for reliable demos
- Generated SQL requires user confirmation before execution
