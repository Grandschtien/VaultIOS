#!/usr/bin/env bash
# Usage: wait-subscription.sh <email> <REGULAR|PREMIUM> [timeout_seconds]
# Polls GET /user/subscription until the tier matches.
source "$(dirname "$0")/env.sh"
source "$QA_SCRIPTS_DIR/lib/api.sh"

email="${1:?Usage: wait-subscription.sh <email> <REGULAR|PREMIUM> [timeout]}"
expected="${2:?Usage: wait-subscription.sh <email> <REGULAR|PREMIUM> [timeout]}"
timeout="${3:-30}"
require_qa_email "$email"

token="$(api_login "$email")"
tier=""
for _ in $(seq 1 "$timeout"); do
  tier="$(api_request GET /user/subscription "$token" | jq -r '.tier')"
  if [[ "$tier" == "$expected" ]]; then
    log "$email tier is $tier"
    exit 0
  fi
  sleep 1
done
die "$email tier is $tier, expected $expected after ${timeout}s"
