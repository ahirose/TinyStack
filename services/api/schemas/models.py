from typing import Any, Optional

from pydantic import BaseModel, Field


class SQLExecuteRequest(BaseModel):
    sql: str


class SQLExecuteResponse(BaseModel):
    request_id: str
    ast: dict[str, Any]
    result: dict[str, Any]
    error: Optional[str] = None


class SchemaTable(BaseModel):
    name: str
    columns: list[dict[str, str]]


class SchemaResponse(BaseModel):
    tables: list[SchemaTable]
    docs: list[dict[str, str]] = Field(default_factory=list)


class NLToSQLRequest(BaseModel):
    query: str


class NLToSQLResponse(BaseModel):
    request_id: str
    sql: str
    prompt: str
    similar_examples: list[dict[str, Any]] = Field(default_factory=list)
    source: str = "llm"


class SummarizeRequest(BaseModel):
    sql: str
    rows: list[dict[str, Any]]


class SummarizeResponse(BaseModel):
    request_id: str
    summary: str
    prompt: str


class SimilarQueryItem(BaseModel):
    id: int
    nl_query: str
    sql_text: str
    score: float


class SimilarQueriesResponse(BaseModel):
    query: str
    results: list[SimilarQueryItem]


class TraceResponse(BaseModel):
    request_id: str
    trace: dict[str, Any]


class HealthResponse(BaseModel):
    status: str
    components: dict[str, str]
