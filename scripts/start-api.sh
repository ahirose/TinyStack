#!/usr/bin/env bash
cd "$(dirname "$0")/.."
export PYTHONPATH="$(pwd)/services/api"
source .venv/bin/activate 2>/dev/null || true
cd services/api
python main.py
