# Cursor 공식 문서 레퍼런스

> 저자: jimmy
> 날짜: 2026-02-12
> 출처: https://cursor.com/docs (Rules, Commands, Skills, Subagents, Hooks)

이 문서는 Cursor 공식 문서에서 `.cursor/` 디렉터리 구성과 관련된 5가지 핵심 기능을 정리한 것입니다.

---

## 목차

1. [Rules (룰)](#1-rules-룰)
2. [Commands (커맨드)](#2-commands-커맨드)
3. [Agent Skills (스킬)](#3-agent-skills-스킬)
4. [Subagents (서브에이전트)](#4-subagents-서브에이전트)
5. [Hooks (훅)](#5-hooks-훅)

---

## 1. Rules (룰)

Rules는 Agent에 시스템 수준 지시사항을 제공합니다. 프롬프트, 스크립트 등을 묶어 워크플로우를 관리하고 팀 간에 공유할 수 있습니다.

### 1.1 룰의 동작 원리

LLM은 완료 간에 메모리를 유지하지 않습니다. Rules는 프롬프트 수준에서 지속적이고 재사용 가능한 컨텍스트를 제공합니다. 적용되면 모델 컨텍스트 시작 부분에 포함됩니다.

### 1.2 룰의 4가지 유형

| 유형 | 위치 | 범위 |
|------|------|------|
| Project Rules | `.cursor/rules/` | 프로젝트 범위, 버전 관리 가능 |
| User Rules | Cursor Settings > Rules | 모든 프로젝트에 전역 적용 |
| Team Rules | Cursor 대시보드 | 팀 전체 적용 (Team/Enterprise) |
| AGENTS.md | 프로젝트 루트 | `.cursor/rules` 대체 (단순한 경우) |

### 1.3 Project Rules 파일 구조

`.cursor/rules/` 안의 마크다운 파일(`.md` 또는 `.mdc`).

```
.cursor/rules/
  react-patterns.mdc       # frontmatter 포함 룰
  api-guidelines.md        # 단순 마크다운 룰
  frontend/
    components.md           # 폴더로 구성 가능
```

### 1.4 룰 적용 방식 (Rule Types)

frontmatter의 `description`, `globs`, `alwaysApply` 속성으로 제어합니다.

| Rule Type | 동작 |
|-----------|------|
| Always Apply | `alwaysApply: true` - 모든 채팅 세션에 적용 |
| Apply Intelligently | `alwaysApply: false`, `globs` 없음 - Agent가 description 기반으로 관련성 판단 |
| Apply to Specific Files | `globs` 패턴 지정 - 파일 패턴 매칭 시 적용 |
| Apply Manually | `@룰이름`으로 채팅에서 직접 멘션 |

### 1.5 Frontmatter 형식

```yaml
---
description: "프론트엔드 컴포넌트와 API 검증 표준"
alwaysApply: false
globs:
  - "src/components/**/*.tsx"
---

...룰 내용...
```

### 1.6 Best Practices

- 500줄 이하로 유지
- 큰 룰은 여러 개의 조합 가능한 룰로 분리
- 구체적인 예시나 참조 파일 제공
- 모호한 가이드 지양, 명확한 내부 문서처럼 작성
- 파일 내용 복사 대신 파일 참조 사용 (최신 상태 유지)
- git에 체크인하여 팀 전체가 활용

### 1.7 피해야 할 것

- 스타일 가이드 전체 복사 (린터 사용)
- 모든 명령어 문서화 (Agent가 npm, git, pytest 등을 이미 알고 있음)
- 드물게 적용되는 엣지 케이스 지시 추가
- 코드베이스에 이미 있는 내용 복제

### 1.8 Remote Rules (GitHub)

GitHub 저장소에서 직접 룰을 가져올 수 있습니다. Cursor Settings > Rules, Commands > Add Rule > Remote Rule (Github).

### 1.9 AGENTS.md

프로젝트 루트에 배치하는 단순한 마크다운 파일. `.cursor/rules`의 대안으로, 메타데이터나 복잡한 설정 없이 간단한 지시사항에 적합합니다. 서브디렉터리에도 배치 가능.

---

## 2. Commands (커맨드)

커맨드는 채팅 입력 상자에서 `/` 접두사로 트리거되는 재사용 가능한 워크플로우입니다.

### 2.1 커맨드 위치

| 위치 | 범위 |
|------|------|
| `.cursor/commands/` | 프로젝트 수준 |
| `~/.cursor/commands/` | 글로벌 (사용자 수준) |
| Cursor Dashboard | 팀 커맨드 (Team/Enterprise) |

### 2.2 커맨드 만들기

1. `.cursor/commands/` 디렉터리 생성
2. 설명적 이름의 `.md` 파일 추가 (예: `review-code.md`, `write-tests.md`)
3. 순수 마크다운으로 커맨드 동작을 기술
4. `/`를 입력하면 자동으로 나타남

```
.cursor/
└── commands/
    ├── code-review-checklist.md
    ├── create-pr.md
    ├── security-audit.md
    └── setup-new-feature.md
```

### 2.3 커맨드 파일 형식

순수 마크다운 파일. 공식 문서에서 frontmatter(YAML)에 대한 언급은 없습니다.

### 2.4 파라미터

커맨드 이름 뒤에 추가 컨텍스트를 입력할 수 있습니다:

```
/commit and /pr these changes to address DX-523
```

### 2.5 Team Commands

팀 관리자가 Cursor Dashboard에서 생성. 모든 팀 멤버에게 자동 동기화.

---

## 3. Agent Skills (스킬)

Agent Skills는 AI 에이전트에 전문 기능을 확장하는 오픈 표준입니다. 도메인별 지식과 워크플로우를 패키징합니다.

### 3.1 스킬의 특성

- Portable: Agent Skills 표준을 지원하는 모든 에이전트에서 작동
- Version-controlled: 파일로 저장, 저장소에서 추적 가능
- Executable: 에이전트가 실행할 수 있는 스크립트/코드 포함 가능
- Progressive: 필요 시 리소스를 온디맨드 로드 (컨텍스트 효율적)

### 3.2 스킬 디렉터리

| 위치 | 범위 |
|------|------|
| `.cursor/skills/` | 프로젝트 수준 |
| `.claude/skills/`, `.codex/skills/` | 프로젝트 수준 (호환성) |
| `~/.cursor/skills/` | 사용자 수준 (글로벌) |
| `~/.claude/skills/`, `~/.codex/skills/` | 사용자 수준 (글로벌, 호환성) |

### 3.3 스킬 폴더 구조

```
.cursor/
└── skills/
    └── deploy-app/
        ├── SKILL.md           # 필수
        ├── scripts/           # 선택: 실행 가능한 코드
        │   ├── deploy.sh
        │   └── validate.py
        ├── references/        # 선택: 추가 문서
        │   └── REFERENCE.md
        └── assets/            # 선택: 정적 리소스
            └── config-template.json
```

### 3.4 SKILL.md 형식

```yaml
---
name: my-skill
description: 이 스킬이 하는 일과 사용 시점. 에이전트가 관련성을 판단하는 데 사용됨.
license: MIT
compatibility:
  - tool: ast-grep
    check: command -v sg
metadata:
  author: jimmy
disable-model-invocation: true
---

# My Skill

에이전트를 위한 상세 지시사항.

## When to Use

- 이 스킬은 ...할 때 사용
...
```

### 3.5 Frontmatter 필드

| 필드 | 필수 | 설명 |
|------|------|------|
| `name` | 예 | 스킬 식별자. 소문자, 숫자, 하이픈만 허용. 부모 폴더명과 일치해야 함 |
| `description` | 예 | 스킬 설명과 사용 시점. 에이전트가 관련성 판단에 사용 |
| `license` | 아니오 | 라이선스 이름 또는 참조 |
| `compatibility` | 아니오 | 환경 요구사항 (시스템 패키지, 네트워크 접근 등) |
| `metadata` | 아니오 | 임의 키-값 매핑 |
| `disable-model-invocation` | 아니오 | `true`이면 `/스킬이름`으로 명시적 호출 시에만 포함. 자동 적용 안 됨 |

### 3.6 자동 호출 비활성화

기본적으로 스킬은 에이전트가 관련성 있다고 판단하면 자동 적용됩니다. `disable-model-invocation: true`로 설정하면 전통적인 슬래시 커맨드처럼 동작합니다.

### 3.7 룰/커맨드에서 스킬로 마이그레이션

Cursor 2.4에 내장된 `/migrate-to-skills` 스킬 사용:

- Dynamic rules (Apply Intelligently 설정, `alwaysApply: false`, `globs` 없음) -> 표준 스킬로 변환
- Slash commands -> `disable-model-invocation: true` 스킬로 변환

`alwaysApply: true`이거나 특정 `globs`가 있는 룰은 마이그레이션 대상이 아닙니다.

### 3.8 스킬 확인 방법

Cursor Settings > Rules > Agent Decides 섹션에서 발견된 스킬을 확인할 수 있습니다.

---

## 4. Subagents (서브에이전트)

서브에이전트는 Cursor의 Agent가 작업을 위임할 수 있는 전문 AI 어시스턴트입니다. 각 서브에이전트는 자체 컨텍스트 창에서 작동하고, 특정 유형의 작업을 처리하며, 결과를 부모 에이전트에 반환합니다.

### 4.1 핵심 장점

- Context isolation: 각 서브에이전트가 자체 컨텍스트 창 보유
- Parallel execution: 여러 서브에이전트를 동시에 실행
- Specialized expertise: 커스텀 프롬프트, 도구 접근, 모델 설정 가능
- Reusability: 프로젝트 간 재사용 가능

### 4.2 빌트인 서브에이전트

| 서브에이전트 | 목적 | 이유 |
|-------------|------|------|
| Explore | 코드베이스 검색/분석 | 탐색 시 대량의 중간 출력이 메인 컨텍스트를 부풀림. 빠른 모델로 병렬 검색 |
| Bash | 쉘 명령어 실행 | 명령어 출력이 장황. 부모를 결정에 집중하게 함 |
| Browser | 브라우저 제어 (MCP) | DOM 스냅샷과 스크린샷이 노이즈가 많음. 관련 결과만 필터링 |

### 4.3 Foreground vs Background

| 모드 | 동작 | 적합한 경우 |
|------|------|------------|
| Foreground | 완료될 때까지 블록. 즉시 결과 반환 | 출력이 필요한 순차적 작업 |
| Background | 즉시 반환. 독립적으로 작업 | 장시간 실행 또는 병렬 작업 |

### 4.4 파일 위치

| 유형 | 위치 | 범위 |
|------|------|------|
| Project | `.cursor/agents/` | 현재 프로젝트 |
| | `.claude/agents/`, `.codex/agents/` | 호환성 |
| User | `~/.cursor/agents/` | 모든 프로젝트 |
| | `~/.claude/agents/`, `~/.codex/agents/` | 호환성 |

### 4.5 파일 형식

YAML frontmatter가 있는 마크다운 파일:

```yaml
---
name: security-auditor
description: Security specialist. Use when implementing auth, payments, or handling sensitive data.
model: inherit
readonly: true
is_background: false
---

You are a security expert auditing code for vulnerabilities.

When invoked:
1. Identify security-sensitive code paths
2. Check for common vulnerabilities
...
```

### 4.6 Configuration 필드

| 필드 | 필수 | 설명 |
|------|------|------|
| `name` | 아니오 | 고유 식별자. 소문자와 하이픈. 기본값: 파일명(확장자 제외) |
| `description` | 아니오 | 사용 시점. Agent가 위임 결정에 읽음 |
| `model` | 아니오 | `fast`, `inherit`, 또는 특정 모델 ID. 기본값: `inherit` |
| `readonly` | 아니오 | `true`이면 쓰기 권한 제한 |
| `is_background` | 아니오 | `true`이면 백그라운드에서 실행 (완료 대기 안 함) |

### 4.7 서브에이전트 호출 방법

자동 위임: Agent가 작업 복잡도, 서브에이전트 description, 현재 컨텍스트를 기반으로 자동 위임.

명시적 호출: `/name` 구문 사용:

```
> /verifier confirm the auth flow is complete
> /debugger investigate this error
```

### 4.8 Best Practices

- 집중된 서브에이전트: 각 서브에이전트는 단일하고 명확한 책임
- description 투자: `description` 필드가 위임 시점을 결정. 정교하게 다듬기
- 간결한 프롬프트: 길고 장황한 프롬프트는 집중력 저하
- 버전 관리: `.cursor/agents/`를 저장소에 체크인

### 4.9 안티패턴

- 수십 개의 모호한 서브에이전트 생성 금지 (2-3개로 시작, 명확한 용도가 있을 때만 추가)
- "일반적인 작업에 사용"과 같은 모호한 description 금지
- 2,000단어 프롬프트는 더 느리고 유지보수 어려움
- 단일 목적 작업은 슬래시 커맨드나 스킬 사용

### 4.10 Orchestrator 패턴

복잡한 워크플로우에서 부모 에이전트가 여러 전문 서브에이전트를 순차적으로 조율:

1. Planner: 요구사항 분석 및 기술 계획 작성
2. Implementer: 계획에 따라 Feature 구현
3. Verifier: 구현이 요구사항과 일치하는지 확인

각 핸드오프에는 다음 에이전트가 명확한 컨텍스트를 갖도록 구조화된 출력 포함.

### 4.11 서브에이전트 vs 스킬

| 서브에이전트 사용 시 | 스킬 사용 시 |
|-------------------|-------------|
| 긴 리서치 작업에 컨텍스트 격리 필요 | 단일 목적 작업 (변경 로그 생성, 포맷팅) |
| 여러 작업 스트림을 병렬 실행 | 빠르고 반복 가능한 액션 |
| 여러 단계에 걸친 전문 지식 필요 | 한 번에 완료되는 작업 |
| 작업의 독립적 검증 필요 | 별도 컨텍스트 창 불필요 |

---

## 5. Hooks (훅)

Hooks는 커스텀 스크립트를 사용하여 에이전트 루프를 관찰, 제어, 확장합니다. stdio를 통해 JSON으로 양방향 통신하는 프로세스로 실행됩니다.

### 5.1 용도

- 편집 후 포매터 실행
- 이벤트 분석 추가
- PII 또는 시크릿 스캔
- 위험한 작업 게이팅 (예: SQL 쓰기)
- 서브에이전트 (Task tool) 실행 제어
- 세션 시작 시 컨텍스트 주입

### 5.2 훅 유형: Command vs Prompt

| 유형 | 설명 |
|------|------|
| Command (기본) | 쉘 스크립트 실행. stdin으로 JSON 입력, stdout으로 JSON 출력 |
| Prompt | LLM이 자연어 조건을 평가. 스크립트 작성 없이 정책 적용 가능 |

### 5.3 설정 파일

`hooks.json` 파일 위치:

| 위치 | 범위 | 우선순위 |
|------|------|---------|
| Enterprise 시스템 경로 | 전체 조직 | 최고 |
| Cursor Dashboard | 팀 | 높음 |
| `<project>/.cursor/hooks.json` | 프로젝트 | 중간 |
| `~/.cursor/hooks.json` | 사용자 | 낮음 |

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      { "command": ".cursor/hooks/setup-check.sh" }
    ],
    "afterFileEdit": [
      { "command": ".cursor/hooks/format.sh" }
    ],
    "preToolUse": [
      {
        "command": ".cursor/hooks/validate-tool.sh",
        "matcher": "Shell|Read|Write"
      }
    ]
  }
}
```

### 5.4 스크립트 실행 경로

- Project hooks (`.cursor/hooks.json`): 프로젝트 루트에서 실행
- User hooks (`~/.cursor/hooks.json`): `~/.cursor/`에서 실행

### 5.5 Per-Script 설정 옵션

| 옵션 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `command` | string | 필수 | 스크립트 경로 또는 명령어 |
| `type` | `"command"` / `"prompt"` | `"command"` | 훅 실행 유형 |
| `timeout` | number | 플랫폼 기본 | 실행 타임아웃 (초) |
| `loop_limit` | number / null | 5 | stop/subagentStop 훅의 루프 제한 |
| `matcher` | string | - | 훅 실행 필터 기준 |

### 5.6 Exit Code 동작

- Exit 0: 성공, JSON 출력 사용
- Exit 2: 액션 차단 (`decision: "deny"`와 동일)
- 기타: 훅 실패, 액션 진행 (fail-open)

예외: `beforeMCPExecution`, `beforeReadFile`는 fail-closed (실패 시 차단)

### 5.7 사용 가능한 Hook Events

Agent 훅:

| 이벤트 | 시점 | 주요 출력 |
|--------|------|----------|
| `sessionStart` | 새 대화 생성 시 | `env`, `additional_context`, `continue` |
| `sessionEnd` | 대화 종료 시 | (fire-and-forget) |
| `preToolUse` | 도구 실행 전 | `decision`, `reason`, `updated_input` |
| `postToolUse` | 도구 실행 후 | `updated_mcp_tool_output` |
| `postToolUseFailure` | 도구 실패 시 | (관찰 전용) |
| `subagentStart` | 서브에이전트 생성 전 | `decision`, `reason` |
| `subagentStop` | 서브에이전트 완료 시 | `followup_message` |
| `beforeShellExecution` | 쉘 명령 실행 전 | `permission`, `user_message`, `agent_message` |
| `afterShellExecution` | 쉘 명령 실행 후 | (관찰 전용) |
| `beforeMCPExecution` | MCP 도구 실행 전 | `permission` (fail-closed) |
| `afterMCPExecution` | MCP 도구 실행 후 | (관찰 전용) |
| `beforeReadFile` | 파일 읽기 전 | `permission` (fail-closed) |
| `afterFileEdit` | 파일 편집 후 | (관찰 전용) |
| `beforeSubmitPrompt` | 프롬프트 제출 전 | `continue`, `user_message` |
| `preCompact` | 컨텍스트 압축 전 | `user_message` |
| `stop` | 에이전트 루프 종료 시 | `followup_message` |
| `afterAgentResponse` | 어시스턴트 메시지 완료 후 | (관찰 전용) |
| `afterAgentThought` | 사고 블록 완료 후 | (관찰 전용) |

Tab 훅:

| 이벤트 | 시점 | 설명 |
|--------|------|------|
| `beforeTabFileRead` | Tab이 파일 읽기 전 | 인라인 완성용 접근 제어 |
| `afterTabFileEdit` | Tab이 파일 편집 후 | 인라인 완성 후 포매터 실행 |

### 5.8 Matcher 설정

훅이 실행되는 시점을 필터링합니다:

- `preToolUse`: 도구 타입으로 필터 - `Shell`, `Read`, `Write`, `Grep`, `Delete`, `MCP`, `Task` 등
- `subagentStart`: 서브에이전트 타입으로 필터 - `generalPurpose`, `explore`, `shell` 등
- `beforeShellExecution`: 쉘 명령어 텍스트로 필터

```json
{
  "preToolUse": [
    {
      "command": "./validate-shell.sh",
      "matcher": "Shell"
    }
  ]
}
```

### 5.9 환경 변수

훅 스크립트에 자동 제공되는 환경 변수:

| 변수 | 설명 |
|------|------|
| `CURSOR_PROJECT_DIR` | 워크스페이스 루트 디렉터리 |
| `CURSOR_VERSION` | Cursor 버전 문자열 |
| `CURSOR_USER_EMAIL` | 인증된 사용자 이메일 (로그인 시) |
| `CLAUDE_PROJECT_DIR` | 프로젝트 디렉터리 별칭 (Claude 호환) |

### 5.10 Prompt 기반 훅 예시

```json
{
  "hooks": {
    "beforeShellExecution": [
      {
        "type": "prompt",
        "prompt": "이 명령어가 실행하기에 안전한지 확인하세요. 읽기 전용 작업만 허용하세요.",
        "timeout": 10
      }
    ]
  }
}
```

---

## 요약: .cursor 디렉터리 전체 구조

```
.cursor/
├── rules/              # 프로젝트 룰 (.md, .mdc)
│   └── *.mdc           # frontmatter(description, globs, alwaysApply) + 마크다운
├── commands/           # 슬래시 커맨드 (.md)
│   └── *.md            # 순수 마크다운 (frontmatter 없음)
├── skills/             # Agent Skills
│   └── {skill-name}/
│       ├── SKILL.md    # frontmatter(name, description 등) + 마크다운
│       ├── scripts/    # 실행 가능한 스크립트 (선택)
│       ├── references/ # 추가 문서 (선택)
│       └── assets/     # 정적 리소스 (선택)
├── agents/             # 커스텀 서브에이전트 (.md)
│   └── *.md            # frontmatter(name, description, model 등) + 마크다운
├── hooks.json          # 훅 설정
└── hooks/              # 훅 스크립트
    └── *.sh            # stdin JSON -> stdout JSON
```

---

## 핵심 의사결정 가이드

| 필요한 것 | 사용할 기능 |
|-----------|-------------|
| 모든 세션에 적용되는 지시사항 | Rule (`alwaysApply: true`) |
| 특정 파일 패턴에만 적용되는 규칙 | Rule (`globs` 사용) |
| Agent가 상황에 맞게 판단하는 지식 | Skill |
| 빠르고 반복 가능한 단일 동작 | Skill (`disable-model-invocation: true`) 또는 Command |
| 자체 프롬프트가 있는 복합 워크플로우 | Command |
| 컨텍스트 격리가 필요한 전문 작업 | Subagent |
| 병렬로 실행해야 하는 작업들 | Subagent (여러 개 동시 실행) |
| 파일 편집 후 자동 포맷팅 | Hook (`afterFileEdit`) |
| 위험한 명령어 차단 | Hook (`beforeShellExecution` 또는 `preToolUse`) |
| 세션 시작 시 환경 설정 | Hook (`sessionStart`) |
