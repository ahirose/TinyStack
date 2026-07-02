#!/usr/bin/env bash
# Prepare TinyContainer rootfs and host environment for TinyStack auto-start
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

tinystack_log "Setting up TinyStack platform for TinyContainer..."
tinystack_require_rootfs
tinystack_ensure_dirs

# --- Host venv (for LLM worker with PyTorch; glibc / WSL) ---
HOST_PY="$(tinystack_find_python)"
if [[ -z "$HOST_PY" ]]; then
  tinystack_log "Creating host venv at $TINYSTACK_ROOT/.venv"
  python3 -m venv "$TINYSTACK_ROOT/.venv"
  HOST_PY="$TINYSTACK_ROOT/.venv/bin/python"
fi

tinystack_log "Installing host Python deps (API + LLM worker)..."
"$HOST_PY" -m pip install -q -U pip
"$HOST_PY" -m pip install -q fastapi uvicorn pydantic httpx torch sentence-transformers pytest httpx

# --- Build frontend on host ---
if command -v npm >/dev/null 2>&1; then
  tinystack_log "Building frontend..."
  (cd "$TINYSTACK_ROOT/frontend" && npm install --silent && npm run build)
else
  tinystack_log "WARN: npm not found; skip frontend build (run manually: cd frontend && npm run build)"
fi

# --- Alpine rootfs packages (API in chroot) ---
tinystack_log "Installing Alpine packages in rootfs (python3, nginx)..."
tinystack_sudo chroot "$ROOTFS" /bin/sh -c "
  set -e
  apk update >/dev/null
  apk add --no-cache python3 py3-pip nginx curl >/dev/null
  pip3 install --break-system-packages -q fastapi uvicorn pydantic httpx 2>/dev/null || \
    pip3 install -q fastapi uvicorn pydantic httpx
"

# --- Copy static web + nginx config ---
WEB_ROOT="$ROOTFS/opt/tinystack/web"
tinystack_sudo mkdir -p "$WEB_ROOT"
if [[ -d "$TINYSTACK_ROOT/frontend/dist" ]]; then
  tinystack_sudo cp -r "$TINYSTACK_ROOT/frontend/dist/"* "$WEB_ROOT/"
fi

tinystack_sudo mkdir -p "$ROOTFS/etc/nginx/http.d"
tinystack_sudo cp "$SCRIPT_DIR/nginx-tinystack.conf" "$ROOTFS/etc/nginx/http.d/tinystack.conf"

# Replace port placeholder
tinystack_sudo sed -i "s/__API_PORT__/${API_PORT}/g" "$ROOTFS/etc/nginx/http.d/tinystack.conf"
tinystack_sudo sed -i "s/__WEB_PORT__/${WEB_PORT}/g" "$ROOTFS/etc/nginx/http.d/tinystack.conf"

tinystack_log "Setup complete."
echo
echo "Next: $SCRIPT_DIR/run_all.sh"
