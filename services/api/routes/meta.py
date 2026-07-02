import uuid

from fastapi import APIRouter, HTTPException, Query

from schemas.models import SimilarQueriesResponse, SimilarQueryItem, TraceResponse
from services.db_service import db_service
from services.llm_service import llm_service
from services.trace_service import trace_service
from services.vector_service import vector_service

router = APIRouter(prefix="/api/meta", tags=["meta"])


@router.get("/similar-queries", response_model=SimilarQueriesResponse)
def similar_queries(q: str = Query(..., min_length=1)) -> SimilarQueriesResponse:
    history = db_service.get_query_history()
    results = vector_service.find_similar_queries(q, history, top_k=5)
    items = [
        SimilarQueryItem(
            id=r["id"],
            nl_query=r["nl_query"],
            sql_text=r["sql_text"],
            score=r["score"],
        )
        for r in results
    ]
    return SimilarQueriesResponse(query=q, results=items)


@router.get("/trace/{request_id}", response_model=TraceResponse)
def get_trace(request_id: str) -> TraceResponse:
    trace = trace_service.get(request_id)
    if trace is None:
        raise HTTPException(status_code=404, detail="Trace not found")
    return TraceResponse(request_id=request_id, trace=trace)


from pydantic import BaseModel


class HistoryRequest(BaseModel):
    nl_query: str
    sql_text: str


@router.post("/history")
def record_history(body: HistoryRequest) -> dict:
    db_service.save_query_history(body.nl_query, body.sql_text)
    return {"status": "ok"}


@router.get("/components")
def component_status() -> dict:
    return {
        "minirdb": "ok",
        "tinyllm": llm_service.status,
        "vectorizer": vector_service.status,
        "tinycontainer": "scripts in deploy/tinycontainer/",
    }
