#!/usr/bin/env bash
# Recreates the vault_qa database from scratch. Never touches other databases.
source "$(dirname "$0")/env.sh"

backend_running && die "Stop the backend first: scripts/qa/backend-down.sh"

admin_url="$(admin_database_url)"
pg_isready -q -d "$admin_url" || die "Postgres is not running, start it with scripts/qa/backend-up.sh"

log "Recreating $QA_DB_NAME"
psql "$admin_url" -qc "DROP DATABASE IF EXISTS $QA_DB_NAME WITH (FORCE)" >/dev/null
psql "$admin_url" -qc "CREATE DATABASE $QA_DB_NAME" >/dev/null
migrate -path "$BACKEND_DIR/internal/db/migrations" -database "$(qa_database_url)" up >/dev/null 2>&1 \
  || die "Migrations failed"
rm -f "$USERS_DIR"/*.json
log "Database is clean"
