import contextlib
import io
import sys
from pathlib import Path
from typing import Any, Optional

from fastapi import FastAPI
from pydantic import BaseModel, Field

ROOT = Path(__file__).resolve().parents[2]
TINYLLM_PKG = ROOT / "packages" / "tinyllm"
if str(TINYLLM_PKG) not in sys.path:
    sys.path.insert(0, str(TINYLLM_PKG))

from config import worker_host, worker_port  # noqa: E402

app = FastAPI(title="TinyStack LLM Worker", version="0.1.0")

_model = None
_tokenizer = None
_device = None
_generate_text = None
_load_error: Optional[str] = None


class GenerateRequest(BaseModel):
    prompt: str
    max_new_tokens: int = Field(default=80, ge=1, le=256)
    temperature: float = Field(default=0.4, ge=0.0, le=2.0)
    top_k: Optional[int] = 20


class GenerateResponse(BaseModel):
    text: str
    source: str


def _ensure_model() -> bool:
    global _model, _tokenizer, _device, _generate_text, _load_error
    if _model is not None:
        return True
    model_path = TINYLLM_PKG / "tiny_llm_model.pt"
    if not model_path.exists():
        _load_error = f"Model not found: {model_path}"
        return False
    try:
        import torch
        from inference import generate_text, load_model

        _device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        with contextlib.redirect_stdout(io.StringIO()):
            _model, _tokenizer = load_model(str(model_path), _device)
        _generate_text = generate_text
        return True
    except Exception as exc:
        _load_error = str(exc)
        return False


@app.on_event("startup")
def startup() -> None:
    _ensure_model()


@app.get("/health")
def health() -> dict[str, Any]:
    if _ensure_model():
        return {"status": "ok", "component": "tinyllm-worker"}
    return {"status": "degraded", "component": "tinyllm-worker", "error": _load_error}


@app.post("/generate", response_model=GenerateResponse)
def generate(body: GenerateRequest) -> GenerateResponse:
    if not _ensure_model():
        return GenerateResponse(text="", source="unavailable")

    raw = _generate_text(
        _model,
        _tokenizer,
        body.prompt,
        max_new_tokens=body.max_new_tokens,
        temperature=body.temperature,
        top_k=body.top_k,
        device=_device,
        verbose=False,
    )
    generated = raw[len(body.prompt) :] if raw.startswith(body.prompt) else raw
    return GenerateResponse(text=generated.strip(), source="llm")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host=worker_host, port=worker_port)
