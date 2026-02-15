#!/bin/bash
# source: origin
# Cursor postToolUse hook: Ensure TODO list completion.
# After each tool use, reminds the agent to check remaining TODOs.

# JSON field extractor (jq with fallback to grep+sed)
json_field() {
  local json="$1" field="$2"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r ".$field // empty" 2>/dev/null
  else
    printf '%s' "$json" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed "s/\"$field\"[[:space:]]*:[[:space:]]*\"//" | sed 's/"$//'
  fi
}

# Read JSON input from stdin
INPUT=$(cat)

# Extract the tool name
TOOL_NAME=$(json_field "$INPUT" "tool_name")

# Only trigger after substantive tools (not reads/searches)
case "$TOOL_NAME" in
  Write|StrReplace|Shell|EditNotebook)
    # Check if any task-folder has an active ralph-state.md
    if [ -d ".cursor/project/state" ]; then
      for state_dir in .cursor/project/state/*/; do
        [ -d "$state_dir" ] || continue
        if [ -f "${state_dir}ralph-state.md" ]; then
          ACTIVE=$(grep -o 'active: true' "${state_dir}ralph-state.md" 2>/dev/null)
          if [ -n "$ACTIVE" ]; then
            TASK_NAME=$(basename "$state_dir")
            printf '{"additional_context":"[TODO Continuation] Ralph Loop active for task '\''%s'\''. Check remaining TODOs and continue working toward completion."}\n' "$TASK_NAME"
            exit 0
          fi
        fi
      done
    fi
    ;;
esac

# Default: no additional context
printf '{}\n'
exit 0
