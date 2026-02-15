#!/bin/bash
# Doctor — 구조 검증 스크립트
# 저자: jimmy
# 날짜: 2026-02-14
#
# .cursor 설정의 구조적 무결성을 자동으로 검증합니다.
# 사용법: bash .cursor/skills/doctor/scripts/validate.sh

set -euo pipefail

# 프로젝트 루트 감지 (.cursor 디렉터리가 있는 곳)
if [ -d ".cursor" ]; then
  CURSOR_DIR=".cursor"
elif [ -d "$(git rev-parse --show-toplevel 2>/dev/null)/.cursor" ]; then
  CURSOR_DIR="$(git rev-parse --show-toplevel)/.cursor"
else
  echo "[ERROR] .cursor 디렉터리를 찾을 수 없습니다. 프로젝트 루트에서 실행하세요."
  exit 1
fi

# 카운터
PASS=0
WARN=0
FAIL=0
FAIL_LIST=()
WARN_LIST=()

pass() {
  PASS=$((PASS + 1))
}

warn() {
  WARN=$((WARN + 1))
  WARN_LIST+=("$1")
}

fail() {
  FAIL=$((FAIL + 1))
  FAIL_LIST+=("$1")
}

# YAML frontmatter에서 특정 키 값을 추출하는 간단한 파서
# 사용: extract_frontmatter_field <file> <field>
extract_frontmatter_field() {
  local file="$1"
  local field="$2"
  # frontmatter는 첫 번째 ---와 두 번째 --- 사이
  awk '/^---$/{n++; next} n==1{print}' "$file" | grep "^${field}:" | sed "s/^${field}:[[:space:]]*//" | sed 's/^"//' | sed 's/"$//'
}

has_frontmatter() {
  local file="$1"
  head -1 "$file" | grep -q "^---$"
}

echo "[Doctor Validation Report]"
echo "=========================="
echo ""

# ============================================================
# 1. hooks.json 구조 검증
# ============================================================
echo "--- 1. hooks.json 검증 ---"

HOOKS_FILE="$CURSOR_DIR/hooks.json"
if [ -f "$HOOKS_FILE" ]; then
  # version 필드 확인
  VERSION=$(jq -r '.version // empty' "$HOOKS_FILE" 2>/dev/null || echo "")
  if [ "$VERSION" = "1" ]; then
    pass
    echo "  [PASS] hooks.json version = 1"
  else
    fail "hooks.json: version 필드가 1이 아닙니다 (현재: $VERSION)"
    echo "  [FAIL] hooks.json version = $VERSION (expected: 1)"
  fi

  # 유효한 이벤트 이름 확인
  VALID_EVENTS="sessionStart preToolUse postToolUse afterFileEdit"
  EVENTS=$(jq -r '.hooks | keys[]' "$HOOKS_FILE" 2>/dev/null || echo "")
  for event in $EVENTS; do
    if echo "$VALID_EVENTS" | grep -qw "$event"; then
      pass
      echo "  [PASS] 유효한 이벤트: $event"
    else
      fail "hooks.json: 알 수 없는 이벤트 '$event'"
      echo "  [FAIL] 알 수 없는 이벤트: $event"
    fi
  done

  # 참조 스크립트 존재 및 실행 권한 확인
  SCRIPTS=$(jq -r '.hooks[][] | .command' "$HOOKS_FILE" 2>/dev/null || echo "")
  for script in $SCRIPTS; do
    if [ -f "$script" ]; then
      pass
      echo "  [PASS] 스크립트 존재: $script"
      if [ -x "$script" ]; then
        pass
        echo "  [PASS] 실행 권한 있음: $script"
      else
        warn "$script: 실행 권한이 없습니다 (chmod +x 필요)"
        echo "  [WARN] 실행 권한 없음: $script"
      fi
    else
      fail "$script: 참조 스크립트가 존재하지 않습니다"
      echo "  [FAIL] 스크립트 없음: $script"
    fi
  done

  # matcher 값 PascalCase 확인
  MATCHERS=$(jq -r '.hooks[][] | .matcher // empty' "$HOOKS_FILE" 2>/dev/null || echo "")
  for matcher in $MATCHERS; do
    # matcher는 파이프(|)로 구분된 PascalCase 값
    IFS='|' read -ra PARTS <<< "$matcher"
    for part in "${PARTS[@]}"; do
      if echo "$part" | grep -qE '^[A-Z][a-zA-Z]*$'; then
        pass
      else
        warn "hooks.json: matcher '$part'가 PascalCase가 아닙니다"
        echo "  [WARN] matcher PascalCase 위반: $part"
      fi
    done
  done
