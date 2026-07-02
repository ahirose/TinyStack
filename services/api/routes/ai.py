import uuid

from fastapi import APIRouter

from schemas.models import (
    NLToSQLRequest,
    NLToSQLResponse,
    SummarizeRequest,
    SummarizeResponse,
)
from services.db_service import db_service
from services.llm_service import llm_service
from services.trace_service import trace_service
from services.vector_service import vector_service

router = APIRouter(prefix="/api/ai", tags=["ai"])


@router.post("/nl-to-sql", response_model=NLToSQLResponse)
def nl_to_sql(body: NLToSQLRequest) -> NLToSQLResponse:
    request_id = str(uuid.uuid4())
    schema = db_service.list_schema()
    history = db_service.get_query_history()
    similar = vector_service.find_similar_queries(body.query, history, top_k=3)
    sql, prompt, source = llm_service.nl_to_sql(body.query, schema, similar)
    trace_service.save(
        request_id,
        {
            "type": "nl_to_sql",
            "query": body.query,
            "prompt": prompt,
            "sql": sql,
            "source": source,
            "similar_examples": similar,
        },
    )
    return NLToSQLResponse(
        request_id=request_id,
        sql=sql,
        prompt=prompt,
        similar_examples=similar,
        source=source,
    )


@router.post("/summarize", response_model=SummarizeResponse)
def summarize(body: SummarizeRequest) -> SummarizeResponse:
    request_id = str(uuid.uuid4())
    summary, prompt = llm_service.summarize(body.sql, body.rows)
    trace_service.save(
        request_id,
        {
            "type": "summarize",
            "sql": body.sql,
            "row_count": len(body.rows),
            "prompt": prompt,
            "summary": summary,
        },
    )
    return SummarizeResponse(request_id=request_id, summary=summary, prompt=prompt)


from pydantic import BaseModel


class SaveHistoryRequest(BaseModel):
    nl_query: str
    sql_text: str


@router.post("/save-history")
def save_history(body: SaveHistoryRequest) -> dict:
    db_service.save_query_history(body.nl_query, body.sql_text)
    return {"status": "ok"}
