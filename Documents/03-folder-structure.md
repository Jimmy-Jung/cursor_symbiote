# 폴더 구조

> 저자: jimmy | 날짜: 2026-02-16

## 전체 트리

```
.cursor/
├── rules/                          # 시스템 룰
│   ├── kernel/                     # 커널 룰 (보호 대상, 마이그레이션 불가)
│   │   ├── synapse.mdc             # 오케스트레이터 (alwaysApply: true)
│   │   ├── orchestration.mdc       # 4-Phase Workflow (Agent Decides)
│   │   ├── agent-delegation.mdc    # Agent 위임 규칙 (Agent Decides)
│   │   └── cursor-official-reference.mdc  # .cursor/ 파일 품질 게이트 (globs)
│   └── project/                    # 프로젝트별 룰 (/setup 후 생성)
│       ├── context.mdc             # 프로젝트 컨텍스트 (alwaysApply: true)
│       └── *.mdc                   # 플랫폼, 프레임워크, 아키텍처 룰
│
├── commands/                       # 슬래시 커맨드 (10개, 순수 마크다운)
│   ├── autopilot.md                # 4-Phase 자동 실행
│   ├── ralph.md                    # 완료까지 자율 반복
│   ├── pipeline.md                 # 에이전트 체이닝
│   ├── plan.md                     # 계획 세션
│   ├── pr.md                       # PR 생성
│   ├── review.md                   # 코드 리뷰
│   ├── analyze.md                  # 분석 세션
│   ├── solid-review.md             # SOLID 원칙 분석
│   ├── stats.md                    # 사용 통계 조회
│   └── clean.md                    # state 폴더 정리
│
├── skills/                         # Agent Skills (34개)
│   ├── {skill-name}/
│   │   ├── SKILL.md                # 필수: frontmatter + 워크플로우
│   │   ├── scripts/                # 선택: 실행 스크립트
│   │   ├── references/             # 선택: 추가 참조 문서
│   │   └── assets/                 # 선택: 정적 리소스
│   │
│   │ # 핵심 워크플로우
│   ├── setup/                      # 프로젝트 부트스트랩
│   ├── evolve/                     # 설정 진화
│   ├── autonomous-loop/            # 자율 실행 루프
│   ├── ralplan/                    # 반복적 기획 합의
│   ├── cancel/                     # 통합 취소
│   │
│   │ # 탐색 및 분석
│   ├── deep-search/                # 심층 코드 탐색
│   ├── deep-index/                 # 코드베이스 인덱싱
│   ├── research/                   # 병렬 리서치
│   ├── lsp/                        # LSP 통합 가이드
│   │
│   │ # 코드 품질
│   ├── code-accuracy/              # 코드 정확성 + 환각 방지
│   ├── planning/                   # 개발 계획 수립
│   ├── verify-loop/                # 완료 기준 검증
│   ├── clean-functions/            # 함수 품질
│   ├── comment-checker/            # 주석 품질 + AI 주석 감지
│   ├── code-review/                # 독립 코드 리뷰
│   ├── security-review/            # 독립 보안 리뷰
│   ├── build-fix/                  # 빌드 오류 자동 수정
│   │
│   │ # 설계 원칙
│   ├── design-principles/          # OOP + SOLID 원칙
│   ├── tdd/                        # 테스트 주도 개발
│   │
│   │ # 리팩토링 및 분석
│   ├── refactoring/                # 리팩토링 검증
│   ├── reverse-engineering/        # 레거시 코드 분석
│   ├── ast-refactor/               # AST 기반 리팩토링
│   │
│   │ # 문서화 및 다이어그램
│   ├── documentation/              # 문서 작성
│   ├── mermaid/                    # Mermaid 다이어그램
│   ├── prd/                        # PRD 생성
│   │
│   │ # Git
│   ├── git-commit/                 # 커밋 메시지 자동 생성
│   ├── branch-convention/          # 브랜치 컨벤션
│   ├── merge-request/              # MR/PR 컨벤션
│   │
│   │ # 시스템 관리
│   ├── ecomode/                    # 토큰 절약 모드
│   ├── doctor/                     # .cursor 자기 진단
│   │   └── scripts/validate.sh     #   Layer 2 구조 검증 스크립트
│   ├── learner/                    # 세션 패턴 학습
│   ├── help/                       # 사용 가이드
│   ├── note/                       # Compaction 내성 메모장
│   ├── notify-user/                # IDE-Slack 에스컬레이션
│   │   ├── SETUP-GUIDE.md          #   Slack 연동 가이드
│   │   └── .env.example            #   환경 변수 템플릿
│   └── solid/                      # SOLID 검증
│
├── agents/                         # 커스텀 서브에이전트 (6개)
│   ├── analyst.md                  # Metis — 사전 분석
│   ├── planner.md                  # Prometheus — 전략 기획
│   ├── critic.md                   # Momus — 계획 검증
│   ├── implementer.md              # Executor — 코드 구현
│   ├── debugger.md                 # 디버깅
│   └── reviewer.md                 # 코드 리뷰
│
├── hooks.json                      # 훅 이벤트 설정
├── hooks/                          # 훅 스크립트 (6개)
│   ├── setup-check.sh              # 세션 시작 시 부트스트랩 확인
│   ├── guard-shell.sh              # 위험한 쉘 명령어 차단
│   ├── usage-tracker.sh            # 사용 빈도 자동 추적
│   ├── todo-continuation.sh        # Ralph Loop 시 TODO 완료 강제
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
│   ├── hooks/                      # Layer 1: 훅 단위 테스트
│   │   ├── setup-check.bats
│   │   ├── guard-shell.bats
│   │   ├── recovery.bats
│   │   ├── todo-continuation.bats
│   │   └── comment-checker.bats
│   └── fixtures/                   # 테스트 데이터
│       ├── ralph-state-active.md
│       ├── ralph-state-inactive.md
│       ├── sample-code-many-comments.swift
│       └── sample-code-clean.swift
│
└── project/                        # 프로젝트 상태 (/setup 후 생성)
    ├── manifest.json.template      # manifest 템플릿
    ├── VERSION                     # 설정 버전
    ├── history/                    # 진화 히스토리
    ├── usage-data/                 # 사용 빈도 추적 데이터 (자동 생성)
    │   ├── .tracked-since          # 추적 시작일
    │   ├── skills/{name}           # 스킬별 카운터
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

## 핵심 디렉터리 설명

### `rules/kernel/`

시스템의 핵심 룰 파일입니다. 보호 대상으로, 스킬로 마이그레이션하거나 임의 수정하면 안 됩니다.

- `synapse.mdc`: 모든 세션에 항상 적용되는 오케스트레이터. 사용자 메시지를 분석하고 적절한 에이전트를 초기화합니다.
- `orchestration.mdc`: 복잡한 작업 시 자동 적용되는 4-Phase Workflow 전략입니다.
- `agent-delegation.mdc`: Subagent에 작업을 위임할 때의 규칙과 Phase별 매핑입니다.
- `cursor-official-reference.mdc`: `.cursor/` 파일 생성/수정 시 공식 스펙 준수를 강제하는 품질 게이트입니다.

### `rules/project/`

`/setup` 또는 `/evolve` 실행 후 자동 생성되는 프로젝트별 룰입니다. `context.mdc`는 `alwaysApply: true`로 모든 에이전트가 참조합니다.

### `commands/`

순수 마크다운 파일입니다 (YAML frontmatter 없음). 채팅에서 `/이름`으로 호출합니다.

### `skills/`

각 스킬은 `{skill-name}/SKILL.md` 구조입니다. YAML frontmatter에 `name`, `description`이 필수이며, `disable-model-invocation: true`가 있으면 `/이름`으로만 호출됩니다 (Agent 자동 적용 차단).

### `agents/`

YAML frontmatter에 `name`, `description`, `model`, `readonly` 필드가 있습니다. `model: fast`는 읽기 중심 작업, `model: inherit`는 깊은 추론이 필요한 구현 작업에 사용됩니다.

### `hooks/`

`hooks.json`에 이벤트(sessionStart, preToolUse, postToolUse, subagentStart, afterFileEdit)와 스크립트를 등록합니다. 스크립트는 stdin JSON → stdout JSON 프로토콜을 따릅니다.

### `project/state/`

작업별 격리 폴더(`{ISO8601}_{task-name}/`)가 생성됩니다. Ralph Loop의 상태(`ralph-state.md`), 메모장(`notepad.md`), PRD(`prd.json`)가 저장됩니다. 완료 후 `/clean`으로 정리합니다.

### `project/usage-data/`

`usage-tracker.sh` 훅이 자동으로 채우는 사용 빈도 데이터입니다. 각 파일은 `{횟수}|{ISO8601}` 형식입니다. `/stats`로 분석합니다.