else
  fail "hooks.json 파일이 존재하지 않습니다"
  echo "  [FAIL] hooks.json 없음"
fi

echo ""

# ============================================================
# 2. 에이전트 frontmatter 검증
# ============================================================
echo "--- 2. 에이전트 검증 ---"

AGENTS_DIR="$CURSOR_DIR/agents"
if [ -d "$AGENTS_DIR" ]; then
  for agent_file in "$AGENTS_DIR"/*.md; do
    [ -f "$agent_file" ] || continue
    agent_name=$(basename "$agent_file" .md)

    if ! has_frontmatter "$agent_file"; then
      fail "$agent_file: YAML frontmatter가 없습니다"
      echo "  [FAIL] frontmatter 없음: $agent_name"
      continue
    fi

    # name 필드
    NAME=$(extract_frontmatter_field "$agent_file" "name")
    if [ -n "$NAME" ]; then
      pass
    else
      fail "agents/$agent_name.md: 'name' 필드 누락"
      echo "  [FAIL] name 누락: $agent_name"
    fi

    # description 필드
    DESC=$(extract_frontmatter_field "$agent_file" "description")
    if [ -n "$DESC" ]; then
      pass
      # "Use when" 패턴 확인
      if echo "$DESC" | grep -qi "use when\|use only when"; then
        pass
      else
        warn "agents/$agent_name.md: description에 'Use when' 패턴이 없습니다"
        echo "  [WARN] 'Use when' 없음: $agent_name"
      fi
    else
      fail "agents/$agent_name.md: 'description' 필드 누락"
      echo "  [FAIL] description 누락: $agent_name"
    fi

    # model 필드
    MODEL=$(extract_frontmatter_field "$agent_file" "model")
    if [ -n "$MODEL" ]; then
      if [ "$MODEL" = "fast" ] || [ "$MODEL" = "inherit" ]; then
        pass
        echo "  [PASS] $agent_name: name=$NAME, model=$MODEL"
      else
        warn "agents/$agent_name.md: model='$MODEL' (expected: fast 또는 inherit)"
        echo "  [WARN] model 값 이상: $agent_name ($MODEL)"
      fi
    else
      fail "agents/$agent_name.md: 'model' 필드 누락"
      echo "  [FAIL] model 누락: $agent_name"
    fi
  done
else
  warn "agents/ 디렉터리가 없습니다"
  echo "  [WARN] agents/ 디렉터리 없음"
fi

echo ""

# ============================================================
# 3. 스킬 frontmatter 검증
# ============================================================
echo "--- 3. 스킬 검증 ---"

SKILLS_DIR="$CURSOR_DIR/skills"
if [ -d "$SKILLS_DIR" ]; then
  for skill_dir in "$SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    folder_name=$(basename "$skill_dir")
    skill_file="$skill_dir/SKILL.md"

    if [ ! -f "$skill_file" ]; then
      fail "skills/$folder_name/: SKILL.md 파일이 없습니다"
      echo "  [FAIL] SKILL.md 없음: $folder_name"
      continue
    fi

    if ! has_frontmatter "$skill_file"; then
      fail "skills/$folder_name/SKILL.md: YAML frontmatter가 없습니다"
      echo "  [FAIL] frontmatter 없음: $folder_name"
      continue
    fi

    # name 필드
    NAME=$(extract_frontmatter_field "$skill_file" "name")
    if [ -n "$NAME" ]; then
      # 폴더명과 name 일치 확인
      if [ "$NAME" = "$folder_name" ]; then
        pass
      else
        fail "skills/$folder_name/SKILL.md: name='$NAME'가 폴더명 '$folder_name'과 불일치"
        echo "  [FAIL] name/폴더 불일치: $folder_name (name=$NAME)"
      fi
    else
      fail "skills/$folder_name/SKILL.md: 'name' 필드 누락"
      echo "  [FAIL] name 누락: $folder_name"
    fi

    # description 필드
    DESC=$(extract_frontmatter_field "$skill_file" "description")
    if [ -n "$DESC" ]; then
      pass
      if echo "$DESC" | grep -qi "use when"; then
        pass
        echo "  [PASS] $folder_name: name=$NAME, Use when 포함"
      else
        warn "skills/$folder_name/SKILL.md: description에 'Use when' 패턴이 없습니다"
        echo "  [WARN] 'Use when' 없음: $folder_name"
      fi
    else
      fail "skills/$folder_name/SKILL.md: 'description' 필드 누락"
      echo "  [FAIL] description 누락: $folder_name"
    fi
  done
else
  warn "skills/ 디렉터리가 없습니다"
  echo "  [WARN] skills/ 디렉터리 없음"
fi

echo ""

# ============================================================
# 4. 커맨드 검증
# ============================================================
echo "--- 4. 커맨드 검증 ---"

COMMANDS_DIR="$CURSOR_DIR/commands"
if [ -d "$COMMANDS_DIR" ]; then
  for cmd_file in "$COMMANDS_DIR"/*.md; do
    [ -f "$cmd_file" ] || continue
    cmd_name=$(basename "$cmd_file" .md)

    # 커맨드는 frontmatter가 없어야 함
    if has_frontmatter "$cmd_file"; then
      warn "commands/$cmd_name.md: YAML frontmatter가 있습니다 (커맨드는 순수 마크다운이어야 함)"
      echo "  [WARN] frontmatter 존재: $cmd_name"
    else
      pass
      echo "  [PASS] $cmd_name: 순수 마크다운 형식"
    fi
  done
else
  warn "commands/ 디렉터리가 없습니다"
  echo "  [WARN] commands/ 디렉터리 없음"
fi

echo ""

# ============================================================
# 5. manifest.json 스키마 검증
# ============================================================
echo "--- 5. manifest.json 검증 ---"

MANIFEST="$CURSOR_DIR/project/manifest.json"
if [ -f "$MANIFEST" ]; then
  # 필수 최상위 키
  for key in version defaults project stack activated; do
    if jq -e ".$key" "$MANIFEST" > /dev/null 2>&1; then
      pass
    else
      fail "manifest.json: 필수 키 '$key' 누락"
      echo "  [FAIL] 키 누락: $key"
    fi
  done

  # defaults 하위 키
  for key in completionLevel maxRalphIterations; do
    if jq -e ".defaults.$key" "$MANIFEST" > /dev/null 2>&1; then
      pass
    else
      fail "manifest.json: defaults.$key 누락"
      echo "  [FAIL] defaults.$key 누락"
    fi
  done

  # 배열 타입 확인
  for key in "project.languages" "project.platforms" "stack.frameworks" "stack.libraries"; do
    TYPE=$(jq -r ".$key | type" "$MANIFEST" 2>/dev/null || echo "missing")
    if [ "$TYPE" = "array" ]; then
      pass
    elif [ "$TYPE" = "missing" ]; then
      warn "manifest.json: $key 키가 없습니다"
      echo "  [WARN] $key 없음"
    else
      fail "manifest.json: $key의 타입이 array가 아닙니다 (현재: $TYPE)"
      echo "  [FAIL] $key 타입 오류: $TYPE"
    fi
  done

  echo "  [PASS] manifest.json 스키마 검증 완료"
else
  warn "manifest.json이 없습니다 (/setup으로 생성하세요)"
  echo "  [WARN] manifest.json 없음 (setup 전 상태)"
fi

echo ""

# ============================================================
# 6. 경로 참조 무결성
# ============================================================
echo "--- 6. 경로 참조 무결성 ---"

# 에이전트와 스킬에서 .cursor/ 경로 참조를 추출하고 존재 확인
REF_COUNT=0
REF_BROKEN=0

check_references() {
  local file="$1"
  local label="$2"

  # 백틱이나 따옴표 안의 .cursor/ 경로를 추출
  local refs
  refs=$(grep -oE '`\.cursor/[^`]+`|"\.cursor/[^"]+"' "$file" 2>/dev/null | sed 's/[`"]//g' || true)

  for ref in $refs; do
    REF_COUNT=$((REF_COUNT + 1))
    # 와일드카드나 패턴은 건너뜀
    if echo "$ref" | grep -qE '\*|\{'; then
      continue
    fi
    if [ -e "$ref" ]; then
      pass
    else
      REF_BROKEN=$((REF_BROKEN + 1))
      warn "$label: 참조 '$ref'가 존재하지 않습니다"
      echo "  [WARN] 깨진 참조: $label → $ref"
    fi
  done
}

# 에이전트 파일 검사
if [ -d "$CURSOR_DIR/agents" ]; then
  for f in "$CURSOR_DIR"/agents/*.md; do
    [ -f "$f" ] || continue
    check_references "$f" "agents/$(basename "$f")"
  done
fi

# 스킬 파일 검사
if [ -d "$CURSOR_DIR/skills" ]; then
  for f in "$CURSOR_DIR"/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    folder=$(basename "$(dirname "$f")")
    check_references "$f" "skills/$folder/SKILL.md"
  done
fi

if [ "$REF_BROKEN" -eq 0 ]; then
  echo "  [PASS] 모든 경로 참조가 유효합니다 (검사: ${REF_COUNT}개)"
else
  echo "  [WARN] ${REF_BROKEN}/${REF_COUNT}개 경로 참조가 깨져 있습니다"
fi

echo ""

# ============================================================
# 7. 사용 추적 시스템 건강 검사
# ============================================================
echo "--- 7. 사용 추적 시스템 ---"

USAGE_DATA_DIR="$CURSOR_DIR/project/usage-data"
TRACKER_SCRIPT="$CURSOR_DIR/hooks/usage-tracker.sh"

# usage-tracker.sh 존재 및 실행 권한
if [ -f "$TRACKER_SCRIPT" ]; then
  pass
  echo "  [PASS] usage-tracker.sh 존재"
  if [ -x "$TRACKER_SCRIPT" ]; then
    pass
    echo "  [PASS] usage-tracker.sh 실행 권한 있음"
  else
    fail "usage-tracker.sh: 실행 권한이 없습니다 (chmod +x 필요)"
    echo "  [FAIL] usage-tracker.sh 실행 권한 없음"
  fi
else
  fail "usage-tracker.sh가 존재하지 않습니다"
  echo "  [FAIL] usage-tracker.sh 없음"
fi

# hooks.json에 usage-tracker.sh가 Read matcher로 등록되어 있는가
if [ -f "$HOOKS_FILE" ]; then
  TRACKER_REGISTERED=$(jq -r '.hooks.postToolUse[]? | select(.command == ".cursor/hooks/usage-tracker.sh") | .matcher // ""' "$HOOKS_FILE" 2>/dev/null || echo "")
  if [ "$TRACKER_REGISTERED" = "Read" ]; then
    pass
    echo "  [PASS] hooks.json에 usage-tracker.sh 등록 (matcher: Read)"
  elif [ -n "$TRACKER_REGISTERED" ]; then
    warn "hooks.json: usage-tracker.sh의 matcher가 'Read'가 아닙니다 (현재: $TRACKER_REGISTERED)"
    echo "  [WARN] matcher 불일치: $TRACKER_REGISTERED (expected: Read)"
  else
    warn "hooks.json: usage-tracker.sh가 postToolUse에 등록되지 않았습니다"
    echo "  [WARN] usage-tracker.sh 미등록"
  fi
fi

# usage-data 디렉터리 구조
if [ -d "$USAGE_DATA_DIR" ]; then
  pass
  echo "  [PASS] usage-data/ 디렉터리 존재"

  for subdir in skills commands agents; do
    if [ -d "$USAGE_DATA_DIR/$subdir" ]; then
      pass
    else
      warn "usage-data/$subdir/ 디렉터리가 없습니다"
      echo "  [WARN] usage-data/$subdir/ 없음"
    fi
  done

  # .tracked-since 파일 확인
  if [ -f "$USAGE_DATA_DIR/.tracked-since" ]; then
    TRACKED_SINCE=$(cat "$USAGE_DATA_DIR/.tracked-since" 2>/dev/null)
    pass
    echo "  [PASS] 추적 활성 (시작: $TRACKED_SINCE)"
  else
    warn "사용 추적이 아직 시작되지 않았습니다 (.tracked-since 없음)"
    echo "  [WARN] 추적 미시작 (세션 사용 후 자동 시작)"
  fi

  # 고아 데이터 감지: 삭제된 스킬/커맨드/에이전트의 카운터가 남아있는지
  ORPHAN_COUNT=0
  if [ -d "$USAGE_DATA_DIR/skills" ]; then
    for data_file in "$USAGE_DATA_DIR"/skills/*; do
      [ -f "$data_file" ] || continue
      name=$(basename "$data_file")
      # .tmp 파일은 무시
      case "$name" in *.tmp) continue ;; esac
      if [ ! -d "$CURSOR_DIR/skills/$name" ]; then
        ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
        warn "usage-data/skills/$name: 대응하는 스킬이 삭제되었습니다 (고아 데이터)"
        echo "  [WARN] 고아 데이터: skills/$name"
      fi
    done
  fi
  if [ -d "$USAGE_DATA_DIR/commands" ]; then
    for data_file in "$USAGE_DATA_DIR"/commands/*; do
      [ -f "$data_file" ] || continue
      name=$(basename "$data_file")
      case "$name" in *.tmp) continue ;; esac
      if [ ! -f "$CURSOR_DIR/commands/$name.md" ]; then
        ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
        warn "usage-data/commands/$name: 대응하는 커맨드가 삭제되었습니다 (고아 데이터)"
        echo "  [WARN] 고아 데이터: commands/$name"
      fi
    done
  fi
  if [ -d "$USAGE_DATA_DIR/agents" ]; then
    for data_file in "$USAGE_DATA_DIR"/agents/*; do
      [ -f "$data_file" ] || continue
      name=$(basename "$data_file")
      case "$name" in *.tmp) continue ;; esac
      if [ ! -f "$CURSOR_DIR/agents/$name.md" ]; then
        ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
        warn "usage-data/agents/$name: 대응하는 에이전트가 삭제되었습니다 (고아 데이터)"
        echo "  [WARN] 고아 데이터: agents/$name"
      fi
    done
  fi
  if [ "$ORPHAN_COUNT" -eq 0 ]; then
    pass
    echo "  [PASS] 고아 데이터 없음"
  fi

  # 데이터 파일 형식 유효성 ({count}|{timestamp})
  FORMAT_ERRORS=0
  for subdir in skills commands agents; do
    [ -d "$USAGE_DATA_DIR/$subdir" ] || continue
    for data_file in "$USAGE_DATA_DIR/$subdir"/*; do
      [ -f "$data_file" ] || continue
      name=$(basename "$data_file")
      case "$name" in *.tmp) continue ;; esac
      content=$(cat "$data_file" 2>/dev/null)
      # 형식: {숫자}|{ISO8601 타임스탬프}
      if ! echo "$content" | grep -qE '^[0-9]+\|[0-9]{4}-[0-9]{2}-[0-9]{2}T'; then
        FORMAT_ERRORS=$((FORMAT_ERRORS + 1))
        warn "usage-data/$subdir/$name: 잘못된 데이터 형식 ($content)"
        echo "  [WARN] 형식 오류: $subdir/$name"
      fi
    done
  done
  if [ "$FORMAT_ERRORS" -eq 0 ]; then
    pass
    echo "  [PASS] 모든 데이터 파일 형식 유효"
  fi

  # 사용 통계 요약
  TOTAL_SKILLS=0; TRACKED_SKILLS=0
  TOTAL_COMMANDS=0; TRACKED_COMMANDS=0
  TOTAL_AGENTS=0; TRACKED_AGENTS=0
  for skill_dir in "$CURSOR_DIR"/skills/*/; do
    [ -d "$skill_dir" ] && [ -f "${skill_dir}SKILL.md" ] && TOTAL_SKILLS=$((TOTAL_SKILLS + 1))
  done
  for cmd_file in "$CURSOR_DIR"/commands/*.md; do
    [ -f "$cmd_file" ] && TOTAL_COMMANDS=$((TOTAL_COMMANDS + 1))
  done
  for agent_file in "$CURSOR_DIR"/agents/*.md; do
    [ -f "$agent_file" ] && TOTAL_AGENTS=$((TOTAL_AGENTS + 1))
  done
  if [ -d "$USAGE_DATA_DIR/skills" ]; then
    for f in "$USAGE_DATA_DIR"/skills/*; do
      [ -f "$f" ] && case "$(basename "$f")" in *.tmp) ;; *) TRACKED_SKILLS=$((TRACKED_SKILLS + 1)) ;; esac
    done
  fi
  if [ -d "$USAGE_DATA_DIR/commands" ]; then
    for f in "$USAGE_DATA_DIR"/commands/*; do
      [ -f "$f" ] && case "$(basename "$f")" in *.tmp) ;; *) TRACKED_COMMANDS=$((TRACKED_COMMANDS + 1)) ;; esac
    done
  fi
  if [ -d "$USAGE_DATA_DIR/agents" ]; then
    for f in "$USAGE_DATA_DIR"/agents/*; do
      [ -f "$f" ] && case "$(basename "$f")" in *.tmp) ;; *) TRACKED_AGENTS=$((TRACKED_AGENTS + 1)) ;; esac
    done
  fi
  echo "  [INFO] 사용 추적 현황: 스킬 $TRACKED_SKILLS/$TOTAL_SKILLS, 커맨드 $TRACKED_COMMANDS/$TOTAL_COMMANDS, 에이전트 $TRACKED_AGENTS/$TOTAL_AGENTS"
else
  warn "usage-data/ 디렉터리가 없습니다 (세션 사용 후 자동 생성)"
  echo "  [WARN] usage-data/ 없음 (추적 미시작)"
fi

echo ""

# ============================================================
# 8. 교차 참조 정합성 (synapse.mdc 참조 vs 실제 파일)
# ============================================================
echo "--- 8. 교차 참조 정합성 ---"

SYNAPSE_FILE="$CURSOR_DIR/rules/kernel/synapse.mdc"
if [ -f "$SYNAPSE_FILE" ]; then
  # synapse.mdc에서 스킬 이름 참조 추출 (skill activation guide, mode detection 등)
  # 패턴: 스킬 이름은 소문자-하이픈으로 skills/ 디렉터리명과 매칭
  MISSING_SKILLS=0
  MISSING_AGENTS=0

  # 실제 존재하는 스킬 목록
  EXISTING_SKILLS=""
  for skill_dir in "$CURSOR_DIR"/skills/*/; do
    [ -d "$skill_dir" ] || continue
    EXISTING_SKILLS="$EXISTING_SKILLS $(basename "$skill_dir")"
  done

  # synapse.mdc에서 알려진 스킬 참조 확인
  KNOWN_SKILL_REFS="code-accuracy planning clean-functions code-review design-principles tdd documentation mermaid refactoring reverse-engineering git-commit branch-convention merge-request autonomous-loop deep-search deep-index research ecomode prd ralplan build-fix cancel help verify-loop ast-refactor"
  for skill in $KNOWN_SKILL_REFS; do
    if echo "$EXISTING_SKILLS" | grep -qw "$skill"; then
      pass
    else
      MISSING_SKILLS=$((MISSING_SKILLS + 1))
      fail "synapse.mdc 참조 스킬 '$skill'이 .cursor/skills/에 없습니다"
      echo "  [FAIL] 누락 스킬: $skill"
    fi
  done

  # 실제 존재하는 에이전트 목록
  EXISTING_AGENTS=""
  for agent_file in "$CURSOR_DIR"/agents/*.md; do
    [ -f "$agent_file" ] || continue
    EXISTING_AGENTS="$EXISTING_AGENTS $(basename "$agent_file" .md)"
  done

  # synapse.mdc에서 알려진 에이전트 참조 확인
  KNOWN_AGENT_REFS="analyst planner architect critic implementer designer debugger migrator build-fixer reviewer qa-tester security-reviewer doc-writer vision researcher tdd-guide"
  for agent in $KNOWN_AGENT_REFS; do
    if echo "$EXISTING_AGENTS" | grep -qw "$agent"; then
      pass
    else
      MISSING_AGENTS=$((MISSING_AGENTS + 1))
      fail "synapse.mdc 참조 에이전트 '$agent'가 .cursor/agents/에 없습니다"
      echo "  [FAIL] 누락 에이전트: $agent"
    fi
  done

  if [ "$MISSING_SKILLS" -eq 0 ] && [ "$MISSING_AGENTS" -eq 0 ]; then
    echo "  [PASS] synapse.mdc 교차 참조 모두 유효"
  fi

  # 역방향: 존재하지만 synapse.mdc에 언급되지 않은 스킬 식별
  UNREGISTERED=""
  for skill_dir in "$CURSOR_DIR"/skills/*/; do
    [ -d "$skill_dir" ] || continue
    sname=$(basename "$skill_dir")
    # 알려진 참조 목록 + 시스템 관리 스킬에 없으면 미등록
    SYSTEM_SKILLS="setup evolve doctor learner help note notify-user comment-checker lsp security-review ecomode cancel prd"
    if ! echo "$KNOWN_SKILL_REFS $SYSTEM_SKILLS" | grep -qw "$sname"; then
      UNREGISTERED="$UNREGISTERED $sname"
    fi
  done
  if [ -n "$UNREGISTERED" ]; then
    warn "synapse.mdc에 등록되지 않은 스킬:$UNREGISTERED"
    echo "  [WARN] 미등록 스킬:$UNREGISTERED"
  else
    pass
    echo "  [PASS] 모든 스킬이 참조 또는 시스템 스킬로 분류됨"
  fi

