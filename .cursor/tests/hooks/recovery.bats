#!/usr/bin/env bats
# Tests for .cursor/hooks/recovery.sh (postToolUse hook)
# Verifies error recovery suggestions for failed edits and shell commands

HOOK_SCRIPT="$BATS_TEST_DIRNAME/../../hooks/recovery.sh"

make_input() {
  local tool="$1"
  local has_error="$2"
  if [ "$has_error" = "true" ]; then
    printf '{"tool_name":"%s","error":"some error occurred"}' "$tool"
  else
    printf '{"tool_name":"%s","output":"success"}' "$tool"
  fi
}

# --- Edit tools with errors ---

@test "recovery: StrReplace + error → recovery message" {
  result=$(make_input "StrReplace" "true" | bash "$HOOK_SCRIPT")
  [[ "$result" == *'[Recovery]'* ]]
  [[ "$result" == *'Edit failed'* ]]
}

@test "recovery: Write + error → recovery message" {
  result=$(make_input "Write" "true" | bash "$HOOK_SCRIPT")
  [[ "$result" == *'[Recovery]'* ]]
  [[ "$result" == *'Edit failed'* ]]
}

@test "recovery: EditNotebook + error → recovery message" {
  result=$(make_input "EditNotebook" "true" | bash "$HOOK_SCRIPT")
  [[ "$result" == *'[Recovery]'* ]]
  [[ "$result" == *'Edit failed'* ]]
}

@test "recovery: Shell + error → recovery message" {
  result=$(make_input "Shell" "true" | bash "$HOOK_SCRIPT")
  [[ "$result" == *'[Recovery]'* ]]
  [[ "$result" == *'Shell command failed'* ]]
}

# --- Tools without errors → empty JSON ---

@test "recovery: StrReplace + no error → empty JSON" {
  result=$(make_input "StrReplace" "false" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

@test "recovery: Write + no error → empty JSON" {
  result=$(make_input "Write" "false" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

@test "recovery: Shell + no error → empty JSON" {
  result=$(make_input "Shell" "false" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

# --- Non-matching tools → empty JSON ---

@test "recovery: Read tool → empty JSON regardless of error" {
  result=$(make_input "Read" "true" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

@test "recovery: Grep tool → empty JSON" {
  result=$(make_input "Grep" "true" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

# --- Exit code ---

@test "recovery: exit code is always 0" {
  make_input "StrReplace" "true" | bash "$HOOK_SCRIPT"
  [ $? -eq 0 ]
}
