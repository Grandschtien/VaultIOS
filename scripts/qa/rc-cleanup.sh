#!/usr/bin/env bash
# Deletes RevenueCat customers of every QA user created in this run.
source "$(dirname "$0")/env.sh"
source "$QA_SCRIPTS_DIR/lib/revenuecat.sh"

shopt -s nullglob
for file in "$USERS_DIR"/*.json; do
  email="$(jq -r '.email' "$file")"
  require_qa_email "$email"
  if (rc_request DELETE "/subscribers/$(jq -r '.id' "$file")"); then
    rm -f "$file"
    log "Removed RevenueCat customer of $email"
  else
    log "Could not remove RevenueCat customer of $email, will retry next run"
  fi
done
