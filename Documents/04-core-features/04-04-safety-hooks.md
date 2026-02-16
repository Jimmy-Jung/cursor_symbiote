# 안전장치와 훅

> 저자: jimmy | 날짜: 2026-02-16

## 개요

Hooks는 에이전트의 특정 동작 시점에 자동으로 실행되는 셸 스크립트입니다. Git의 pre-commit/post-commit 훅과 비슷한 개념으로, 에이전트가 도구를 사용하거나 파일을 편집할 때 끼어들어 검증, 차단, 추가 컨텍스트 주입을 수행합니다.

## 5가지 이벤트 타이밍

| 이벤트 | 실행 시점 | 용도 | 출력 |
|--------|-----------|------|------|
| `sessionStart` | 세션(대화) 시작 시 | 환경 초기화, 상태 확인 | `{"additional_context":"...","continue":true}` |
| `preToolUse` | 도구 실행 직전 | 위험 명령 차단 | `{"decision":"approve"}` 또는 `{"decision":"deny","reason":"..."}` |
| `postToolUse` | 도구 실행 직후 | 에러 감지, 추가 안내 | `{"additional_context":"..."}` 또는 `{}` |
| `subagentStart` | 서브에이전트 시작 시 | 사용 빈도 추적 | `{}` |
| `afterFileEdit` | 파일 편집 완료 후 | 코드 품질 검사 | `{"additional_context":"..."}` 또는 `{}` |

## 통신 프로토콜

모든 훅은 동일한 프로토콜을 따릅니다:

```
stdin (JSON 입력) → 스크립트 실행 → stdout (JSON 출력)
```

- exit code 0: 성공
- exit code 2: 차단 (preToolUse에서 deny)
- 그 외: fail-open (실패해도 진행)
- JSON 파싱: jq가 있으면 jq, 없으면 grep+sed fallback
- stderr: 디버그 로그에만 사용 (의사결정에 영향 없음)

## 등록된 훅 상세

### 1. setup-check.sh (sessionStart)

세션 시작 시 프로젝트 부트스트랩 상태를 확인합니다.

동작:
1. `manifest.json` 존재 여부 확인 → 없으면 `/setup` 안내 메시지 주입
2. `state/*/ralph-state.md`에서 `active: true` 검색 → 있으면 중단된 Ralph Loop 재개 안내

출력 예시:
```json
{"additional_context":"[Project Bootstrap] manifest.json not found. Run /setup to initialize project configuration.","continue":true}
```

### 2. guard-shell.sh (preToolUse, matcher: Shell)

위험한 쉘 명령어를 실행 전에 차단합니다.

차단 대상 예시:
- `git push --force` (강제 푸시)
- `rm -rf /` (루트 삭제)
- `git reset --hard` (이력 손실)
- 기타 파괴적 명령어

동작: stdin에서 실행 예정 명령어를 읽고, 위험 패턴 매칭 시 deny 응답을 반환합니다.

출력 예시 (차단 시):
```json
{"decision":"deny","reason":"위험한 명령어: git push --force"}
```

### 3. usage-tracker.sh (postToolUse + subagentStart)

스킬/커맨드/에이전트/서브에이전트/시스템 스킬의 사용 빈도를 자동 추적합니다. 3가지 모드로 동작합니다:

postToolUse(Read) 모드:
1. Read 도구로 읽은 파일 경로를 확인
2. `.cursor/skills/`, `.cursor/commands/`, `.cursor/agents/`, `~/.cursor/skills-cursor/` 경로 매칭
3. 매칭되면 `usage-data/{category}/{name}` 파일의 카운터 증가

subagentStart 모드:
1. 빌트인 서브에이전트(explore, shell, browser-use 등) 시작 시 자동 호출
2. JSON에서 서브에이전트 타입 추출
3. `usage-data/subagents/{type}` 카운터 증가

