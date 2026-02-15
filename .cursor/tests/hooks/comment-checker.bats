#!/usr/bin/env bats
# Tests for .cursor/hooks/comment-checker.sh (afterFileEdit hook)
# Verifies detection of unnecessary AI-generated comments

HOOK_SCRIPT="$BATS_TEST_DIRNAME/../../hooks/comment-checker.sh"
FIXTURES="$BATS_TEST_DIRNAME/../fixtures"

make_input() {
  local path="$1"
  printf '{"file_path":"%s"}' "$path"
}

# --- Skipped file types ---

@test "comment-checker: .md file → skip (empty JSON)" {
  result=$(make_input "/tmp/readme.md" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

@test "comment-checker: .json file → skip (empty JSON)" {
  result=$(make_input "/tmp/config.json" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

@test "comment-checker: .yaml file → skip (empty JSON)" {
  result=$(make_input "/tmp/config.yaml" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

@test "comment-checker: .sh file → skip (empty JSON)" {
  result=$(make_input "/tmp/script.sh" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

@test "comment-checker: .mdc file → skip (empty JSON)" {
  result=$(make_input "/tmp/rule.mdc" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

@test "comment-checker: .txt file → skip (empty JSON)" {
  result=$(make_input "/tmp/notes.txt" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

# --- Non-existent file ---

@test "comment-checker: non-existent file → empty JSON" {
  result=$(make_input "/tmp/does-not-exist-at-all.swift" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

# --- Empty file_path ---

@test "comment-checker: empty file_path → empty JSON" {
  result=$(echo '{}' | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

# --- Code files with many suspicious comments (>3) ---

@test "comment-checker: swift file with many comments → warning" {
  result=$(make_input "$FIXTURES/sample-code-many-comments.swift" | bash "$HOOK_SCRIPT")
  [[ "$result" == *'[Comment Checker]'* ]]
  [[ "$result" == *'suspicious comments detected'* ]]
}

# --- Code files with few/no suspicious comments (<=3) ---

@test "comment-checker: swift file with clean comments → empty JSON" {
  result=$(make_input "$FIXTURES/sample-code-clean.swift" | bash "$HOOK_SCRIPT")
  [[ "$result" == '{}' ]]
}

# --- Exit code ---

@test "comment-checker: exit code is always 0" {
  make_input "$FIXTURES/sample-code-many-comments.swift" | bash "$HOOK_SCRIPT"
  [ $? -eq 0 ]
}
