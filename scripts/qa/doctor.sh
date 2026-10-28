#!/usr/bin/env bash
# Checks that everything needed for a QA run is in place. Prints only key names, never values.
source "$(dirname "$0")/env.sh"

problems=0
fail() { printf '  ✗ %s\n' "$*"; problems=$((problems + 1)); }
ok() { printf '  ✓ %s\n' "$*"; }

echo "Tools:"
for tool in docker go migrate psql pg_isready jq curl uuidgen; do
  if command -v "$tool" >/dev/null 2>&1; then ok "$tool"; else fail "$tool is not installed"; fi
done
if docker info >/dev/null 2>&1; then ok "docker daemon"; else fail "docker daemon is not running"; fi

echo "Backend:"
[[ -d "$BACKEND_DIR" ]] && ok "$BACKEND_DIR" || fail "backend repo not found at $BACKEND_DIR"
if [[ -f "$BACKEND_DIR/.env" ]]; then
  for key in DATABASE_URL JWT_SECRET ANTHROPIC_API_KEY OPENROUTER_API_KEY REVENUECAT_API_KEY \
             REVENUECAT_WEBHOOK_AUTHORIZATION REVENUECAT_PREMIUM_ENTITLEMENT_IDS; do
    [[ -n "$(backend_env "$key")" ]] && ok "$key" || fail "$key is empty in Vault_backend/.env"
  done
else
  fail "Vault_backend/.env is missing"
fi

echo "Port $QA_PORT:"
if lsof -nP -iTCP:"$QA_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  if backend_running; then ok "used by the QA backend"; else fail "busy by another process (stop it or set QA_PORT)"; fi
else
  ok "free"
fi

echo "QA config:"
if [[ -f "$QA_DIR/.env.qa.local" ]]; then
  ok "QA/.env.qa.local"
  [[ "$(qa_env RC_TEST_STORE_API_KEY)" == test_* ]] && ok "RC_TEST_STORE_API_KEY" \
    || fail "RC_TEST_STORE_API_KEY must be set to the RevenueCat Test Store key (test_...)"
else
  fail "QA/.env.qa.local is missing (copy QA/.env.qa.example)"
fi

if (( problems > 0 )); then
  echo "Found $problems problem(s)."
  exit 1
fi
echo "Environment is ready."
