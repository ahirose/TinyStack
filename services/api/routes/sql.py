import uuid

from fastapi import APIRouter

from schemas.models import (
    SchemaResponse,
    SchemaTable,
    SQLExecuteRequest,
    SQLExecuteResponse,
)
from services.db_service import db_service
from services.trace_service import trace_service

router = APIRouter(prefix="/api/sql", tags=["sql"])


@router.post("/execute", response_model=SQLExecuteResponse)
def execute_sql(body: SQLExecuteRequest) -> SQLExecuteResponse:
    request_id = str(uuid.uuid4())
    try:
        ast, result = db_service.execute(body.sql)
        trace_service.save(
            request_id,
            {
                "type": "sql_execute",
                "sql": body.sql,
                "ast": ast,
                "result": result,
            },
        )
        return SQLExecuteResponse(request_id=request_id, ast=ast, result=result)
    except Exception as exc:
        trace_service.save(
            request_id,
            {"type": "sql_execute", "sql": body.sql, "error": str(exc)},
        )
        return SQLExecuteResponse(
            request_id=request_id,
            ast={},
            result={},
            error=str(exc),
        )


@router.get("/schema", response_model=SchemaResponse)
def get_schema() -> SchemaResponse:
    data = db_service.list_schema()
    tables = [SchemaTable(name=t["name"], columns=t["columns"]) for t in data["tables"]]
    return SchemaResponse(tables=tables, docs=data["docs"])
