#!/usr/bin/env bash
# Start TinyLLM worker (host Python + cgroup; shares host network for port 8001)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

tinystack_ensure_dirs

if tinystack_is_running llm; then
  tinystack_log "LLM worker already running (pid $(tinystack_read_pid llm))"
  exit 0
fi

HOST_PY="$(tinystack_find_python)"
if [[ -z "$HOST_PY" ]]; then
  tinystack_log "ERROR: Python not found. Run setup_platform.sh first."
  exit 1
fi

tinystack_log "Starting tinystack-llm on port ${LLM_PORT}..."

tinystack_sudo unshare --pid --uts --fork bash -c "
  hostname tinystack-llm
  cd '$TINYSTACK_ROOT'
  export PYTHONPATH='$TINYSTACK_ROOT/services/llm_worker:$TINYSTACK_ROOT/packages/tinyllm'
  export TINYSTACK_LLM_HOST=127.0.0.1
  export TINYSTACK_LLM_PORT=${LLM_PORT}
  exec '$HOST_PY' -m uvicorn main:app --host 127.0.0.1 --port ${LLM_PORT} --app-dir '$TINYSTACK_ROOT/services/llm_worker'
" >"$LOG_DIR/llm.log" 2>&1 &

LLM_PID=$!
sleep 1
tinystack_save_pid llm "$LLM_PID"
tinystack_apply_cgroup "$LLM_PID" llm "$LLM_MEMORY"

if tinystack_wait_http "http://127.0.0.1:${LLM_PORT}/health" 60; then
  tinystack_log "LLM worker ready (pid ${LLM_PID})"
else
  tinystack_log "WARN: LLM worker health check timed out. See $LOG_DIR/llm.log"
fi

echo "LLM PID: $LLM_PID"
echo "Attach: sudo nsenter --target $LLM_PID --pid --uts /bin/sh"
