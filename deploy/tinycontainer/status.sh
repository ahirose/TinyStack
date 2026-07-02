#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

echo "TinyStack status"
echo "================"
for svc in llm api web; do
  if tinystack_is_running "$svc"; then
    pid="$(tinystack_read_pid "$svc")"
    echo "  ${svc}: running (pid ${pid})"
  else
    echo "  ${svc}: stopped"
  fi
done
echo
echo "Endpoints:"
echo "  Web: http://127.0.0.1:${WEB_PORT}/"
echo "  API: http://127.0.0.1:${API_PORT}/health"
echo "  LLM: http://127.0.0.1:${LLM_PORT}/health"
