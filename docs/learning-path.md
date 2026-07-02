# TinyStack Learning Path

Recommended order for understanding how TinyStack works, from infrastructure to UI.

## 1. minimalRDBMS (Data Layer)

Start with the lowest layer — how SQL becomes persisted rows.

1. Read `packages/minirdb/minirdb/storage.py` — append-only JSON files
2. Read `packages/minirdb/minirdb/parser.py` — regex-based SQL → AST
3. Read `packages/minirdb/minirdb/executor.py` — AST dispatch
4. Run REPL: `cd packages/minirdb && python -m minirdb.cli`
5. In TinyStack: execute SQL in the Playground and inspect **Parser AST** tab

## 2. TinyVectorizer (Semantic Search)

Understand embeddings before LLM integration.

1. Read `packages/vectorizer/vectorizer.py`
2. Run demo: `cd packages/vectorizer && python vectorizer.py`
3. In TinyStack: type a natural language query and watch **Vector Search** tab

## 3. TinyLLM (Language Model)

Learn transformer inference and text generation.

1. Read `packages/tinyllm/tiny_transformer.py` — model architecture
2. Read `packages/tinyllm/inference.py` — autoregressive generation
3. Run: `cd packages/tinyllm && python inference.py --prompt "Hello"`
4. In TinyStack: use **Generate SQL** and inspect **LLM Prompt** tab

## 4. TinyContainer (Runtime)

Learn Linux isolation primitives used by Docker/Kubernetes.

1. Read `packages/tinycontainer/shell_version/README.md`
2. Run steps 1–7 in `shell_version/`
3. Run `deploy/tinycontainer/run_all.sh` and attach with `nsenter`
4. Compare with `deploy/dev/docker-compose.yml` for production-like dev

## 5. TinyStack Integration

1. `services/api/services/db_service.py` — minirdb wrapper + bootstrap
2. `services/api/services/llm_service.py` — prompt building + generation
3. `services/api/services/vector_service.py` — similarity search
4. `frontend/src/pages/SQLPlayground.tsx` — full user flow

## Suggested Exercises

- Add a new table in `bootstrap/bootstrap.sql` and reload data
- Extend NL→SQL rule patterns in `llm_service.py`
- Add a fifth Explain tab showing raw trace from `/api/meta/trace/{id}`
- Implement veth networking between TinyContainer instances (see TinyContainer FAQ)
