# TinyStack

Educational full-stack SQL + AI platform combining:

- [minimalRDBMS](https://github.com/ahirose/minimalRDBMS) — minimal relational database
- [TinyLLM](https://github.com/ahirose/TinyLLM) — transformer language model
- [TinyVectorizer](https://github.com/ahirose/TinyVectorizer) — semantic embeddings
- [TinyContainer](https://github.com/ahirose/TinyContainer) — Linux container learning scripts

## Features

- Web SQL Playground with AST visualization (minirdb parser output)
- Natural language → SQL with TinyLLM (confirm before execute)
- Query result summarization
- Similar query search via TinyVectorizer
- Multi-container deployment scripts (TinyContainer step7 pattern)

## Quick Start (Local Dev)

### Prerequisites

- Python 3.11+
- Node.js 20+

### 1. Clone with submodules

```bash
git clone --recurse-submodules https://github.com/ahirose/TinyStack.git
cd TinyStack
```

If already cloned:

```bash
git submodule update --init --recursive
```

### 2. Install API dependencies

```bash
python -m venv .venv
# Windows
.venv\Scripts\activate
# Linux/macOS
source .venv/bin/activate

pip install fastapi uvicorn pydantic torch sentence-transformers
```

### 3. Start API

```bash
cd services/api
python main.py
```

API: http://localhost:8000  
Health: http://localhost:8000/health

### 4. Start Frontend

```bash
cd frontend
npm install
npm run dev
```

UI: http://localhost:5173

## Demo Flow

1. Open the Playground — Architecture Tour on first visit
2. Run `SELECT * FROM users;` — see AST in Explain panel
3. Type "Show all users" in NL panel — Generate SQL — confirm insert
4. Run generated SQL — view TinyLLM summary
5. Check Components tab for service status

## Docker Compose (WSL2 / Linux)

```bash
cd deploy/dev
docker compose up --build
```

- Frontend: http://localhost:5173
- API: http://localhost:8000

## TinyContainer Deployment (WSL2 / Linux)

```bash
cd packages/tinycontainer/shell_version
chmod +x *.sh
./setup_rootfs.sh

cd ../../../deploy/tinycontainer
chmod +x *.sh
./run_all.sh
```

Attach to a container:

```bash
sudo nsenter --target <PID> --pid --mount --uts --net /bin/sh
```

See [docs/learning-path.md](docs/learning-path.md) for the recommended reading order.

## Project Structure

```
TinyStack/
├── packages/          # git submodules (minirdb, tinyllm, vectorizer, tinycontainer)
├── services/api/      # FastAPI backend
├── frontend/          # React + Monaco SQL editor
├── bootstrap/         # Sample database seed SQL
├── deploy/            # Docker + TinyContainer scripts
└── docs/              # Architecture and learning guides
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/sql/execute` | Execute SQL, return AST + rows |
| GET | `/api/sql/schema` | List tables and schema docs |
| POST | `/api/ai/nl-to-sql` | Natural language → SQL |
| POST | `/api/ai/summarize` | Summarize query results |
| GET | `/api/meta/similar-queries?q=` | Semantic query search |
| GET | `/api/meta/trace/{id}` | Request trace for learning |
| GET | `/health` | Component health |

## Notes

- TinyLLM submodule uses branch `claude/simple-transformer-llm-01GmUrtoHTtU8jK7XU4TD1gg`
- minirdb supports CREATE, INSERT, SELECT only (educational scope)
- Generated SQL is never auto-executed — user must confirm
- TinyContainer requires Linux or WSL2 with sudo

## License

Educational use. See individual submodule repositories for their licenses.
