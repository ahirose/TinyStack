from typing import Any


class TraceService:
    def __init__(self, max_entries: int = 100):
        self._traces: dict[str, dict[str, Any]] = {}
        self._order: list[str] = []
        self.max_entries = max_entries

    def save(self, request_id: str, trace: dict[str, Any]) -> None:
        self._traces[request_id] = trace
        if request_id in self._order:
            self._order.remove(request_id)
        self._order.append(request_id)
        while len(self._order) > self.max_entries:
            old = self._order.pop(0)
            self._traces.pop(old, None)

    def get(self, request_id: str) -> dict[str, Any] | None:
        return self._traces.get(request_id)


trace_service = TraceService()
