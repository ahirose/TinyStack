import re
import sys
from pathlib import Path
from typing import Any, Optional

from config import TINYLLM_MODEL, TINYLLM_PKG

if str(TINYLLM_PKG) not in sys.path:
    sys.path.insert(0, str(TINYLLM_PKG))


class LLMService:
    def __init__(self):
        self._model = None
        self._tokenizer = None
        self._device = None
        self._available = False
        self._load_error: Optional[str] = None

    def _ensure_model(self) -> bool:
        if self._model is not None:
            return True
        if not TINYLLM_MODEL.exists():
            self._load_error = f"Model not found: {TINYLLM_MODEL}"
            return False
        try:
            import contextlib
            import io

            import torch
            from inference import generate_text, load_model

            self._device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
            with contextlib.redirect_stdout(io.StringIO()):
                self._model, self._tokenizer = load_model(str(TINYLLM_MODEL), self._device)
            self._generate_text = generate_text
            self._available = True
            return True
        except Exception as exc:
            self._load_error = str(exc)
            return False

    @property
    def status(self) -> str:
        if self._ensure_model():
            return "ok"
        return f"unavailable: {self._load_error}"

    def build_nl_to_sql_prompt(
        self,
        nl_query: str,
        schema: dict[str, Any],
        examples: list[dict[str, Any]],
    ) -> str:
        schema_lines = []
        for table in schema.get("tables", []):
            cols = ", ".join(f"{c['name']} {c['type']}" for c in table.get("columns", []))
            schema_lines.append(f"- {table['name']}({cols})")
        for doc in schema.get("docs", []):
            schema_lines.append(
                f"  # {doc['table_name']}.{doc['column_name']}: {doc['description']}"
            )

        example_lines = []
        for ex in examples:
            example_lines.append(f"Q: {ex.get('nl_query')}\nSQL: {ex.get('sql_text')}")

        return (
            "[SYSTEM] You are a minirdb SQL generator. Output only CREATE/INSERT/SELECT.\n"
            "[SCHEMA]\n"
            + "\n".join(schema_lines)
            + "\n[EXAMPLES]\n"
            + ("\n".join(example_lines) if example_lines else "(none)")
            + f"\n[USER] {nl_query}\nSQL:"
        )

    def _extract_sql(self, text: str) -> str:
        patterns = [
            r"(SELECT\s+.+?;)",
            r"(INSERT\s+INTO\s+.+?;)",
            r"(CREATE\s+TABLE\s+.+?;)",
        ]
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE | re.DOTALL)
            if match:
                return match.group(1).strip()
        line = text.split("\n")[0].strip()
        if not line.endswith(";"):
            line += ";"
        return line

    def _rule_based_nl_to_sql(self, nl_query: str) -> Optional[str]:
        q = nl_query.lower()
        if "user" in q or "ユーザー" in q:
            if "all" in q or "全" in q or "一覧" in q or "表示" in q:
                return "SELECT * FROM users;"
        if "product" in q or "商品" in q:
            if "all" in q or "全" in q or "一覧" in q:
                return "SELECT * FROM products;"
            if "1000" in q or "安" in q:
                return "SELECT * FROM products WHERE price = 500;"
        if "count" in q or "数" in q:
            return "SELECT * FROM users;"
        return None

    def nl_to_sql(
        self,
        nl_query: str,
        schema: dict[str, Any],
        examples: list[dict[str, Any]],
    ) -> tuple[str, str, str]:
        prompt = self.build_nl_to_sql_prompt(nl_query, schema, examples)
        rule_sql = self._rule_based_nl_to_sql(nl_query)
        if rule_sql:
            return rule_sql, prompt, "rule_based"

        if not self._ensure_model():
            fallback = rule_sql or "SELECT * FROM users;"
            return fallback, prompt, "fallback"

        try:
            raw = self._generate_text(
                self._model,
                self._tokenizer,
                prompt,
                max_new_tokens=80,
                temperature=0.3,
                top_k=20,
                device=self._device,
                verbose=False,
            )
            generated = raw[len(prompt) :] if raw.startswith(prompt) else raw
            sql = self._extract_sql(generated)
            return sql, prompt, "llm"
        except Exception:
            fallback = rule_sql or "SELECT * FROM users;"
            return fallback, prompt, "fallback"

    def build_summarize_prompt(self, sql: str, rows: list[dict[str, Any]]) -> str:
        preview = rows[:5]
        return (
            "[SYSTEM] Summarize SQL query results in 2-3 sentences (Japanese or English).\n"
            f"[SQL] {sql}\n"
            f"[ROWS] {preview}\n"
            f"[TOTAL] {len(rows)} rows\n"
            "Summary:"
        )

    def summarize(self, sql: str, rows: list[dict[str, Any]]) -> tuple[str, str]:
        prompt = self.build_summarize_prompt(sql, rows)
        if not rows:
            return "No rows returned.", prompt

        if not self._ensure_model():
            summary = self._template_summary(sql, rows)
            return summary, prompt

        try:
            raw = self._generate_text(
                self._model,
                self._tokenizer,
                prompt,
                max_new_tokens=60,
                temperature=0.5,
                top_k=20,
                device=self._device,
                verbose=False,
            )
            generated = raw[len(prompt) :] if raw.startswith(prompt) else raw
            summary = generated.strip() or self._template_summary(sql, rows)
            return summary[:500], prompt
        except Exception:
            return self._template_summary(sql, rows), prompt

    def _template_summary(self, sql: str, rows: list[dict[str, Any]]) -> str:
        cols = list(rows[0].keys()) if rows else []
        return (
            f"Query returned {len(rows)} row(s) with columns: {', '.join(cols)}. "
            f"Executed: {sql.strip()}"
        )


llm_service = LLMService()
