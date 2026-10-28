#!/usr/bin/env bash
# Usage: seed.sh <email> <fixture.json>
# Fixture: {"categories": [{name, icon, color}], "expenses": [{title, amount, currency, category, days_ago}]}
# Expense "category" is a category name; "Unmapped" exists for every new user.
source "$(dirname "$0")/env.sh"
source "$QA_SCRIPTS_DIR/lib/api.sh"

email="${1:?Usage: seed.sh <email> <fixture.json>}"
fixture="${2:?Usage: seed.sh <email> <fixture.json>}"
require_qa_email "$email"
[[ -f "$fixture" ]] || fixture="$QA_DIR/fixtures/$fixture"
[[ -f "$fixture" ]] || die "Fixture not found: $2"

token="$(api_login "$email")"

while IFS= read -r category; do
  api_request POST /categories "$token" "$category" >/dev/null
done < <(jq -c '.categories[]? | {name, icon, color}' "$fixture")

category_ids="$(api_request GET /categories "$token" | jq -c '[.categories[] | {(.name): .id}] | add // {}')"

expenses="[]"
while IFS= read -r expense; do
  days_ago="$(jq -r '.days_ago // 0' <<<"$expense")"
  time_of_add="$(date -u -v-"${days_ago}"d +%Y-%m-%dT%H:%M:%SZ)"
  expenses="$(jq -c --argjson expense "$expense" --argjson ids "$category_ids" --arg time "$time_of_add" '
    . + [{
      title: $expense.title,
      amount: $expense.amount,
      currency: $expense.currency,
      category: ($ids[$expense.category] // error("Unknown category " + $expense.category)),
      time_of_add: $time
    }]' <<<"$expenses")"
done < <(jq -c '.expenses[]?' "$fixture")

if [[ "$expenses" != "[]" ]]; then
  api_request POST /expenses "$token" "$(jq -c '{expenses: .}' <<<"$expenses")" >/dev/null
fi

log "Seeded $email: $(jq '.categories | length' "$fixture") categories, $(jq 'length' <<<"$expenses") expenses"
