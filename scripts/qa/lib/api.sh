#!/usr/bin/env bash
# HTTP helpers for the local QA backend. Source after env.sh.

# api_request METHOD PATH [TOKEN] [BODY] — prints the response body, fails on HTTP >= 400.
api_request() {
  local method="$1" path="$2" token="${3:-}" body="${4:-}"
  local args=(-sS -X "$method" -H "Content-Type: application/json" -w $'\n%{http_code}')
  [[ -n "$token" ]] && args+=(-H "Authorization: Bearer $token")
  [[ -n "$body" ]] && args+=(--data "$body")

  local response status
  response="$(curl "${args[@]}" "$API$path")" || die "$method $path: backend is unreachable"
  status="${response##*$'\n'}"
  response="${response%$'\n'*}"
  if (( status >= 400 )); then
    printf '%s\n' "$response" >&2
    die "$method $path failed with HTTP $status"
  fi
  printf '%s' "$response"
}

# api_login EMAIL — prints a fresh access token.
api_login() {
  local body
  body="$(jq -n --arg email "$1" --arg password "$QA_PASSWORD" \
    '{provider: "password", email: $email, password: $password}')"
  api_request POST /auth/login "" "$body" | jq -er '.access_token'
}

# user_id EMAIL — backend user id saved by create-user.sh (it is also the RevenueCat app user id).
user_id() {
  local file
  file="$(user_file "$1")"
  [[ -f "$file" ]] || die "Unknown QA user $1, create it with scripts/qa/create-user.sh"
  jq -er '.id' "$file"
}
