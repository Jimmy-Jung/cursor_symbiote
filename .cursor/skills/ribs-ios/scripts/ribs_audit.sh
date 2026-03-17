#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"

if ! command -v rg >/dev/null 2>&1; then
  echo "ERROR: ripgrep (rg) is required."
  exit 2
fi

declare -i PASS_COUNT=0
declare -i HIGH_FAIL=0
declare -i MID_FAIL=0
declare -i LOW_WARN=0

log_pass() {
  PASS_COUNT+=1
  printf 'PASS  [%s] %s\n' "$1" "$2"
}

log_fail() {
  local severity="$1"
  local code="$2"
  local message="$3"
  printf 'FAIL  [%s] %s\n' "$code" "$message"
  case "$severity" in
    high) HIGH_FAIL+=1 ;;
    medium) MID_FAIL+=1 ;;
    low) LOW_WARN+=1 ;;
  esac
}

check_root_launchrouter() {
  if rg -n --glob '*.swift' 'class RootRouter: .*LaunchRouter<' "$TARGET_DIR/Modules" >/dev/null 2>&1; then
    log_pass "root-launchrouter" "RootRouter uses LaunchRouter."
  else
    log_fail high "root-launchrouter" "RootRouter should inherit LaunchRouter<...>."
  fi
}

check_app_launch_call() {
  if rg -n --glob '*.swift' 'launchRouter\.launch\(from:' "$TARGET_DIR/App" "$TARGET_DIR/Modules" >/dev/null 2>&1; then
    log_pass "root-launch-call" "App entry launches root router via launch(from:)."
  else
    log_fail high "root-launch-call" "App entry should call launchRouter.launch(from: window)."
  fi
}

check_builder_router_boundary() {
  local suspect_files=()
  while IFS= read -r file; do
    if awk '
      BEGIN { in_interactor = 0; depth = 0; found = 0 }
      {
        line = $0
        if (in_interactor == 0 && line ~ /class[[:space:]].*Interactor[[:space:]:<]/) {
          in_interactor = 1
          depth = 0
          found = 0
        }

        if (in_interactor == 1) {
          if (line ~ /Builder/) {
            found = 1
          }

          tmp = line
          open_count = gsub(/\{/, "{", tmp)
          tmp = line
          close_count = gsub(/\}/, "}", tmp)
          depth += open_count - close_count

          if (depth <= 0 && open_count > 0) {
            if (found == 1) {
              exit 0
            }
            in_interactor = 0
            depth = 0
            found = 0
          }
        }
      }
      END { exit 1 }
    ' "$file"; then
      suspect_files+=("$file")
    fi
  done < <(rg --files --glob '*.swift' "$TARGET_DIR/Modules" "$TARGET_DIR/App" 2>/dev/null || true)

  if ((${#suspect_files[@]} == 0)); then
    log_pass "interactor-builder-ownership" "No Interactor owns child builders."
  else
    log_fail high "interactor-builder-ownership" "Interactor appears to own Builder in: ${suspect_files[*]}"
  fi
}

check_dependency_component_pattern() {
  local dep_ok comp_ok builder_ok
  dep_ok=0
  comp_ok=0
  builder_ok=0
  rg -n --glob '*.swift' 'protocol .*Dependency: Dependency' "$TARGET_DIR/Modules" >/dev/null 2>&1 && dep_ok=1
  rg -n --glob '*.swift' 'Component<' "$TARGET_DIR/Modules" >/dev/null 2>&1 && comp_ok=1
  rg -n --glob '*.swift' 'Builder<' "$TARGET_DIR/Modules" >/dev/null 2>&1 && builder_ok=1

  if [[ "$dep_ok" -eq 1 && "$comp_ok" -eq 1 && "$builder_ok" -eq 1 ]]; then
    log_pass "dependency-component-builder" "Dependency/Component/Builder generic pattern exists."
  else
    log_fail medium "dependency-component-builder" "Expected protocol Dependency + Component<> + Builder<> pattern."
  fi
}

check_presentable_listener_boundary() {
  local protocol_ok listener_var_ok
  protocol_ok=0
  listener_var_ok=0
  rg -n --glob '*.swift' 'protocol .*PresentableListener' "$TARGET_DIR/Modules" >/dev/null 2>&1 && protocol_ok=1
  rg -n --glob '*.swift' 'var listener: .*PresentableListener\?' "$TARGET_DIR/Modules" >/dev/null 2>&1 && listener_var_ok=1

  if [[ "$protocol_ok" -eq 1 && "$listener_var_ok" -eq 1 ]]; then
    log_pass "presentable-listener" "PresentableListener boundary is defined."
  else
    log_fail medium "presentable-listener" "Missing PresentableListener protocol or listener property."
  fi
}

check_manual_lifecycle_calls() {
  if rg -n --glob '*.swift' '(interactor|interactable)\.activate\(|(interactor|interactable)\.deactivate\(' "$TARGET_DIR/App" "$TARGET_DIR/Modules" >/dev/null 2>&1; then
    log_fail low "manual-lifecycle-call" "Manual activate/deactivate calls found. Verify router lifecycle ownership."
  else
    log_pass "manual-lifecycle-call" "No manual activate/deactivate calls in app modules."
  fi
}

echo "RIBs iOS Audit"
echo "Target: $TARGET_DIR"
echo

check_root_launchrouter
check_app_launch_call
check_builder_router_boundary
check_dependency_component_pattern
check_presentable_listener_boundary
check_manual_lifecycle_calls

echo
echo "Summary: pass=$PASS_COUNT high_fail=$HIGH_FAIL medium_fail=$MID_FAIL low_warn=$LOW_WARN"

if ((HIGH_FAIL > 0)); then
  exit 2
fi

if ((MID_FAIL > 0)); then
  exit 1
fi

exit 0
