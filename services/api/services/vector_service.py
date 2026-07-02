import sys
from typing import Any

from config import VECTORIZER_PKG

if str(VECTORIZER_PKG) not in sys.path:
    sys.path.insert(0, str(VECTORIZER_PKG))


class VectorService:
    def __init__(self):
        self._available = False
        self._load_error: str | None = None

    def _check(self) -> bool:
        if self._available:
            return True
        try:
            import vectorizer  # noqa: F401

            self._available = True
            return True
        except Exception as exc:
            self._load_error = str(exc)
            return False

    @property
    def status(self) -> str:
        if self._check():
            return "ok"
        return f"unavailable: {self._load_error}"

    def find_similar_queries(
        self, query: str, history: list[dict[str, Any]], top_k: int = 3
    ) -> list[dict[str, Any]]:
        if not history:
            return []
        if not self._check():
            return self._keyword_fallback(query, history, top_k)

        import vectorizer

        documents = [str(h.get("nl_query") or "") for h in history]
        try:
            query_emb = vectorizer.vectorize(query)
            from sentence_transformers import util

            doc_embs = [vectorizer.vectorize(d) for d in documents]
            import torch

            q = torch.tensor([query_emb])
            d = torch.tensor(doc_embs)
            sims = util.cos_sim(q, d)[0]
            ranked = sorted(
                enumerate(sims.tolist()),
                key=lambda x: x[1],
                reverse=True,
            )[:top_k]
            results = []
            for idx, score in ranked:
                row = history[idx]
                results.append(
                    {
                        "id": int(row.get("id") or idx),
                        "nl_query": str(row.get("nl_query") or ""),
                        "sql_text": str(row.get("sql_text") or ""),
                        "score": float(score),
                    }
                )
            return results
        except Exception:
            return self._keyword_fallback(query, history, top_k)

    def _keyword_fallback(
        self, query: str, history: list[dict[str, Any]], top_k: int
    ) -> list[dict[str, Any]]:
        q = query.lower()
        scored = []
        for row in history:
            nl = str(row.get("nl_query") or "").lower()
            overlap = sum(1 for word in q.split() if word in nl)
            scored.append((overlap, row))
        scored.sort(key=lambda x: x[0], reverse=True)
        results = []
        for score, row in scored[:top_k]:
            results.append(
                {
                    "id": int(row.get("id") or 0),
                    "nl_query": str(row.get("nl_query") or ""),
                    "sql_text": str(row.get("sql_text") or ""),
                    "score": float(score) / max(len(q.split()), 1),
                }
            )
        return results


vector_service = VectorService()
