import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional

from config import BOOTSTRAP_SQL, DATA_DIR, MINIRDB_PKG

if str(MINIRDB_PKG) not in sys.path:
    sys.path.insert(0, str(MINIRDB_PKG))

from minirdb import Executor, Storage, parse_sql  # noqa: E402


class DBService:
    def __init__(self, data_dir: Optional[Path] = None):
        self.data_dir = Path(data_dir or DATA_DIR)
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.storage = Storage(str(self.data_dir))
        self.executor = Executor(self.storage)
        self._bootstrapped = False

    def ensure_bootstrap(self) -> None:
        if self._bootstrapped:
            return
        marker = self.data_dir / ".bootstrapped"
        if marker.exists():
            self._bootstrapped = True
            return
        if not BOOTSTRAP_SQL.exists():
            self._bootstrapped = True
            marker.touch()
            return
        text = BOOTSTRAP_SQL.read_text(encoding="utf-8")
        for part in text.split(";"):
            stmt = part.strip()
            if not stmt or stmt.startswith("--"):
                continue
            try:
                ast = parse_sql(stmt + ";")
                self.executor.execute(ast)
            except Exception:
                pass
        marker.touch()
        self._bootstrapped = True

    def execute(self, sql: str) -> tuple[dict[str, Any], dict[str, Any]]:
        normalized = sql.strip()
        if not normalized.endswith(";"):
            normalized += ";"
        ast = parse_sql(normalized)
        result = self.executor.execute(ast)
        return ast, result

    def list_schema(self) -> dict[str, Any]:
        tables: list[dict[str, Any]] = []
        for filename in os.listdir(self.data_dir):
            if not filename.endswith(".schema.json"):
                continue
            table = filename.replace(".schema.json", "")
            schema_path = self.data_dir / filename
            with open(schema_path, encoding="utf-8") as f:
                schema = json.load(f)
            tables.append({"name": table, "columns": schema.get("columns", [])})

        docs: list[dict[str, str]] = []
        if self.storage.table_exists("schema_docs"):
            docs_rows = self.storage.select("schema_docs")
            for row in docs_rows:
                docs.append(
                    {
                        "table_name": str(row.get("table_name", "")),
                        "column_name": str(row.get("column_name", "")),
                        "description": str(row.get("description", "")),
                    }
                )
        return {"tables": tables, "docs": docs}

    def get_query_history(self) -> list[dict[str, Any]]:
        if not self.storage.table_exists("query_history"):
            return []
        return self.storage.select("query_history")

    def save_query_history(self, nl_query: str, sql_text: str) -> None:
        if not self.storage.table_exists("query_history"):
            return
        rows = self.storage.select("query_history")
        next_id = max((int(r.get("id") or 0) for r in rows), default=0) + 1
        now = datetime.now(timezone.utc).isoformat()
        self.storage.insert(
            "query_history",
            {
                "id": next_id,
                "nl_query": nl_query,
                "sql_text": sql_text,
                "created_at": now,
            },
        )


db_service = DBService()
