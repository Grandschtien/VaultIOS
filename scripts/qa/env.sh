#!/usr/bin/env bash
# Shared settings for QA scripts. Source it, do not run it directly.
# Secrets are read from Vault_backend/.env and QA/.env.qa.local and are never printed.
set -euo pipefail

QA_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$QA_SCRIPTS_DIR/../.." && pwd)"
BACKEND_DIR="${BACKEND_DIR:-$(cd "$IOS_DIR/../Vault_backend" && pwd)}"
QA_DIR="$IOS_DIR/QA"
RUN_DIR="$QA_DIR/.run"
USERS_DIR="$RUN_DIR/users"
PID_FILE="$RUN_DIR/backend.pid"
BACKEND_LOG="$RUN_DIR/backend.log"

QA_PORT="${QA_PORT:-8080}"
API="http://localhost:$QA_PORT"
QA_DB_NAME="vault_qa"
RC_API="https://api.revenuecat.com/v1"

mkdir -p "$USERS_DIR"

log() { printf '[qa] %s\n' "$*" >&2; }
die() { printf '[qa] ERROR: %s\n' "$*" >&2; exit 1; }

# env_value KEY FILE — value of the first KEY= line, without surrounding quotes.
env_value() {
  local line
  line="$(grep -E "^$1=" "$2" 2>/dev/null | head -1 || true)"
  line="${line#*=}"
  line="${line%\"}"; line="${line#\"}"
  line="${line%\'}"; line="${line#\'}"
  printf '%s' "$line"
}

backend_env() { env_value "$1" "$BACKEND_DIR/.env"; }
qa_env() { env_value "$1" "$QA_DIR/.env.qa.local"; }

QA_PASSWORD="$(qa_env QA_PASSWORD)"
QA_PASSWORD="${QA_PASSWORD:-QaPassw0rd!2026}"
QA_DEV_CODE="$(qa_env QA_DEV_CODE)"
QA_DEV_CODE="${QA_DEV_CODE:-424242}"

# Database URLs derived from the backend DATABASE_URL: same server, different database.
database_url_for() {
  local base query=""
  base="$(backend_env DATABASE_URL)"
  [[ -n "$base" ]] || die "DATABASE_URL is missing in $BACKEND_DIR/.env"
  [[ "$base" == *\?* ]] && query="?${base#*\?}"
  base="${base%%\?*}"
  printf '%s/%s%s' "${base%/*}" "$1" "$query"
}

qa_database_url() { database_url_for "$QA_DB_NAME"; }
admin_database_url() { database_url_for "postgres"; }

# QA accounts are disposable; refuse to touch anything that does not look like one.
require_qa_email() {
  [[ "$1" =~ ^qa[-+._a-z0-9]*@example\.com$ ]] || die "Not a QA email: $1 (expected qa-...@example.com)"
}

user_file() { printf '%s/%s.json' "$USERS_DIR" "$1"; }

backend_running() {
  [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}
