import os
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[2]
DATA_DIR = Path(os.environ.get("TINYSTACK_DATA_DIR", ROOT_DIR / "data"))
BOOTSTRAP_SQL = ROOT_DIR / "bootstrap" / "bootstrap.sql"
MINIRDB_PKG = ROOT_DIR / "packages" / "minirdb"
TINYLLM_PKG = ROOT_DIR / "packages" / "tinyllm"
VECTORIZER_PKG = ROOT_DIR / "packages" / "vectorizer"
TINYLLM_MODEL = TINYLLM_PKG / "tiny_llm_model.pt"
LLM_SERVICE_URL = os.environ.get("TINYSTACK_LLM_URL", "")
API_HOST = os.environ.get("TINYSTACK_API_HOST", "0.0.0.0")
API_PORT = int(os.environ.get("TINYSTACK_API_PORT", "8000"))
