#!/bin/bash
set -euo pipefail

ROOT_DIR="${1:-.}"
TASK_ID="${2:-}"
COUNT="${3:-3}"

STATE_ROOT="$ROOT_DIR/.cursor/project/state"

if [ -z "$TASK_ID" ]; then
  echo "[tm-expand][ERROR] taskId is required" >&2
  exit 1
fi

if [ ! -d "$STATE_ROOT" ]; then
  echo "[tm-expand][ERROR] state directory not found: $STATE_ROOT" >&2
  exit 1
fi

MATCHED_FILES=()
while IFS= read -r task_file; do
  if jq -e --arg id "$TASK_ID" '.tasks[]? | select(.id == $id)' "$task_file" >/dev/null 2>&1; then
    MATCHED_FILES+=("$task_file")
  fi
done < <(find "$STATE_ROOT" -maxdepth 2 -type f -name task.json | sort)

MATCH_COUNT=${#MATCHED_FILES[@]}
if [ "$MATCH_COUNT" -eq 0 ]; then
  echo "[tm-expand][ERROR] task not found in state/*/task.json: $TASK_ID" >&2
  exit 1
fi

if [ "$MATCH_COUNT" -gt 1 ]; then
  echo "[tm-expand][ERROR] task id is ambiguous across multiple task.json files: $TASK_ID" >&2
  for f in "${MATCHED_FILES[@]}"; do
    echo "  - ${f#$ROOT_DIR/}" >&2
  done
  exit 1
fi

TASK_JSON="${MATCHED_FILES[0]}"
TASK_FOLDER="$(basename "$(dirname "$TASK_JSON")")"

if jq -e --arg id "$TASK_ID" '.tasks[] | select(.id == $id) | (.subtasks | length > 0)' "$TASK_JSON" >/dev/null 2>&1; then
  echo "[tm-expand][ERROR] task already has subtasks: $TASK_ID" >&2
  exit 1
fi

TMP_JSON="$(mktemp)"
jq --arg id "$TASK_ID" --argjson count "$COUNT" '
  .tasks |= map(
    if .id == $id then
      .subtasks = [
        range(1; $count + 1) as $n
        | {
            id: ($id + "." + ($n | tostring)),
            title: (.title + " - Step " + ($n | tostring)),
            description: ("Subtask " + ($n | tostring) + " for task " + $id),
            status: "pending",
            priority: .priority,
            dependencies: (if $n == 1 then [] else [$id + "." + (($n - 1) | tostring)] end),
            details: (.details + "\n\nSubtask step " + ($n | tostring)),
            testStrategy: .testStrategy,
            metadata: (.metadata + { parentTaskId: $id, generatedBy: "tm-expand" })
          }
      ]
    else
      .
    end
  )
' "$TASK_JSON" > "$TMP_JSON"
mv "$TMP_JSON" "$TASK_JSON"

echo "[tm-expand]"
echo ""
echo "- taskId: $TASK_ID"
echo "- taskFolder: $TASK_FOLDER"
echo "- target: ${TASK_JSON#$ROOT_DIR/}"
echo "- createdSubtasks: $COUNT"
echo "- recommendedNext: /tm-validate"
