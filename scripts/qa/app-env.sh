#!/usr/bin/env bash
# Usage: app-env.sh [qa-...@example.com]
# Prints launch environment for DeviceInteractionInstallAndRun as JSON.
# With an email it logs in through the API and adds VAULT_QA_SESSION, so the app starts on the main screen.
source "$(dirname "$0")/env.sh"
source "$QA_SCRIPTS_DIR/lib/api.sh"

rc_key="$(qa_env RC_TEST_STORE_API_KEY)"
[[ "$rc_key" == test_* ]] || die "RC_TEST_STORE_API_KEY (test_...) is missing in QA/.env.qa.local"

session=""
if [[ -n "${1:-}" ]]; then
  require_qa_email "$1"
  body="$(jq -n --arg email "$1" --arg password "$QA_PASSWORD" \
    '{provider: "password", email: $email, password: $password}')"
  session="$(api_request POST /auth/login "" "$body" | jq -c .)"
fi

jq -n --arg api "$API" --arg rc "$rc_key" --arg session "$session" \
  '{VAULT_API_BASE_URL: $api, VAULT_QA_MODE: "1", REVENUECAT_API_KEY: $rc}
   + (if $session == "" then {} else {VAULT_QA_SESSION: $session} end)'
