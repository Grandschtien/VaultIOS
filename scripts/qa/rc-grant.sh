#!/usr/bin/env bash
# Usage: rc-grant.sh <email> [entitlement] [duration]
# Grants a promotional entitlement in RevenueCat and syncs the backend. Duration: daily, weekly, monthly, ...
source "$(dirname "$0")/env.sh"
source "$QA_SCRIPTS_DIR/lib/api.sh"
source "$QA_SCRIPTS_DIR/lib/revenuecat.sh"

email="${1:?Usage: rc-grant.sh <email> [entitlement] [duration]}"
entitlement="${2:-premium_access}"
duration="${3:-weekly}"
require_qa_email "$email"
id="$(user_id "$email")"

rc_request GET "/subscribers/$id"
rc_request POST "/subscribers/$id/entitlements/$entitlement/promotional" "$(jq -n --arg d "$duration" '{duration: $d}')"
log "Granted $entitlement ($duration) to $email"
"$QA_SCRIPTS_DIR/rc-sync.sh" "$email" INITIAL_PURCHASE
