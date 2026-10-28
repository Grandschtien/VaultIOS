#!/usr/bin/env bash
# Usage: rc-sync.sh <email> [EVENT_TYPE]
# Sends a RevenueCat-style webhook to the local backend so it re-reads the customer from RevenueCat.
source "$(dirname "$0")/env.sh"
source "$QA_SCRIPTS_DIR/lib/api.sh"

email="${1:?Usage: rc-sync.sh <email> [EVENT_TYPE]}"
event_type="${2:-INITIAL_PURCHASE}"
require_qa_email "$email"

authorization="$(backend_env REVENUECAT_WEBHOOK_AUTHORIZATION)"
[[ -n "$authorization" ]] || die "REVENUECAT_WEBHOOK_AUTHORIZATION is missing in Vault_backend/.env"

body="$(jq -n --arg id "$(uuidgen)" --arg type "$event_type" --arg user "$(user_id "$email")" \
  '{api_version: "1.0", event: {id: $id, type: $type, app_user_id: $user, original_app_user_id: $user}}')"

# The backend answers 5xx on the first sync of a user without a subscription row, but stores it;
# RevenueCat retries in production, so retry here as well.
for attempt in 1 2 3; do
  status="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$API/webhooks/revenuecat" \
    -H "Content-Type: application/json" -H "Authorization: $authorization" --data "$body")"
  (( status < 500 )) && break
  log "Webhook sync attempt $attempt returned HTTP $status, retrying"
  sleep 1
done
(( status < 400 )) || die "Webhook sync failed with HTTP $status (see $BACKEND_LOG)"
log "Synced $email ($event_type)"
