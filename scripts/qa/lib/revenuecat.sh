#!/usr/bin/env bash
# RevenueCat REST API v1 helpers. Source after env.sh. Uses the secret key from Vault_backend/.env.

# rc_request METHOD PATH [BODY] — fails on HTTP >= 400, prints nothing on success.
rc_request() {
  local method="$1" path="$2" body="${3:-}"
  local key
  key="$(backend_env REVENUECAT_API_KEY)"
  [[ -n "$key" ]] || die "REVENUECAT_API_KEY is missing in Vault_backend/.env"

  local args=(-sS -o /dev/null -w '%{http_code}' -X "$method"
    -H "Authorization: Bearer $key" -H "Content-Type: application/json")
  [[ -n "$body" ]] && args+=(--data "$body")

  local status
  status="$(curl "${args[@]}" "$RC_API$path")" || die "RevenueCat is unreachable"
  (( status < 400 )) || die "RevenueCat $method $path failed with HTTP $status"
}
