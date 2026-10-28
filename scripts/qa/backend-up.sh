#!/usr/bin/env bash
# Starts Postgres (shared with local development), prepares the vault_qa database and runs the backend against it.
source "$(dirname "$0")/env.sh"

if backend_running && curl -fsS "$API/health" >/dev/null 2>&1; then
  log "Backend is already running (pid $(cat "$PID_FILE"))"
  exit 0
fi

log "Starting Postgres"
(cd "$BACKEND_DIR" && docker compose --profile infra up -d postgres >/dev/null)

admin_url="$(admin_database_url)"
qa_url="$(qa_database_url)"

for _ in $(seq 1 30); do
  pg_isready -q -d "$admin_url" && break
  sleep 1
done
pg_isready -q -d "$admin_url" || die "Postgres is not ready"

if [[ "$(psql "$admin_url" -tAc "SELECT 1 FROM pg_database WHERE datname = '$QA_DB_NAME'")" != "1" ]]; then
  log "Creating database $QA_DB_NAME"
  psql "$admin_url" -qc "CREATE DATABASE $QA_DB_NAME" >/dev/null
fi

log "Applying migrations"
migrate -path "$BACKEND_DIR/internal/db/migrations" -database "$qa_url" up >/dev/null 2>&1 \
  || die "Migrations failed, run: migrate -path internal/db/migrations -database <vault_qa url> up"

log "Building backend"
(cd "$BACKEND_DIR" && go build -o "$RUN_DIR/vault-server" ./cmd/server)

log "Starting backend on $API"
(
  cd "$BACKEND_DIR"
  DATABASE_URL="$qa_url" \
  APP_ENV=development \
  PORT="$QA_PORT" \
  HTTPS_ENABLED=false \
  METRICS_ENABLED=false \
  SWAGGER_ENABLED=false \
  DEV_EMAIL_VERIFICATION_CODE="$QA_DEV_CODE" \
  nohup "$RUN_DIR/vault-server" >"$BACKEND_LOG" 2>&1 &
  echo $! >"$PID_FILE"
)

for _ in $(seq 1 60); do
  curl -fsS "$API/health" >/dev/null 2>&1 && { log "Backend is up (log: $BACKEND_LOG)"; exit 0; }
  backend_running || break
  sleep 1
done

tail -20 "$BACKEND_LOG" >&2 || true
die "Backend did not become healthy"
