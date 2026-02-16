# .cursor — Self-Evolving AI Agent Configuration

> 저자: jimmy
> 날짜: 2026-02-16
> 버전: 1.0.0

Cursor IDE의 AI Agent를 전문가 팀처럼 운영하기 위한 설정 시스템입니다.
오케스트레이터(Synapse)가 16개의 커스텀 에이전트 + 빌트인 subagent, 35개의 스킬, 10개의 커맨드를 조율하며,
프로젝트가 성장함에 따라 설정 자체도 함께 진화합니다.
사용 빈도를 자동 추적하여 미사용 항목을 식별하고 지속적으로 설정을 최적화합니다.

> 상세 아키텍처/기능별 문서는 [Documents/](Documents/00-TOC.md)를 참조하세요.

---

## 목차

1. [빠른 시작](#빠른-시작)
2. [디렉터리 구조](#디렉터리-구조)
3. [동작 원리](#동작-원리)
4. [Rules — 룰](#rules--룰)
5. [Commands — 커맨드](#commands--커맨드)
6. [Skills — 스킬](#skills--스킬)
7. [Agents — 서브에이전트](#agents--서브에이전트)
8. [Hooks — 훅](#hooks--훅)
9. [Usage Tracking — 사용 추적](#usage-tracking--사용-추적)
10. [Tests — 테스트](#tests--테스트)
11. [오케스트레이션 시스템](#오케스트레이션-시스템)
12. [자기 진화 메커니즘](#자기-진화-메커니즘)
13. [사용 예시](#사용-예시)
14. [커스터마이징](#커스터마이징)
15. [공식 문서 레퍼런스](#공식-문서-레퍼런스)
16. [상세 문서](#상세-문서)

---

## 빠른 시작

### 1. 기존 프로젝트에 적용

`.cursor/` 폴더를 프로젝트 루트에 복사한 후:

```bash
chmod +x .cursor/hooks/*.sh   # Hook 스크립트 실행 권한 부여
```

Cursor 채팅에서:

```
/setup
```

setup 스킬이 코드베이스를 분석하여 `manifest.json`과 `context.mdc`를 자동 생성합니다.

### 1-1. 이전 버전에서 업그레이드

이미 `.cursor`를 사용 중인 프로젝트에서 새 버전으로 업그레이드하려면:

```bash
mv .cursor .cursor.back   # 기존 설정 백업
# 새 .cursor 폴더를 프로젝트 루트에 복사
/setup                     # setup 실행
```

setup이 `.cursor.back`을 자동 감지하여 이전 설정을 분석합니다.
각 파일의 `source: origin` 태그와 새 `.cursor`의 파일을 비교하여 3가지로 분류합니다:

- `origin` — 기본 제공 파일. 새 버전으로 교체 (이관 스킵)
- `origin (modified)` — 기본 제공 파일을 사용자가 수정한 경우. 새 버전을 존중하고, 수정본은 `project/history/modified-origins/`에 백업
- `custom` — 사용자가 만든 파일. 새 환경으로 이관

### 2. 일상적인 사용

```
"로그인 화면을 만들어줘"          → Synapse가 자동으로 적절한 에이전트를 조율
"/autopilot 결제 기능 구현"       → 4-Phase 워크플로우 자동 실행
"/ralph 끝까지 완료해"            → 완료될 때까지 자율 반복 루프
"/autopilot 대규모 리팩토링"      → 병렬 에이전트 자율 작업 파이프라인
"/plan API 리팩토링"              → 분석→기획→검증 계획 세션
"/review"                        → 코드 리뷰
"/pr"                            → Pull Request 생성
"심층 분석해줘 인증 로직"         → deep-search 스킬 자동 활성화
"도움말"                          → help 스킬 자동 활성화
```

### 3. 프로젝트 변화 반영

새 의존성 추가, 대규모 리팩토링 등 프로젝트가 변경된 후:

```
/evolve
```

---

## 디렉터리 구조

```
.cursor/
├── rules/                          # 시스템 룰
│   └── kernel/
│       ├── synapse.mdc             # 오케스트레이터 (항상 적용)
│       ├── orchestration.mdc       # 4-Phase Workflow, Skill Composition (자동 적용)
│       ├── agent-delegation.mdc    # Agent 위임 규칙, 에이전트 생성 가이드 (자동 적용)
│       └── cursor-official-reference.mdc  # .cursor/ 파일 품질 게이트 (globs 기반)
│
├── commands/                       # 슬래시 커맨드 (/이름으로 호출, 10개)
│   ├── autopilot.md                # 4-Phase 자동 실행 (Team Mode Pipeline)
│   ├── pipeline.md                 # 에이전트 체이닝
│   ├── plan.md                     # 계획 세션
│   ├── pr.md                       # PR 생성
│   ├── review.md                   # 코드 리뷰
│   ├── analyze.md                  # 분석 세션
│   ├── solid-review.md              # SOLID 원칙 분석
│   ├── stats.md                    # 사용 통계 조회 및 미사용 항목 관리
│   ├── clean.md                    # state 폴더 정리
│   └── ralph.md                    # Ralph Loop 자율 실행
│
├── skills/                         # Agent Skills (35개)
│   │
│   │ # 핵심 워크플로우
│   ├── setup/                      # 프로젝트 부트스트랩
│   ├── evolve/                     # 설정 진화
│   ├── autonomous-loop/            # 자율 실행 루프 (Ralph + Autopilot 모드)
│   ├── ralplan/                    # 반복적 기획 합의 (Planner+Architect+Critic)
│   ├── cancel/                     # 통합 취소 매커니즘
│   │
│   │ # 탐색 및 분석
│   ├── deep-search/                # 심층 코드 탐색
│   ├── deep-index/                 # 코드베이스 인덱싱
│   ├── research/                   # 병렬 리서치 오케스트레이션
│   ├── lsp/                        # LSP 통합 가이드
│   │
│   │ # 코드 품질
│   ├── code-accuracy/              # 코드 정확성 + 라이브러리 검증
│   ├── planning/                   # 개발 계획 수립
│   ├── verify-loop/                # 완료 기준 검증
│   ├── clean-functions/            # 함수 품질
│   ├── comment-checker/            # 주석 품질 관리 + AI 주석 감지
│   ├── code-review/                # 독립 코드 리뷰
│   ├── security-review/            # 독립 보안 리뷰
│   ├── build-fix/                  # 빌드 오류 자동 수정
│   │
│   │ # 설계 원칙
│   ├── design-principles/          # OOP + SOLID 원칙
│   ├── solid/                      # SOLID 원칙 분석 및 검증
│   ├── tdd/                        # 테스트 주도 개발
│   │
│   │ # 리팩토링 및 분석
│   ├── refactoring/                # 리팩토링 검증
│   ├── reverse-engineering/        # 레거시 코드 분석
│   ├── ast-refactor/               # AST 기반 리팩토링
│   │
│   │ # 문서화 및 다이어그램
│   ├── documentation/              # README, API 문서, 아키텍처 문서 작성
│   ├── mermaid/                    # Mermaid 다이어그램 작성
│   ├── prd/                        # PRD 생성
│   │
│   │ # Git
│   ├── git-commit/                 # 커밋 메시지 자동 생성 + 컨벤션
│   ├── branch-convention/          # 브랜치 컨벤션
│   ├── merge-request/              # MR/PR 컨벤션
│   │
│   │ # 시스템 관리
│   ├── ecomode/                    # 토큰 절약 실행 모드
│   ├── doctor/                     # .cursor 자기 진단
│   │   └── scripts/validate.sh    #   Layer 2 구조 검증 스크립트
│   ├── learner/                    # 세션 패턴 학습 및 추출
│   ├── help/                       # 사용 가이드
│   ├── note/                       # Compaction 내성 메모장
│   └── notify-user/                # IDE-Slack 에스컬레이션 (사전 알림 + 폴링 + 결과 전송)
│       ├── SETUP-GUIDE.md         #   Slack 연동 설정 가이드
│       └── .env.example           #   환경 변수 템플릿
│
├── agents/                         # 커스텀 서브에이전트 (16개)
│   ├── analyst.md                  # 사전 분석 (Metis)
│   ├── planner.md                  # 전략 기획 (Prometheus)
│   ├── critic.md                   # 계획 검증 (Momus)
│   ├── implementer.md              # 코드 구현 (Executor)
│   ├── debugger.md                 # 디버깅
│   ├── reviewer.md                 # 코드 리뷰
│   ├── architect.md                # 아키텍처 분석 및 구조 결정
│   ├── build-fixer.md              # 빌드 오류 진단 및 수정
│   ├── designer.md                 # UI/UX 설계 분석
│   ├── doc-writer.md               # 문서 작성
│   ├── migrator.md                 # 코드/데이터 마이그레이션
│   ├── qa-tester.md                # QA 검증, 테스트 커버리지
│   ├── researcher.md               # 기술 리서치
│   ├── security-reviewer.md        # 보안 취약점 분석
│   ├── tdd-guide.md                # TDD 워크플로우 가이드
│   └── vision.md                   # 시각적 분석 (스크린샷, 목업)
│
├── hooks.json                      # 훅 이벤트 설정
├── hooks/                          # 훅 스크립트 (6개)
│   ├── setup-check.sh              # 세션 시작 시 부트스트랩 확인
│   ├── guard-shell.sh              # 위험한 쉘 명령어 차단
│   ├── usage-tracker.sh            # 사용 빈도 추적 (스킬/커맨드/에이전트/서브에이전트/시스템 스킬)
│   ├── todo-continuation.sh        # TODO 완료 강제 (Ralph Loop 시)
│   ├── recovery.sh                 # 편집 오류/세션 복구
│   └── comment-checker.sh          # AI 불필요 주석 감지
│
├── docs/                           # 참조 문서
│   └── cursor-official-reference.md  # Cursor 공식 문서 정리
│
├── tests/                          # 설정 검증 테스트 (3-Layer)
│   ├── README.md                   # 테스트 가이드
│   ├── run-all.sh                  # 통합 테스트 러너
│   ├── scenarios.md                # Layer 3: 수동 검증 시나리오
│   ├── hooks/                      # Layer 1: 훅 단위 테스트 (bats)
│   │   ├── setup-check.bats
│   │   ├── guard-shell.bats
│   │   ├── recovery.bats
│   │   ├── todo-continuation.bats
│   │   ├── usage-tracker.bats
│   │   └── comment-checker.bats
│   └── fixtures/                   # 테스트 데이터
│       ├── ralph-state-active.md
│       ├── ralph-state-inactive.md
│       ├── sample-code-many-comments.swift
│       └── sample-code-clean.swift
│
└── project/                        # 프로젝트 상태 (setup 후 생성)
    ├── manifest.json.template      # manifest 템플릿
    ├── VERSION                     # 설정 버전
    ├── usage-data/                 # 사용 빈도 추적 데이터 (자동 생성)
    │   ├── .tracked-since          # 추적 시작일
    │   ├── skills/{name}           # 스킬별 카운터 ({count}|{timestamp})
    │   ├── commands/{name}         # 커맨드별 카운터
    │   ├── agents/{name}           # 에이전트별 카운터
    │   ├── subagents/{name}        # 빌트인 서브에이전트별 카운터
    │   └── system-skills/{name}    # 시스템 스킬별 카운터
    └── state/                      # 런타임 상태
        └── {ISO8601}_{task-name}/  # 작업별 격리 폴더
            ├── ralph-state.md      # 루프 제어 메타데이터
            ├── notepad.md          # Compaction 내성 메모장
            └── prd.json            # PRD (선택)
```

---

## 동작 원리

### 전체 흐름

```
사용자 메시지
     │
     ▼
┌──────────────────────────────────────┐
│  Hooks (sessionStart)                │  ← 세션 시작 시 환경 점검
│  - setup-check.sh                    │
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│  Rules (항상 적용)                    │  ← 모든 메시지에 적용되는 지시사항
│  - synapse.mdc (오케스트레이터)        │
│  - context.mdc (프로젝트 컨텍스트)     │
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│  Synapse (오케스트레이터)              │  ← 작업 복잡도 판단 및 분배
│  - Simple → 직접 처리                 │
│  - Medium → 단일 에이전트 위임         │
│  - Complex → 4-Phase 워크플로우        │
│  - Autonomous → Ralph/Autopilot 루프   │
└──────────┬───────────────────────────┘
           │
     ┌─────┼─────┐
     ▼     ▼     ▼
 Agents  Skills  Commands
     │     │     │
     └─────┼─────┘
           ▼
┌──────────────────────────────────────┐
│  Hooks (도구 사용 전후)               │  ← 자동화된 안전장치 및 관리
│  - preToolUse: guard-shell.sh        │  ← 위험 명령어 차단
│  - postToolUse: usage-tracker.sh     │  ← 스킬/커맨드/에이전트/시스템 스킬 추적
│  - subagentStart: usage-tracker.sh   │  ← 빌트인 서브에이전트 추적
│  - postToolUse: todo-continuation.sh │  ← TODO 완료 강제
│  - postToolUse: recovery.sh          │  ← 오류 복구
│  - afterFileEdit: comment-checker.sh │  ← 불필요 주석 감지
└──────────────────────────────────────┘
```

### 계층 구조

| 계층 | 역할 | 파일 위치 |
|------|------|-----------|
| Orchestrator | 작업 분배, 워크플로우 관리 | `rules/kernel/synapse.mdc` |
| Agents | 전문 작업 수행 (컨텍스트 격리) | `agents/*.md` |
| Skills | 도메인별 지식과 워크플로우 | `skills/*/SKILL.md` |
| Commands | 사용자가 직접 트리거하는 매크로 | `commands/*.md` |
| Hooks | 이벤트 기반 자동화 | `hooks.json` + `hooks/*.sh` |
| Rules | 시스템 수준 지시사항 | `rules/**/*.mdc` |
| Tests | 설정 검증 (3-Layer 체계) | `tests/**` |
| Docs | 참조 문서 (코드 생성에 비관여) | `docs/*.md` |

### 적용 시점

```
세션 시작 ──→ sessionStart Hook 실행
           ──→ alwaysApply: true 룰 로드 (synapse.mdc, context.mdc)

메시지 입력 ──→ globs 매칭 룰 자동 적용
           ──→ Agent가 관련 Skill 자동 감지 및 적용

/커맨드 입력 ──→ 해당 커맨드 파일 실행
/스킬 입력  ──→ 해당 스킬 SKILL.md 로드

도구 사용 전 ──→ preToolUse Hook 실행 (guard-shell.sh)
도구 사용 후 ──→ postToolUse Hook 실행 (usage-tracker.sh, todo-continuation.sh, recovery.sh)
서브에이전트 시작 ──→ subagentStart Hook 실행 (usage-tracker.sh)
파일 편집 후 ──→ afterFileEdit Hook 실행 (comment-checker.sh)
```

---

## Rules — 룰

룰은 Agent에 시스템 수준 지시사항을 제공합니다. 적용되면 모델 컨텍스트 시작 부분에 포함됩니다.

### 파일 형식

```yaml
---
description: "이 룰이 하는 일"
alwaysApply: false
globs:
  - "src/**/*.ts"
---

# 룰 본문 (마크다운)
```

### 적용 방식

| 방식 | 설정 | 사용 시점 |
|------|------|-----------|
| Always Apply | `alwaysApply: true` | 오케스트레이터, 프로젝트 컨텍스트 |
| Globs | `globs: ["*.tsx"]` | 특정 파일 작업 시 자동 적용 |
| Agent Decides | description만 | Agent가 상황 판단 (Skill 권장) |
| Manual | `@룰이름`으로 멘션 | 필요할 때 명시적 호출 |

### 현재 등록된 룰

| 룰 | 적용 방식 | 역할 |
|----|-----------|------|
| `kernel/synapse.mdc` | Always Apply | 오케스트레이터 — 에이전트 조율, 워크플로우 관리 |
| `kernel/orchestration.mdc` | Agent Decides | 4-Phase Workflow, Skill Composition, Parallel Agent Dispatch |
| `kernel/agent-delegation.mdc` | Agent Decides | Phase별 에이전트 위임 규칙, 에이전트 생성 가이드 |
| `kernel/cursor-official-reference.mdc` | Globs (`.cursor/**`) | .cursor/ 파일 생성/수정 시 공식 스펙 준수 강제 |

`/setup` 실행 후 `rules/project/` 아래에 프로젝트별 룰이 추가됩니다.

---

## Commands — 커맨드

채팅에서 `/이름`으로 호출하는 워크플로우 매크로입니다. 순수 마크다운 파일(frontmatter 없음)입니다.

| 커맨드 | 호출 | 동작 |
|--------|------|------|
| Autopilot | `/autopilot` | 병렬 최대 성능 파이프라인 — 4-Phase 전체 실행 (분석→기획→구현→검증), 검증 실패 시 자동 회귀 |
| Ralph | `/ralph` | 완료까지 자율 반복 루프 (Plan→Execute→Verify, 최대 10회) |
| Pipeline | `/pipeline` | 에이전트를 순차 체이닝 (앞 에이전트 출력이 다음 에이전트 입력) |
| Plan | `/plan` | 계획 세션 (analyst→planner→critic) |
| PR | `/pr` | 현재 브랜치에서 PR 생성 (git diff 분석 + MR 컨벤션 적용) |
| Review | `/review` | 코드 리뷰 (reviewer, 보안 모드 시 security-reviewer 추가) |
| Analyze | `/analyze` | analyst 에이전트로 심층 분석 세션 |
| Solid Review | `/solid-review` | SOLID 원칙 분석 — 대상 코드의 설계 품질 검사 및 리팩토링 제안 |
| Stats | `/stats` | 사용 통계 조회 — 빈도 분석, 미사용 항목 하이라이트, 제거 추천, usage-stats.json 생성 |
| Stats Reset | `/stats --reset` | 추적 데이터 초기화 — 전체/카테고리/특정 항목별 카운터 리셋 |
| Clean | `/clean` | 완료된 작업의 state 폴더 정리 |

사용 예:

```
/autopilot 사용자 프로필 페이지 구현
/ralph 결제 모듈 끝까지 완성해줘
/autopilot 대규모 API 리팩토링
/analyze 이 모듈의 리스크를 분석해줘
/plan API v2 리팩토링
/pipeline analyst → planner → implementer → reviewer
/solid-review
/review
/pr
/stats
```

---

## Skills — 스킬

Agent에 전문 기능을 확장하는 지식 패키지입니다.
Agent가 작업 맥락에 따라 자동으로 관련 스킬을 감지하여 적용하거나,
`/스킬이름`으로 명시적으로 호출할 수 있습니다.

### Skill Tiers

토큰 효율을 위해 Core/Extended로 구분됩니다:

| Tier | 스킬 | 로드 시점 |
|------|------|-----------|
| Core | code-accuracy, verify-loop, planning, git-commit | 코드 작성 시 항상 우선 |
| Extended | 나머지 31개 | 작업 맥락에 따라 선택적 |

단순한 수정이나 질문에서는 Core만 참조하고, Feature 구현이나 리팩토링 등 복잡한 작업에서 관련 Extended 스킬을 추가로 로드합니다.

### 파일 구조

```
.cursor/skills/{skill-name}/
├── SKILL.md           # 필수: frontmatter + 워크플로우
├── scripts/           # 선택: 실행 가능한 스크립트
├── references/        # 선택: 추가 참조 문서
└── assets/            # 선택: 정적 리소스
```

### 수동 호출 스킬 (`disable-model-invocation: true` — `/이름`으로만 호출)

| 스킬 | 호출 | 역할 |
|------|------|------|
| setup | `/setup` | 프로젝트 부트스트랩 — 스택 감지, manifest.json과 context.mdc 생성 |
| evolve | `/evolve` | 프로젝트 변화 감지, .cursor 설정 진화 |
| autonomous-loop | `/ralph`, `/autopilot` | 자율 반복 루프 (Ralph: 완료 보장, Autopilot: 병렬 최대 성능) |
| ralplan | `/ralplan` | 반복적 기획 합의 (Planner→Architect→Critic 순환) |
| cancel | `/cancel` | 자율 루프 안전 중단, task-folder 상태 정리, 진행 보고 |
| clean | `/clean` | 완료된 작업의 state/{task-folder} 정리 |
| tdd | `/tdd` | TDD Red-Green-Refactor 사이클 강제 |
| ecomode | `/ecomode` | 토큰 절약 실행 모드 (fast 모델 우선, 병렬 제한) |
| prd | `/prd` | PRD 생성 (user stories, acceptance criteria) |

### 자동 감지 스킬 (Agent가 상황에 따라 자동 적용)

| 스킬 | 역할 |
|------|------|
| code-accuracy | 심볼 존재 확인, import 검증, 라이브러리 API 검증, 환각 방지 |
| planning | 개발 계획 수립 방법론 |
| verify-loop | 4-Level 완료 기준과 재시도 전략 |
| clean-functions | 함수 품질 (크기, SRP, 추상화, 에러 처리) |
| comment-checker | 주석 품질 관리 + AI 생성 불필요 주석 감지 |
| code-review | 독립 코드 리뷰 (구조, 품질, 안전성, 테스트) |
| security-review | 보안 취약점 검토 (인젝션, 인증, 시크릿) |
| build-fix | 빌드 오류 자동 수정 (import, 타입, 설정) |
| research | 병렬 리서치 오케스트레이션 (Context7 + WebSearch + 코드베이스) |
| lsp | LSP 통합 가이드 (Go to Definition, Find References 워크플로우) |
| design-principles | OOP + SOLID 설계 원칙 |
| solid | SOLID 원칙별 위반 검사 및 리팩토링 제안 |
| refactoring | 리팩토링 전후 비교 검증 |
| reverse-engineering | 레거시 코드 리버스 엔지니어링 |
| ast-refactor | ast-grep 기반 구조적 코드 변환 |
| deep-search | 다중 전략 심층 탐색 (Grep + SemanticSearch + Glob) |
| deep-index | 코드베이스 인덱싱, 모듈 요약 생성 |
| documentation | README, API 문서, 아키텍처 문서 작성 |
| mermaid | Mermaid 다이어그램 작성 |
| git-commit | git diff 분석 후 커밋 메시지 자동 생성 + Conventional Commits 컨벤션 |
| branch-convention | Git 브랜치 네이밍 컨벤션 |
| merge-request | MR/PR 컨벤션과 템플릿 |
| note | Compaction 내성 메모장 (컨텍스트 윈도우 초과 시 정보 보존) |
| notify-user | IDE-Slack 에스컬레이션 (사전 알림 + 폴링 + 결과 전송, SETUP-GUIDE.md 포함) |
| doctor | .cursor 설정 자기 진단 (파일 존재, 경로 무결성, 권한 검사) |
| learner | 세션 패턴 학습 및 스킬/룰 자동 추출 |
| help | 사용 가능한 에이전트, 스킬, 커맨드, 키워드 목록 |

---

## Agents — 서브에이전트

각 서브에이전트는 자체 컨텍스트 창에서 독립적으로 작동하는 전문가입니다.
Synapse 오케스트레이터가 작업을 위임하거나, `/이름`으로 직접 호출할 수 있습니다.

### 커스텀 에이전트 (16개)

프로젝트 컨벤션과 context.mdc를 로드하여 빌트인보다 깊은 프로젝트 이해를 제공합니다.

핵심 에이전트 (4-Phase Workflow 주축):

| 에이전트 | 역할 | Model | Readonly |
|----------|------|-------|----------|
| analyst (Metis) | 사전 분석, 요구사항 정제, 리스크 식별 | fast | O |
| planner (Prometheus) | 전략 기획, 구현 계획 수립 | inherit | X |
| critic (Momus) | 계획 비판적 검토, 숨겨진 의존성 탐지 | fast | O |
| implementer (Executor) | 코드 구현, Feature 개발 | inherit | X |
| debugger | 버그 수정, 메모리 릭, 성능 문제 | inherit | X |
| reviewer | 코드 리뷰, 패턴 준수 검증 | fast | O |

전문 에이전트 (Phase별 위임 시 활용):

| 에이전트 | 역할 | Model | Readonly |
|----------|------|-------|----------|
| architect | 아키텍처 분석 및 구조 결정 | inherit | X |
| build-fixer | 빌드 오류 진단 및 수정 | inherit | X |
| designer | UI/UX 설계 분석 | inherit | X |
| doc-writer | 문서 작성 | inherit | X |
| migrator | 코드/데이터 마이그레이션 | inherit | X |
| qa-tester | QA 검증, 테스트 커버리지 확인 | fast | O |
| researcher | 기술 리서치, 라이브러리 비교 | fast | O |
| security-reviewer | 보안 취약점 분석 | fast | O |
| tdd-guide | TDD 워크플로우 가이드 | fast | O |
| vision | 시각적 분석 (스크린샷, UI 목업) | fast | O |

### Cursor 빌트인 subagent_type

커스텀 에이전트와 함께 Cursor 빌트인 subagent_type도 활용합니다. `agent-delegation` 룰에 상세 매핑이 정의되어 있습니다.

| 작업 | subagent_type | 설명 |
|------|---------------|------|
| 코드 탐색 | explore | 코드베이스 탐색, 파일 검색 |
| 터미널 작업 | shell | git, 빌드 도구 등 CLI |
| 브라우저 테스트 | browser-use | 웹 UI 테스트, 폼 자동화 |
| 범용 작업 | generalPurpose | 복합 검색, 멀티스텝 실행 |

Model 설명:
- `fast`: 빠르고 가벼운 모델 (분석, 리뷰, 리서치 등 읽기 중심 작업)
- `inherit`: 부모 에이전트와 동일 모델 (구현, 설계 등 깊은 추론 필요)

Readonly:
- `O`: 읽기 전용 (파일 수정 불가, 분석/검토 전용)
- `X`: 쓰기 가능 (파일 생성/수정 가능)

### 직접 호출 예시

```
/analyst 이 기능의 리스크를 분석해줘
/reviewer 지금까지 변경사항을 리뷰해줘
/debugger 이 에러를 조사해줘
```

---

## Hooks — 훅

에이전트의 특정 동작 시점에 자동으로 실행되는 셸 스크립트입니다.
Git의 pre-commit/post-commit 훅과 개념이 비슷합니다.
에이전트가 도구를 사용하거나 파일을 편집할 때 끼어들어 검증, 차단, 추가 컨텍스트 주입을 수행합니다.

설정 파일은 `hooks.json`, 스크립트는 `hooks/` 폴더에 위치합니다.

### 5가지 이벤트 타이밍

| 이벤트 | 실행 시점 | 용도 | 출력 형식 |
|--------|-----------|------|-----------|
| `sessionStart` | 세션(대화) 시작 시 | 환경 초기화, 상태 확인 | `{"additional_context":"...","continue":true}` |
| `preToolUse` | 도구 실행 직전 | 위험한 명령 차단 (approve/deny) | `{"decision":"approve"}` 또는 `{"decision":"deny","reason":"..."}` |
| `postToolUse` | 도구 실행 직후 | 에러 감지, 추가 안내 주입 | `{"additional_context":"..."}` 또는 `{}` |
| `subagentStart` | 서브에이전트 시작 시 | 서브에이전트 사용 추적 | `{}` |
| `afterFileEdit` | 파일 편집 완료 후 | 코드 품질 검사 | `{"additional_context":"..."}` 또는 `{}` |

`matcher` 필드로 특정 도구에만 훅을 적용할 수 있습니다 (예: `"matcher": "Shell"`).

### 등록된 훅 (6개)

| 이벤트 | 스크립트 | matcher | 역할 |
|--------|----------|---------|------|
| `sessionStart` | `setup-check.sh` | — | 세션 시작 시 manifest.json 존재 확인, 중단된 Ralph Loop 감지 |
| `preToolUse` | `guard-shell.sh` | Shell | 위험한 쉘 명령어 차단 |
| `postToolUse` | `usage-tracker.sh` | Read | 스킬/커맨드/에이전트/시스템 스킬 파일 읽기 시 사용 빈도 자동 추적 |
| `postToolUse` | `todo-continuation.sh` | Write, StrReplace, Shell, EditNotebook | Ralph Loop 활성 시 TODO 완료 강제 리마인드 |
| `postToolUse` | `recovery.sh` | StrReplace, Write, EditNotebook, Shell | 편집/쉘 오류 발생 시 복구 가이드 제공 |
| `subagentStart` | `usage-tracker.sh` | — | 빌트인 서브에이전트 시작 시 사용 빈도 자동 추적 |
| `afterFileEdit` | `comment-checker.sh` | — | AI 생성 불필요 주석 패턴 감지 및 경고 |

### 통신 프로토콜

모든 훅은 동일한 프로토콜을 따릅니다: stdin으로 JSON 입력 → stdout으로 JSON 출력 → exit code (0: 성공, 2: 차단). JSON 파싱은 jq가 있으면 jq를, 없으면 grep+sed fallback을 사용합니다.

### 훅 추가 방법

1. `.cursor/hooks/`에 스크립트 생성 → `chmod +x` 실행 권한 부여
2. `hooks.json`에 등록:

```json
{"version":1,"hooks":{"preToolUse":[{"command":".cursor/hooks/my-guard.sh","matcher":"Shell"}]}}
```
---

## Usage Tracking — 사용 추적

`usage-tracker.sh` 훅이 5개 카테고리의 사용 빈도를 자동 추적합니다:

| 카테고리 | 추적 방식 | 설명 |
|----------|----------|------|
| skills | postToolUse(Read) + CLI | 프로젝트 스킬 |
| commands | postToolUse(Read) + CLI | 슬래시 커맨드 |
| agents | postToolUse(Read) + CLI | 커스텀 에이전트 |
| subagents | subagentStart hook + CLI | 빌트인 서브에이전트 (explore, shell 등) |
| system-skills | postToolUse(Read) + CLI | 시스템 스킬 (~/.cursor/skills-cursor/) |

데이터는 `usage-data/{category}/{name}` 파일에 `{횟수}|{ISO8601}` 형식으로 저장됩니다.
`/stats`로 사용 빈도 순위, 미사용 항목, 제거 추천을 확인할 수 있습니다. `/stats --reset`으로 카운터를 초기화합니다.

---

## Tests — 테스트

`.cursor/tests/` 디렉터리에 설정의 정합성을 검증하는 3-Layer 테스트 체계가 구성되어 있습니다.

### 의존성

- [bats-core](https://github.com/bats-core/bats-core): 쉘 스크립트 테스트 프레임워크
- jq (선택): JSON 파싱 보조

```bash
brew install bats-core jq
```

### 3-Layer 검증 체계

| Layer | 유형 | 자동화 | 설명 |
|-------|------|--------|------|
| Layer 1 | 훅 스크립트 단위 테스트 | 자동 (bats) | 6개 훅의 입출력을 122개 케이스로 검증 |
| Layer 2 | 구조 검증 스크립트 | 자동 (validate.sh) | frontmatter, 경로 참조, 스키마 유효성 검사 |
| Layer 3 | 시나리오 체크리스트 | 수동 | 에이전트/스킬 행동 24개 시나리오 수동 확인 |

### Layer 1: 훅 스크립트 단위 테스트 (122 tests)

| 훅 | 테스트 수 | 검증 내용 |
|----|-----------|-----------|
| setup-check.sh | 6 | manifest.json/ralph-state.md 상태별 출력 |
| guard-shell.sh | 23 | 위험 명령 차단, 안전 명령 허용, 엣지 케이스 |
| usage-tracker.sh | 62 | CLI/Hook/SubAgent 모드, 5개 카테고리, 검증, 크로스 모드 |
| recovery.sh | 10 | 도구별 에러 복구 메시지, 비매칭 도구 무시 |
| todo-continuation.sh | 10 | Ralph Loop 활성 시 TODO 연속 알림 |
| comment-checker.sh | 11 | 파일 타입 필터링, 주석 패턴 탐지 |

### 실행 방법

전체 테스트:

```bash
bash .cursor/tests/run-all.sh
```

개별 훅 테스트:

```bash
bats .cursor/tests/hooks/guard-shell.bats
bats .cursor/tests/hooks/setup-check.bats
```

구조 검증만 (Layer 2):

```bash
bash .cursor/skills/doctor/scripts/validate.sh
```

시나리오 체크리스트 (Layer 3)는 `tests/scenarios.md`를 참조하여 수동으로 확인합니다.

---

## 오케스트레이션 시스템

### Synapse 오케스트레이터

`synapse.mdc`는 모든 세션에 적용되는 메인 오케스트레이터입니다 (~80줄, alwaysApply).
사용자 메시지를 분석하여 작업 복잡도를 판단하고, 적절한 워크플로우를 선택합니다.

복잡한 작업 시 `orchestration` 룰(4-Phase Workflow, Skill Composition)과 `agent-delegation` 룰(Phase별 위임 규칙)이 Cursor에 의해 자동 적용됩니다.

### 복잡도별 워크플로우

Simple (단일 파일 수정, 질문):

```
Synapse가 직접 처리 (Subagent overhead 방지)
```

Medium (버그 수정, 단일 API 추가):

```
debugger 또는 implementer → reviewer
```

Complex (3개 이상 파일, 새 Feature):

```
Phase 0: analyst (요구사항 분석)
Phase 1: planner → critic (기획 + 검증), 필요 시 architect subagent
Phase 2: implementer (구현), UI 시 designer subagent, 빌드 오류 시 build-fixer subagent
Phase 3: reviewer + qa-tester subagent (검증, 병렬)
→ 실패 시 Phase 2로 회귀
```

Autonomous (대규모 자율 작업):

```
/ralph  → 완료까지 Plan→Execute→Verify 반복 (최대 10회)
/autopilot → Analyze→Plan→Execute→Verify 병렬 파이프라인 (최대 3회)
```

상세 오케스트레이션 전략은 `orchestration` 룰을 참조하세요.

### 자연어 모드 감지

특정 키워드가 포함되면 자동으로 모드가 활성화됩니다:

| 키워드 | 활성화 |
|--------|--------|
| "끝까지", "멈추지 마", "must complete" | Ralph Mode (자율 완료) |
| "심층 분석", "deep search" | Deep Analysis (analyst + deep-search 병렬) |
| "보안 포함", "security review" | Security Mode (security-reviewer 포함) |
| "테스트까지", "tdd", "test first" | QA/TDD Mode (tdd + qa-tester 포함) |
| "문서화까지", "with docs" | Doc Mode (doc-writer 포함) |
| "최대 성능", "병렬로", "autopilot" | Autopilot (병렬 자율 파이프라인) |
| "절약", "eco", "budget", "효율적으로" | Ecomode (토큰 절약 실행) |
| "조사", "research", "리서치" | Research Mode (research 스킬 실행) |
| "기획 합의", "ralplan" | Ralplan Mode (반복적 기획 합의) |
| "빌드 수정", "build fix" | Build Fix (빌드 오류 수정) |
| "요구사항 정리", "PRD" | PRD Mode (PRD 생성) |
| "인덱싱", "코드베이스 파악" | Index Mode (deep-index 실행) |
| "취소", "cancel", "중단" | Cancel (자율 루프 중단) |
| "도움말", "help", "사용법" | Help (기능 목록 표시) |

### 4-Level 완료 기준

| Level | 기준 | 적용 |
|-------|------|------|
| 1 Minimal | 코드 완료 + Lint 0 에러 | 단순 수정 |
| 2 Standard | Level 1 + 기능 동작 + Reviewer 승인 | 일반 작업 |
| 3 Thorough | Level 2 + 테스트 통과 + QA 검증 | Feature 구현 |
| 4 Production | Level 3 + 보안 검토 + 문서화 | 릴리즈 |

---

## 자기 진화 메커니즘

이 `.cursor` 설정은 정적인 설정 파일이 아니라, 프로젝트와 함께 성장하는 시스템입니다.

### 생명주기

```
/setup (탄생)
  → manifest.json, context.mdc 생성
  → 프로젝트 스택 자동 감지
  → 프로젝트별 룰 생성

/evolve (진화)
  → 변경된 의존성, 패턴, 구조 감지
  → manifest.json 업데이트 (moltCount 증가)
  → context.mdc 갱신
  → 새 룰 추가/기존 룰 수정

/deep-index (학습)
  → 코드베이스 전체 인덱싱
  → 모듈 요약, 의존성 그래프, 진입점 맵 생성
  → context.mdc 보강

/doctor (진단)
  → .cursor 설정 건강 상태 자동 검사
  → 깨진 경로 참조, 누락 파일, 권한 문제 감지
  → 수정 제안 및 적용

/stats (사용 분석)
  → 스킬/커맨드/에이전트 사용 빈도 분석
  → 미사용 항목 하이라이트 및 제거 추천
  → 데이터 기반 설정 최적화 의사결정

/learner (패턴 추출)
  → 세션에서 반복되는 작업 패턴 감지
  → 새 스킬/룰로 자동 추출
  → evolve 스킬과 연동하여 설정 진화
```

### Compaction 내성 (Note 시스템)

`.cursor/project/state/{task-folder}/notepad.md`에 중요한 컨텍스트를 저장합니다:
- 작업별 task-folder로 격리되어 동시 다중 작업 지원
- 컨텍스트 윈도우 초과 시에도 핵심 정보가 보존됩니다
- Ralph Loop / Autopilot iteration 간 상태를 전달합니다
- 에이전트 간 정보를 공유합니다
- 완료 후 `/clean` 커맨드로 task-folder 정리

### 품질 게이트

`cursor-official-reference.mdc` 룰이 `.cursor/` 내부 파일의 품질 게이트 역할을 합니다:

- Agent가 `.cursor/` 내 파일을 생성/수정할 때 자동 활성화 (globs 기반)
- 각 파일 유형별 체크리스트 강제 (Rules, Commands, Skills, Agents, Hooks)
- 불확실한 스펙은 `docs/cursor-official-reference.md`를 참조

### 세션 시작 자동 점검

`setup-check.sh` 훅이 매 세션 시작 시:

1. `manifest.json` 존재 여부 확인 → 없으면 `/setup` 안내
2. `state/*/ralph-state.md`에서 중단된 Ralph Loop 감지 → 있으면 `/ralph` 재개 안내

### 진화 원칙

1. 반복 패턴은 Skill이나 Command로 캡슐화
2. 500줄 초과 룰은 분리
3. 중복 지식은 하나의 참조 소스로 통합
4. 공식 문서 변경 시 `docs/cursor-official-reference.md` 갱신
5. Apply Intelligently 룰은 Skill로 전환 검토
6. 반복적 검증 작업은 Hook으로 자동화

---

## 사용 예시

```
/autopilot 사용자 프로필 편집 기능 구현     → 4-Phase 자동 파이프라인
/ralph 결제 모듈 끝까지 완성해줘            → 완료까지 자율 반복 (최대 10회)
/plan API v2 리팩토링                      → 분석→기획→검증 계획 세션
/review                                   → 코드 리뷰
/pr                                       → PR 생성
"심층 분석해줘 인증 로직"                   → deep-search 자동 활성화
"eco 모드로 이 버그 수정해줘"               → 토큰 절약 모드
/stats                                    → 사용 빈도 분석, 미사용 항목 추천
/stats --reset                            → 추적 카운터 초기화
도움말                                     → 전체 기능 목록 + 사용 빈도
```

---

## 커스터마이징

### 새 스킬 추가

1. `.cursor/skills/{skill-name}/SKILL.md` 생성
2. frontmatter에 `name`, `description` 작성
3. 자동 적용을 원하지 않으면 `disable-model-invocation: true` 추가

```yaml
---
name: my-custom-skill
description: 이 스킬의 역할. Use when ...
---

# My Custom Skill

## When to Use
...

## Workflow
1. ...
```

### 새 커맨드 추가

1. `.cursor/commands/{command-name}.md` 생성
2. 순수 마크다운으로 워크플로우 기술 (frontmatter 없음)

```markdown
# My Command

1. 첫 번째 단계
2. 두 번째 단계
...
```

### 새 에이전트 추가

1. `.cursor/agents/{agent-name}.md` 생성
2. frontmatter에 `name`, `description`, `model`, `readonly` 설정

### 새 훅 추가

1. `.cursor/hooks/` 아래에 스크립트 생성
2. `chmod +x` 실행 권한 부여
3. `hooks.json`에 이벤트와 스크립트 경로 등록

### 설정 진단

`.cursor` 설정에 문제가 있는 것 같으면:

```
/doctor
```

깨진 경로 참조, 누락 파일, 권한 문제 등을 자동으로 진단하고 수정 방안을 제시합니다.

### 사용 통계 확인 및 정리

미사용 스킬/커맨드/에이전트를 식별하고 정리하려면:

```
/stats
```

사용 빈도 순위, 미사용 항목, 제거 추천을 표시합니다. 추적 데이터는 세션 사용 시 자동 수집됩니다.

추적 데이터를 초기화하여 새로 측정을 시작하려면:

```
/stats --reset
```

카테고리별 또는 특정 항목만 초기화할 수도 있습니다:

```
/stats --reset 스킬
/stats --reset code-accuracy, git-commit
```

---

## 공식 문서 레퍼런스

Cursor의 Rules, Commands, Skills, Subagents, Hooks 공식 스펙은
`.cursor/docs/cursor-official-reference.md`에 정리되어 있습니다.

Agent가 `.cursor/` 파일을 생성/수정할 때 이 레퍼런스를 자동으로 참조합니다
(`cursor-official-reference.mdc` 룰에 의해 강제).

원본 출처: https://cursor.com/docs

---

## 상세 문서

[Documents/](Documents/00-TOC.md) 폴더에 아키텍처, 기능별 상세 문서가 정리되어 있습니다.

| 문서 | 설명 |
|------|------|
| [프로젝트 개요](Documents/01-project-overview.md) | 기술 스택, 핵심 개념 소개 |
| [아키텍처](Documents/02-architecture.md) | Orchestrator 패턴, 계층 구조, 워크플로우 |
| [폴더 구조](Documents/03-folder-structure.md) | 디렉터리별 역할 |
| [오케스트레이션](Documents/04-core-features/04-01-orchestration.md) | 4-Phase Workflow 상세 |
| [자율 실행 루프](Documents/04-core-features/04-02-autonomous-loop.md) | Ralph/Autopilot 상세 |
| [자기 진화](Documents/04-core-features/04-03-self-evolution.md) | setup→evolve→doctor→stats 생명주기 |
| [안전장치와 훅](Documents/04-core-features/04-04-safety-hooks.md) | 6개 훅 동작 원리 |
| [데이터 흐름](Documents/05-data-flow.md) | 메시지 처리, 상태 관리 |
| [구성 요소 관계](Documents/06-dependencies.md) | Rules-Skills-Agents-Commands-Hooks 관계 |
| [설치 및 적용](Documents/07-build-deploy.md) | 설치, 테스트, 업그레이드 |
| [온보딩 가이드](Documents/08-onboarding.md) | 신규 사용자 시작 가이드 |
