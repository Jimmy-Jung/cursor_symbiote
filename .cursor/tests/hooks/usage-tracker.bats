#!/usr/bin/env bats
# Tests for .cursor/hooks/usage-tracker.sh
# Triple-mode: postToolUse hook + subagentStart hook + CLI self-report
# Covers: skills, commands, agents, subagents, system-skills
#
# Author: jimmy
# Date: 2026-02-16

HOOK_SCRIPT="$BATS_TEST_DIRNAME/../../hooks/usage-tracker.sh"

setup() {
  TEST_WORK_DIR=$(mktemp -d)
  mkdir -p "$TEST_WORK_DIR/.cursor/project/usage-data"/{skills,commands,agents,subagents,system-skills}
  ORIG_DIR="$PWD"
  cd "$TEST_WORK_DIR"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_WORK_DIR"
}

make_hook_input() {
  local path="$1"
  printf '{"tool_name":"Read","tool_input":{"path":"%s"}}' "$path"
}

read_count() {
  local file="$1"
  if [ -f "$file" ]; then
    cut -d'|' -f1 "$file"
  else
    echo "0"
  fi
}

read_timestamp() {
  local file="$1"
  if [ -f "$file" ]; then
    cut -d'|' -f2 "$file"
  else
    echo ""
  fi
}

# ═══════════════════════════════════════════════════════════════════════
#  CLI mode: basic operations
# ═══════════════════════════════════════════════════════════════════════

@test "cli: skills category → creates file with count 1" {
  run bash "$HOOK_SCRIPT" skills doctor
  [ "$status" -eq 0 ]
  [ "$(read_count .cursor/project/usage-data/skills/doctor)" -eq 1 ]
}

@test "cli: commands category → creates file with count 1" {
  run bash "$HOOK_SCRIPT" commands autopilot
  [ "$status" -eq 0 ]
  [ "$(read_count .cursor/project/usage-data/commands/autopilot)" -eq 1 ]
}

@test "cli: agents category → creates file with count 1" {
  run bash "$HOOK_SCRIPT" agents implementer
  [ "$status" -eq 0 ]
  [ "$(read_count .cursor/project/usage-data/agents/implementer)" -eq 1 ]
}

@test "cli: subagents category → creates file with count 1" {
  run bash "$HOOK_SCRIPT" subagents explore
  [ "$status" -eq 0 ]
  [ "$(read_count .cursor/project/usage-data/subagents/explore)" -eq 1 ]
}

@test "cli: system-skills category → creates file with count 1" {
  run bash "$HOOK_SCRIPT" system-skills create-rule
  [ "$status" -eq 0 ]
  [ "$(read_count .cursor/project/usage-data/system-skills/create-rule)" -eq 1 ]
}

@test "cli: sequential calls increment counter" {
  bash "$HOOK_SCRIPT" skills planning
  bash "$HOOK_SCRIPT" skills planning
  bash "$HOOK_SCRIPT" skills planning
  [ "$(read_count .cursor/project/usage-data/skills/planning)" -eq 3 ]
}

@test "cli: creates .tracked-since on first call" {
  [ ! -f .cursor/project/usage-data/.tracked-since ]
  bash "$HOOK_SCRIPT" skills doctor
  [ -f .cursor/project/usage-data/.tracked-since ]
  local ts
  ts=$(cat .cursor/project/usage-data/.tracked-since)
  [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]
}

@test "cli: does not overwrite existing .tracked-since" {
  echo "2025-01-01T00:00:00Z" > .cursor/project/usage-data/.tracked-since
  bash "$HOOK_SCRIPT" skills doctor
  [ "$(cat .cursor/project/usage-data/.tracked-since)" = "2025-01-01T00:00:00Z" ]
}

