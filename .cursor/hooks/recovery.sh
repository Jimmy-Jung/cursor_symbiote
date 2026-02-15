#!/bin/bash
# source: origin
# Cursor postToolUse hook: Error recovery for edit failures.
# Detects failed edits and suggests recovery actions.

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

# Extract tool name and check for error presence
TOOL_NAME=$(json_field "$INPUT" "tool_name")
HAS_ERROR=$(printf '%s' "$INPUT" | grep -q '"error"' && echo "yes" || echo "")

# Only handle edit-related tools
case "$TOOL_NAME" in
  StrReplace|Write|EditNotebook)
    if [ -n "$HAS_ERROR" ]; then
      printf '{"additional_context":"[Recovery] Edit failed. Re-read the file to get current content before retrying. If old_string was not found, the file may have changed."}\n'
      exit 0
    fi
    ;;
  Shell)
    if [ -n "$HAS_ERROR" ]; then
      printf '{"additional_context":"[Recovery] Shell command failed. Check the error output and adjust the command. Consider using ReadLints to check for build issues."}\n'
      exit 0
    fi
    ;;
esac

# Default: no additional context
printf '{}\n'
exit 0
