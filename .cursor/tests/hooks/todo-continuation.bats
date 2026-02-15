#!/usr/bin/env bats
# Tests for .cursor/hooks/todo-continuation.sh (postToolUse hook)
# Verifies TODO continuation reminders during active Ralph Loop in task-folders

HOOK_SCRIPT="$BATS_TEST_DIRNAME/../../hooks/todo-continuation.sh"
FIXTURES="$BATS_TEST_DIRNAME/../fixtures"

setup() {
  TEST_DIR="$(mktemp -d)"
  mkdir -p "$TEST_DIR/.cursor/project/state"
  ORIG_DIR="$(pwd)"
  cd "$TEST_DIR"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

make_input() {
  local tool="$1"
  printf '{"tool_name":"%s","output":"ok"}' "$tool"
}

setup_active_task() {
  mkdir -p .cursor/project/state/2026-02-13T1430_login-feature
  cp "$FIXTURES/ralph-state-active.md" .cursor/project/state/2026-02-13T1430_login-feature/ralph-state.md
}

setup_inactive_task() {
  mkdir -p .cursor/project/state/2026-02-13T1430_login-feature
  cp "$FIXTURES/ralph-state-inactive.md" .cursor/project/state/2026-02-13T1430_login-feature/ralph-state.md
}

# --- Ralph active + matching tools ---

@test "todo-continuation: Write + ralph active in task-folder → continuation message" {
  setup_active_task
  result=$(make_input "Write" | bash "$HOOK_SCRIPT")
  [[ "$result" == *'[TODO Continuation]'* ]]
  [[ "$result" == *'Ralph Loop active'* ]]
}

@test "todo-continuation: StrReplace + ralph active → continuation message" {
  setup_active_task
  result=$(make_input "StrReplace" | bash "$HOOK_SCRIPT")
  [[ "$result" == *'[TODO Continuation]'* ]]
}

@test "todo-continuation: Shell + ralph active → continuation message" {
  setup_active_task
  result=$(make_input "Shell" | bash "$HOOK_SCRIPT")
  [[ "$result" == *'[TODO Continuation]'* ]]
}

@test "todo-continuation: EditNotebook + ralph active → continuation message" {
  setup_active_task
  result=$(make_input "EditNotebook" | bash "$HOOK_SCRIPT")
  [[ "$result" == *'[TODO Continuation]'* ]]
}

# --- Ralph inactive ---

@test "todo-continuation: Write + ralph inactive → empty JSON" {
  setup_inactive_task
  result=$(make_input "Write" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

# --- No ralph-state.md file ---

@test "todo-continuation: Write + no task-folder → empty JSON" {
  result=$(make_input "Write" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

# --- Non-matching tools ---

@test "todo-continuation: Read tool + ralph active → empty JSON" {
  setup_active_task
  result=$(make_input "Read" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

@test "todo-continuation: Grep tool + ralph active → empty JSON" {
  setup_active_task
  result=$(make_input "Grep" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

@test "todo-continuation: Glob tool + ralph active → empty JSON" {
  setup_active_task
  result=$(make_input "Glob" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

# --- Exit code ---

@test "todo-continuation: exit code is always 0" {
  setup_active_task
  make_input "Write" | bash "$HOOK_SCRIPT"
  [ $? -eq 0 ]
}
