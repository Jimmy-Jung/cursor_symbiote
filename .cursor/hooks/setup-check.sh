#!/bin/bash
# source: origin
# Cursor sessionStart hook: Check project bootstrap status
# Communicates via JSON over stdio per Cursor Hooks specification.

# JSON escape helper
json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | tr '\n' ' '
}

# Consume stdin (required by hook protocol)
cat > /dev/null

CONTEXT_PARTS=()

# Check manifest.json existence
if [ ! -f ".cursor/project/manifest.json" ]; then
  CONTEXT_PARTS+=("[Project Bootstrap] manifest.json not found. Run /setup to initialize project configuration.")
fi

# Check for interrupted Ralph Loops in task-folders
if [ -d ".cursor/project/state" ]; then
  for state_dir in .cursor/project/state/*/; do
    [ -d "$state_dir" ] || continue
    if [ -f "${state_dir}ralph-state.md" ]; then
      ACTIVE=$(grep -o 'active: true' "${state_dir}ralph-state.md" 2>/dev/null)
      if [ -n "$ACTIVE" ]; then
        TASK_NAME=$(basename "$state_dir")
        CONTEXT_PARTS+=("[Ralph Loop] Task '${TASK_NAME}' interrupted. Consider resuming with /ralph.")
      fi
    fi
  done
fi

# Build additional_context from collected parts
if [ ${#CONTEXT_PARTS[@]} -gt 0 ]; then
  JOINED=""
  for part in "${CONTEXT_PARTS[@]}"; do
    if [ -n "$JOINED" ]; then
      JOINED="$JOINED $part"
    else
      JOINED="$part"
    fi
  done
  ESCAPED=$(json_escape "$JOINED")
  # Output JSON with additional_context
  printf '{"additional_context":"%s","continue":true}\n' "$ESCAPED"
else
  # No issues found — output minimal JSON
  printf '{"continue":true}\n'
fi

exit 0
