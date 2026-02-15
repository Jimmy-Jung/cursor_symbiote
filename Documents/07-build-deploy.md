# 설치 및 적용

> 저자: jimmy | 날짜: 2026-02-16

## 개요

cursor_symbiote를 프로젝트에 적용하는 방법, 테스트 실행, 업그레이드 절차를 설명합니다.

## 선행 조건

| 항목 | 필수/선택 | 버전/설명 |
|------|----------|-----------|
| Cursor IDE | 필수 | Rules, Hooks, Skills, Agents 지원 버전 |
| bash/zsh | 필수 | Hook 스크립트 실행 |
| bats-core | 선택 | Hook 단위 테스트 |
| jq | 선택 | JSON 파싱 (없으면 fallback 동작) |

```bash
# 선택적 도구 설치 (macOS)
brew install bats-core jq
```

## 신규 설치

### Step 1: 폴더 복사

`.cursor/` 폴더를 프로젝트 루트에 복사합니다.

### Step 2: 실행 권한 부여

```bash
chmod +x .cursor/hooks/*.sh
```

### Step 3: 프로젝트 초기화

Cursor 채팅에서:

```
/setup
```

setup 스킬이 자동으로:
1. 코드베이스를 분석하여 프로젝트 스택 감지
2. `manifest.json` 생성
3. `context.mdc` 생성 (모든 에이전트가 참조하는 프로젝트 컨텍스트)
4. 프로젝트별 규칙 생성

### Step 4: 코드베이스 인덱싱 (선택)

```
/deep-index
```

코드베이스를 전체 인덱싱하여 모듈 요약, 의존성 그래프를 생성합니다.

## 이전 버전에서 업그레이드

이미 `.cursor`를 사용 중인 프로젝트에서 새 버전으로 업그레이드하는 경우:

### Step 1: 기존 설정 백업

```bash
mv .cursor .cursor.back
```

### Step 2: 새 .cursor 복사

새 `.cursor/` 폴더를 프로젝트 루트에 복사합니다.

### Step 3: setup 실행

```
/setup
```

setup이 `.cursor.back`을 자동 감지하여:
- `origin` 파일: 새 버전으로 교체
- `origin (modified)` 파일: 새 버전 존중, 수정본은 `history/modified-origins/`에 백업
- `custom` 파일: 새 환경으로 이관

### Step 4: 확인

이관 결과를 확인하고, 수정했던 origin 파일이 있다면 `history/modified-origins/`에서 참고하여 재적용합니다.

## 일상적 사용

### 기본 명령어

```
"로그인 화면을 만들어줘"          → Synapse가 적절한 에이전트 조율
/autopilot 결제 기능 구현         → 4-Phase 자동 파이프라인
/ralph 끝까지 완료해              → 완료까지 자율 반복
/plan API 리팩토링                → 계획 세션
/review                          → 코드 리뷰
/pr                              → PR 생성
```

### 자연어 트리거

```
"심층 분석해줘 인증 로직"         → deep-search 자동 활성화
"eco 모드로 이 버그 수정해줘"     → 토큰 절약 모드
"보안 포함해서 API 리팩토링"      → 보안 리뷰 포함
도움말                           → 전체 기능 목록
```

## 유지 관리

| 시점 | 명령 | 설명 |
|------|------|------|
| 의존성/구조 변경 후 | `/evolve` | 설정 진화 |
| 뭔가 이상할 때 | `/doctor` | 자기 진단 |
| 사용 통계 확인 | `/stats` | 빈도 분석, 미사용 항목 추천 |
| 추적 초기화 | `/stats --reset` | 카운터 리셋 |
| 작업 완료 후 | `/clean` | state 폴더 정리 |

## 테스트

### 3-Layer 검증 체계

| Layer | 유형 | 자동화 | 설명 |
|-------|------|--------|------|
| Layer 1 | 훅 단위 테스트 | 자동 (bats) | 60개 케이스로 5개 훅 검증 |
| Layer 2 | 구조 검증 | 자동 (validate.sh) | frontmatter, 경로, 스키마 검사 |
| Layer 3 | 시나리오 체크리스트 | 수동 | 24개 시나리오 수동 확인 |

### 테스트 실행

전체 테스트:

```bash
bash .cursor/tests/run-all.sh
```

개별 훅 테스트:

```bash
bats .cursor/tests/hooks/guard-shell.bats
bats .cursor/tests/hooks/setup-check.bats
bats .cursor/tests/hooks/recovery.bats
bats .cursor/tests/hooks/todo-continuation.bats
bats .cursor/tests/hooks/comment-checker.bats
```

구조 검증만 (Layer 2):

```bash
bash .cursor/skills/doctor/scripts/validate.sh
```

시나리오 체크리스트 (Layer 3)는 `tests/scenarios.md`를 참조하여 수동 확인합니다.

### 테스트 커버리지

| 훅 | 테스트 수 | 검증 내용 |
|----|-----------|-----------|
| setup-check.sh | 6 | manifest.json/ralph-state.md 상태별 출력 |
| guard-shell.sh | 23 | 위험 명령 차단, 안전 명령 허용, 엣지 케이스 |
| recovery.sh | 10 | 도구별 에러 복구 메시지, 비매칭 도구 무시 |
| todo-continuation.sh | 10 | Ralph Loop 활성 시 TODO 연속 알림 |
| comment-checker.sh | 11 | 파일 타입 필터링, 주석 패턴 탐지 |

## .gitignore 권장

```
# 런타임 상태 (작업별 임시 데이터)
.cursor/project/state/

# 사용 추적 데이터
.cursor/project/usage-data/

# 프로젝트 설정 (프로젝트별 생성됨)
.cursor/project/manifest.json
.cursor/rules/project/

# 히스토리
.cursor/project/history/
```

커널 룰, 스킬, 에이전트, 커맨드, 훅, 테스트는 버전 관리에 포함하여 팀 전체가 공유할 수 있습니다.

## 커스터마이징

### 새 스킬 추가

```
.cursor/skills/{skill-name}/SKILL.md
```

frontmatter에 `name`, `description` 작성. 자동 적용을 막으려면 `disable-model-invocation: true` 추가.

### 새 커맨드 추가

```
.cursor/commands/{command-name}.md
```

순수 마크다운으로 워크플로우 기술 (frontmatter 없음).

### 새 에이전트 추가

```
.cursor/agents/{agent-name}.md
```

frontmatter에 `name`, `description`, `model`, `readonly` 설정.

### 새 훅 추가

1. `.cursor/hooks/`에 스크립트 생성
2. `chmod +x` 실행 권한 부여
3. `hooks.json`에 이벤트와 경로 등록
