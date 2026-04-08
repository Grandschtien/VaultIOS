#!/usr/bin/env bash
set -euo pipefail

TASK="${1:-}"

if [ -z "$TASK" ]; then
  echo "Usage: ./scripts/codex-task.sh \"your task description\""
  exit 1
fi

PROMPT=$(cat <<EOF
You are working in this repository.

Mandatory rules:
- Before implementation, write a plan first.
- The plan must break the task into subtasks if needed.
- Do not implement anything until the plan is shown.
- The final implementation for this run must stay under 500 changed lines total (added + deleted).
- If the task cannot fit into 500 changed lines, stop after the plan and propose smaller subtasks.
- Do not refactor unrelated code.
- Modify only files directly needed for the current task.

Required response structure:
1. Plan
2. Risks
3. Files to change
4. Implementation
5. Verification

Task:
$TASK
EOF
)

codex "$PROMPT"
