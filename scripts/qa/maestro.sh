#!/usr/bin/env bash
# Usage: maestro.sh [flow ids…] — runs Maestro flows from Maestro/ against the local QA backend (all flows when no ids).
# Each flow gets a fresh qa-maestro-…@example.com account. Its header declares the setup:
#   # qa-setup: create-user; seed <fixture>; rc-grant [entitlement] [duration]; rc-revoke [entitlement]
# The app must already be installed on the booted simulator as a Debug build.
source "$(dirname "$0")/env.sh"
source "$QA_SCRIPTS_DIR/lib/api.sh"

# The first start of the iOS driver on a simulator builds and installs it, which takes longer than the default timeout.
export MAESTRO_DRIVER_STARTUP_TIMEOUT="${MAESTRO_DRIVER_STARTUP_TIMEOUT:-180000}"
export MAESTRO_CLI_NO_ANALYTICS=1

command -v maestro >/dev/null || die "maestro is not installed: curl -fsSL https://get.maestro.mobile.dev | bash"
MAESTRO_DIR="$IOS_DIR/Maestro"

"$QA_SCRIPTS_DIR/backend-up.sh"

# inputText types through the keyboard: with a non-Latin layout first, Latin letters are dropped.
xcrun simctl spawn booted defaults write .GlobalPreferences AppleKeyboards \
  -array "en_US@sw=QWERTY;hw=Automatic" "emoji@sw=Emoji" \
  || die "No booted simulator"

rc_key="$(qa_env RC_TEST_STORE_API_KEY)"
[[ "$rc_key" == test_* ]] || die "RC_TEST_STORE_API_KEY (test_...) is missing in QA/.env.qa.local"

flows=()
if (( $# )); then
  for id in "$@"; do flows+=("$MAESTRO_DIR/$id.yaml"); done
else
  flows=("$MAESTRO_DIR"/[0-9]*.yaml)
fi

header() { sed -n "s/^# $1: *//p" "$2" | head -1; }

run_setup() {
  local email="$1" steps="$2" step
  [[ -n "$steps" ]] || return 0
  IFS=';' read -ra steps <<<"$steps"
  for step in "${steps[@]}"; do
    read -ra step <<<"$step"
    (( ${#step[@]} )) || continue
    case "${step[0]}" in
      create-user|rc-grant|rc-revoke) "$QA_SCRIPTS_DIR/${step[0]}.sh" "$email" "${step[@]:1}" >/dev/null || return 1 ;;
      seed) "$QA_SCRIPTS_DIR/seed.sh" "$email" "${step[1]}" || return 1 ;;
      *) die "Unknown setup step: ${step[0]}" ;;
    esac
  done
}

results=()
failed=0
for flow in "${flows[@]}"; do
  [[ -f "$flow" ]] || die "Flow not found: $flow"
  id="$(basename "$flow" .yaml)"
  email="qa-maestro-$(date +%s)-${id%%-*}@example.com"
  log "Running $id as $email"

  status=PASS
  user=""
  if ! run_setup "$email" "$(header qa-setup "$flow")"; then
    status=BLOCKED
  else
    [[ -f "$(user_file "$email")" ]] && user="$(user_id "$email")"
    maestro test \
      -e EMAIL="$email" \
      -e QA_PASSWORD="$QA_PASSWORD" \
      -e QA_DEV_CODE="$QA_DEV_CODE" \
      -e API_BASE_URL="$API" \
      -e RC_API_KEY="$rc_key" \
      -e USER_ID="$user" \
      -e RC_WEBHOOK_AUTH="$(backend_env REVENUECAT_WEBHOOK_AUTHORIZATION)" \
      "$flow" || status=FAIL
  fi

  "$QA_SCRIPTS_DIR/delete-user.sh" "$email" 2>/dev/null || log "Could not delete $email (it may not exist)"
  [[ "$status" == PASS ]] || failed=1
  results+=("$status $id")
done

printf '%s\n' "${results[@]}"
exit "$failed"
