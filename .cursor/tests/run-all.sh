#!/bin/bash
# .cursor 설정 검증 통합 테스트 러너
# 저자: jimmy
# 날짜: 2026-02-12
#
# 사용법: bash .cursor/tests/run-all.sh
# 또는:   cd .cursor/tests && bash run-all.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE} .cursor 설정 검증 테스트${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# bats 설치 확인
if ! command -v bats &> /dev/null; then
  echo -e "${RED}[ERROR] bats-core가 설치되어 있지 않습니다.${NC}"
  echo "  brew install bats-core"
  exit 1
fi

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0

# Layer 1: 훅 스크립트 단위 테스트
echo -e "${YELLOW}--- Layer 1: 훅 스크립트 단위 테스트 ---${NC}"
echo ""

for test_file in "$SCRIPT_DIR"/hooks/*.bats; do
  test_name=$(basename "$test_file" .bats)
  echo -e "${BLUE}[TEST] $test_name${NC}"

  if output=$(cd "$PROJECT_ROOT" && bats "$test_file" 2>&1); then
    passed=$(echo "$output" | grep -c "^ok " || true)
    TOTAL_PASS=$((TOTAL_PASS + passed))
    echo -e "${GREEN}  PASS: $passed tests${NC}"
  else
    passed=$(echo "$output" | grep -c "^ok " || true)
    failed=$(echo "$output" | grep -c "^not ok " || true)
    TOTAL_PASS=$((TOTAL_PASS + passed))
    TOTAL_FAIL=$((TOTAL_FAIL + failed))
    echo -e "${RED}  FAIL: $failed tests${NC}"
    echo "$output" | grep "^not ok " | while read -r line; do
      echo -e "${RED}    $line${NC}"
    done
  fi
  echo ""
done

# Layer 2: doctor 구조 검증
echo -e "${YELLOW}--- Layer 2: 구조 검증 (validate.sh) ---${NC}"
echo ""

VALIDATE_SCRIPT="$SCRIPT_DIR/../skills/doctor/scripts/validate.sh"
if [ -f "$VALIDATE_SCRIPT" ] && [ -x "$VALIDATE_SCRIPT" ]; then
  echo -e "${BLUE}[VALIDATE] doctor/scripts/validate.sh${NC}"
  (cd "$PROJECT_ROOT" && bash "$VALIDATE_SCRIPT") || true
else
  echo -e "${YELLOW}[SKIP] validate.sh가 없거나 실행 권한이 없습니다.${NC}"
  TOTAL_SKIP=$((TOTAL_SKIP + 1))
fi
echo ""

# 결과 요약
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE} 결과 요약${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "  ${GREEN}PASS: $TOTAL_PASS${NC}"
echo -e "  ${RED}FAIL: $TOTAL_FAIL${NC}"
echo -e "  ${YELLOW}SKIP: $TOTAL_SKIP${NC}"
echo ""

if [ "$TOTAL_FAIL" -gt 0 ]; then
  echo -e "${RED}일부 테스트가 실패했습니다.${NC}"
  exit 1
else
  echo -e "${GREEN}모든 테스트가 통과했습니다.${NC}"
  exit 0
fi
