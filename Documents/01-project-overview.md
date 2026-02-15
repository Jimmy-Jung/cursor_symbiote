# 프로젝트 개요

> 저자: jimmy | 날짜: 2026-02-16

## cursor_symbiote란?

cursor_symbiote는 Cursor IDE의 AI Agent를 전문가 팀처럼 운영하기 위한 자기진화(Self-Evolving) 설정 시스템입니다. `.cursor/` 폴더 하나로 오케스트레이터(Synapse)가 6개의 커스텀 에이전트, 34개의 스킬, 9개의 커맨드, 6개의 훅을 조율하며, 프로젝트가 성장함에 따라 설정 자체도 함께 진화합니다.

이 시스템은 특정 프로젝트 전용이 아닙니다. iOS, Web, Backend 등 어떤 프로젝트에든 `.cursor/` 폴더를 복사하고 `/setup`을 실행하면 코드베이스를 자동 분석하여 프로젝트에 맞게 초기화됩니다.

## 핵심 가치

- 전문가 팀 운영: 분석가, 기획자, 비평가, 구현자, 디버거, 리뷰어가 각자의 역할에 집중
- 자율 완료: Ralph Loop / Autopilot으로 사용자 개입 없이 Plan→Execute→Verify 반복
- 자기 진화: `/setup` → `/evolve` → `/doctor` → `/stats` 생명주기로 프로젝트와 함께 성장
- 안전장치 내장: 위험 명령 차단, 불필요 주석 감지, 에러 복구가 자동 실행
- 사용 추적: 스킬/커맨드/에이전트 사용 빈도를 자동 추적하여 최적화 의사결정 지원

## 기술 스택

| 항목 | 상세 |
|------|------|
| 플랫폼 | Cursor IDE |
| 파일 형식 | Markdown, YAML frontmatter, JSON, Shell (bash) |
| 테스트 프레임워크 | bats-core (Shell 단위 테스트) |
| 외부 도구 | jq (선택), ast-grep (선택), Context7 MCP |
| 버전 | 1.0.0 |

## 주요 구성 요소

### Rules (4개)

시스템 수준 지시사항입니다. 모든 세션에 적용되거나, 특정 조건에서 자동 적용됩니다.

| 룰 | 적용 방식 | 역할 |
|----|-----------|------|
| `synapse.mdc` | Always Apply | 오케스트레이터 — 에이전트 조율, 워크플로우 관리 |
| `orchestration.mdc` | Agent Decides | 4-Phase Workflow, Skill Composition |
| `agent-delegation.mdc` | Agent Decides | Phase별 에이전트 위임 규칙 |
| `cursor-official-reference.mdc` | Globs (`.cursor/**`) | .cursor/ 파일 품질 게이트 |

### Commands (9개)

채팅에서 `/이름`으로 호출하는 워크플로우 매크로입니다.

| 커맨드 | 동작 |
|--------|------|
| `/autopilot` | 4-Phase 자동 파이프라인 (병렬 최대 성능) |
| `/ralph` | 완료까지 자율 반복 루프 (최대 10회) |
| `/pipeline` | 에이전트 순차 체이닝 |
| `/plan` | 계획 세션 (analyst→planner→critic) |
| `/pr` | PR 생성 |
| `/review` | 코드 리뷰 |
| `/analyze` | 심층 분석 세션 |
| `/stats` | 사용 통계 조회 및 미사용 항목 관리 |
| `/clean` | 완료된 작업의 state 폴더 정리 |

### Skills (34개)

Agent에 전문 기능을 확장하는 지식 패키지입니다. Core 4개(code-accuracy, verify-loop, planning, git-commit)는 코드 작성 시 항상 우선 참조되며, Extended 30개는 작업 맥락에 따라 선택적으로 로드됩니다.

주요 카테고리:
- 핵심 워크플로우: setup, evolve, autonomous-loop, ralplan, cancel
- 탐색/분석: deep-search, deep-index, research, lsp
- 코드 품질: code-accuracy, verify-loop, clean-functions, comment-checker, code-review, security-review, build-fix
- 설계 원칙: design-principles, tdd
- 문서/다이어그램: documentation, mermaid, prd
- Git: git-commit, branch-convention, merge-request
- 시스템 관리: ecomode, doctor, learner, help, note, notify-user

### Agents (6개 커스텀 + Cursor 빌트인)

각 서브에이전트는 자체 컨텍스트 창에서 독립 작동하는 전문가입니다.

| 에이전트 | 역할 | Model | Readonly |
|----------|------|-------|----------|
| analyst (Metis) | 사전 분석, 요구사항 정제 | fast | O |
| planner (Prometheus) | 전략 기획, 구현 계획 | inherit | X |
| critic (Momus) | 계획 비판적 검토 | fast | O |
| implementer (Executor) | 코드 구현 | inherit | X |
| debugger | 버그 수정, 성능 | inherit | X |
| reviewer | 코드 리뷰 | fast | O |

### Hooks (6개)

에이전트 동작 시점에 자동 실행되는 셸 스크립트입니다.

| 훅 | 이벤트 | 역할 |
|----|--------|------|
| setup-check.sh | sessionStart | manifest.json 확인, 중단된 Ralph Loop 감지 |
| guard-shell.sh | preToolUse | 위험 명령어 차단 |
| usage-tracker.sh | postToolUse | 사용 빈도 자동 추적 |
| todo-continuation.sh | postToolUse | Ralph Loop 시 TODO 완료 강제 |
| recovery.sh | postToolUse | 편집/쉘 오류 복구 가이드 |
| comment-checker.sh | afterFileEdit | AI 불필요 주석 감지 |

## 자연어 모드 감지

특정 키워드가 포함되면 커맨드 없이도 자동으로 모드가 활성화됩니다.

| 키워드 예시 | 활성화 모드 |
|------------|-----------|
| "끝까지", "멈추지 마" | Ralph Mode (자율 완료) |
| "심층 분석", "deep search" | Deep Analysis |
| "보안 포함", "security review" | Security Mode |
| "최대 성능", "병렬로", "autopilot" | Autopilot |
| "절약", "eco", "효율적으로" | Ecomode |
| "도움말", "help" | Help |

전체 키워드 목록은 [02-architecture.md](./02-architecture.md)를 참조하세요.
