#!/usr/bin/env bash
# Shared helpers for TinyStack on TinyContainer

set -euo pipefail

TINYSTACK_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TINYSTACK_ROOT="$(cd "$TINYSTACK_LIB_DIR/../.." && pwd)"
TINYSTACK_DEPLOY_DIR="$(cd "$TINYSTACK_LIB_DIR/.." && pwd)"
TC_SHELL_DIR="${TINYCONTAINER_SHELL_DIR:-$TINYSTACK_ROOT/packages/tinycontainer/shell_version}"
ROOTFS="${TINYCONTAINER_ROOTFS:-$TC_SHELL_DIR/rootfs}"
PID_DIR="${TINYSTACK_PID_DIR:-/tmp/tinystack}"
LOG_DIR="${TINYSTACK_LOG_DIR:-/tmp/tinystack/logs}"

API_PORT="${TINYSTACK_API_PORT:-8000}"
LLM_PORT="${TINYSTACK_LLM_PORT:-8001}"
WEB_PORT="${TINYSTACK_WEB_PORT:-8080}"
LLM_MEMORY="${TINYSTACK_LLM_MEMORY:-512M}"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

tinystack_log() {
  echo "[TinyStack] $*"
}

tinystack_require_rootfs() {
  if [[ ! -d "$ROOTFS/bin" ]]; then
    tinystack_log "ERROR: rootfs not found at $ROOTFS"
    tinystack_log "Run: cd $TC_SHELL_DIR && ./setup_rootfs.sh"
    tinystack_log "Then: $TINYSTACK_DEPLOY_DIR/setup_platform.sh"
    exit 1
  fi
}

tinystack_ensure_dirs() {
  mkdir -p "$PID_DIR" "$LOG_DIR" "$TINYSTACK_ROOT/data"
}

tinystack_save_pid() {
  local name="$1"
  local pid="$2"
  echo "$pid" >"$PID_DIR/${name}.pid"
}

tinystack_read_pid() {
  local name="$1"
  local file="$PID_DIR/${name}.pid"
  if [[ -f "$file" ]]; then
    cat "$file"
  fi
}

tinystack_is_running() {
  local pid
  pid="$(tinystack_read_pid "$1" || true)"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

tinystack_sudo() {
  # shellcheck disable=SC2068
  $SUDO "$@"
}

tinystack_bind_mount() {
  local src="$1"
  local dest="$2"
  if mountpoint -q "$dest" 2>/dev/null; then
    return 0
  fi
  tinystack_sudo mkdir -p "$dest"
  tinystack_sudo mount --bind "$src" "$dest"
}

tinystack_bind_platform() {
  tinystack_bind_mount "$TINYSTACK_ROOT" "$ROOTFS/opt/tinystack"
  tinystack_bind_mount "$TINYSTACK_ROOT/data" "$ROOTFS/opt/tinystack/data"
}

tinystack_unbind_platform() {
  if mountpoint -q "$ROOTFS/opt/tinystack/data" 2>/dev/null; then
    tinystack_sudo umount "$ROOTFS/opt/tinystack/data" || true
  fi
  if mountpoint -q "$ROOTFS/opt/tinystack" 2>/dev/null; then
    tinystack_sudo umount "$ROOTFS/opt/tinystack" || true
  fi
}

tinystack_apply_cgroup() {
  local pid="$1"
  local name="$2"
  local memory="$3"
  local cgroup_path="/sys/fs/cgroup/tinystack_${name}"

  if [[ ! -d /sys/fs/cgroup ]]; then
    return 0
  fi

  tinystack_sudo mkdir -p "$cgroup_path" 2>/dev/null || return 0
  if [[ -f "$cgroup_path/memory.max" ]]; then
    echo "$memory" | tinystack_sudo tee "$cgroup_path/memory.max" >/dev/null
    echo "$pid" | tinystack_sudo tee "$cgroup_path/cgroup.procs" >/dev/null 2>&1 || true
    tinystack_log "Applied cgroup memory limit ${memory} to ${name} (pid ${pid})"
  fi
}

tinystack_find_python() {
  if [[ -x "$TINYSTACK_ROOT/.venv/bin/python" ]]; then
    echo "$TINYSTACK_ROOT/.venv/bin/python"
  elif command -v python3 >/dev/null 2>&1; then
    command -v python3
  else
    echo ""
  fi
}

tinystack_wait_http() {
  local url="$1"
  local retries="${2:-30}"
  local i
  for ((i = 1; i <= retries; i++)); do
    if curl -sf "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

tinystack_stop_one() {
  local name="$1"
  local pid
  pid="$(tinystack_read_pid "$name" || true)"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    tinystack_log "Stopping ${name} (pid ${pid})..."
    tinystack_sudo kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  rm -f "$PID_DIR/${name}.pid"
}

tinystack_stop_all() {
  tinystack_stop_one web
  tinystack_stop_one api
  tinystack_stop_one llm
  tinystack_unbind_platform
}

tinystack_print_urls() {
  echo
  tinystack_log "Platform is running:"
  echo "  Web UI:  http://127.0.0.1:${WEB_PORT}/"
  echo "  API:     http://127.0.0.1:${API_PORT}/health"
  echo "  LLM:     http://127.0.0.1:${LLM_PORT}/health"
  echo
  tinystack_log "Attach to containers:"
  for svc in api web llm; do
    local pid
    pid="$(tinystack_read_pid "$svc" || true)"
    if [[ -n "$pid" ]]; then
      echo "  ${svc}: sudo nsenter --target ${pid} --pid --mount --uts /bin/sh"
    fi
  done
  echo
  tinystack_log "Logs: $LOG_DIR"
  tinystack_log "Stop: $TINYSTACK_DEPLOY_DIR/stop_all.sh"
}
