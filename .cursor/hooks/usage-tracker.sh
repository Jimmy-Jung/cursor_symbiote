#!/bin/bash
# source: origin
# Cursor usage tracker — triple-mode: postToolUse hook + subagentStart hook + CLI.
#
# Hook mode (stdin):       postToolUse(Read) — 스킬/커맨드/에이전트/시스템 스킬 자동 추적
# SubAgent mode (stdin):   subagentStart — 빌트인 서브에이전트 + 매칭 커스텀 에이전트 자동 추적
# CLI mode (args):         에이전트 자기보고 — 인라인 로드 시 직접 호출
#
# CLI usage:
#   bash .cursor/hooks/usage-tracker.sh <category> <name>
#   category: skills | commands | agents | subagents | system-skills
#   example:  bash .cursor/hooks/usage-tracker.sh subagents explore
#
# Author: jimmy
# Date: 2026-02-14
#
# Data format: .cursor/project/usage-data/{category}/{name}
#   Each file contains: {count}|{ISO8601 timestamp}

# ── Shared: increment counter ────────────────────────────────────────
increment_counter() {
  local category="$1" name="$2"

  local data_dir=".cursor/project/usage-data/$category"
  local data_file="$data_dir/$name"
  local since_file=".cursor/project/usage-data/.tracked-since"
  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  mkdir -p "$data_dir" 2>/dev/null

  if [ ! -f "$since_file" ]; then
    printf '%s\n' "$now" > "$since_file"
  fi

  local current=0
  if [ -f "$data_file" ]; then
    current=$(cut -d'|' -f1 "$data_file" 2>/dev/null)
    case "$current" in
      ''|*[!0-9]*) current=0 ;;
    esac
  fi

  local new_count=$((current + 1))
  local temp_file="${data_file}.tmp"
  printf '%d|%s\n' "$new_count" "$now" > "$temp_file" 2>/dev/null && mv "$temp_file" "$data_file" 2>/dev/null
}

# ── JSON helpers ──────────────────────────────────────────────────────
json_field() {
  local json="$1" field="$2"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r ".$field // empty" 2>/dev/null
  else
    printf '%s' "$json" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed "s/\"$field\"[[:space:]]*:[[:space:]]*\"//" | sed 's/"$//'
  fi
}

json_nested_field() {
  local json="$1" parent="$2" field="$3"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r ".$parent.$field // empty" 2>/dev/null
  else
    local parent_val
    parent_val=$(printf '%s' "$json" | grep -o "\"$parent\"[[:space:]]*:[[:space:]]*{[^}]*}" | head -1)
    if [ -n "$parent_val" ]; then
      printf '%s' "$parent_val" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed "s/\"$field\"[[:space:]]*:[[:space:]]*\"//" | sed 's/"$//'
    fi
  fi
}

# ── CLI mode: direct invocation with arguments ───────────────────────
if [ $# -ge 2 ]; then
  CATEGORY="$1"
  NAME="$2"

  case "$CATEGORY" in
    skills|commands|agents|subagents|system-skills) ;;
    *)
      echo "error: invalid category '$CATEGORY' (must be skills|commands|agents|subagents|system-skills)" >&2
      exit 1
      ;;
  esac

  NAME=$(printf '%s' "$NAME" | tr -cd 'a-zA-Z0-9_-')
  if [ -z "$NAME" ]; then
    echo "error: invalid name" >&2
    exit 1
  fi

  if [ "$CATEGORY" = "commands" ] && [ "$NAME" = "stats" ]; then
    exit 0
  fi

  increment_counter "$CATEGORY" "$NAME"
  exit 0
fi

# ── Hook mode: stdin JSON (auto-detect postToolUse vs subagentStart) ──

INPUT=$(cat)

# ── Try subagentStart detection first ─────────────────────────────────
# subagentStart provides subagent type in stdin JSON.
# Try common field names: subagent_type, type
SUBAGENT_TYPE=$(json_field "$INPUT" "subagent_type")
if [ -z "$SUBAGENT_TYPE" ]; then
  SUBAGENT_TYPE=$(json_field "$INPUT" "type")
fi

if [ -n "$SUBAGENT_TYPE" ]; then
  CLEAN_TYPE=$(printf '%s' "$SUBAGENT_TYPE" | tr -cd 'a-zA-Z0-9_-')
  if [ -n "$CLEAN_TYPE" ]; then
    increment_counter "subagents" "$CLEAN_TYPE"
    # Auto-track matching custom agent (.cursor/agents/{type}.md)
    if [ -f ".cursor/agents/${CLEAN_TYPE}.md" ]; then
      increment_counter "agents" "$CLEAN_TYPE"
    fi
  fi
  printf '{}\n'
  exit 0
fi

# ── postToolUse(Read) mode: extract file path ─────────────────────────

FILE_PATH=$(json_nested_field "$INPUT" "tool_input" "path")

if [ -z "$FILE_PATH" ]; then
  FILE_PATH=$(json_field "$INPUT" "path")
fi

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

CATEGORY=""
NAME=""

case "$FILE_PATH" in
  */.cursor/skills/*/SKILL.md|.cursor/skills/*/SKILL.md)
    CATEGORY="skills"
    NAME=$(echo "$FILE_PATH" | sed 's|.*/\.cursor/skills/\([^/]*\)/SKILL\.md|\1|')
    if [ "$NAME" = "$FILE_PATH" ]; then
      NAME=$(echo "$FILE_PATH" | sed 's|\.cursor/skills/\([^/]*\)/SKILL\.md|\1|')
    fi
    ;;
  */skills-cursor/*/SKILL.md|*/.cursor/skills-cursor/*/SKILL.md)
    CATEGORY="system-skills"
    NAME=$(echo "$FILE_PATH" | sed 's|.*/skills-cursor/\([^/]*\)/SKILL\.md|\1|')
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
    printf '{}\n'
    exit 0
    ;;
esac

if [ -z "$NAME" ] || [ -z "$CATEGORY" ]; then
  printf '{}\n'
  exit 0
fi

if [ "$CATEGORY" = "commands" ] && [ "$NAME" = "stats" ]; then
  printf '{}\n'
  exit 0
fi

increment_counter "$CATEGORY" "$NAME"

printf '{}\n'
exit 0