CLI 자기보고 모드:
1. 에이전트가 `bash .cursor/hooks/usage-tracker.sh <category> <name>`으로 직접 호출
2. @멘션, /슬래시 커맨드, 자동 매칭으로 인라인 로드된 항목을 추적

데이터 형식:
```
{횟수}|{ISO8601-타임스탬프}
```

카테고리: skills, commands, agents, subagents, system-skills

### 4. todo-continuation.sh (postToolUse, matcher: Write|StrReplace|Shell|EditNotebook)

Ralph Loop가 활성화된 상태에서 TODO 완료를 강제합니다.

동작:
1. `state/*/ralph-state.md`에서 `active: true`인 task-folder 확인
2. 활성 루프가 있으면 "TODO 항목을 모두 완료하세요" 리마인드 메시지 주입
3. 비활성 시 빈 JSON 출력

### 5. recovery.sh (postToolUse, matcher: StrReplace|Write|EditNotebook|Shell)

편집/쉘 오류 발생 시 복구 가이드를 제공합니다.

동작:
1. 도구 실행 결과에서 에러 여부 확인
2. 에러 유형별 복구 가이드 메시지 주입
3. 비매칭 도구나 정상 실행 시 빈 JSON 출력

### 6. comment-checker.sh (afterFileEdit)

파일 편집 후 AI가 생성한 불필요한 주석 패턴을 감지합니다.

감지 패턴 예시:
- `// TODO: implement`
- `// This function does X` (코드가 명확할 때 불필요)
- 과도한 설명 주석

동작: 편집된 파일을 분석하여 불필요 주석 패턴 발견 시 경고 메시지를 주입합니다.

## hooks.json 구조

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      { "command": ".cursor/hooks/setup-check.sh" }
    ],
    "preToolUse": [
      {
        "command": ".cursor/hooks/guard-shell.sh",
        "matcher": "Shell"
      }
    ],
    "postToolUse": [
      {
        "command": ".cursor/hooks/usage-tracker.sh",
        "matcher": "Read"
      },
      {
        "command": ".cursor/hooks/todo-continuation.sh",
        "matcher": "Write|StrReplace|Shell|EditNotebook"
      },
      {
        "command": ".cursor/hooks/recovery.sh",
        "matcher": "StrReplace|Write|EditNotebook|Shell"
      }
    ],
    "subagentStart": [
      { "command": ".cursor/hooks/usage-tracker.sh" }
    ],
    "afterFileEdit": [
      { "command": ".cursor/hooks/comment-checker.sh" }
    ]
  }
}
```

`matcher` 필드로 특정 도구에만 훅을 적용할 수 있습니다. 여러 도구를 매칭하려면 `|`로 구분합니다.

## 테스트

각 훅에 대해 bats-core 단위 테스트가 작성되어 있습니다 (총 122 tests):

| 훅 | 테스트 수 | 파일 |
|----|-----------|------|
| setup-check.sh | 6 | `tests/hooks/setup-check.bats` |
| guard-shell.sh | 23 | `tests/hooks/guard-shell.bats` |
| usage-tracker.sh | 62 | `tests/hooks/usage-tracker.bats` |
| recovery.sh | 10 | `tests/hooks/recovery.bats` |
| todo-continuation.sh | 10 | `tests/hooks/todo-continuation.bats` |
| comment-checker.sh | 11 | `tests/hooks/comment-checker.bats` |

실행 방법:
```bash
bats .cursor/tests/hooks/guard-shell.bats   # 개별 훅 테스트
bash .cursor/tests/run-all.sh               # 전체 테스트
```

## 새 훅 추가 방법

1. `.cursor/hooks/`에 스크립트 생성
2. `chmod +x` 실행 권한 부여
3. `hooks.json`에 이벤트와 경로 등록

```json
{
  "preToolUse": [
    {
      "command": ".cursor/hooks/my-guard.sh",
      "matcher": "Shell"
    }
  ]
}
```

스크립트는 반드시 stdin에서 JSON을 소비하고, stdout으로 JSON을 출력해야 합니다.