else
  fail "synapse.mdc가 존재하지 않습니다"
  echo "  [FAIL] synapse.mdc 없음"
fi

echo ""

# ============================================================
# 9. 파일 크기 및 품질
# ============================================================
echo "--- 9. 파일 크기 및 품질 ---"

# 500줄 초과 룰 파일 감지
OVERSIZED=0
for rule_file in "$CURSOR_DIR"/rules/**/*.mdc "$CURSOR_DIR"/rules/**/*.md; do
  [ -f "$rule_file" ] || continue
  line_count=$(wc -l < "$rule_file" | tr -d ' ')
  if [ "$line_count" -gt 500 ]; then
    OVERSIZED=$((OVERSIZED + 1))
    warn "$rule_file: ${line_count}줄 (500줄 초과 — 분리 권장)"
    echo "  [WARN] 과대 룰: $(basename "$rule_file") (${line_count}줄)"
  fi
done
if [ "$OVERSIZED" -eq 0 ]; then
  pass
  echo "  [PASS] 모든 룰 파일 500줄 이하"
fi

# 빈 SKILL.md 또는 빈 커맨드 파일 감지
EMPTY_FILES=0
for skill_file in "$CURSOR_DIR"/skills/*/SKILL.md; do
  [ -f "$skill_file" ] || continue
  # frontmatter만 있고 본문이 없는 경우 (10줄 이하)
  line_count=$(wc -l < "$skill_file" | tr -d ' ')
  if [ "$line_count" -lt 5 ]; then
    EMPTY_FILES=$((EMPTY_FILES + 1))
    warn "$(basename "$(dirname "$skill_file")")/SKILL.md: 내용이 너무 짧습니다 (${line_count}줄)"
    echo "  [WARN] 빈 스킬: $(basename "$(dirname "$skill_file")") (${line_count}줄)"
  fi
done
for cmd_file in "$CURSOR_DIR"/commands/*.md; do
  [ -f "$cmd_file" ] || continue
  line_count=$(wc -l < "$cmd_file" | tr -d ' ')
  if [ "$line_count" -lt 3 ]; then
    EMPTY_FILES=$((EMPTY_FILES + 1))
    warn "commands/$(basename "$cmd_file"): 내용이 너무 짧습니다 (${line_count}줄)"
    echo "  [WARN] 빈 커맨드: $(basename "$cmd_file") (${line_count}줄)"
  fi
done
if [ "$EMPTY_FILES" -eq 0 ]; then
  pass
  echo "  [PASS] 빈 파일 없음"
fi

# 중복 이름 감지 (에이전트, 스킬, 커맨드 간 이름 충돌)
ALL_NAMES=""
DUPLICATE_COUNT=0
for agent_file in "$CURSOR_DIR"/agents/*.md; do
  [ -f "$agent_file" ] || continue
  name=$(basename "$agent_file" .md)
  if echo "$ALL_NAMES" | grep -qw "$name"; then
    DUPLICATE_COUNT=$((DUPLICATE_COUNT + 1))
    warn "이름 충돌: '$name'이 여러 카테고리에 존재합니다"
    echo "  [WARN] 이름 충돌: $name"
  fi
  ALL_NAMES="$ALL_NAMES $name"
done
for skill_dir in "$CURSOR_DIR"/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name=$(basename "$skill_dir")
  if echo "$ALL_NAMES" | grep -qw "$name"; then
    DUPLICATE_COUNT=$((DUPLICATE_COUNT + 1))
    warn "이름 충돌: '$name'이 여러 카테고리에 존재합니다"
    echo "  [WARN] 이름 충돌: $name"
  fi
  ALL_NAMES="$ALL_NAMES $name"
done
for cmd_file in "$CURSOR_DIR"/commands/*.md; do
  [ -f "$cmd_file" ] || continue
  name=$(basename "$cmd_file" .md)
  if echo "$ALL_NAMES" | grep -qw "$name"; then
    DUPLICATE_COUNT=$((DUPLICATE_COUNT + 1))
    warn "이름 충돌: '$name'이 여러 카테고리에 존재합니다"
    echo "  [WARN] 이름 충돌: $name"
  fi
  ALL_NAMES="$ALL_NAMES $name"
done
if [ "$DUPLICATE_COUNT" -eq 0 ]; then
  pass
  echo "  [PASS] 이름 충돌 없음"
fi

echo ""

# ============================================================
# 결과 요약
# ============================================================
echo "=========================="
echo "[결과 요약]"
echo "  PASS: $PASS"
echo "  WARN: $WARN"
echo "  FAIL: $FAIL"
echo ""

if [ ${#FAIL_LIST[@]} -gt 0 ]; then
  echo "FAIL 목록:"
  for item in "${FAIL_LIST[@]}"; do
    echo "  - $item"
  done
  echo ""
fi

if [ ${#WARN_LIST[@]} -gt 0 ]; then
  echo "WARN 목록:"
  for item in "${WARN_LIST[@]}"; do
    echo "  - $item"
  done
  echo ""
fi

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi
