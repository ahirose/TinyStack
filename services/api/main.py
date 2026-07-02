from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routes import ai, meta, sql
from schemas.models import HealthResponse
from services.db_service import db_service
from services.llm_service import llm_service
from services.vector_service import vector_service


@asynccontextmanager
async def lifespan(_app: FastAPI):
    db_service.ensure_bootstrap()
    yield


app = FastAPI(
    title="TinyStack API",
    description="Educational full-stack SQL + AI platform",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(sql.router)
app.include_router(ai.router)
app.include_router(meta.router)


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(
        status="ok",
        components={
            "api": "ok",
            "minirdb": "ok",
            "tinyllm": llm_service.status,
            "vectorizer": vector_service.status,
        },
    )


if __name__ == "__main__":
    import uvicorn

    from config import API_HOST, API_PORT

    uvicorn.run("main:app", host=API_HOST, port=API_PORT, reload=True)