@test "cli: timestamp follows ISO8601 format" {
  bash "$HOOK_SCRIPT" skills doctor
  local ts
  ts=$(read_timestamp .cursor/project/usage-data/skills/doctor)
  [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "cli: no stdout output" {
  run bash "$HOOK_SCRIPT" skills doctor
  [ "$output" = "" ]
}

# ═══════════════════════════════════════════════════════════════════════
#  CLI mode: validation
# ═══════════════════════════════════════════════════════════════════════

@test "cli: invalid category → exit 1 with error" {
  run bash "$HOOK_SCRIPT" invalid-cat test
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid category"* ]]
}

@test "cli: category 'rules' is invalid → exit 1" {
  run bash "$HOOK_SCRIPT" rules synapse
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid category"* ]]
}

@test "cli: empty name → exit 1 with error" {
  run bash "$HOOK_SCRIPT" skills ''
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid name"* ]]
}

@test "cli: name with only special chars → exit 1" {
  run bash "$HOOK_SCRIPT" skills '../../..'
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid name"* ]]
}

@test "cli: name sanitization strips path traversal" {
  bash "$HOOK_SCRIPT" skills 'hello/../etc/passwd'
  [ -f .cursor/project/usage-data/skills/helloetcpasswd ]
  [ ! -f .cursor/project/usage-data/skills/hello ]
  [ "$(read_count .cursor/project/usage-data/skills/helloetcpasswd)" -eq 1 ]
}

@test "cli: name with spaces and special chars → sanitized" {
  bash "$HOOK_SCRIPT" agents 'my agent!@#$%^&*()'
  [ -f .cursor/project/usage-data/agents/myagent ]
  [ "$(read_count .cursor/project/usage-data/agents/myagent)" -eq 1 ]
}

@test "cli: hyphenated name preserved" {
  bash "$HOOK_SCRIPT" skills code-accuracy
  [ -f .cursor/project/usage-data/skills/code-accuracy ]
  [ "$(read_count .cursor/project/usage-data/skills/code-accuracy)" -eq 1 ]
}

@test "cli: underscore name preserved" {
  bash "$HOOK_SCRIPT" skills my_skill
  [ -f .cursor/project/usage-data/skills/my_skill ]
  [ "$(read_count .cursor/project/usage-data/skills/my_skill)" -eq 1 ]
}

# ═══════════════════════════════════════════════════════════════════════
#  CLI mode: stats exclusion
# ═══════════════════════════════════════════════════════════════════════

@test "cli: commands/stats is excluded" {
  run bash "$HOOK_SCRIPT" commands stats
  [ "$status" -eq 0 ]
  [ ! -f .cursor/project/usage-data/commands/stats ]
}

@test "cli: skills/stats is NOT excluded" {
  bash "$HOOK_SCRIPT" skills stats
  [ -f .cursor/project/usage-data/skills/stats ]
}

# ═══════════════════════════════════════════════════════════════════════
#  CLI mode: corrupt data recovery
# ═══════════════════════════════════════════════════════════════════════

@test "cli: corrupt data file → resets to 1" {
  echo "garbage|2025-01-01T00:00:00Z" > .cursor/project/usage-data/skills/broken
  bash "$HOOK_SCRIPT" skills broken
  [ "$(read_count .cursor/project/usage-data/skills/broken)" -eq 1 ]
}

@test "cli: empty data file → starts at 1" {
  touch .cursor/project/usage-data/skills/empty-file
  bash "$HOOK_SCRIPT" skills empty-file
  [ "$(read_count .cursor/project/usage-data/skills/empty-file)" -eq 1 ]
}

@test "cli: data file with no separator → resets to 1" {
  echo "notanumber" > .cursor/project/usage-data/agents/bad
  bash "$HOOK_SCRIPT" agents bad
  [ "$(read_count .cursor/project/usage-data/agents/bad)" -eq 1 ]
}

# ═══════════════════════════════════════════════════════════════════════
#  CLI mode: subagents and system-skills
# ═══════════════════════════════════════════════════════════════════════

@test "cli: all builtin subagent types" {
  for type in generalPurpose explore shell browser-use; do
    bash "$HOOK_SCRIPT" subagents "$type"
  done
  [ "$(read_count .cursor/project/usage-data/subagents/generalPurpose)" -eq 1 ]
  [ "$(read_count .cursor/project/usage-data/subagents/explore)" -eq 1 ]
  [ "$(read_count .cursor/project/usage-data/subagents/shell)" -eq 1 ]
  [ "$(read_count .cursor/project/usage-data/subagents/browser-use)" -eq 1 ]
}

@test "cli: all system skill types" {
  for name in create-rule create-skill create-subagent update-cursor-settings migrate-to-skills; do
    bash "$HOOK_SCRIPT" system-skills "$name"
  done
  [ "$(read_count .cursor/project/usage-data/system-skills/create-rule)" -eq 1 ]
  [ "$(read_count .cursor/project/usage-data/system-skills/create-subagent)" -eq 1 ]
  [ "$(read_count .cursor/project/usage-data/system-skills/migrate-to-skills)" -eq 1 ]
}

# ═══════════════════════════════════════════════════════════════════════
#  SubAgent hook mode: subagentStart stdin JSON
# ═══════════════════════════════════════════════════════════════════════

@test "subagent-hook: subagent_type field → tracked" {
  result=$(printf '{"subagent_type":"explore","description":"search code"}' | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/subagents/explore)" -eq 1 ]
}

@test "subagent-hook: type field fallback → tracked" {
  result=$(printf '{"type":"shell","description":"run command"}' | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/subagents/shell)" -eq 1 ]
}

@test "subagent-hook: generalPurpose → tracked" {
  result=$(printf '{"subagent_type":"generalPurpose"}' | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/subagents/generalPurpose)" -eq 1 ]
}

@test "subagent-hook: browser-use → tracked" {
  result=$(printf '{"subagent_type":"browser-use"}' | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/subagents/browser-use)" -eq 1 ]
}

@test "subagent-hook: custom agent types (analyst, implementer, etc.) → tracked" {
  printf '{"subagent_type":"analyst"}' | bash "$HOOK_SCRIPT"
  printf '{"subagent_type":"implementer"}' | bash "$HOOK_SCRIPT"
  printf '{"subagent_type":"reviewer"}' | bash "$HOOK_SCRIPT"
  [ "$(read_count .cursor/project/usage-data/subagents/analyst)" -eq 1 ]
  [ "$(read_count .cursor/project/usage-data/subagents/implementer)" -eq 1 ]
  [ "$(read_count .cursor/project/usage-data/subagents/reviewer)" -eq 1 ]
}

@test "subagent-hook: sequential calls increment" {
  printf '{"subagent_type":"explore"}' | bash "$HOOK_SCRIPT"
  printf '{"subagent_type":"explore"}' | bash "$HOOK_SCRIPT"
  printf '{"subagent_type":"explore"}' | bash "$HOOK_SCRIPT"
  [ "$(read_count .cursor/project/usage-data/subagents/explore)" -eq 3 ]
}

@test "subagent-hook: sanitizes type name" {
  result=$(printf '{"subagent_type":"bad/../type"}' | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ -f .cursor/project/usage-data/subagents/badtype ]
}

# ═══════════════════════════════════════════════════════════════════════
#  Hook mode: system-skills (skills-cursor paths)
# ═══════════════════════════════════════════════════════════════════════

@test "hook: absolute skills-cursor path → system-skills tracked" {
  result=$(make_hook_input "/Users/jimmy/.cursor/skills-cursor/create-rule/SKILL.md" | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/system-skills/create-rule)" -eq 1 ]
}

@test "hook: skills-cursor create-skill → tracked" {
  result=$(make_hook_input "/Users/jimmy/.cursor/skills-cursor/create-skill/SKILL.md" | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/system-skills/create-skill)" -eq 1 ]
}

@test "hook: skills-cursor update-cursor-settings → tracked" {
  result=$(make_hook_input "/Users/jimmy/.cursor/skills-cursor/update-cursor-settings/SKILL.md" | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/system-skills/update-cursor-settings)" -eq 1 ]
}

@test "hook: skills-cursor non-SKILL.md → not tracked" {
  result=$(make_hook_input "/Users/jimmy/.cursor/skills-cursor/create-rule/README.md" | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(find .cursor/project/usage-data/system-skills -type f | wc -l)" -eq 0 ]
}

# ═══════════════════════════════════════════════════════════════════════
#  Hook mode: skills path variants
# ═══════════════════════════════════════════════════════════════════════

@test "hook: absolute skills path → tracked" {
  result=$(make_hook_input "/Users/jimmy/project/.cursor/skills/doctor/SKILL.md" | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/skills/doctor)" -eq 1 ]
}

@test "hook: relative skills path → tracked" {
  result=$(make_hook_input ".cursor/skills/planning/SKILL.md" | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/skills/planning)" -eq 1 ]
}

# ═══════════════════════════════════════════════════════════════════════
#  Hook mode: commands path variants
# ═══════════════════════════════════════════════════════════════════════

@test "hook: absolute commands path → tracked" {
  result=$(make_hook_input "/Users/jimmy/project/.cursor/commands/ralph.md" | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/commands/ralph)" -eq 1 ]
}

@test "hook: relative commands path → tracked" {
  result=$(make_hook_input ".cursor/commands/autopilot.md" | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/commands/autopilot)" -eq 1 ]
}

# ═══════════════════════════════════════════════════════════════════════
#  Hook mode: agents path variants
# ═══════════════════════════════════════════════════════════════════════

@test "hook: absolute agents path → tracked" {
  result=$(make_hook_input "/Users/jimmy/project/.cursor/agents/implementer.md" | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/agents/implementer)" -eq 1 ]
}

@test "hook: relative agents path → tracked" {
  result=$(make_hook_input ".cursor/agents/critic.md" | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/agents/critic)" -eq 1 ]
}

# ═══════════════════════════════════════════════════════════════════════
#  Hook mode: non-tracked paths
# ═══════════════════════════════════════════════════════════════════════

@test "hook: regular source file → not tracked" {
  result=$(make_hook_input "src/main.ts" | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(find .cursor/project/usage-data -type f -not -name '.tracked-since' | wc -l)" -eq 0 ]
}

@test "hook: .cursor/rules file → not tracked" {
  result=$(make_hook_input ".cursor/rules/kernel/synapse.mdc" | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(find .cursor/project/usage-data -type f -not -name '.tracked-since' | wc -l)" -eq 0 ]
}

@test "hook: .cursor/hooks file → not tracked" {
  result=$(make_hook_input ".cursor/hooks/guard-shell.sh" | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(find .cursor/project/usage-data -type f -not -name '.tracked-since' | wc -l)" -eq 0 ]
}

@test "hook: skills file that is not SKILL.md → not tracked" {
  result=$(make_hook_input ".cursor/skills/doctor/scripts/validate.sh" | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(find .cursor/project/usage-data -type f -not -name '.tracked-since' | wc -l)" -eq 0 ]
}

# ═══════════════════════════════════════════════════════════════════════
#  Hook mode: edge cases
# ═══════════════════════════════════════════════════════════════════════

@test "hook: empty JSON → empty output, exit 0" {
  run bash -c 'echo "{}" | bash "'"$HOOK_SCRIPT"'"'
  [ "$status" -eq 0 ]
  [ "$output" = '{}' ]
}

@test "hook: no path field → empty output, exit 0" {
  run bash -c 'echo "{\"tool_name\":\"Read\",\"tool_input\":{}}" | bash "'"$HOOK_SCRIPT"'"'
  [ "$status" -eq 0 ]
  [ "$output" = '{}' ]
}

@test "hook: malformed JSON → empty output, exit 0" {
  run bash -c 'echo "not-json-at-all" | bash "'"$HOOK_SCRIPT"'"'
  [ "$status" -eq 0 ]
  [ "$output" = '{}' ]
}

@test "hook: stats command excluded" {
  make_hook_input ".cursor/commands/stats.md" | bash "$HOOK_SCRIPT"
  [ ! -f .cursor/project/usage-data/commands/stats ]
}

@test "hook: output is always {}" {
  result=$(make_hook_input "/Users/jimmy/.cursor/skills/doctor/SKILL.md" | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
}

# ═══════════════════════════════════════════════════════════════════════
#  Hook mode: alternative JSON field locations
# ═══════════════════════════════════════════════════════════════════════

@test "hook: top-level path field → tracked" {
  result=$(printf '{"path":".cursor/skills/verify-loop/SKILL.md"}' | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/skills/verify-loop)" -eq 1 ]
}

@test "hook: tool_input.file_path field → tracked" {
  result=$(printf '{"tool_input":{"file_path":".cursor/agents/debugger.md"}}' | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/agents/debugger)" -eq 1 ]
}

@test "hook: top-level file_path field → tracked" {
  result=$(printf '{"file_path":".cursor/commands/ralph.md"}' | bash "$HOOK_SCRIPT")
  [ "$result" = '{}' ]
  [ "$(read_count .cursor/project/usage-data/commands/ralph)" -eq 1 ]
}

# ═══════════════════════════════════════════════════════════════════════
#  Hook mode: corrupt data recovery
# ═══════════════════════════════════════════════════════════════════════

@test "hook: corrupt existing data → resets count" {
  echo "xyz|2025-01-01T00:00:00Z" > .cursor/project/usage-data/skills/corrupt
  make_hook_input ".cursor/skills/corrupt/SKILL.md" | bash "$HOOK_SCRIPT"
  [ "$(read_count .cursor/project/usage-data/skills/corrupt)" -eq 1 ]
}

# ═══════════════════════════════════════════════════════════════════════
#  Cross-mode: both modes share same data store
# ═══════════════════════════════════════════════════════════════════════

@test "cross: CLI then hook increments same counter" {
  bash "$HOOK_SCRIPT" skills doctor
  [ "$(read_count .cursor/project/usage-data/skills/doctor)" -eq 1 ]
  make_hook_input ".cursor/skills/doctor/SKILL.md" | bash "$HOOK_SCRIPT"
  [ "$(read_count .cursor/project/usage-data/skills/doctor)" -eq 2 ]
}

@test "cross: hook then CLI increments same counter" {
  make_hook_input ".cursor/agents/planner.md" | bash "$HOOK_SCRIPT"
  [ "$(read_count .cursor/project/usage-data/agents/planner)" -eq 1 ]
  bash "$HOOK_SCRIPT" agents planner
  [ "$(read_count .cursor/project/usage-data/agents/planner)" -eq 2 ]
}

@test "cross: subagent hook then CLI increments same counter" {
  printf '{"subagent_type":"explore"}' | bash "$HOOK_SCRIPT"
  [ "$(read_count .cursor/project/usage-data/subagents/explore)" -eq 1 ]
  bash "$HOOK_SCRIPT" subagents explore
  [ "$(read_count .cursor/project/usage-data/subagents/explore)" -eq 2 ]
}

@test "cross: system-skills hook then CLI increments same counter" {
  make_hook_input "/Users/jimmy/.cursor/skills-cursor/create-rule/SKILL.md" | bash "$HOOK_SCRIPT"
  [ "$(read_count .cursor/project/usage-data/system-skills/create-rule)" -eq 1 ]
  bash "$HOOK_SCRIPT" system-skills create-rule
  [ "$(read_count .cursor/project/usage-data/system-skills/create-rule)" -eq 2 ]
}

# ═══════════════════════════════════════════════════════════════════════
#  Data format verification
# ═══════════════════════════════════════════════════════════════════════

@test "data: file format is {count}|{ISO8601}" {
  bash "$HOOK_SCRIPT" skills doctor
  local content
  content=$(cat .cursor/project/usage-data/skills/doctor)
  [[ "$content" =~ ^[0-9]+\|[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "data: single line, no trailing content" {
  bash "$HOOK_SCRIPT" commands autopilot
  local lines
  lines=$(wc -l < .cursor/project/usage-data/commands/autopilot)
  [ "$lines" -eq 1 ]
}

@test "data: no .tmp files left behind" {
  bash "$HOOK_SCRIPT" skills doctor
  [ "$(find .cursor/project/usage-data -name '*.tmp' | wc -l)" -eq 0 ]
}
