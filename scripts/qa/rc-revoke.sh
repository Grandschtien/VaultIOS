#!/usr/bin/env bash
# Usage: rc-revoke.sh <email> [entitlement]
# Revokes promotional entitlements in RevenueCat and syncs the backend.
source "$(dirname "$0")/env.sh"
source "$QA_SCRIPTS_DIR/lib/api.sh"
source "$QA_SCRIPTS_DIR/lib/revenuecat.sh"

email="${1:?Usage: rc-revoke.sh <email> [entitlement]}"
entitlement="${2:-premium_access}"
require_qa_email "$email"

rc_request POST "/subscribers/$(user_id "$email")/entitlements/$entitlement/revoke_promotionals"
log "Revoked $entitlement from $email"
"$QA_SCRIPTS_DIR/rc-sync.sh" "$email" EXPIRATION
