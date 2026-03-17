#!/bin/bash
set -euo pipefail

ROOT_DIR="${1:-.}"
TASKMASTER_DIR="$ROOT_DIR/.cursor/project/taskmaster"
STATE_ROOT="$ROOT_DIR/.cursor/project/state"
LEGACY_TASKS_JSON="$TASKMASTER_DIR/tasks.json"
STATE_JSON="$TASKMASTER_DIR/state.json"
CONFIG_JSON="$TASKMASTER_DIR/config.json"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  [PASS] $1"
}

warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  echo "  [WARN] $1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "  [FAIL] $1"
}

echo "[tm-validate]"
echo ""

if [ ! -d "$TASKMASTER_DIR" ]; then
  echo "  [INFO] not initialized: $TASKMASTER_DIR"
  exit 0
fi

for file in "$STATE_JSON" "$CONFIG_JSON"; do
  if [ -f "$file" ]; then
    pass "exists: $(basename "$file")"
  else
    fail "missing runtime file: $(basename "$file")"
  fi
done

if [ -f "$LEGACY_TASKS_JSON" ]; then
  warn "legacy runtime detected: $(basename "$LEGACY_TASKS_JSON")"
fi

for file in "$STATE_JSON" "$CONFIG_JSON"; do
  if [ -f "$file" ]; then
    if jq empty "$file" >/dev/null 2>&1; then
      pass "valid json: $(basename "$file")"
    else
      fail "invalid json: $(basename "$file")"
    fi
  fi
done

if [ -d "$STATE_ROOT" ]; then
  pass "exists: $(basename "$STATE_ROOT")"
else
  warn "state directory missing: $STATE_ROOT"
fi

TASK_FILES=()
TASK_FILE_COUNT=0
if [ -d "$STATE_ROOT" ]; then
  while IFS= read -r file; do
    TASK_FILES+=("$file")
    TASK_FILE_COUNT=$((TASK_FILE_COUNT + 1))
  done < <(find "$STATE_ROOT" -maxdepth 2 -type f -name task.json | sort)
fi

if [ "$TASK_FILE_COUNT" -eq 0 ]; then
  warn "no task.json found under .cursor/project/state/*"
else
  pass "discovered task.json files: $TASK_FILE_COUNT"
fi

if [ -f "$STATE_JSON" ]; then
  jq -e '.currentTag and (.migrationNoticeShown | type == "boolean")' "$STATE_JSON" >/dev/null 2>&1 \
    && pass "state.json required keys present" \
    || fail "state.json missing required keys"
fi

if [ -f "$CONFIG_JSON" ]; then
  jq -e '.defaults and .workflow and .execution' "$CONFIG_JSON" >/dev/null 2>&1 \
    && pass "config.json required sections present" \
    || fail "config.json missing required sections"
fi

for task_file in "${TASK_FILES[@]-}"; do
  if [ -z "${task_file:-}" ]; then
    continue
  fi
  folder_name="$(basename "$(dirname "$task_file")")"

  if jq -e '
    .version and .tasks and (.tasks | type == "array")
  ' "$task_file" >/dev/null 2>&1; then
    pass "task.json required keys present: $folder_name"
  else
    fail "task.json missing required keys: $folder_name"
    continue
  fi

  if jq -e '
    (.tasks | length == 0)
    or ([ .tasks[]? | .id and .status and .priority and .metadata ] | all)
  ' "$task_file" >/dev/null 2>&1; then
    pass "task shape valid: $folder_name"
  else
    fail "task entries missing required fields: $folder_name"
  fi

  if jq -e '
    [ .tasks[].id ] as $ids
    | [ .tasks[]
        | {id, broken: [ .dependencies[] | select(($ids | index(.)) == null) ] }
        | select(.broken | length > 0)
      ] | length == 0
  ' "$task_file" >/dev/null 2>&1; then
    pass "dependencies valid: $folder_name"
  else
    fail "dependencies reference missing ids: $folder_name"
  fi

  if jq -e --arg folder "$folder_name" '
    [ .tasks[]?
      | select((.metadata.taskFolder // $folder) != $folder)
    ] | length == 0
  ' "$task_file" >/dev/null 2>&1; then
    pass "metadata.taskFolder synced: $folder_name"
  else
    fail "metadata.taskFolder mismatch: $folder_name"
  fi
done

if [ -f "$STATE_JSON" ]; then
  CURRENT_TASK_ID="$(jq -r '.currentTaskId // empty' "$STATE_JSON" 2>/dev/null || true)"
  if [ -z "$CURRENT_TASK_ID" ]; then
    warn "currentTaskId is null"
  elif [ "$TASK_FILE_COUNT" -eq 0 ]; then
    warn "currentTaskId present but no task.json available to validate"
  else
    MATCHED="false"
    for task_file in "${TASK_FILES[@]-}"; do
      if [ -z "${task_file:-}" ]; then
        continue
      fi
      if jq -e --arg id "$CURRENT_TASK_ID" '.tasks[]? | select(.id == $id)' "$task_file" >/dev/null 2>&1; then
        MATCHED="true"
        break
      fi
    done

    if [ "$MATCHED" = "true" ]; then
      pass "currentTaskId points to existing task"
    else
      fail "currentTaskId does not match any task in state/*/task.json"
    fi
  fi
fi

echo ""
echo "[Summary]"
echo "  PASS: $PASS_COUNT"
echo "  WARN: $WARN_COUNT"
echo "  FAIL: $FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
