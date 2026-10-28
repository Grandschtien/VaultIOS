#!/usr/bin/env bash
# Usage: delete-user.sh <email> — deletes the account on the QA backend.
source "$(dirname "$0")/env.sh"
source "$QA_SCRIPTS_DIR/lib/api.sh"

email="${1:?Usage: delete-user.sh <email>}"
require_qa_email "$email"

token="$(api_login "$email")"
api_request DELETE /account "$token" >/dev/null
log "Deleted $email from the backend (RevenueCat customer stays until rc-cleanup.sh)"
