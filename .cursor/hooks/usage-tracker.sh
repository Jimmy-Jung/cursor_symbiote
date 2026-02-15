#!/bin/bash
# source: origin
# Cursor postToolUse hook: Track usage of skills, commands, and agents.
# Increments counters when .cursor/ skill/command/agent files are read.
#
# Author: jimmy
# Date: 2026-02-14
#
# Data format: .cursor/project/usage-data/{category}/{name}
#   Each file contains: {count}|{ISO8601 timestamp}

# JSON field extractor (jq with fallback to grep+sed)
json_field() {
  local json="$1" field="$2"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r ".$field // empty" 2>/dev/null
  else
    printf '%s' "$json" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed "s/\"$field\"[[:space:]]*:[[:space:]]*\"//" | sed 's/"$//'
  fi
}

# JSON nested field extractor for tool_input.path (jq with fallback)
json_nested_field() {
  local json="$1" parent="$2" field="$3"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r ".$parent.$field // empty" 2>/dev/null
  else
    # Fallback: extract parent object then find field within it
    local parent_val
    parent_val=$(printf '%s' "$json" | grep -o "\"$parent\"[[:space:]]*:[[:space:]]*{[^}]*}" | head -1)
    if [ -n "$parent_val" ]; then
      printf '%s' "$parent_val" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed "s/\"$field\"[[:space:]]*:[[:space:]]*\"//" | sed 's/"$//'
    fi
  fi
}

# Read JSON input from stdin (required by hook protocol)
INPUT=$(cat)

# Extract file path from postToolUse input (tool_input.path)
FILE_PATH=$(json_nested_field "$INPUT" "tool_input" "path")

# Fallback: try top-level "path" field
if [ -z "$FILE_PATH" ]; then
  FILE_PATH=$(json_field "$INPUT" "path")
fi

# Fallback: try "file_path" field (top-level or nested)
if [ -z "$FILE_PATH" ]; then
  FILE_PATH=$(json_nested_field "$INPUT" "tool_input" "file_path")
fi
if [ -z "$FILE_PATH" ]; then
  FILE_PATH=$(json_field "$INPUT" "file_path")
fi

if [ -z "$FILE_PATH" ]; then
  printf '{}\n'
  exit 0
fi

# Determine category and name from the path
CATEGORY=""
NAME=""

case "$FILE_PATH" in
  */.cursor/skills/*/SKILL.md|.cursor/skills/*/SKILL.md)
    CATEGORY="skills"
    NAME=$(echo "$FILE_PATH" | sed 's|.*/\.cursor/skills/\([^/]*\)/SKILL\.md|\1|')
    # Handle relative path case
    if [ "$NAME" = "$FILE_PATH" ]; then
      NAME=$(echo "$FILE_PATH" | sed 's|\.cursor/skills/\([^/]*\)/SKILL\.md|\1|')
    fi
    ;;
  */.cursor/commands/*.md|.cursor/commands/*.md)
    CATEGORY="commands"
    NAME=$(basename "$FILE_PATH" .md)
    ;;
  */.cursor/agents/*.md|.cursor/agents/*.md)
    CATEGORY="agents"
    NAME=$(basename "$FILE_PATH" .md)
    ;;
  *)
    # Not a tracked file — exit immediately
    printf '{}\n'
    exit 0
    ;;
esac

# Validate extracted name
if [ -z "$NAME" ] || [ -z "$CATEGORY" ]; then
  printf '{}\n'
  exit 0
fi

# Skip tracking the stats command itself to avoid noise
if [ "$CATEGORY" = "commands" ] && [ "$NAME" = "stats" ]; then
  printf '{}\n'
  exit 0
fi

# Paths
DATA_DIR=".cursor/project/usage-data/$CATEGORY"
DATA_FILE="$DATA_DIR/$NAME"
SINCE_FILE=".cursor/project/usage-data/.tracked-since"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Ensure directory exists
mkdir -p "$DATA_DIR" 2>/dev/null

# Initialize tracked-since marker on first ever tracking
if [ ! -f "$SINCE_FILE" ]; then
  printf '%s\n' "$NOW" > "$SINCE_FILE"
fi

# Read current count and increment
if [ -f "$DATA_FILE" ]; then
  CURRENT=$(cut -d'|' -f1 "$DATA_FILE" 2>/dev/null)
  # Validate numeric
  case "$CURRENT" in
    ''|*[!0-9]*) CURRENT=0 ;;
  esac
else
  CURRENT=0
fi

NEW_COUNT=$((CURRENT + 1))

# Write updated count (atomic-ish: write to temp then move)
TEMP_FILE="${DATA_FILE}.tmp"
printf '%d|%s\n' "$NEW_COUNT" "$NOW" > "$TEMP_FILE" 2>/dev/null && mv "$TEMP_FILE" "$DATA_FILE" 2>/dev/null

# Default: no additional context
printf '{}\n'
exit 0
