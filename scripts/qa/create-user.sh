#!/usr/bin/env bash
# Usage: create-user.sh <qa-...@example.com> [currency]
# Registers a ready-to-use account (no email verification) and prints its user id.
source "$(dirname "$0")/env.sh"
source "$QA_SCRIPTS_DIR/lib/api.sh"

email="${1:?Usage: create-user.sh <email> [currency]}"
currency="${2:-USD}"
require_qa_email "$email"

body="$(jq -n --arg email "$email" --arg password "$QA_PASSWORD" --arg currency "$currency" \
  '{provider: "password", email: $email, password: $password, name: "QA", currency: $currency, preferred_language: "en"}')"
id="$(api_request POST /auth/register "" "$body" | jq -er '.user.id')"

jq -n --arg id "$id" --arg email "$email" '{id: $id, email: $email}' >"$(user_file "$email")"
log "Created $email"
printf '%s\n' "$id"
