#!/usr/bin/env bash
# Stops the QA backend. Postgres keeps running because it is shared with local development.
source "$(dirname "$0")/env.sh"

if backend_running; then
  pid="$(cat "$PID_FILE")"
  kill "$pid"
  for _ in $(seq 1 10); do
    kill -0 "$pid" 2>/dev/null || break
    sleep 1
  done
  log "Backend stopped"
else
  log "Backend is not running"
fi
rm -f "$PID_FILE"
