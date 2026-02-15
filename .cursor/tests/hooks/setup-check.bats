#!/usr/bin/env bats
# Tests for .cursor/hooks/setup-check.sh (sessionStart hook)
# Verifies bootstrap status detection: manifest.json and task-folder ralph-state.md

HOOK_SCRIPT="$BATS_TEST_DIRNAME/../../hooks/setup-check.sh"

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

@test "setup-check: manifest.json missing → additional_context contains warning" {
  # No manifest.json created → should warn
  result=$(echo '{}' | bash "$HOOK_SCRIPT")
  [[ "$result" == *'"additional_context"'* ]]
  [[ "$result" == *'manifest.json not found'* ]]
  [[ "$result" == *'"continue":true'* ]]
}

@test "setup-check: manifest.json exists → minimal JSON output" {
  echo '{"version":"1.0.0"}' > .cursor/project/manifest.json
  result=$(echo '{}' | bash "$HOOK_SCRIPT")
  [[ "$result" == '{"continue":true}' ]]
}

@test "setup-check: ralph-state.md active in task-folder → interrupted loop warning" {
  echo '{"version":"1.0.0"}' > .cursor/project/manifest.json
  mkdir -p .cursor/project/state/2026-02-13T1430_login-feature
  printf '# Ralph State\n\n- active: true\n- iteration: 3\n' > .cursor/project/state/2026-02-13T1430_login-feature/ralph-state.md
  result=$(echo '{}' | bash "$HOOK_SCRIPT")
  [[ "$result" == *'Interrupted'* ]]
  [[ "$result" == *'2026-02-13T1430_login-feature'* ]]
  [[ "$result" == *'"continue":true'* ]]
}

@test "setup-check: ralph-state.md inactive in task-folder → no warning" {
  echo '{"version":"1.0.0"}' > .cursor/project/manifest.json
  mkdir -p .cursor/project/state/2026-02-13T1430_login-feature
  printf '# Ralph State\n\n- active: false\n- iteration: 5\n' > .cursor/project/state/2026-02-13T1430_login-feature/ralph-state.md
  result=$(echo '{}' | bash "$HOOK_SCRIPT")
  [[ "$result" == '{"continue":true}' ]]
}

@test "setup-check: both manifest missing and ralph active → both warnings" {
  mkdir -p .cursor/project/state/2026-02-13T1430_login-feature
  printf '# Ralph State\n\n- active: true\n- iteration: 3\n' > .cursor/project/state/2026-02-13T1430_login-feature/ralph-state.md
  result=$(echo '{}' | bash "$HOOK_SCRIPT")
  [[ "$result" == *'manifest.json not found'* ]]
  [[ "$result" == *'Interrupted'* ]]
  [[ "$result" == *'"continue":true'* ]]
}

@test "setup-check: exit code is always 0" {
  echo '{}' | bash "$HOOK_SCRIPT"
  [ $? -eq 0 ]
}
