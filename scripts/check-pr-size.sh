#!/usr/bin/env bash
set -euo pipefail

BASE_REF="${1:-origin/main}"
HEAD_REF="${2:-HEAD}"

ADDED=$(git diff --numstat "$BASE_REF...$HEAD_REF" | awk '{a += $1} END {print a+0}')
DELETED=$(git diff --numstat "$BASE_REF...$HEAD_REF" | awk '{d += $2} END {print d+0}')
TOTAL=$((ADDED + DELETED))

echo "Added: $ADDED"
echo "Deleted: $DELETED"
echo "Total changed lines: $TOTAL"

LIMIT=500

if [ "$TOTAL" -gt "$LIMIT" ]; then
  echo "PR is too large: $TOTAL lines changed. Limit is $LIMIT."
  exit 1
fi

echo "PR size check passed."
