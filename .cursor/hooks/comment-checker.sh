#!/bin/bash
# source: origin
# Cursor afterFileEdit hook: Detect unnecessary AI-generated comments.
# Warns when edited files contain patterns of low-value comments.

# JSON escape helper
json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | tr '\n' ' '
}

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

# Extract the file path
FILE_PATH=$(json_field "$INPUT" "file_path")

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  printf '{}\n'
  exit 0
fi

# Skip non-code files
case "$FILE_PATH" in
  *.md|*.mdc|*.json|*.yaml|*.yml|*.txt|*.sh|*.env*)
    printf '{}\n'
    exit 0
    ;;
esac

# Count suspicious comment patterns
COMMENT_COUNT=0

# Pattern 1: Obvious/self-documenting comments (e.g., "// Initialize variable")
P1=$(grep -cE '^\s*(//|#|/\*)\s*(Initialize|Set|Get|Return|Create|Update|Delete|Check|Handle|Process)\s' "$FILE_PATH" 2>/dev/null || echo 0)

# Pattern 2: Commented-out code blocks (language-agnostic keywords)
P2=$(grep -cE '^\s*(//|#)\s*(if |for |while |function |def |class |return |import |from |require |include |export |const |var |let )' "$FILE_PATH" 2>/dev/null || echo 0)

# Pattern 3: TODO/FIXME/HACK without context
P3=$(grep -cE '^\s*(//|#)\s*(TODO|FIXME|HACK|XXX)\s*$' "$FILE_PATH" 2>/dev/null || echo 0)

COMMENT_COUNT=$((P1 + P2 + P3))

if [ "$COMMENT_COUNT" -gt 3 ]; then
  ESCAPED_PATH=$(json_escape "$FILE_PATH")
  printf '{"additional_context":"[Comment Checker] %d suspicious comments detected in %s. Consider running comment-checker skill to review: self-documenting comments (%d), commented-out code (%d), empty TODOs (%d)."}\n' "$COMMENT_COUNT" "$ESCAPED_PATH" "$P1" "$P2" "$P3"
else
  printf '{}\n'
fi

exit 0
